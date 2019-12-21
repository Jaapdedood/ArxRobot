package com.arxterra.controllers
{
	import com.arxterra.interfaces.IPermissionsChecker;
	import com.arxterra.utils.NonUIComponentBase;
	import com.arxterra.utils.PermissionsCheckerBase;
	import com.arxterra.vo.CameraConfig;
	import com.arxterra.vo.MessageData;
	import com.arxterra.vo.UserState;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.utils.Timer;
	
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.VerticalAlign;
	
	[Event(name="camera_changed", type="flash.events.Event")]
	[Event(name="camera_config_changed", type="flash.events.Event")]
	[Event(name="camera_dimensions_ready", type="flash.events.Event")]
	[Event(name="camera_inset_align_h", type="flash.events.Event")]
	[Event(name="camera_inset_align_v", type="flash.events.Event")]
	[Event(name="camera_inset_size", type="flash.events.Event")]
	[Event(name="camera_monitor", type="flash.events.Event")]
	
	public class CameraManager extends NonUIComponentBase
	{
		// CONSTANTS
		
		public static const CAMERA_CHANGED:String = 'camera_changed';
		public static const CAMERA_CONFIG_CHANGED:String = 'camera_config_changed';
		public static const CAMERA_DIMENSIONS_READY:String = 'camera_dimensions_ready';
		public static const CAMERA_INSET_ALIGN_H:String = 'camera_inset_align_h';
		public static const CAMERA_INSET_ALIGN_V:String = 'camera_inset_align_v';
		public static const CAMERA_INSET_SIZE:String = 'camera_inset_size';
		public static const CAMERA_MONITOR:String = 'camera_monitor';
		
		public static const INSET_SIZE_MAX:Number = 1.0;
		public static const INSET_SIZE_MIN:Number = 0.1;
		
		// CONSTRUCTOR AND INSTANCE
		
		/**
		 * Singleton: use static property <b>instance</b> to get a reference.
		 */
		public function CameraManager ( enforcer:SingletonEnforcer )
		{
			super();
			_sessionMgr = SessionManager.instance;
			_cfg = new CameraConfig ( );
			if ( _sessionMgr.permissionsChecker )
			{
				if ( _sessionMgr.permissionsChecker.cameraPermitted )
				{
					_cam = Camera.getCamera ( );
				}
				if ( _sessionMgr.permissionsChecker.microphonePermitted )
				{
					_mic = Microphone.getMicrophone ( );
				}
			}
		}
		
		/**
		 * Singleton instance
		 */
		public static function get instance ( ) : CameraManager
		{
			if ( !__instance )
			{
				__instance = new CameraManager ( new SingletonEnforcer ( ) );
			}
			return __instance;
		}
		
		private static var __instance:CameraManager;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="camera_changed")]
		public function get camera():Camera
		{
			if ( !_cam )
			{
				cameraSetByIndex ( ); // attempt to get a camera object now
			}
			return _cam;
		}
		public function set camera(value:Camera):void
		{
			if ( _sessionMgr.permissionsChecker && _sessionMgr.permissionsChecker.cameraPermitted )
			{
				if( _cam !== value)
				{
					_cam = value;
					_CfgApply ( );
					dispatchEvent ( new Event ( CAMERA_CHANGED ) );
				}
			}
		}
		
		public function get cameraEnabled():Boolean
		{
			return _bCamEnabled;
		}
		private function _CamEnabledSet(value:Boolean):void
		{
			if ( value != _bCamEnabled )
			{
				if ( value )
				{
					if ( _sessionMgr.permissionsChecker && _sessionMgr.permissionsChecker.cameraPermitted )
					{
						_bCamEnabled = true;
						motionSet ( _sessionMgr.isMoving );
						// apply current config
						_CfgApply ( );
					}
					else if ( _vPermRetries != null )
					{
						_vPermRetries.push ( _PermCamRetry );
					}
				}
				else
				{
					_bCamEnabled = false;
					_FpsTimerClear ( );
				}
			}
		}
		
		[Bindable (event="camera_dimensions_ready")]
		public function get cameraHeight():int
		{
			return _iHt;
		}
		
		[Bindable (event="camera_dimensions_ready")]
		public function get cameraWidth():int
		{
			return _iWd;
		}
		
		[Bindable (event="camera_config_changed")]
		public function get configActive():CameraConfig
		{
			return _cfg;
		}
		public function set configActive(value:CameraConfig):void
		{
			if ( _cfg !== value )
			{
				_cfg = value;
				_CfgApply ( );
				_CfgChangeEventDispatch ( );
			}
		}
		
		[Bindable]
		public function get enabled():Boolean
		{
			return _bEnabled;
		}
		public function set enabled(value:Boolean):void
		{
			_bEnabled = value;
			_vPermRetries = new <Function> [];
			_CamEnabledSet ( value );
			_MicEnabledSet ( value );
			if ( _vPermRetries.length > 0 )
			{
				_sessionMgr.permissionsChecker.addEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsDone );
			}
			else
			{
				_vPermRetries = null;
			}
		}
		
		[Inspectable (enumeration="center,left,right")]
		[Bindable(event="camera_inset_align_h")]
		public function get insetAlignH():String
		{
			return _sInsetAlignH;
		}
		public function set insetAlignH(value:String):void
		{
			if( _sInsetAlignH !== value)
			{
				_sInsetAlignH = value;
				dispatchEvent ( new Event ( CAMERA_INSET_ALIGN_H ) );
			}
		}
		
		[Inspectable (enumeration="bottom,middle,top")]
		[Bindable(event="camera_inset_align_v")]
		public function get insetAlignV():String
		{
			return _sInsetAlignV;
		}
		public function set insetAlignV(value:String):void
		{
			if( _sInsetAlignV !== value)
			{
				_sInsetAlignV = value;
				dispatchEvent ( new Event ( CAMERA_INSET_ALIGN_V ) );
			}
		}
		
		[Bindable(event="camera_inset_size")]
		/**
		 * Inset size as a fraction of the limiting dimension of video pod
		 */
		public function get insetSize():Number
		{
			return _nInsetSize;
		}
		/**
		 * @private
		 */
		public function set insetSize(value:Number):void
		{
			if( _nInsetSize !== value)
			{
				_nInsetSize = value;
				dispatchEvent ( new Event ( CAMERA_INSET_SIZE ) );
			}
		}
		
		public function get microphone ( ) : Microphone
		{
			if ( !_mic )
			{
				if ( _sessionMgr.permissionsChecker && _sessionMgr.permissionsChecker.microphonePermitted )
				{
					_mic = Microphone.getMicrophone ( );
				}
			}
			return _mic;
		}
		
		public function get microphoneEnabled():Boolean
		{
			return _bMicEnabled;
		}
		private function _MicEnabledSet(value:Boolean):void
		{
			if ( value != _bMicEnabled )
			{
				if ( value )
				{
					if ( _sessionMgr.permissionsChecker && _sessionMgr.permissionsChecker.microphonePermitted )
					{
						_bMicEnabled = true;
						if ( !_mic )
						{
							_mic = Microphone.getMicrophone ( );
						}
						_MicCfg ( );
					}
					else if ( _vPermRetries != null )
					{
						_vPermRetries.push ( _PermMicRetry );
					}
				}
				else
				{
					_bMicEnabled = false;
				}
			}
		}
		
		[Bindable (event="camera_monitor")]
		public function get monitor():Boolean
		{
			return _bMon;
		}
		public function set monitor(value:Boolean):void
		{
			if( _bMon !== value)
			{
				_bMon = value;
				dispatchEvent ( new Event ( CAMERA_MONITOR ) );
			}
		}
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Index of -1 requests the default camera
		 */
		public function cameraSetByIndex ( index:int = -1 ) : void
		{
			if ( !_sessionMgr.permissionsChecker )
				return;
			
			if ( !_sessionMgr.permissionsChecker.cameraPermitted )
				return;
			
			if ( index >= 0 && index < Camera.names.length )
			{
				camera = Camera.getCamera ( index.toString() );
			}
			else
			{
				camera = Camera.getCamera ( );
			}
		}
		
		public function configAdjustRequest ( bool:Boolean ) : void
		{
			/*
			if ( _sessionMgr.moveIgnore )
			{
				_debugOut ( 'cameraConfigAdjustRequest discarded due to emergency flags: ' + _sessionMgr.emergencyFlagsGet() );
				return;
			}
			*/
			// if true, only apply if actually have cameraConfigMotion
			if ( bool )
			{
				if ( !_userState.cameraConfigMotion )
				{
					bool = false;
				}
			}
			if ( bool == _userState.cameraAdjustForMotion )
			{
				return;  // no change
			}
			
			_userState.cameraAdjustForMotion = bool;
			
			_callLater ( _CfgAdjustReport );
			// if we were moving, the change to cameraAdjustForMotion
			// now puts us in non-compliance, so switch config
			if ( _sessionMgr.isMoving )
			{
				if ( bool )
				{
					configActive = _userState.cameraConfigMotion;
				}
				else
				{
					configActive = _userState.cameraConfigDefault;
				}
			}
		}
		
		public function configDefaultRequest ( cc:CameraConfig ) : void
		{
			/*
			if ( _sessionMgr.moveIgnore )
			{
				_debugOut ( 'cameraConfigDefaultRequest discarded due to emergency flags: ' + _sessionMgr.emergencyFlagsGet() );
				return;
			}
			*/
			_userState.cameraConfigDefault = cc;
			if ( !_sessionMgr.isMoving || !_userState.cameraAdjustForMotion )
			{
				configActive = _userState.cameraConfigDefault;
			}
		}
		
		public function configMotionRequest ( cc:CameraConfig ) : void
		{
			/*
			if ( _sessionMgr.moveIgnore )
			{
				_debugOut ( 'cameraConfigMotionRequest discarded due to emergency flags: ' + _sessionMgr.emergencyFlagsGet() );
				return;
			}
			*/
			_userState.cameraConfigMotion = cc;
			
			if ( _sessionMgr.isMoving && _userState.cameraAdjustForMotion )
			{
				configActive = _userState.cameraConfigMotion;
			}
		}
		
		public function configRequest ( cc:CameraConfig ) : void
		{
			/*
			if ( _sessionMgr.moveIgnore )
			{
				_debugOut ( 'cameraConfigRequest discarded due to emergency flags: ' + _sessionMgr.emergencyFlagsGet() );
				return;
			}
			*/
			configActive = cc;
		}
		
		public function dimensionsCheck ( ) : void
		{
			if ( _iSizeChks >= 0 )
				return; // already checking
			
			_iSizeChks = 0;
			_callLater ( _SizeCheck );
		}
		
		public function fpsPollRequest ( msec:int ) : void
		{
			if ( msec < 1 )
			{
				// turn polling off
				_FpsTimerClear ( );
			}
			else
			{
				if ( msec < 500 )
				{
					// don't poll more often than once every half second
					_iFpsMsec = 500;
				}
				else
				{
					_iFpsMsec = msec;
				}
				// start polling or update delay value if already running
				_FpsTimerSet ( );
			}
		}
		
		public function motionSet ( on:Boolean ) : void
		{
			if ( _bCamEnabled && _userState.cameraAdjustForMotion )
			{
				if ( on )
				{
					configActive = _userState.cameraConfigMotion;
				}
				else
				{
					configActive = _userState.cameraConfigDefault;
				}
			}
		}
		
		public function userStateInit ( userState:UserState ) : void
		{
			_userState = userState;
			if ( !_userState.cameraConfigDefault )
			{
				_userState.cameraConfigDefault = _cfg;
			}
			else
			{
				_cfg = _userState.cameraConfigDefault;
			}
			
			if ( isNaN ( _userState.cameraIndex ) )
			{
				_userState.cameraIndex = 0;
			}
			else
			{
				cameraSetByIndex ( _userState.cameraIndex );
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bCamEnabled:Boolean = false;
		private var _bEnabled:Boolean = false;
		private var _bMicEnabled:Boolean = false;
		private var _bMon:Boolean = false;
		private var _cam:Camera;
		private var _cfg:CameraConfig;
		private var _iFpsMsec:int = 2000;
		private var _iHt:int = 0;
		private var _iWd:int = 0;
		private var _iSizeChks:int = -1;
		private var _mic:Microphone;
		private var _nInsetSize:Number = 0.5;
		private var _sessionMgr:SessionManager;
		private var _sInsetAlignH:String = HorizontalAlign.RIGHT;
		private var _sInsetAlignV:String = VerticalAlign.BOTTOM;
		private var _tmrFps:Timer; // FPS polling
		private var _userState:UserState;
		private var _vPermRetries:Vector.<Function>;
		
		
		// PRIVATE METHODS
		
		private function _CfgAdjustReport ( ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'ccfga', _userState.cameraAdjustForMotion ) ] );
		}
		
		private function _CfgApply ( ) : void
		{
			if ( !_bCamEnabled )
				return;
			
			if ( !_cam )
				return;
			
			try
			{
				// ask the camera for what we want,
				// and we'll find out later what it really gives us
				_cam.setMode (
					_cfg.width,
					_cfg.height,
					_cfg.fps,
					_cfg.favorArea
				);
				_cam.setQuality ( _cfg.bandWidth, _cfg.quality );
				_cam.setKeyFrameInterval ( _cfg.keyFrameInterval );
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_cam_set', true, [ err.message ] );
				return;
			}
			dimensionsCheck ( );
		}
		
		private function _CfgChangeEventDispatch ( ) : void
		{
			dispatchEvent ( new Event ( CAMERA_CONFIG_CHANGED ) );
		}
		
		private function _CfgReport ( ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [
				new MessageData ( 'ccfg',
					new CameraConfig (
						_iWd,
						_iHt,
						Math.min ( _cfg.fps, _cam.currentFPS ),
						_cfg.favorArea,
						_cam.bandwidth,
						_cam.quality,
						_cam.keyFrameInterval
					),
					true
				)
			] );
		}
		
		private function _FpsPoll ( event:TimerEvent ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [
				new MessageData ( 'cfps', _cam.currentFPS )
			] );
		}
		
		private function _FpsTimerClear ( ) : void
		{
			if ( !_tmrFps )
				return;
			
			_tmrFps.stop ( );
			_tmrFps.removeEventListener ( TimerEvent.TIMER, _FpsPoll );
			_tmrFps = null;
		}
		
		private function _FpsTimerSet ( ) : void
		{
			if ( !_tmrFps )
			{
				_tmrFps = new Timer ( _iFpsMsec, 0 );
				_tmrFps.addEventListener ( TimerEvent.TIMER, _FpsPoll );
			}
			else
			{
				_tmrFps.reset ( );
				_tmrFps.delay = _iFpsMsec;
			}
			_tmrFps.start ( );
		}
		
		private function _MicCfg ( ) : void
		{
			_mic.setSilenceLevel ( 2 );
		}
		
		private function _PermCamRetry ( ) : void
		{
			_CamEnabledSet ( _bEnabled );
		}
		
		private function _PermMicRetry ( ) : void
		{
			_MicEnabledSet ( _bEnabled );
		}
		
		private function _PermsDone ( event:Event = null ) : void
		{
			_sessionMgr.permissionsChecker.removeEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsDone );
			_callLater ( _PermsRetry );
		}
		
		private function _PermsRetry ( ) : void
		{
			if ( _vPermRetries != null )
			{
				var iLim:int = _vPermRetries.length;
				var i:int;
				for ( i=0; i<iLim; i++ )
				{
					_callLater ( _vPermRetries [ i ] );
				}
				_vPermRetries.length = 0;
				_vPermRetries = null;
			}
		}
		
		private function _SizeCheck ( ) : void
		{
			// dimensions may not be populated
			// instantly after a mode change
			var nWd:Number = _cam.width || 0;
			if ( nWd < 1 )
			{
				if ( ++_iSizeChks > 99 )
				{
					_iSizeChks = -1;
					_debugOut ( 'camera size check exceeded iteration limit' );
				}
				else
				{
					_callLater ( _SizeCheck );
				}
				return;
			}
			// if get here, we're ready to go
			_iSizeChks = -1;
			_iWd = nWd;
			_iHt = _cam.height;
			_callLater ( _CfgReport );
			dispatchEvent ( new Event ( CAMERA_DIMENSIONS_READY ) );
		}
	}
}
class SingletonEnforcer {}
