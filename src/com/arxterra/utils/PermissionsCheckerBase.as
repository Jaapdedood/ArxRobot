package com.arxterra.utils
{
	import com.arxterra.interfaces.IPermissionsChecker;
	import com.arxterra.vo.UserState;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.PermissionEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.permissions.PermissionStatus;
	import flash.sensors.Geolocation;
	import flash.utils.Timer;
	
	[Event(name="permissions_all_permitted_change", type="flash.events.Event")]
	[Event(name="permissions_camera_status_change", type="flash.events.Event")]
	[Event(name="permissions_changeable_change", type="flash.events.Event")]
	[Event(name="permissions_done", type="flash.events.Event")]
	[Event(name="permissions_done_change", type="flash.events.Event")]
	[Event(name="permissions_file_status_change", type="flash.events.Event")]
	[Event(name="permissions_geolocation_status_change", type="flash.events.Event")]
	[Event(name="permissions_microphone_status_change", type="flash.events.Event")]
	[Event(name="permissions_view_header_change", type="flash.events.Event")]
	
	/**
	 * Base class for permissions checking.
	 * Must be extended by subclass specific to the operating system.
	 */
	[Bindable]
	public class PermissionsCheckerBase extends NonUIComponentBase implements IPermissionsChecker
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const PERMISSIONS_ALL_PERMITTED_CHANGE:String = 'permissions_all_permitted_change';
		public static const PERMISSIONS_CAMERA_STATUS_CHANGE:String = 'permissions_camera_status_change';
		public static const PERMISSIONS_CHANGEABLE_CHANGE:String = 'permissions_changeable_change';
		public static const PERMISSIONS_DONE:String = 'permissions_done';
		public static const PERMISSIONS_DONE_CHANGE:String = 'permissions_done_change';
		public static const PERMISSIONS_FILE_STATUS_CHANGE:String = 'permissions_file_status_change';
		public static const PERMISSIONS_GEOLOCATION_STATUS_CHANGE:String = 'permissions_geolocation_status_change';
		public static const PERMISSIONS_MICROPHONE_STATUS_CHANGE:String = 'permissions_microphone_status_change';
		public static const PERMISSIONS_VIEW_HEADER_CHANGE:String = 'permissions_view_header_change';
		
		protected static const _ACT_CHECK_DELAY:int = 5000;
		protected static const _ACT_RETRIES_LIMIT:int = 2;
		
		protected static const _PRM_NONE:uint = 0;
		protected static const _PRM_CAM:uint = 1;
		protected static const _PRM_GEO:uint = 2;
		protected static const _PRM_MIC:uint = 4;
		protected static const _PRM_FILE:uint = 8;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function PermissionsCheckerBase ( )
		{
			super();
			_callLaterDelaySet ( 500 );
			_actionQueue = new <uint> [];
			NativeApplication.nativeApplication.addEventListener ( Event.ACTIVATE, _appActivated );
			_viewHeadRsrc = 'perms_head';
		}
		
		override public function dismiss ( ) : void
		{
			NativeApplication.nativeApplication.removeEventListener ( Event.ACTIVATE, _appActivated );
			_actionCheckTimerClear ( );
			super.dismiss ( );
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable(event="permissions_all_permitted_change")]
		public function get allPermitted():Boolean
		{
			return _okay;
		}
		protected function _allPermittedSet(value:Boolean):void
		{
			if ( _okay !== value )
			{
				_okay = value;
				dispatchEvent(new Event(PERMISSIONS_ALL_PERMITTED_CHANGE));
			}
		}
		
		[Bindable(event="permissions_camera_status_change")]
		public function get cameraChangeable():Boolean
		{
			return _changeableCam;
		}
		[Bindable(event="permissions_camera_status_change")]
		public function get cameraDone():Boolean
		{
			return _doneCam;
		}
		[Bindable(event="permissions_camera_status_change")]
		public function get cameraPermitted():Boolean
		{
			return _okayCam;
		}
		[Bindable(event="permissions_camera_status_change")]
		public function get cameraStatus():String
		{
			return _osPrefix + _statusCam;
		}
		protected function _cameraStatusSet(value:String):void
		{
			if( _statusCam !== value)
			{
				_statusCam = value;
				_changeableCam = ( _statusCam == PermissionStatus.UNKNOWN );
				_doneCam = !( _userState.mayRequestCamera && _changeableCam );
				_okayCam = !( _statusCam == PermissionStatus.UNKNOWN || _statusCam == PermissionStatus.DENIED );
				_cameraStatusChangeEventSend ( );
			}
		}
		protected function _cameraStatusChangeEventSend ( ) : void
		{
			dispatchEvent ( new Event ( PERMISSIONS_CAMERA_STATUS_CHANGE ) );
		}
		
		
		[Bindable(event="permissions_changeable_change")]
		public function get changeable():Boolean
		{
			return _changeable;
		}
		protected function _changeableSet(value:Boolean):void
		{
			if( _changeable !== value)
			{
				_changeable = value;
				dispatchEvent(new Event(PERMISSIONS_CHANGEABLE_CHANGE));
			}
		}
		
		
		[Bindable(event="permissions_done_change")]
		/**
		 * Done means we have asked for everything the user allowed us
		 * to request, not necessarily that every request was granted
		 */
		public function get done():Boolean
		{
			return _done;
		}
		protected function _doneSet(value:Boolean):void
		{
			if( _done !== value)
			{
				_done = value;
				dispatchEvent(new Event(PERMISSIONS_DONE_CHANGE));
			}
		}
		
		[Bindable(event="permissions_file_status_change")]
		public function get fileChangeable():Boolean
		{
			return _changeableFile;
		}
		[Bindable(event="permissions_file_status_change")]
		public function get fileDone():Boolean
		{
			return _doneFile;
		}
		[Bindable(event="permissions_file_status_change")]
		public function get filePermitted():Boolean
		{
			return _okayFile;
		}
		[Bindable(event="permissions_file_status_change")]
		public function get fileStatus():String
		{
			return _osPrefix + _statusFile;
		}
		/**
		 * Treat this as abstract method, which Android subclass must override
		 */		
		protected function _fileStatusSet(value:String):void
		{
			if( _statusFile !== value)
			{
				_statusFile = value;
			}
		}
		protected function _fileStatusChangeEventSend ( ) : void
		{
			dispatchEvent ( new Event ( PERMISSIONS_FILE_STATUS_CHANGE ) );
		}
		
		[Bindable(event="permissions_geolocation_status_change")]
		public function get geolocationChangeable():Boolean
		{
			return _changeableGeo;
		}
		[Bindable(event="permissions_geolocation_status_change")]
		public function get geolocationDone():Boolean
		{
			return _doneGeo;
		}
		[Bindable(event="permissions_geolocation_status_change")]
		public function get geolocationPermitted():Boolean
		{
			return _okayGeo;
		}
		[Bindable(event="permissions_geolocation_status_change")]
		public function get geolocationStatus():String
		{
			return _osPrefix + _statusGeo;
		}
		protected function _geolocationStatusSet(value:String):void
		{
			if( _statusGeo !== value)
			{
				_statusGeo = value;
				_changeableGeo = ( _statusGeo == PermissionStatus.UNKNOWN );
				_doneGeo = !( _userState.mayRequestGeolocation && _changeableGeo );
				_okayGeo = !( _statusGeo == PermissionStatus.UNKNOWN || _statusGeo == PermissionStatus.DENIED );
				_geoStatusChangeEventSend ( );
			}
		}
		protected function _geoStatusChangeEventSend ( ) : void
		{
			dispatchEvent ( new Event ( PERMISSIONS_GEOLOCATION_STATUS_CHANGE ) );
		}
		
		[Bindable(event="permissions_microphone_status_change")]
		public function get microphoneChangeable():Boolean
		{
			return _changeableMic;
		}
		[Bindable(event="permissions_microphone_status_change")]
		public function get microphoneDone():Boolean
		{
			return _doneMic;
		}
		[Bindable(event="permissions_microphone_status_change")]
		public function get microphonePermitted():Boolean
		{
			return _okayMic;
		}
		[Bindable(event="permissions_microphone_status_change")]
		public function get microphoneStatus():String
		{
			return _osPrefix + _statusMic;
		}
		protected function _microphoneStatusSet(value:String):void
		{
			if( _statusMic !== value)
			{
				_statusMic = value;
				_changeableMic = ( _statusMic == PermissionStatus.UNKNOWN );
				_doneMic = !( _userState.mayRequestMicrophone && _changeableMic );
				_okayMic = !( _statusMic == PermissionStatus.UNKNOWN || _statusMic == PermissionStatus.DENIED );
				_micStatusChangeEventSend ( );
			}
		}
		protected function _micStatusChangeEventSend ( ) : void
		{
			dispatchEvent ( new Event ( PERMISSIONS_MICROPHONE_STATUS_CHANGE ) );
		}
		
		[Bindable(event="permissions_view_header_change")]
		public function get viewHeaderResource():String
		{
			return _viewHeadRsrc;
		}
		protected function _viewHeaderResourceSet(value:String):void
		{
			if ( _viewHeadRsrc !== value )
			{
				_viewHeadRsrc = value;
				dispatchEvent ( new Event ( PERMISSIONS_VIEW_HEADER_CHANGE ) );
			}
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function request ( ) : void
		{
			if ( _tmrActCheck )
			{
				// already busy
				return;
			}
			
			_permsUpdate ( );
			_actionQueue.length = 0;
			var iIdx:int = 0;
			if ( !_doneGeo )
			{
				_actionQueue [ iIdx++ ] = _PRM_GEO;
			}
			if ( !_doneCam )
			{
				_actionQueue [ iIdx++ ] = _PRM_CAM;
			}
			if ( !_doneMic )
			{
				_actionQueue [ iIdx++ ] = _PRM_MIC;
			}
			_queueNext ( );
		}
		
		public function userStateInit ( userState:UserState ) : void
		{
			_userState = userState;
			_permsUpdate ( );
		}
		
		
		// PROTECTED PROPERTIEES
		
		protected var _actionId:uint;
		protected var _actionQueue:Vector.<uint>;
		protected var _cam:Camera;
		protected var _changeable:Boolean = false;
		protected var _changeableCam:Boolean = false;
		protected var _changeableFile:Boolean = true;
		protected var _changeableGeo:Boolean = false;
		protected var _changeableMic:Boolean = false;
		protected var _done:Boolean = false;
		protected var _doneCam:Boolean = false;
		protected var _doneFile:Boolean = true;
		protected var _doneGeo:Boolean = false;
		protected var _doneMic:Boolean = false;
		protected var _geo:Geolocation;
		protected var _mic:Microphone;
		protected var _okay:Boolean = false;
		protected var _okayCam:Boolean = false;
		protected var _okayFile:Boolean = true;
		protected var _okayGeo:Boolean = false;
		protected var _okayMic:Boolean = false;
		protected var _osPrefix:String = ''; // subclass should change this
		protected var _retries:int = 0;
		protected var _statusCam:String;
		protected var _statusFile:String = PermissionStatus.GRANTED;
		protected var _statusGeo:String;
		protected var _statusMic:String;
		protected var _tmrActCheck:Timer;
		protected var _userState:UserState;
		protected var _viewHeadRsrc:String;
		
		
		// PROTECTED METHODS
		
		protected function _actionCheckTimeout ( event:TimerEvent = null ) : void
		{
			_actionCheckTimerClear ( );
			switch ( _actionId )
			{
				case _PRM_CAM:
				{
					_camTimedOut ( );
					break;
				}
				case _PRM_GEO:
				{
					_geoTimedOut ( );
					break;
				}
				case _PRM_MIC:
				{
					_micTimedOut ( );
					break;
				}
				default:
				{
					
					break;
				}
			}
		}
		
		protected function _actionCheckTimerClear ( actionId:uint = _PRM_NONE, resetRetries:Boolean = false ) : void
		{
			if ( resetRetries )
			{
				_retries = 0;
			}
			
			if ( _tmrActCheck )
			{
				if ( actionId == _PRM_NONE || actionId == _actionId )
				{
					_tmrActCheck.stop ( );
					_tmrActCheck.removeEventListener ( TimerEvent.TIMER, _actionCheckTimeout );
					_tmrActCheck = null;
				}
			}
		}
		
		/**
		 * Subclass overrides should call this
		 */
		protected function _actionCheckTimerSet ( actionId:uint, msec:Number = _ACT_CHECK_DELAY ) : void
		{
			_actionId = actionId;
			if ( !_tmrActCheck )
			{
				_tmrActCheck = new Timer ( msec, 1 );
				_tmrActCheck.addEventListener ( TimerEvent.TIMER, _actionCheckTimeout );
				_tmrActCheck.start ( );
			}
			else
			{
				_tmrActCheck.reset ( );
				_tmrActCheck.delay = msec;
				_tmrActCheck.start ( );
			}
		}
		
		protected function _actionRetryOk ( ) : Boolean
		{
			if ( ++ _retries < _ACT_RETRIES_LIMIT )
			{
				return true; // return
			}
			
			_retries = 0;
			return false;
		}
		
		protected function _appActivated ( event:Event ) : void
		{
			_permsUpdate ( );
		}
		
		protected function _camPermStatus ( event:PermissionEvent ) : void
		{
			_camRequestDone ( );
		}
		
		protected function _camRequest ( ) : void
		{
			if ( !_cam )
			{
				_cam = Camera.getCamera ( );
			}
			if ( _cam )
			{
				_cam.addEventListener ( PermissionEvent.PERMISSION_STATUS, _camPermStatus );
				try
				{
					_cam.requestPermission ( );
				}
				catch ( err:Error )
				{
					// should only get here if another request was in progress, so try again
					_cam.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _camPermStatus );
					_callLater ( _camRequest );
					_debugOut ( 'Camera permission request exception: ' + err.message );
				}
			}
		}
		
		protected function _camRequestDone ( ) : void
		{
			_actionCheckTimerClear ( );
			if ( _cam )
			{
				_cam.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _camPermStatus );
				_cam = null;
			}
			_permUpdateCam ( );
			_callLater ( _queueNext );
		}
		
		protected function _camTimedOut ( ) : void
		{
			_debugOut ( 'Camera permission request timed out' );
			_camRequestDone ( );
		}
		
		protected function _geoPermStatus ( event:PermissionEvent ) : void
		{
			_geoRequestDone ( );
		}
		
		protected function _geoRequest ( ) : void
		{
			if ( !_geo )
			{
				_geo = new Geolocation ( );
				_geo.locationAlwaysUsePermission = true;
			}
			if ( _geo )
			{
				_geo.addEventListener ( PermissionEvent.PERMISSION_STATUS, _geoPermStatus );
				try
				{
					_geo.requestPermission ( );
				}
				catch ( err:Error )
				{
					// should only get here if another request was in progress, so try again
					_geo.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _geoPermStatus );
					_callLater ( _geoRequest );
					_debugOut ( 'Geolocation permission request exception: ' + err.message );
				}
			}
		}
		
		protected function _geoRequestDone ( ) : void
		{
			_actionCheckTimerClear ( );
			if ( _geo )
			{
				_geo.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _geoPermStatus );
				_geo = null;
			}
			_permUpdateGeo ( );
			_callLater ( _queueNext );
		}
		
		protected function _geoTimedOut ( ) : void
		{
			_debugOut ( 'Geolocation permission request timed out' );
			_geoRequestDone ( );
		}
		
		protected function _micPermStatus ( event:PermissionEvent ) : void
		{
			_micRequestDone ( );
		}
		
		protected function _micRequest ( ) : void
		{
			if ( !_mic )
			{
				_mic = Microphone.getMicrophone ( );
			}
			if ( _mic )
			{
				_mic.addEventListener ( PermissionEvent.PERMISSION_STATUS, _micPermStatus );
				try
				{
					_mic.requestPermission ( );
				}
				catch ( err:Error )
				{
					// should only get here if another request was in progress, so try again
					_mic.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _micPermStatus );
					_callLater ( _micRequest );
					_debugOut ( 'Microphone permission request exception: ' + err.message );
				}
			}
		}
		
		protected function _micRequestDone ( ) : void
		{
			_actionCheckTimerClear ( );
			if ( _mic )
			{
				_mic.removeEventListener ( PermissionEvent.PERMISSION_STATUS, _micPermStatus );
			}
			
			_callLater ( _queueNext );
		}
		
		protected function _micTimedOut ( ) : void
		{
			_debugOut ( 'Microphone permission request timed out' );
			_micRequestDone ( );
		}
		
		protected function _permUpdateCam ( ) : void
		{
			_cameraStatusSet ( Camera.permissionStatus );
		}
		
		protected function _permUpdateFile ( ) : void
		{
			// subclass must override
		}
		
		protected function _permUpdateGeo ( ) : void
		{
			_geolocationStatusSet ( Geolocation.permissionStatus );
		}
		
		protected function _permUpdateMic ( ) : void
		{
			_microphoneStatusSet ( Microphone.permissionStatus );
		}
		
		protected function _permsUpdate ( rebuild:Boolean = true ) : void
		{
			if ( rebuild )
			{
				_permUpdateCam ( );
				_permUpdateFile ( );
				_permUpdateGeo ( );
				_permUpdateMic ( );
			}
			_changeableSet ( _changeableCam || _changeableFile || _changeableGeo || _changeableMic );
			_doneSet ( _doneCam && _doneFile && _doneGeo && _doneMic );
			_allPermittedSet ( _okayCam && _okayFile && _okayGeo && _okayMic );
		}
		
		protected function _queueNext ( ) : void
		{
			if ( _actionQueue.length < 1 )
			{
				// done with queue
				_permsUpdate ( false );
				if ( !_okay )
				{
					_viewHeaderResourceSet ( 'perms_head_explain' );
				}
				dispatchEvent ( new Event ( PERMISSIONS_DONE ) );
				return;
			}
			// next request
			_actionCheckTimerSet ( _actionQueue.shift ( ) );
			switch ( _actionId )
			{
				case _PRM_CAM:
				{
					_camRequest ( );
					break;
				}
				case _PRM_GEO:
				{
					_geoRequest ( );
					break;
				}
				default:
					// case _PRM_MIC:
				{
					_micRequest ( );
					break;
				}
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		
		
		// PRIVATE METHODS
		
	}
}
