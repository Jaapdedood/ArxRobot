package com.arxterra.utils
{
	import com.arxterra.controllers.CameraManager;
	import com.arxterra.controllers.SessionManager;
	import com.arxterra.controllers.WaypointsManager;
	import com.arxterra.icons.IconModeSmRobotCS;
	import com.arxterra.vo.CameraConfig;
	import com.arxterra.vo.CameraMove;
	import com.arxterra.vo.EmergencyFlags;
	import com.arxterra.vo.MessageByteArray;
	import com.arxterra.vo.MessageData;
	import com.arxterra.vo.MoveProps;
	import com.arxterra.vo.Ping;
	import com.arxterra.vo.SfsPreset;
	import com.arxterra.vo.ShortXY;
	import com.arxterra.vo.UserState;
	import com.arxterra.vo.WaypointCoordinates;
	import com.arxterra.vo.WaypointsList;
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.Room;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.variables.SFSRoomVariable;
	import com.smartfoxserver.v2.entities.variables.SFSUserVariable;
	import com.smartfoxserver.v2.redbox.events.RedBoxConnectionEvent;
	import com.smartfoxserver.v2.requests.CreateRoomRequest;
	import com.smartfoxserver.v2.requests.JoinRoomRequest;
	import com.smartfoxserver.v2.requests.LoginRequest;
	import com.smartfoxserver.v2.requests.LogoutRequest;
	import com.smartfoxserver.v2.requests.PrivateMessageRequest;
	import com.smartfoxserver.v2.requests.RoomEvents;
	import com.smartfoxserver.v2.requests.RoomPermissions;
	import com.smartfoxserver.v2.requests.RoomSettings;
	import com.smartfoxserver.v2.requests.SetRoomVariablesRequest;
	import com.smartfoxserver.v2.requests.SetUserVariablesRequest;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.system.Security;
	import flash.utils.Timer;
	
	import mx.collections.ArrayList;
	
	import away3d.core.math.MathConsts;
	
	
	/**
	 * Pilot connector for the Client-Server operational
	 * mode, which depends upon the SmartFoxServer.
	 */
	[Bindable]
	public class PilotConnectorCS extends PilotConnector
	{
		// CONSTANTS
		
		private const _ROOM_VAR_MSECS:int = 5000;
		private const _USER_VAR_MSECS:int = 250;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function get connectPresetsList ( ) : ArrayList
		{
			return new ArrayList ( _aPresets );
		}
		
		[Bindable (event="icon_changed")]
		override public function get icon ( ) : Object
		{
			return IconModeSmRobotCS;
		}
		
		public var connectPresetTypical:SfsPreset;
		public var connectPrompt:String;
		
		public function get connectSettings():SfsPreset
		{
			return _connectSettings;
		}
		public function set connectSettings(value:SfsPreset):void
		{
			if ( value )
			{
				_connectSettings = value.clone ( );
				_sessionMgr.userState.sfsConfig = value;
			}
			else
			{
				_connectSettings = value;
			}
		}
		
		public var loginAssetsDir:String;
		public var loginPilotNames:String;
		public var loginPrompt:String;
		public var loginRobotName:String;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @copy PilotConnectorCS
		 */
		public function PilotConnectorCS ( )
		{
			super ( );
			// NOTE: Do not call init() here, because it
			// is called in the superclass constructor.
		}
		
		override public function dismiss ( ) : void
		{
			_wpsMgr = null;
			
			_ConnectTimerDismiss ( );
			
			_sessionMgr.removeEventListener ( SessionManager.APP_RESIZED, _AppResized );
			_sessionMgr.removeEventListener ( SessionManager.AV_SENDER_METADATA_CHANGED, _AvSenderMetadataUpdate );
			
			_WatchDogDismiss ( );
			
			if ( _tmrRoomVars )
			{
				_tmrRoomVars.stop ( );
				_tmrRoomVars.removeEventListener ( TimerEvent.TIMER, _RoomVarsQueuedSend );
				_tmrRoomVars = null;
			}
			
			if ( _tmrUserVars )
			{
				_tmrUserVars.stop ( );
				_tmrUserVars.removeEventListener ( TimerEvent.TIMER, _UserVarsQueuedSend );
				_tmrUserVars = null;
			}
			
			if ( _camMgr )
			{
				_camMgr.removeEventListener ( CameraManager.CAMERA_CHANGED, _AvSenderCameraChanged );
				_camMgr.removeEventListener ( CameraManager.CAMERA_CONFIG_CHANGED, _AvSenderConfigChanged );
				_camMgr.removeEventListener ( CameraManager.CAMERA_DIMENSIONS_READY, _AvSenderDimensionsReady );
				_camMgr.removeEventListener ( CameraManager.CAMERA_INSET_ALIGN_H, _AvSenderMonitorUpdateQueue );
				_camMgr.removeEventListener ( CameraManager.CAMERA_INSET_ALIGN_V, _AvSenderMonitorUpdateQueue );
				_camMgr.removeEventListener ( CameraManager.CAMERA_INSET_SIZE, _AvSenderMonitorUpdateQueue );
				_camMgr.removeEventListener ( CameraManager.CAMERA_MONITOR, _AvSenderMonitorUpdateQueue );
				_camMgr.enabled = false;
				_camMgr = null;
			}
			
			if ( _sf )
			{
				
				// SmartFox event listeners
				_sf.removeEventListener ( SFSEvent.CONNECTION, _Connection );
				_sf.removeEventListener ( SFSEvent.CONNECTION_LOST, _ConnectionLost );
				_sf.removeEventListener ( SFSEvent.PING_PONG, _LagMonitorUpdate );
				_sf.removeEventListener ( SFSEvent.LOGIN_ERROR, _LoginFailed );
				_sf.removeEventListener ( SFSEvent.LOGIN, _LoginSucceeded );
				_sf.removeEventListener ( SFSEvent.LOGOUT, _LogoutDone );
				_sf.removeEventListener ( SFSEvent.PRIVATE_MESSAGE, _PrivateMessageReceived );
				_sf.removeEventListener ( SFSEvent.ROOM_CREATION_ERROR, _RoomCreationError );
				_sf.removeEventListener ( SFSEvent.ROOM_JOIN, _JoinSuccess );
				_sf.removeEventListener ( SFSEvent.ROOM_JOIN_ERROR, _JoinFailure );
				_sf.removeEventListener ( SFSEvent.USER_COUNT_CHANGE, _UserCountChanged );
				_sf.removeEventListener ( SFSEvent.USER_ENTER_ROOM, _UserEnteredRoom );
				_sf.removeEventListener ( SFSEvent.USER_EXIT_ROOM, _UserExitedRoom );
				
				if ( _sf.isConnected )
				{
					if ( _sf.currentZone.length > 0 )
					{
						_AvCastMgrDismiss ( );
						_sf.send ( new LogoutRequest ( ) );
					}
					_sf.disconnect ( );
				}
				_sf = null;
			}
			
			super.dismiss ( );
		}
		
		/**
		 * Called automatically by superclass during instantiation,
		 * but may also be called manually to reactivate
		 * if object was previously dismissed.
		 * Subclass overrides must call super.init().
		 */
		override public function init ( ) : void
		{
			super.init ( );
			
			var userState:UserState = _sessionMgr.userState;
			_connectSettings = userState.sfsConfig;
			
			loginAssetsDir = userState.assetsDir;
			loginPilotNames = userState.pilotNames;
			loginPrompt = '';
			loginRobotName = userState.robotName;
			
			_tmrUserVars = new Timer ( _USER_VAR_MSECS, 0 );
			_tmrUserVars.addEventListener ( TimerEvent.TIMER, _UserVarsQueuedSend );
			
			_tmrRoomVars = new Timer ( _ROOM_VAR_MSECS, 0 );
			_tmrRoomVars.addEventListener ( TimerEvent.TIMER, _RoomVarsQueuedSend );
			
			_WatchDogInit ( );
			
			_wpsMgr = WaypointsManager.instance;
			
			// instantiate SmartFox client class
			_sf = new SmartFox ( _sessionMgr.debugOn );
			_debugOut ( 'status_sfs_api', true, [ _sf.version ] );
			
			// SmartFox event listeners
			_sf.addEventListener ( SFSEvent.CONNECTION, _Connection );
			_sf.addEventListener ( SFSEvent.CONNECTION_LOST, _ConnectionLost );
			_sf.addEventListener ( SFSEvent.PING_PONG, _LagMonitorUpdate );
			_sf.addEventListener ( SFSEvent.LOGIN_ERROR, _LoginFailed );
			_sf.addEventListener ( SFSEvent.LOGIN, _LoginSucceeded );
			_sf.addEventListener ( SFSEvent.LOGOUT, _LogoutDone );
			_sf.addEventListener ( SFSEvent.PRIVATE_MESSAGE, _PrivateMessageReceived );
			_sf.addEventListener ( SFSEvent.ROOM_CREATION_ERROR, _RoomCreationError );
			_sf.addEventListener ( SFSEvent.ROOM_JOIN, _JoinSuccess );
			_sf.addEventListener ( SFSEvent.ROOM_JOIN_ERROR, _JoinFailure );
			_sf.addEventListener ( SFSEvent.USER_COUNT_CHANGE, _UserCountChanged );
			_sf.addEventListener ( SFSEvent.USER_ENTER_ROOM, _UserEnteredRoom );
			_sf.addEventListener ( SFSEvent.USER_EXIT_ROOM, _UserExitedRoom );
			
			_camMgr = CameraManager.instance;
			_camMgr.addEventListener ( CameraManager.CAMERA_CHANGED, _AvSenderCameraChanged );
			_camMgr.addEventListener ( CameraManager.CAMERA_CONFIG_CHANGED, _AvSenderConfigChanged );
			_camMgr.addEventListener ( CameraManager.CAMERA_DIMENSIONS_READY, _AvSenderDimensionsReady );
			_camMgr.addEventListener ( CameraManager.CAMERA_INSET_ALIGN_H, _AvSenderMonitorUpdateQueue );
			_camMgr.addEventListener ( CameraManager.CAMERA_INSET_ALIGN_V, _AvSenderMonitorUpdateQueue );
			_camMgr.addEventListener ( CameraManager.CAMERA_INSET_SIZE, _AvSenderMonitorUpdateQueue );
			_camMgr.addEventListener ( CameraManager.CAMERA_MONITOR, _AvSenderMonitorUpdateQueue );
			_camMgr.enabled = true;
			
			_sessionMgr.addEventListener ( SessionManager.AV_SENDER_METADATA_CHANGED, _AvSenderMetadataUpdate );
			_sessionMgr.addEventListener ( SessionManager.APP_RESIZED, _AppResized );
			
			_callLater ( _PresetsLoad );
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Stop the outbound AV stream
		 * @return Boolean <b>true</b> if stream was on
		 */
		override public function avSenderClear ( ) : Boolean
		{
			var bWasOn:Boolean = false;
			
			_AvSenderMonitorClear ( );
			
			if ( _nsSndr != null )
			{
				bWasOn = true;
				_avCastMgr.unpublishLiveCast ( );
				_nsSndr = null;
			}
			
			return bWasOn;
		}
		
		/**
		 * Start the outbound AV stream
		 */
		override public function avSenderPublish ( ) : void
		{
			avSenderClear ( );
			
			if ( !_sessionMgr.testCfgMediaStreamAllow )
				return;
			
			// Publish my live cast
			if ( !_avCastMgr )
				return;
			
			if ( !_avCastMgr.isConnected )
				return;
			
			var bOk:Boolean = true;
			var aParams:Array;
			var sRsrc:String;
			var sStat:String;
			var bVidOk:Boolean = _camMgr.cameraEnabled;
			var bAudOk:Boolean = _camMgr.microphoneEnabled;
			if ( bVidOk || bAudOk )
			{
				try
				{
					_nsSndr = _avCastMgr.publishLiveCast ( bVidOk, bAudOk );
					if ( !_nsSndr )
					{
						sRsrc = 'error_livecast_stream_null';
						bOk = false;
					}
				}
				catch ( err:Error )
				{
					sRsrc = 'error_livecast_publish';
					aParams = [ err.message ];
					bOk = false;
				}
				if ( bOk )
				{
					// stream has initialized successfully
					sRsrc = 'status_livecast_publish';
					_camMgr.dimensionsCheck ( );
				}
			}
			else
			{
				sRsrc = 'status_livecast_no_permit';
			}
			sStat = _resourceManager.getString ( 'default', sRsrc, aParams );
			_debugOut ( sStat );
			_sessionMgr.statusSet ( sStat );
		}
		
		public function connectQueue ( preset:SfsPreset = null ) : void
		{
			if ( preset )
			{
				// called from connect view
				connectSettings = preset;
				_sessionMgr.viewStatePop ( 'connect_prompt_cs' );
			}
			Security.loadPolicyFile ( 'xmlsocket://' + connectSettings.host + ':' + connectSettings.port );
			if ( _sf && _sf.isConnected )
			{
				if ( !_sf.lastJoinedRoom )
				{
					_sessionMgr.viewStatePush ( 'login_prompt_cs' );
				}
			}
			else
			{
				_callLater ( _Connect );
			}
		}
		
		public function connectToggle ( ) : void
		{
			if ( _sf )
			{
				if ( _sf.isConnected )
				{
					disconnectQueue ( );
				}
				else
				{
					connectQueue ( );
				}
			}
		}
		
		public function disconnectQueue ( ) : void
		{
			if ( _sf.isConnected )
			{
				if ( _sf.currentZone.length > 0 )
				{
					_AvCastMgrDismiss ( );
					_sf.send ( new LogoutRequest ( ) );
				}
				else
				{
					_sf.disconnect ( );
				}
			}
		}
		
		public function lagMonitorAllowed ( value:Boolean ) : void
		{
			if ( !_sleeping && _sf && _sf.isConnected )
			{
				_sf.enableLagMonitor ( value );
			}
		}
		
		/**
		 * @param verbose Boolean true if to report errors to user
		 * @return Boolean true if validates okay, false if not
		 */
		public function loginRequestQueue (
			robotName:String,
			pilotNames:String,
			assetsDir:String,
			verbose:Boolean = true
		) : Boolean
		{
			if ( loginValidate ( robotName, pilotNames, assetsDir, verbose ) )
			{
				// validated ok
				
				// for now no passwords needed
				_LoginAttempt ( loginRobotName );
				return true; // return
			}
			
			return false;
		}
		
		public function loginValidate (
			robotName:String,
			pilotNames:String,
			assetsDir:String,
			verbose:Boolean = true
		) : Boolean
		{
			
			var reEnds:RegExp = /^\s+|\s+$/g;
			var reExcess:RegExp = /\s{2,}/g;
			var sRobotName:String = robotName.replace ( reEnds, '' );
			sRobotName = sRobotName.replace ( reExcess, ' ' );
			var sRobotNameLc:String = sRobotName.toLowerCase ( );
			var iLen:int = sRobotName.length;
			var bError:Boolean = false;
			var aLobbyNames:Array = [ 'lobby', 'lounge' ];
			var aPilots:Array = [];
			if ( iLen < 3 || iLen > 32 || aLobbyNames.indexOf ( sRobotNameLc ) >= 0 )
			{
				// invalid Robot name
				bError = true;
			}
			else
			{
				var sPilots:String = pilotNames.replace ( reEnds, '' );
				sPilots = sPilots.replace ( reExcess, ' ' );
				if ( sPilots.length < 3 )
				{
					// invalid Pilot name
					bError = true;
				}
				else
				{
					aPilots = sPilots.split ( /\s*,\s*/ );
					var iLim:int = aPilots.length;
					var i_sName:String;
					var i_sNameLc:String;
					for ( var i:int=0; i<iLim; i++ )
					{
						i_sName = aPilots [ i ];
						i_sNameLc = i_sName.toLowerCase ( );
						iLen = i_sName.length;
						if ( iLen < 3 || iLen > 32 || aLobbyNames.indexOf ( i_sNameLc ) >= 0 || i_sNameLc == sRobotNameLc )
						{
							// invalid Pilot name
							bError = true;
							break;
						}
					}
					sPilots = aPilots.join ( ',' );
				}
			}
			
			loginRobotName = sRobotName;
			loginPilotNames = sPilots;
			loginAssetsDir = assetsDir.replace ( reEnds, '' );
			
			if ( bError )
			{
				var sErr:String = _resourceManager.getString ( 'default', 'error_login_name' );
				// _debugOut ( sErr );
				if ( verbose )
				{
					loginPrompt = sErr;
					// dispatchEvent ( new DialogEvent ( DialogEvent.ALERT, 'error_login_name', 'error_login_name_title' ) );
				}
				_hasValidLoginSet ( false );
				return false; // return
			}
			
			// if get here, have reasonable entries
			_vsPilots = Vector.<String> ( aPilots );
			
			loginPrompt = '';
			var userState:UserState = _sessionMgr.userState;
			userState.robotName = loginRobotName;
			userState.pilotNames = loginPilotNames;
			userState.assetsDir = loginAssetsDir;
			
			_hasValidLoginSet ( true );
			return true;
		}
		
		public function mediaStreamAllowed ( value:Boolean ) : void
		{
			if ( value )
			{
				if ( !_sleeping )
				{
					_AvCastMgrInit ( );
				}
			}
			else
			{
				_AvCastMgrDismiss ( );
			}
		}
		
		override public function roomVarsQueue ( vars:Vector.<MessageData>, immediate:Boolean = false ) : void
		{
			// only keeping the latest value if any repeats
			var i:int;
			var iLim:int = vars.length;
			var i_md:MessageData;
			for ( i=0; i<iLim; i++ )
			{
				i_md = vars [ i ];
				_roomVarsQueued [ i_md.message ] = i_md;
			}
			if ( immediate )
			{
				if ( _sf && _sf.isConnected )
				{
					_RoomVarsQueuedSend ( );
				}
			}
		}
		
		override public function sleep ( ) : void
		{
			super.sleep ( );
			if ( _sf && _sf.isConnected && _sessionMgr.testCfgLagMonSfAllow )
			{
				_sf.enableLagMonitor ( false );
			}
			_TimersCancelAll ( );
			_AvCastMgrDismiss ( );
		}
		
		override public function userVarsQueue ( vars:Vector.<MessageData>, immediate:Boolean = false ) : void
		{
			// only keeping the latest value if any repeats
			var i:int;
			var iLim:int = vars.length;
			var i_md:MessageData;
			for ( i=0; i<iLim; i++ )
			{
				i_md = vars [ i ];
				_userVarsQueued [ i_md.message ] = i_md;
			}
			if ( immediate )
			{
				if ( _sf && _sf.isConnected )
				{
					_UserVarsQueuedSend ( );
				}
			}
		}
		
		override public function wake ( ) : void
		{
			super.wake ( );
			if ( _sf && _sf.isConnected && _sf.lastJoinedRoom )
			{
				if ( _sessionMgr.testCfgLagMonSfAllow )
				{
					_sf.enableLagMonitor ( true );
				}
				_tmrUserVars.start ( );
				_tmrRoomVars.start ( );
				_callLater ( _AvCastMgrInit );
			}
		}
		
		public function watchDogsAllowed ( value:Boolean ) : void
		{
			userVarsQueue ( new <MessageData> [ new MessageData ( 'wdge', value ) ] );
			if ( value )
			{
				_WatchDogInit ( );
			}
			else
			{
				_WatchDogDismiss ( );
			}
			
		}
		
		
		// PROTECTED METHODS
		
		override protected function _debugChanged ( value:Boolean ) : void
		{
			super._debugChanged ( value );
			if ( _sf )
			{
				_sf.debug = value;
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _aPresets:Array;
		private var _avCastMgr:AVCastManagerArx;
		private var _bMonUpdtQueued:Boolean = false;
		private var _bSndrPubQueued:Boolean = false;
		private var _camMgr:CameraManager;
		private var _connectSettings:SfsPreset;
		private var _iPilotUserId:int = 0;
		// will update _iSfsLagRT to latest average from SmartFox's lag monitoring
		private var _iSfsLagRT:int = 200;
		private var _nsRcvr:NetStream;
		private var _nsSndr:NetStream;
		private var _sf:SmartFox;
		private var _tmrConnect:Timer; // connection timeout
		private var _tmrDog:Timer; // watch dog timer
		private var _tmrRoomVars:Timer; // send queued room variables
		private var _tmrUserVars:Timer; // send queued user variables
		private var _vidRcvr:Video;
		private var _vidSndr:Video;
		private var _vsPilots:Vector.<String>;
		// private var _vsPilotsQueue:Vector.<String> = new <String> [];
		private var _wpsMgr:WaypointsManager;
		
		// PRIVATE METHODS
		
		private function _AppResized ( event:Event = null ) : void
		{
			_AvSenderPublishQueue ( );
		}
		
		private function _AvCastMgrDismiss ( ) : void
		{
			if ( !_avCastMgr )
				return;
			
			avSenderClear ( );
			avReceiverClear ( );
			
			_avCastMgr.removeEventListener ( RedBoxConnectionEvent.AV_CONNECTION_INITIALIZED, _AvConnectionInited );
			_avCastMgr.removeEventListener ( RedBoxConnectionEvent.AV_CONNECTION_ERROR, _AvConnectionError );
			_avCastMgr.destroy ( );
			_avCastMgr = null;
		}
		
		private function _AvCastMgrInit ( ) : void
		{
			if ( !_sessionMgr.testCfgMediaStreamAllow )
				return;
			
			_sessionMgr.statusSetResource ( 'status_sfs_livecast_wait' );
			
			// instantiate AVCastManager
			_avCastMgr = new AVCastManagerArx ( _sf, _sf.currentIp, false, true );
			
			_avCastMgr.addEventListener ( RedBoxConnectionEvent.AV_CONNECTION_INITIALIZED, _AvConnectionInited );
			_avCastMgr.addEventListener ( RedBoxConnectionEvent.AV_CONNECTION_ERROR, _AvConnectionError );
		}
		
		private function _AvConnectionError ( event:RedBoxConnectionEvent ) : void
		{
			var sStat:String = _resourceManager.getString ( 'default', 'error_av_connect', [ event.params.errorCode ] );
			_debugOut ( sStat );
			_sessionMgr.statusSet ( sStat );
		}
		
		private function _AvConnectionInited ( event:RedBoxConnectionEvent ) : void
		{
			_AvSenderPublishQueue ( );
			avReceiverSubscribe ( );
		}
		
		private function _AvSenderCameraChanged ( event:Event = null ) : void
		{
			_AvSenderPublishQueue ( );
		}
		
		private function _AvSenderConfigChanged ( event:Event = null ) : void
		{
			if ( _sleeping )
				return;
			
			if ( !_nsSndr )
			{
				_AvSenderPublishQueue ( );
			}
		}
		
		private function _AvSenderDimensionsReady ( event:Event = null ) : void
		{
			_AvSenderMetadataUpdate ( );
		}
		
		private function _AvSenderMetadataUpdate ( event:Event = null ) : void
		{
			// Send video transform factors to Control Panel
			userVarsQueue ( new <MessageData> [
				new MessageData ( 'cvfh', _sessionMgr.userState.cameraFlipHorizontal ),
				new MessageData ( 'cvfv', _sessionMgr.userState.cameraFlipVertical ),
				new MessageData ( 'cvr', _sessionMgr.videoSenderRotation )
			] );
			// if monitoring outbound video, update its dimensions
			_AvSenderMonitorUpdateQueue ( );
		}
		
		private function _AvSenderMonitorClear ( ) : void
		{
			if ( !_vidSndr )
				return;
			
			_vidSndr.attachCamera ( null );
			_vidSndr.clear ( );
			_sessionMgr.videoPod.removeChild ( _vidSndr );
			_vidSndr = null;
		}
		
		private function _AvSenderMonitorUpdate ( event:TimerEvent ) : void
		{
			_bMonUpdtQueued = false;
			var tmr:Timer = event.target as Timer;
			tmr.stop ( );
			tmr.removeEventListener ( TimerEvent.TIMER, _AvSenderMonitorUpdate );
			tmr = null;
			
			_AvSenderMonitorClear ( );
			
			if ( !_sessionMgr.testCfgMediaStreamAllow )
				return; // return
			
			if ( !_camMgr.monitor )
				return; // return
			
			if ( !_avCastMgr )
				return; // return
			
			if ( !_avCastMgr.isConnected )
				return; // return
			
			var iVidPodHt:int = _sessionMgr.videoPodHeight;
			var iVidPodWd:int = _sessionMgr.videoPodWidth;
			var iVidHt:int = _camMgr.cameraHeight;
			var iVidWd:int = _camMgr.cameraWidth;
			var nVidHtRot:Number;
			var nVidWdRot:Number;
			var nVidHtPost:Number;
			var nVidWdPost:Number;
			var nScale:Number;
			if ( _sessionMgr.orientedPortrait )
			{
				nVidHtRot = iVidWd;
				nVidWdRot = iVidHt;
			}
			else
			{
				nVidHtRot = iVidHt;
				nVidWdRot = iVidWd;
			}
			if ( _sessionMgr.videoPodAspectRatio < ( nVidHtRot / nVidWdRot ) )
			{
				// height is limiting
				nScale = _camMgr.insetSize * iVidPodHt / nVidHtRot;
			}
			else
			{
				// width is limiting
				nScale = _camMgr.insetSize * iVidPodWd / nVidWdRot;
			}
			// calculate post-transform dimensions
			nVidHtPost = nScale * nVidHtRot;
			nVidWdPost = nScale * nVidWdRot;
			// create transform matrix
			// to position the video in the videoPod
			var mat:Matrix = new Matrix ( );
			// move center to origin
			mat.translate ( -iVidWd / 2, -iVidHt / 2 );
			// apply rotation if necessary
			if ( _sessionMgr.orientedPortrait )
			{
				mat.rotate ( _sessionMgr.videoSenderRotation * MathConsts.DEGREES_TO_RADIANS );
			}
			// apply scale
			var userState:UserState = _sessionMgr.userState;
			mat.scale ( nScale * ( userState.cameraFlipHorizontal ? -1 : 1 ), nScale * ( userState.cameraFlipVertical ? -1 : 1 ) );
			// translate as dictated by alignment settings
			var oAlignVals:Object = {
				'left': -0.5, 'center': 0, 'right': 0.5,
				'top': -0.5, 'middle': 0, 'bottom': 0.5
			};
			// X translated by 1/2 pod width will center video horizontally.
			// To align left or right edges respectively, subtract or add
			// 1/2 the difference between pod width and video width.
			// Y translated by 1/2 pod height will center video vertically.
			// To align top or bottom edges respectively, subtract or add
			// 1/2 the difference between pod height and video height.
			mat.translate (
				iVidPodWd / 2 + ( iVidPodWd - nVidWdPost ) * ( oAlignVals [ _camMgr.insetAlignH ] as Number ),
				iVidPodHt / 2 + ( iVidPodHt - nVidHtPost ) * ( oAlignVals [ _camMgr.insetAlignV ] as Number )
			);
			// display video
			_vidSndr = new Video ( iVidWd, iVidHt );
			_vidSndr.transform.matrix = mat;
			_sessionMgr.videoPod.addChild ( _vidSndr );
			_vidSndr.attachCamera ( _camMgr.camera );
		}
		
		private function _AvSenderMonitorUpdateQueue ( event:Event = null ) : void
		{
			if ( _bMonUpdtQueued )
				return; // return
			
			_bMonUpdtQueued = true;
			var tmr:Timer = new Timer ( 20, 1 );
			tmr.addEventListener ( TimerEvent.TIMER, _AvSenderMonitorUpdate );
			tmr.start ( );
		}
		
		private function _AvSenderPublish ( event:TimerEvent ) : void
		{
			_bSndrPubQueued = false;
			var tmr:Timer = event.target as Timer;
			tmr.stop ( );
			tmr.removeEventListener ( TimerEvent.TIMER, _AvSenderPublish );
			tmr = null;
			
			avSenderPublish ( );
		}
		
		private function _AvSenderPublishQueue ( event:Event = null ) : void
		{
			if ( _bSndrPubQueued )
				return; // return
			
			_bSndrPubQueued = true;
			var tmr:Timer = new Timer ( 20, 1 );
			tmr.addEventListener ( TimerEvent.TIMER, _AvSenderPublish );
			tmr.start ( );
		}
		
		private function _CameraRestartRequest ( ) : void
		{
			/*
			if ( _sessionMgr.moveIgnore )
			{
				_debugOut ( 'cameraRestartRequest discarded due to emergency flags: ' + _sessionMgr.emergencyFlagsGet() );
				return; // return
			}
			*/
			_AvSenderPublishQueue ( );
		}
		
		private function _Connect ( ) : void
		{
			if ( _sf.isConnected )
			{
				return; // return
			}
			_sessionMgr.statusSetResource ( 'status_sfs_connect_wait', true );
			_ConnectTimerInit ( );
			_isPendingSet ( true );
			_sf.connectWithConfig ( connectSettings.configData );
			// _sessionMgr.viewStatePop ( 'connect_prompt_cs' );
		}
		
		private function _Connection ( event:SFSEvent ) : void
		{
			_ConnectTimerDismiss ( );
			var sStat:String;
			if ( event.params.success )
			{
				_isConnectedSet ( true );
				sStat = _resourceManager.getString ( 'default', 'status_sfs_connect' );
				_sessionMgr.statusSet ( sStat );
				_debugOut ( sStat );
				// _sessionMgr.viewStatePush ( 'login_prompt_cs' );
				_LoginAttempt ( loginRobotName );
			}
			else
			{
				_isConnectedSet ( false );
				_isPendingSet ( false );
				connectPrompt = _resourceManager.getString ( 'default', 'error_sfs_connect', [ event.params.errorMessage ] );
				_sessionMgr.statusSet ( connectPrompt );
				_debugOut ( connectPrompt );
				_sessionMgr.viewStatePush ( 'connect_config_cs' );
			}
		}
		
		private function _ConnectionLost ( event:SFSEvent ) : void
		{
			_isConnectedSet ( false );
			_isPendingSet ( false );
			_isReadySet ( false );
			_TimersCancelAll ( );
			_AvCastMgrDismiss ( );
			connectPrompt = _resourceManager.getString ( 'default', 'error_sfs_connect_lost', [ event.params.reason ] );
			_sessionMgr.statusSet ( connectPrompt );
			_debugOut (connectPrompt );
			// _sessionMgr.viewStatePush ( 'connect_prompt_cs' );
		}
		
		private function _ConnectTimeout ( event:TimerEvent ) : void
		{
			_ConnectTimerDismiss ( );
			_sf.disconnect ( ); // just in case of a race condition
			_isConnectedSet ( false );
			_isPendingSet ( false );
			_isReadySet ( false );
			connectPrompt = _resourceManager.getString ( 'default', 'error_sfs_connect_timeout' );
			_sessionMgr.statusSet ( connectPrompt );
			_debugOut ( connectPrompt );
			// _sessionMgr.viewStatePush ( 'connect_prompt_cs' );
		}
		
		private function _ConnectTimerDismiss ( ) : void
		{
			if ( !_tmrConnect )
				return;
			
			_tmrConnect.stop ( );
			_tmrConnect.removeEventListener ( TimerEvent.TIMER, _ConnectTimeout );
			_tmrConnect = null;
		}
		
		private function _ConnectTimerInit ( ) : void
		{
			if ( !_tmrConnect )
			{
				_tmrConnect = new Timer ( 10000, 1 );
				_tmrConnect.addEventListener ( TimerEvent.TIMER, _ConnectTimeout );
			}
			_tmrConnect.reset ( );
			_tmrConnect.start ( );
		}
		
		private function _HaveValidPilotId ( ) : Boolean
		{
			
			if ( _iPilotUserId < 1 )
				return false;
			
			if ( _sf.lastJoinedRoom )
			{
				if ( _sf.lastJoinedRoom.getUserById ( _iPilotUserId ) )
				{
					return true;
				}
			}
			
			_iPilotUserId = 0;
			return false;
		}
		
		private function _JoinFailure ( event:SFSEvent ) : void
		{
			_debugOut ( 'error_sfs_join', true, [ event.params.errorMessage ], true );
			
			// ##### TODO #####
			_callLater ( _Logout );
		}
		
		private function _JoinSuccess ( event:SFSEvent ) : void
		{
			var sStat:String = _resourceManager.getString ( 'default', 'status_sfs_join', [ event.params.room.name ] );
			_debugOut ( sStat );
			_sessionMgr.statusSet ( sStat );
			_isPendingSet ( false );
			_isReadySet ( true );
			// prepare for av feeds
			_callLater ( _AvCastMgrInit );
			// initialize user and room variables
			_sessionMgr.batchVarsReportQueue ( );
			// start timers
			if ( _sessionMgr.testCfgLagMonSfAllow )
			{
				_sf.enableLagMonitor ( true );
			}
			_tmrUserVars.start ( );
			_tmrRoomVars.start ( );
		}
		
		private function _LagMonitorUpdate ( event:SFSEvent ) : void
		{
			_iSfsLagRT = event.params.lagValue;
		}
		
		private function _LoginAttempt ( userName:String = '', password:String = null, zoneName:String = null, params:ISFSObject = null ) : void
		{
			_sessionMgr.viewStatePop ( 'login_prompt_cs' );
			_sessionMgr.statusSetResource ( 'status_sfs_login_wait', true );
			_sf.send ( new LoginRequest ( userName, password, zoneName, params ) );
		}
		
		private function _LoginFailed ( event:SFSEvent ) : void
		{
			var sErr:String = _resourceManager.getString ( 'default', 'error_sfs_login', [ event.params.errorMessage ] );
			_debugOut ( sErr );
			loginPrompt = sErr;
			if ( _sf.isConnected )
			{
				_sessionMgr.viewStatePush ( 'login_prompt_cs' );
			}
		}
		
		private function _LoginSucceeded ( event:SFSEvent ) : void
		{
			_sessionMgr.statusSetResource ( 'status_sfs_join_wait', true );
			var sRobotName:String = _sessionMgr.userState.robotName;
			// debugOut ( 'status_sfs_login', true, [ event.params.user.name ] );
			if ( _sf.roomManager.containsRoom ( sRobotName ) )
			{
				// should not happen, but just in case...
				_sf.send ( new JoinRoomRequest ( sRobotName ) );
			}
			else
			{
				// create room and auto-join
				var re:RoomEvents = new RoomEvents ( );
				re.allowUserCountChange = true;
				re.allowUserEnter = true;
				re.allowUserExit = true;
				re.allowUserVariablesUpdate = true
				var rp:RoomPermissions = new RoomPermissions ( );
				rp.allowPublicMessages = true;
				var rs:RoomSettings = new RoomSettings ( sRobotName );
				rs.events = re;
				rs.permissions = rp;
				rs.maxUsers = 100;
				rs.maxVariables = 100;
				
				_sf.send ( new CreateRoomRequest ( rs, true ) );
			}
		}
		
		private function _Logout ( ) : void
		{
			if ( _sf.isConnected )
			{
				_sf.send ( new LogoutRequest ( ) );
			}
		}
		
		private function _LogoutDone ( event:SFSEvent ) : void
		{
			_sf.disconnect ( );
		}
		
		private function _PilotCheck ( room:Room, userLeaving:User = null ) : void
		{
			if ( room != _sf.lastJoinedRoom )
				return;
			
			var bPiloted:Boolean = room.getVariable ( 'pib' ).getBoolValue ( );
			var sPilot:String = room.getVariable ( 'pic' ).getStringValue ( );
			if ( !bPiloted )
			{
				_iPilotUserId = 0;
				_sessionMgr.emergencyFlagsClear ( EmergencyFlags.LATENCY );
			}
			else if ( room.getUserByName ( sPilot ) == null || ( userLeaving != null && userLeaving.name == sPilot ) )
			{
				// pilot exited room
				var aRoomVars:Array = [
					new SFSRoomVariable ( 'pib', false ),
					new SFSRoomVariable ( 'pic', '' )
				];
				_sf.send ( new SetRoomVariablesRequest ( aRoomVars ) );
				_iPilotUserId = 0;
				_sessionMgr.emergencyFlagsClear ( EmergencyFlags.LATENCY );
			}
		}
		
		private function _PingReceived ( sfso:ISFSObject ) : void
		{
			var ping:Ping = Ping.newFromSFSObject ( sfso );
			ping.robotTimeStamp = new Date().getTime();
			ping.robotLagSfs = _iSfsLagRT;
			_sf.send ( new PrivateMessageRequest ( 'pong', _iPilotUserId, ping.toSFSObject() ) );
			if ( _sleeping )
			{
				if ( _sessionMgr.batterySupported && _sessionMgr.testCfgBatteryAllow )
				{
					userVarsQueue (
						new <MessageData> [
							new MessageData ( 'pbt', _sessionMgr.batteryPct )
						],
						true
					);
				}
			}
			_WatchDogIntervalSet ( ping.intervalMsecs );
		}
		
		private function _PresetsLoad ( ) : void
		{
			_callLater ( _PrevLoginValidate );
			
			connectPrompt = _resourceManager.getString ( 'default', 'sfs_connect_config_prompt' );
			
			var f:File = File.applicationDirectory.resolvePath ( 'config/sfs-presets.json' );
			var sStat:String;
			if ( !f.exists )
			{
				sStat = _resourceManager.getString ( 'default', 'error_sfs_presets' );
				_debugOut ( sStat );
				_sessionMgr.statusSet ( sStat );
				_sessionMgr.viewStatePush ( 'connect_config_cs' );
				return; // return
			}
			
			// build arrayList of presets, and pre-select the default one
			var sIdDef:String = '';
			_aPresets = [];
			var uPresetsLen:uint = 0;
			var spDef:SfsPreset;
			var spTyp:SfsPreset;
			
			try
			{
				var fs:FileStream = new FileStream();
				// open
				fs.open ( f, FileMode.READ );
				
				// read
				var sJson:String = fs.readUTFBytes ( fs.bytesAvailable );
				
				// close
				fs.close ( );
				
				// debugOut ( sJson );
				
				var oJson:Object = JSON.parse ( sJson );
				
				if ( 'configs' in oJson )
				{
					if ( 'default' in oJson )
					{
						sIdDef = oJson [ 'default' ];
					}
					var iLabelLen:int = 0;
					var oCfgs:Object = oJson [ 'configs' ];
					var i_sId:String;
					var i_sLoc:String;
					var i_iLen:int;
					var i_sp:SfsPreset;
					for ( i_sId in oCfgs )
					{
						i_sp = new SfsPreset ( i_sId, oCfgs [ i_sId ] )
						_aPresets [ uPresetsLen++ ] = i_sp;
						if ( i_sId == sIdDef )
						{
							spDef = i_sp;
						}
						i_sLoc = _resourceManager.getString ( 'default', 'sfs_connect_preset_' + i_sId );
						if ( !i_sLoc )
						{
							i_sLoc = i_sId;
						}
						i_iLen = i_sLoc.length;
						if ( i_iLen > iLabelLen )
						{
							iLabelLen = i_iLen;
							spTyp = i_sp;
						}
					}
				}
			}
			catch ( err:Error )
			{
				sStat = _resourceManager.getString ( 'default', 'error_sfs_presets_load', [ err.message ] );
				_sessionMgr.statusSet ( sStat );
				_debugOut ( sStat, false, null, true );
				_sessionMgr.viewStatePush ( 'connect_config_cs' );
				return; // return
			}
			
			_aPresets.sortOn ( 'id', Array.CASEINSENSITIVE );
			connectPresetTypical = spTyp;
			if ( !_connectSettings )
			{
				connectSettings = spDef.clone ( );
			}
			/*
			if ( _sessionMgr.expertModeOn )
			{
			_sessionMgr.viewStatePush ( 'connect_prompt_cs' );
			}
			else
			{
			// if get here, can try autoconnect
			connectQueue ( );
			}
			*/
		}
		
		/**
		 * Validates login fields persisted from previous session, if any.
		 * If validation fails, goes to the login configuration view.
		 */		
		private function _PrevLoginValidate ( ) : void
		{
			if ( !loginValidate ( loginRobotName, loginPilotNames, loginAssetsDir, false ) )
			{
				_sessionMgr.viewStatePush ( 'login_config_cs' );
			}
		}
		
		private function _PrivateMessageReceived ( event:SFSEvent ) : void
		{
			var sender:User = event.params.sender;
			if ( sender == _sf.mySelf )
				return;
			
			// validate sender so control messages are only accepted from pilot
			var sSenderName:String = sender.name;
			if ( _vsPilots.indexOf ( sSenderName ) < 0 )
				return;
			
			_iPilotUserId = sender.id;
			
			if ( !_sleeping )
			{
				_WatchDogReset ( );
			}
			
			var sMsg:String = event.params.message;
			switch ( sMsg )
			{
				case 'ping':
				{
					_PingReceived ( event.params.data as ISFSObject );
					break;
				}
				case 'emsack':
				{
					_sessionMgr.emergencyAcknowledge ( );
					break;
				}
				case 'mv':
				{
					_sessionMgr.motionRequest ( MoveProps.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'cu':
				{
					_sessionMgr.customRequest ( MessageByteArray.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'cm':
				{
					_sessionMgr.cameraMoveRequest ( CameraMove.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'ch':
				{
					_sessionMgr.cameraMoveHomeRequest ( );
					break;
				}
				case 'cr':
				{
					_sessionMgr.cameraMoveResetRequest ( );
					break;
				}
				case 'cvk':
				{
					_sessionMgr.cameraViewClickRequest ( ShortXY.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'mcl':
				{
					_sessionMgr.motorCurrentLimitRequest ( ( event.params.data as ISFSObject ).getUnsignedByte ( 's' ) );
					break;
				}
				case 'stt':
				{
					_sessionMgr.steeringTrimRequest ( ( event.params.data as ISFSObject ).getDouble ( 't' ) );
					break;
				}
				case 'wp':
				{
					_debugOut ( 'New Waypoint message received' );
					_wpsMgr.waypointAdd ( WaypointCoordinates.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'wp0':
				{
					_debugOut ( 'Deactivate Autopilot message received' );
					_wpsMgr.active = false;
					break;
				}
				case 'wp1':
				{
					_debugOut ( 'Activate Autopilot message received' );
					_wpsMgr.active = true;
					break;
				}
				case 'wpca':
				{
					_debugOut ( 'Clear Waypoint List message received' );
					_wpsMgr.listClear ( );
					break;
				}
				case 'wpd':
				{
					_debugOut ( 'Delete Waypoint message received' );
					_wpsMgr.waypointDelete ( MessageByteArray.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'wpm':
				{
					_debugOut ( 'Move Waypoint message received' );
					_wpsMgr.waypointMove ( WaypointCoordinates.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'wpla':
				{
					_debugOut ( 'Append Waypoint List message received' );
					_wpsMgr.listAppend ( WaypointsList.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'wplr':
				{
					_debugOut ( 'Replace Waypoint List message received' );
					_wpsMgr.listReplace ( WaypointsList.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'fl':
				{
					_sessionMgr.light ( ( event.params.data as ISFSObject ).getBool ( 'b' ) );
					break;
				}
				case 'camerarestart':
				{
					_CameraRestartRequest ( );
					break;
				}
				case 'cameraconfig':
				{
					_camMgr.configRequest ( CameraConfig.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'cameraconfigadjust':
				{
					_camMgr.configAdjustRequest ( ( event.params.data as ISFSObject ).getBool ( 'b' ) );
					break;
				}
				case 'cameraconfigdef':
				{
					_camMgr.configDefaultRequest ( CameraConfig.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'cameraconfigmotion':
				{
					_camMgr.configMotionRequest ( CameraConfig.NewFromSFSObject ( event.params.data as ISFSObject ) );
					break;
				}
				case 'camerafpspollmsec':
				{
					_camMgr.fpsPollRequest ( ( event.params.data as ISFSObject ).getShort ( 'm' ) || 0 );
					break;
				}
				case 'sleep':
				{
					_sessionMgr.sleepRequest ( );
					break;
				}
				case 'wake':
				{
					_sessionMgr.wakeRequest ( );
					break;
				}
				case 'exit':
				{
					_sessionMgr.exitConfirmed ( );
					break;
				}
				default:
				{
					_debugOut ( 'error_control_message', true, [ sMsg ] );
					break;
				}
			}
		}
		
		private function _RoomCreationError ( event:SFSEvent ) : void
		{
			_debugOut ( 'error_sfs_room_creation', true, [ event.params.errorMessage ] );
			// now what?
			// ##### TODO
		}
		
		private function _RoomVarsQueuedSend ( event:TimerEvent = null ) : void
		{
			var vars:Array = [];
			var uLen:uint = 0;
			for each ( var i_md:MessageData in _roomVarsQueued )
			{
				if ( i_md.typeIsComplex )
				{
					vars [ uLen++ ] = new SFSRoomVariable ( i_md.message, i_md.data.toSFSObject() );
				}
				else
				{
					vars [ uLen++ ] = new SFSRoomVariable ( i_md.message, i_md.data );
				}
			}
			if ( uLen > 0 )
			{
				// prepare for next batch
				_roomVarsQueued = {};
				// send all the queued variables
				_sf.send ( new SetRoomVariablesRequest ( vars ) );
			}
		}
		
		private function _TimersCancelAll ( ) : void
		{
			_ConnectTimerDismiss ( );
			_WatchDogCancel ( );
			_tmrRoomVars.stop ( );
			_tmrUserVars.stop ( );
		}
		
		private function _UserCountChanged ( event:SFSEvent ) : void
		{
			_PilotCheck ( event.params.room );
		}
		
		private function _UserEnteredRoom ( event:SFSEvent ) : void
		{
			_PilotCheck ( event.params.room );
		}
		
		private function _UserExitedRoom ( event:SFSEvent ) : void
		{
			var room:Room = event.params.room;
			var user:User = event.params.user;
			if ( room.name == _sessionMgr.userState.robotName &&
				user == _sf.mySelf )
			{
				if ( _sessionMgr.testCfgLagMonSfAllow )
				{
					_sf.enableLagMonitor ( false );
				}
				_TimersCancelAll ( );
				_AvCastMgrDismiss ( );
			}
			else
			{
				_PilotCheck ( event.params.room, event.params.user );
			}
		}
		
		private function _UserVarsQueuedSend ( event:TimerEvent = null ) : void
		{
			var vars:Array = [];
			var uLen:uint = 0;
			for each ( var i_md:MessageData in _userVarsQueued )
			{
				if ( i_md.typeIsComplex )
				{
					vars [ uLen++ ] = new SFSUserVariable ( i_md.message, i_md.data.toSFSObject() );
				}
				else
				{
					vars [ uLen++ ] = new SFSUserVariable ( i_md.message, i_md.data );
				}
			}
			if ( uLen > 0 )
			{
				// prepare for next batch
				_userVarsQueued = {};
				// send all the queued variables
				_sf.send ( new SetUserVariablesRequest ( vars ) );
			}
		}
		
		private function _WatchDogBark ( event:TimerEvent ) : void
		{
			// Watch dog timer lapsed.
			if ( _HaveValidPilotId ( ) )
			{
				_debugOut ( 'status_watchdog', true, [ _tmrDog.delay ] );
				_sessionMgr.emergencyFlagsSet ( EmergencyFlags.LATENCY );
			}
		}
		
		private function _WatchDogCancel ( ) : void
		{
			if ( !_tmrDog )
				return;
			
			_tmrDog.stop ( );
		}
		
		private function _WatchDogDismiss ( ) : void
		{
			if ( !_tmrDog )
				return;
			
			_tmrDog.stop ( );
			_tmrDog.removeEventListener ( TimerEvent.TIMER, _WatchDogBark );
			_tmrDog = null;
		}
		
		private function _WatchDogInit ( ) : void
		{
			if ( !_sessionMgr.testCfgWatchDogsAllow )
				return;
			
			if ( !_tmrDog )
			{
				// default watch dog to 2.1 secs, then adjust when get current value from ping
				_tmrDog = new Timer ( 2100, 1 );
				_tmrDog.addEventListener ( TimerEvent.TIMER, _WatchDogBark );
			}
		}
		
		private function _WatchDogIntervalSet ( pingIntervalMsecs:int ) : void
		{
			if ( !_tmrDog )
				return;
			
			_tmrDog.reset ( );
			// allow a cushion on top of time until next expected ping
			var iNew:int = pingIntervalMsecs * 1.5 + _iSfsLagRT;
			if ( _tmrDog.delay != iNew )
				_tmrDog.delay = iNew;
			_tmrDog.start ( );
		}
		
		private function _WatchDogReset ( ) : void
		{
			if ( !_tmrDog )
				return;
			
			_tmrDog.reset ( );
			_tmrDog.start ( );
		}
	}
}