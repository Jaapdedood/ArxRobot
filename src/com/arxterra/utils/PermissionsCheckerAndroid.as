package com.arxterra.utils
{
	import com.distriqt.extension.permissions.AuthorisationStatus;
	import com.distriqt.extension.permissions.Permissions;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import com.distriqt.extension.permissions.events.AuthorisationEvent;

	/**
	 * Singleton class extending PermissionsCheckerBase
	 * to implement permissions checking specific to Android.
	 */
	public class PermissionsCheckerAndroid extends PermissionsCheckerBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		protected static const _ANDROID_NAME_CAM:String = 'android.permission.CAMERA';
		protected static const _ANDROID_NAME_FILE:String = 'android.permission.WRITE_EXTERNAL_STORAGE';
		protected static const _ANDROID_NAME_GEO:String = 'android.permission.ACCESS_FINE_LOCATION';
		protected static const _ANDROID_NAME_MIC:String = 'android.permission.RECORD_AUDIO';
		
		protected static var _ane:Permissions; // reference to ANE's Permissions.service
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */
		public function PermissionsCheckerAndroid ( enforcer:SingletonEnforcer )
		{
			super();
			_osPrefix = 'android_';
			// check for ANE support
			var sMsg:String = '';
			try
			{
				if ( Permissions.isSupported )
				{
					_bSupported = true;
					_ane = Permissions.service;
				}
			}
			catch ( err:Error )
			{
				sMsg = err.message;
			}
			
			if ( _bSupported )
			{
				_ane.setPermissions (
					[
						_ANDROID_NAME_CAM,
						_ANDROID_NAME_GEO,
						_ANDROID_NAME_MIC,
						_ANDROID_NAME_FILE
					]
				);
			}
			else if ( sMsg.length > 0 )
			{
				_debugOut ( 'error_android_perms_support_detect', true, [ sMsg ] );
			}
			else
			{
				_debugOut ( 'error_android_perms_support', true );
			}
		}
		
		private static var __instance:PermissionsCheckerAndroid
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : PermissionsCheckerAndroid
		{
			if ( !__instance )
			{
				__instance = new PermissionsCheckerAndroid ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		override public function dismiss ( ) : void
		{
			super.dismiss ( );
			__instance = null;
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		

		// OTHER PUBLIC METHODS
		
		override public function request ( ) : void
		{
			if ( _tmrActCheck )
			{
				// already busy
				return;
			}
			
			_permsUpdate ( );
			_actionQueue.length = 0;
			var iIdx:int = 0;
			var asPrms:Array = [];
			_uPrmFlags = 0;
			if ( !_doneCam )
			{
				_uPrmFlags |= _PRM_CAM;
				asPrms [ iIdx++ ] = _ANDROID_NAME_CAM;
			}
			if ( !_doneGeo )
			{
				_uPrmFlags |= _PRM_GEO;
				asPrms [ iIdx++ ] = _ANDROID_NAME_GEO;
			}
			if ( !_doneMic )
			{
				_uPrmFlags |= _PRM_MIC;
				asPrms [ iIdx++ ] = _ANDROID_NAME_MIC;
			}
			if ( !_doneFile )
			{
				_uPrmFlags |= _PRM_FILE;
				asPrms [ iIdx++ ] = _ANDROID_NAME_FILE;
			}
			
			if ( _uPrmFlags > 0 )
			{
				_actionQueue [ 0 ] = _uPrmFlags;
				_ane.setPermissions ( asPrms );
				_nActCheckDelay = asPrms.length * _ACT_CHECK_DELAY;
				_callLater ( _queueNext );
			}
			
		}
		
		
		// PROTECTED PROPERTIES
		
		
		// PROTECTED METHODS
		
		override protected function _actionCheckTimeout ( event:TimerEvent = null ) : void
		{
			_debugOut ( 'Permissions request timed out' );
			_requestDone ( );
		}
		
		protected function _authChanged ( event:AuthorisationEvent ) : void
		{
			_requestDone ( );
		}
		
		override protected function _cameraStatusSet(value:String):void
		{
			if( _statusCam !== value)
			{
				_statusCam = value;
				_changeableCam = ( _statusCam == AuthorisationStatus.NOT_DETERMINED || _statusCam == AuthorisationStatus.SHOULD_EXPLAIN );
				_doneCam = !( _userState.mayRequestCamera && _changeableCam );
				_okayCam = ( _statusCam == AuthorisationStatus.AUTHORISED );
				_cameraStatusChangeEventSend ( );
			}
		}
		
		override protected function _fileStatusSet(value:String):void
		{
			if( _statusFile !== value)
			{
				_statusFile = value;
				_changeableFile = ( _statusFile == AuthorisationStatus.NOT_DETERMINED || _statusFile == AuthorisationStatus.SHOULD_EXPLAIN );
				_doneFile = !( _userState.mayRequestFile && _changeableFile );
				_okayFile = ( _statusFile == AuthorisationStatus.AUTHORISED );
				_fileStatusChangeEventSend ( );
			}
		}
		
		override protected function _geolocationStatusSet(value:String):void
		{
			if( _statusGeo !== value)
			{
				_statusGeo = value;
				_changeableGeo = ( _statusGeo == AuthorisationStatus.NOT_DETERMINED || _statusGeo == AuthorisationStatus.SHOULD_EXPLAIN );
				_doneGeo = !( _userState.mayRequestGeolocation && _changeableGeo );
				_okayGeo = ( _statusGeo == AuthorisationStatus.AUTHORISED );
				_geoStatusChangeEventSend ( );
			}
		}
		
		override protected function _microphoneStatusSet(value:String):void
		{
			if( _statusMic !== value)
			{
				_statusMic = value;
				_changeableMic = ( _statusMic == AuthorisationStatus.NOT_DETERMINED || _statusMic == AuthorisationStatus.SHOULD_EXPLAIN );
				_doneMic = !( _userState.mayRequestMicrophone && _changeableMic );
				_okayMic = ( _statusMic == AuthorisationStatus.AUTHORISED );
				_micStatusChangeEventSend ( );
			}
		}
		
		override protected function _permUpdateCam ( ) : void
		{
			_cameraStatusSet ( _ane.authorisationStatusForPermission ( _ANDROID_NAME_CAM ) );
		}
		
		override protected function _permUpdateFile ( ) : void
		{
			_fileStatusSet ( _ane.authorisationStatusForPermission ( _ANDROID_NAME_FILE ) );
		}
		
		override protected function _permUpdateGeo ( ) : void
		{
			_geolocationStatusSet ( _ane.authorisationStatusForPermission ( _ANDROID_NAME_GEO ) );
		}
		
		override protected function _permUpdateMic ( ) : void
		{
			_microphoneStatusSet ( _ane.authorisationStatusForPermission ( _ANDROID_NAME_MIC ) );
		}
		
		override protected function _queueNext ( ) : void
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
			// next (and only) request
			_actionCheckTimerSet ( _actionQueue.shift ( ), _nActCheckDelay );
			_ane.addEventListener ( AuthorisationEvent.CHANGED, _authChanged );
			_ane.requestAccess ( );
		}
		
		protected function _requestDone ( ) : void
		{
			_actionCheckTimerClear ( );
			_ane.removeEventListener ( AuthorisationEvent.CHANGED, _authChanged );
			_permUpdateCam ( );
			_permUpdateFile ( );
			_permUpdateGeo ( );
			_permUpdateMic ( );
			_callLater ( _queueNext );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bSupported:Boolean = false;
		private var _nActCheckDelay:Number = _ACT_CHECK_DELAY;
		private var _uPrmFlags:uint = 0;
		
	}
}
class SingletonEnforcer {}
