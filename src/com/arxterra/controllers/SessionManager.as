package com.arxterra.controllers
{
	import com.arxterra.events.BleEvent;
	import com.arxterra.events.DialogEvent;
	import com.arxterra.events.StatusDataEvent;
	import com.arxterra.events.TelemetryEvent;
	import com.arxterra.events.UtilityEvent;
	import com.arxterra.icons.IconBattery;
	import com.arxterra.icons.IconBatteryMotor;
	import com.arxterra.interfaces.IMcuConnector;
	import com.arxterra.interfaces.IPermissionsChecker;
	import com.arxterra.interfaces.IPilotConnector;
	import com.arxterra.utils.BatteryUtil;
	import com.arxterra.utils.DeclinationUtil;
	import com.arxterra.utils.DeviceMotionUtil;
	import com.arxterra.utils.FlagsUtil;
	import com.arxterra.utils.HexStringUtil;
	import com.arxterra.utils.McuConnectorBase;
	import com.arxterra.utils.McuConnectorBLE;
	import com.arxterra.utils.McuConnectorBluetooth;
	import com.arxterra.utils.McuConnectorNone;
	import com.arxterra.utils.McuConnectorSocket;
	import com.arxterra.utils.NonUIComponentBase;
	import com.arxterra.utils.PermissionsCheckerAndroid;
	import com.arxterra.utils.PermissionsCheckerBase;
	import com.arxterra.utils.PermissionsCheckerIOS;
	import com.arxterra.utils.PilotConnector;
	import com.arxterra.utils.PilotConnectorCS;
	import com.arxterra.utils.PilotConnectorPP;
	import com.arxterra.utils.PilotConnectorRC;
	import com.arxterra.vo.CameraConfig;
	import com.arxterra.vo.CameraMove;
	import com.arxterra.vo.CoordinatesMessage;
	import com.arxterra.vo.CurrentCoordinates;
	import com.arxterra.vo.CustomCommandConfig;
	import com.arxterra.vo.DialogData;
	import com.arxterra.vo.DialogOption;
	import com.arxterra.vo.EmergencyFlags;
	import com.arxterra.vo.Gps;
	import com.arxterra.vo.InsetConfig;
	import com.arxterra.vo.McuConnectModes;
	import com.arxterra.vo.McuEeprom;
	import com.arxterra.vo.McuMessage;
	import com.arxterra.vo.MediaConfig;
	import com.arxterra.vo.MessageByteArray;
	import com.arxterra.vo.MessageData;
	import com.arxterra.vo.MotorStates;
	import com.arxterra.vo.MoveProps;
	import com.arxterra.vo.OpModes;
	import com.arxterra.vo.QuaternionArx;
	import com.arxterra.vo.RoverData;
	import com.arxterra.vo.SfsPreset;
	import com.arxterra.vo.ShortXY;
	import com.arxterra.vo.StatusData;
	import com.arxterra.vo.UserState;
	import com.distriqt.extension.androidsupport.v4.AndroidSupportV4;
	import com.distriqt.extension.battery.events.BatteryEvent;
	import com.distriqt.extension.core.Core;
	import com.distriqt.extension.devicemotion.events.DeviceMotionEvent;
	
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.StageDisplayState;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.GeolocationEvent;
	import flash.events.KeyboardEvent;
	import flash.events.StageOrientationEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.media.Camera;
	import flash.media.CameraPosition;
	import flash.media.Video;
	import flash.net.registerClassAlias;
	import flash.permissions.PermissionStatus;
	import flash.sensors.Geolocation;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import spark.components.Application;
	
	import away3d.core.math.MathConsts;
	import away3d.core.math.Quaternion;
	
	import org.apache.flex.collections.VectorCollection;
	
	[Event(name="app_resized", type="flash.events.Event")]
	[Event(name="app_view_state_changed", type="flash.events.Event")]
	[Event(name="av_sender_metadata_changed", type="flash.events.Event")]
	[Event(name="ble_manager_changed", type="flash.events.Event")]
	[Event(name="op_mode_changed", type="flash.events.Event")]
	[Event(name="rotation_lock_changed", type="flash.events.Event")]
	[Event(name="sleep_state_changed", type="flash.events.Event")]
	
	[Event(name="status_data_message", type="com.arxterra.events.StatusDataEvent")]
	[Event(name="status_bg_message", type="com.arxterra.events.StatusDataEvent")]
	
	/**
	 * Controls data acquisition and persistence, interactions with
	 * the host device, user session persistence, etc. Provides a
	 * singleton that all views can access to get their data.
	 */
	public class SessionManager extends NonUIComponentBase
	{
		// CONSTANTS

		public static const DISTRIQT_ANE_APP_KEY:String = '64f985c110ff83596be521f142cbf190e85d8a0fX2MzG5JJXlSlbk8ErKKbwDyFacAxL2DkbEmy9hBOdmalRt2vH1O6qJmy4q0azeuDYakBtDWwk823xbTv9N3FKc13XB1tSka6UFkVcYVIxg5lEmlW/PSn/XZbsA4TvLd6a4Q7YOIzLZdauQlpOM5DVZBYcjraMdCgztHwDKfCeuGSH+6KQsqbrSKFSrrd3+pdi8o4jPX7EfxoAu6Ovjk8AEA6uXeJXi4hdv2yPJ02pgnF+vSwW6cmo1rrJkSeMHp0jmm/a+8hK1K+kraDrAgoKfmzMEZ2OMOCxFgKyTDO8FfBjykZ4Nr8APjdxvJOFTk5kYwW+xRTLrLIpOYFQvXcOg==';

		//   event types
		public static const APP_RESIZED:String = 'app_resized';
		public static const APP_VIEW_STATE_CHANGED:String = 'app_view_state_changed';
		public static const AV_SENDER_METADATA_CHANGED:String = 'av_sender_metadata_changed';
		public static const BLE_MANAGER_CHANGED:String = 'ble_manager_changed';
		public static const OP_MODE_CHANGED:String = 'op_mode_changed';
		public static const ROTATION_LOCK_CHANGED:String = 'rotation_lock_changed';
		public static const SLEEP_STATE_CHANGED:String = 'sleep_state_changed';
		
		//   timer defaults
		//     Battery check updates a user variable as least this often when in sleep mode
		//     (and all the time when testing with iOS).  The timer delay must be less than
		//     the maximum user idle time (currently 1000 seconds) we have set in the
		//     SmartFoxServer configuration for the Arx zone.
		public static const BATTERY_CHECK_MSECS:Number = 120000;
		public static const EEPROM_READ_LIMIT:Number = 1000;
		public static const EEPROM_WRITE_INTERVAL:Number = 500; // multiplied by number of bytes to be written
		public static const NAV_GPS_MSEC_DEFAULT:Number = 5000;
		public static const NAV_HDG_MSEC_DEFAULT:Number = 5000;
		public static const QUAT_MSEC_DEFAULT:Number = 1500;
		
		//   layout
		public static const PHI_MAJOR:Number = 0.5 * ( Math.sqrt ( 5 ) + 1 ); // Golden Ratio
		public static const PHI_MINOR:Number = PHI_MAJOR - 1;
		public static const PHI_MINOR_SQ:Number = PHI_MINOR * PHI_MINOR;
		public static const PHI_SUB:Number = 1 - PHI_MINOR;
		public static const DESIGN_DPI:Number = 160;
			
		//   os
		// public static const OS_OTHER:int = 0;
		public static const OS_ANDROID:int = 1;
		public static const OS_IOS:int = 2;
		// public static const OS_BLACKBERRY:int = 3;
		
		private static const _VIEW_STATE_RANK:Object = {
			'home': 0,
			'home_cs': 0,
			'home_pp': 0,
			'home_rc': 0,
			'ble_config': 6,
			'bluetooth_config': 5,
			'connect_config_cs': 4,
			'connect_prompt_cs': 4,
			'custom_config': 1,
			'eeprom_config': 1,
			'login_config_cs': 3,
			'login_prompt_cs': 3,
			'mode_prompt': 0,
			'permissions': 7,
			'phone_config': 2,
			'test_config': 2
		};
		
		private static const _VIEW_STATE_SLOW:Object = {
			'home': false,
			'home_cs': false,
			'home_pp': false,
			'home_rc': false,
			'ble_config': false,
			'bluetooth_config': false,
			'connect_config_cs': false,
			'connect_prompt_cs': false,
			'custom_config': true,
			'eeprom_config': true,
			'login_config_cs': false,
			'login_prompt_cs': false,
			'mode_prompt': false,
			'permissions': false,
			'phone_config': true,
			'test_config': false
		};
		
		// CONSTRUCTOR AND INSTANCE
		
		/**
		 * Singleton: use static property <b>instance</b> to get a reference.
		 */
		public function SessionManager(enforcer:SingletonEnforcer)
		{
			super();
		}
		
		/**
		 * Singleton instance of SessionManager
		 */
		public static function get instance ( ) : SessionManager
		{
			if ( !__instance )
			{
				__instance = new SessionManager ( new SingletonEnforcer ( ) );
			}
			return __instance;
		}
		
		private static var __instance:SessionManager;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable]
		public var actionMenuBgColor:uint = 0x666666;
		[Bindable]
		public var actionMenuBtnStyleName:String;
		[Bindable]
		public function get actionMenuOn():Boolean
		{
			return _bActMnOn;
		}
		public function set actionMenuOn(value:Boolean):void
		{
			_bActMnOn = value;
			if ( value )
			{
				dispatchEvent (
					new StatusDataEvent (
						StatusDataEvent.STATUS_BG_MESSAGE,
						new StatusData ( _sAppVersion )
					)
				);
			}
			else
			{
				dispatchEvent (
					new StatusDataEvent (
						StatusDataEvent.STATUS_BG_MESSAGE
					)
				);
			}
		}
		public var app:Application;
		[Bindable (event="app_view_state_changed")]
		public function get appViewState():String
		{
			return _sAppVwState;
		}
		private function _AppViewStateSet(value:String):void
		{
			if ( _sAppVwState !== value )
			{
				_sAppVwState = value;
				dispatchEvent(new Event('app_view_state_changed'));
			}
		}
		[Bindable]
		public var batteryCleanEnabled:Boolean = false;
		[Bindable]
		public var batteryCleanIcon:Object = IconBattery;
		[Bindable]
		public var batteryCleanMinSafe:int = 0;
		[Bindable]
		public var batteryCleanPct:int = 100;
		[Bindable]
		public var batteryCleanRsrc:String = 'status_batt_clean_';
		public function batteryCleanPctTest ( value:int ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'cbt', value ) ] );
			batteryCleanPct = value;
		}
		[Bindable]
		public var batteryDirtyEnabled:Boolean = false;
		[Bindable]
		public var batteryDirtyIcon:Object = IconBatteryMotor;
		[Bindable]
		public var batteryDirtyMinSafe:int = 0;
		[Bindable]
		public var batteryDirtyPct:int = 100;
		[Bindable]
		public var batteryDirtyRsrc:String = 'status_batt_dirty_';
		public function batteryDirtyPctTest ( value:int ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'dbt', value ) ] );
			batteryDirtyPct = value;
		}
		
		public function get batteryPct():Number
		{
			return _nBatteryPct;
		}
		public function get batterySupported():Boolean
		{
			return _bBatterySupport;
		}
		[Bindable(event="ble_manager_changed")]
		public function get bleManager():BleManager
		{
			return _bleMgr;
		}
		private function _BleManagerSet(value:BleManager):void
		{
			if( _bleMgr !== value)
			{
				_bleMgr = value;
				dispatchEvent ( new Event ( BLE_MANAGER_CHANGED ) );
			}
		}
		[Bindable]
		public function get bleSelected():Boolean
		{
			return _bBleSel;
		}
		public function set bleSelected(value:Boolean):void
		{
			_bBleSel = value;
			var bleMgr:BleManager = BleManager.instance;
			if ( value )
			{
				bleMgr.addEventListener ( BleEvent.BLE_CONFIG, _BleConfigEvent );
				bleMgr.addEventListener ( BleEvent.BLE_PERIPHERAL_CONNECTED, _BlePrConnected );
				bleMgr.addEventListener ( BleEvent.BLE_PERIPHERAL_DISCONNECTED, _BlePrDisconnected );
			}
			else
			{
				bleMgr.removeEventListener ( BleEvent.BLE_CONFIG, _BleConfigEvent );
				bleMgr.removeEventListener ( BleEvent.BLE_PERIPHERAL_CONNECTED, _BlePrConnected );
				bleMgr.removeEventListener ( BleEvent.BLE_PERIPHERAL_DISCONNECTED, _BlePrDisconnected );
				bleMgr.dismiss();
				bleMgr = null;
			}
			_BleManagerSet ( bleMgr );
		}
		[Bindable]
		public var bluetoothSelected:Boolean = false;
		[Bindable]
		public var camMgrEnabledLandscape:Boolean;
		[Bindable]
		public var camMgrEnabledPortrait:Boolean;
		[Bindable]
		public var calloutContentWdMax:Number = 608;
		[Bindable]
		public var customCommandInnerWidth:Number = 144;
		[Bindable]
		public var customCommandOuterWidth:Number = 160;
		[Bindable]
		public function get debugOn():Boolean
		{
			return _bDebug;
		}
		public function set debugOn(value:Boolean):void
		{
			_bDebug = value;
		}
		[Bindable]
		public var debugOverlayAlpha:Number = 0.8;
		[Bindable]
		public function get debugVisible ( ) : Boolean
		{
			return _bDebugVis;
		}
		public function set debugVisible (value:Boolean) : void
		{
			_bDebugVis = value;
			if ( value )
			{
				debugOverlayAlpha = 0.8;
			}
			else
			{
				debugOverlayAlpha = 1;
				debugOn = false;
			}
		}
		public function get eepromsCollection ( ) : VectorCollection
		{
			return new VectorCollection ( _vEeproms );
		}
		public var eepromConfigCaptRsrc:String;
		public var eepromWriteCaptRsrc:String;
		[Bindable]
		public var expertModeOn:Boolean = true;
		// gaps and guiDpiMult change in proportion to runtime DPI during initialization
		[Bindable]
		public var guiGap:Number = 8;
		[Bindable]
		public var guiGap2:Number = 2 * guiGap;
		[Bindable]
		public var guiGap3:Number = 3 * guiGap;
		[Bindable]
		public var guiGap4:Number = 4 * guiGap;
		[Bindable]
		public var guiDpiMult:Number = 1;
		[Bindable]
		public var isBusy:Boolean = true;
		public function get isFirstRun():Boolean
		{
			return _bFirstRun;
		}
		public function get isMoving():Boolean
		{
			return _bMoving;
		}
		private function _IsMovingSet(value:Boolean):void
		{
			_bMoving = value;
			_camMgr.motionSet ( _bMoving );
		}
		[Bindable (event="sleep_state_changed")]
		public function get isSleeping():Boolean
		{
			return _bSleep;
		}
		private function _IsSleepingSet(value:Boolean):void
		{
			if ( _bSleep !== value )
			{	
				_bSleep = value;
				dispatchEvent ( new Event ( SLEEP_STATE_CHANGED ) );
			}
		}
		[Bindable]
		public var lightExternal:Boolean = false;
		[Bindable]
		public var lightOn:Boolean = false;
		[Bindable]
		public var mcuBLE:McuConnectorBLE;
		[Bindable]
		public var mcuBluetooth:McuConnectorBluetooth;
		public function get mcuConnected():Boolean
		{
			return _bMcuConnected;
		}
		private function _McuConnectedSet(value:Boolean):void
		{
			if ( _bMcuConnected !== value )
			{
				_bMcuConnected = value;
				if ( value )
				{
					_debugOut ( 'status_mcu_connected', true );
					if ( _bEepromsNeeded )
					{
						// attempt read now
						_bEepromsNeeded = false;
						var i_eep:McuEeprom = _oEepromById [ 'eepv' ] as McuEeprom;
						if ( mcuSendCommandByteArray ( i_eep.messageBytesForRead ) )
						{
							_EepromReadTimerReset ( );
							statusSetResource ( 'status_eeprom_read' );
						}
						else
						{
							_EepromReadTimedOut ( );
						}
					}
				}
				else
				{
					// prepare to receive current limit default from MCU next we connect
					_bCurrentLimDefRecd = false;
					_debugOut ( 'error_mcu_disconnected', true );
				}
			}
		}
		[Bindable]
		public var mcuConnector:IMcuConnector;
		[Bindable]
		public var motionEnabled:Boolean;
		[Bindable]
		public var motMgrEnabledLandscape:Boolean;
		[Bindable]
		public var motMgrEnabledPortrait:Boolean;
		/*
		public function get moveIgnore():Boolean
		{
			return _bMoveIgnore;
		}
		private function _MoveIgnoreSet(value:Boolean):void
		{
			_bMoveIgnore = value;
		}
		*/
		[Bindable]
		public var orientedPortrait:Boolean = true;
		[Bindable (event="op_mode_changed")]
		public function get opMode():uint
		{
			return _uOpMode;
		}
		private function _OpModeSet(value:uint):void
		{
			if ( _uOpMode !== value )
			{
				_uOpMode = value;
				userState.opMode = value;
				dispatchEvent ( new Event ( OP_MODE_CHANGED ) );
			}
		}
		public var os:int;
		[Bindable]
		public var osAllowsExit:Boolean = true;
		[Bindable]
		public var osIsAndroid:Boolean = false;
		[Bindable]
		public var osIsIOS:Boolean = false;
		[Bindable]
		public var osStatusBarHeight:int = 0;
		[Bindable]
		public var permissionsChecker:IPermissionsChecker;
		[Bindable]
		public var permissionsInited:Boolean = false;
		[Bindable]
		public var pilotConnector:IPilotConnector;
		private var _bRotLock:Boolean = false;
		[Bindable(event="rotation_lock_changed")]
		public function get rotationLocked():Boolean
		{
			return !app.stage.autoOrients;
		}
		private function _RotationLockChangedDispatch():void
		{
			dispatchEvent ( new Event ( ROTATION_LOCK_CHANGED ) );
		}
		private var _dirSetsBkp:File;
		public function get settingsBackupDirectory():File
		{
			return _dirSetsBkp;
		}
		private var _dirSets:File;
		public function get settingsDirectory():File
		{
			return _dirSets;
		}
		public var userState:UserState;
		public var videoPod:UIComponent;
		public function get videoPodAspectRatio():Number
		{
			return _nVidPodAspect;
		}
		public function get videoPodHeight():int
		{
			return _iVidPodHt;
		}
		public function get videoPodWidth():int
		{
			return _iVidPodWd;
		}
		public function get videoSenderRotation():uint
		{
			return _uVidSenderRot;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function actionMenuToggle ( hardware:Boolean = false ) : void
		{
			actionMenuOn = !actionMenuOn;
		}
		
		public function backButton ( ) : void
		{
			if ( !permissionsInited && _sAppVwState == 'permissions' )
			{
				permissionsContinue ( );
			}
			else
			{
				viewStatePop ( );
			}
		}
		
		public function batchVarsReportQueue ( ) : void
		{
			_callLater ( _BatchVarsReport );
		}
		
		public function bleConfigDone ( ) : void
		{
			viewStatePop ( 'ble_config' );
		}
		
		public function bleConfigOpen ( ) : void
		{
			if ( _sAppVwState != 'ble_config' )
			{
				viewStatePush ( 'ble_config' );
			}
		}
		
		public function bleConfigSuccess ( ) : void
		{
			statusSetResource ( 'status_ble_success' );
			bleConfigDone ( );
		}
		
		public function bleConfigToggle ( ) : void
		{
			if ( _sAppVwState == 'ble_config' )
			{
				viewStatePop ( 'ble_config' );
			}
			else
			{
				viewStatePush ( 'ble_config' );
			}
		}
		
		public function bluetoothConfigDone ( ) : void
		{
			viewStatePop ( 'bluetooth_config' );
		}
		
		public function bluetoothConfigOpen ( ) : void
		{
			viewStatePush ( 'bluetooth_config' );
		}
		
		public function bluetoothConfigSuccess ( ) : void
		{
			statusSetResource ( 'status_bt_success' );
			bluetoothConfigDone ( );
		}
		
		public function bluetoothConfigToggle ( ) : void
		{
			if ( _sAppVwState == 'bluetooth_config' )
			{
				viewStatePop ( 'bluetooth_config' );
			}
			else
			{
				viewStatePush ( 'bluetooth_config' );
			}
		}
		
		public function busyIndicatorReady ( ) : void
		{
			if ( _sAppVwStateDelayed.length > 0 )
			{
				var tmr:Timer = new Timer ( 200, 1 );
				tmr.addEventListener ( TimerEvent.TIMER, _AppViewStateSetDelayed );
				tmr.start ( );
			}
		}
		
		public function cameraMoveHomeRequest ( ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'cameraMoveHomeRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			// ##### TESTING #####
			_debugOut ( 'Mcu camera home command: ' + McuMessage.CAMERA_HOME.toString ( 16 ) );
			// ###################
			if ( _bPanOrTiltEnabled )
			{
				mcuSendCommandId ( McuMessage.CAMERA_HOME );
				// ##### TESTING #####
				if ( !_bMcuConnected )
				{
					// fake it
					var vmdToSend:Vector.<MessageData> = new <MessageData> [];
					var uLen:uint = 0;
					if ( _VisionPanUpdate ( _iPanHome ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'cp', _iPanHome );
					}
					if ( _VisionTiltUpdate ( _iTiltHome ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'ct', _iTiltHome );
					}
					if ( uLen > 0 )
					{
						pilotConnector.userVarsQueue ( vmdToSend );
						_VisionOrientUpdateCommit ( );
					}
				}
				// ###################
			}
		}
		
		public function cameraMoveRequest ( cm:CameraMove ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'cameraMoveRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			// ##### TESTING #####
			_debugOut ( 'Mcu camera move command: ' + cm.messageString );
			// ###################
			if ( _bPanOrTiltEnabled )
			{
				mcuSendCommandByteArray ( cm.messageBytesForMcu );
				// ##### TESTING #####
				if ( !_bMcuConnected )
				{
					// fake it
					var vmdToSend:Vector.<MessageData> = new <MessageData> [];
					var uLen:uint = 0;
					if ( _VisionPanUpdate ( cm.panDegrees ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'cp', cm.panDegrees );
					}
					if ( _VisionTiltUpdate ( cm.tiltDegrees ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'ct', cm.tiltDegrees );
					}
					if ( uLen > 0 )
					{
						pilotConnector.userVarsQueue ( vmdToSend );
						_VisionOrientUpdateCommit ( );
					}
				}
				// ###################
			}
		}
		
		public function cameraMoveResetRequest ( ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'cameraMoveResetRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			// ##### TESTING #####
			_debugOut ( 'Mcu camera move reset command: ' + McuMessage.CAMERA_RESET.toString ( 16 ) );
			// ###################
			if ( _bPanOrTiltEnabled )
			{
				mcuSendCommandId ( McuMessage.CAMERA_RESET );
				// ##### TESTING #####
				if ( !_bMcuConnected )
				{
					// fake it
					var vmdToSend:Vector.<MessageData> = new <MessageData> [];
					var uLen:uint = 0;
					if ( _VisionPanUpdate ( _iPanReset ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'cp', _iPanReset );
					}
					if ( _VisionTiltUpdate ( _iTiltReset ) )
					{
						vmdToSend [ uLen++ ] = new MessageData ( 'ct', _iTiltReset );
					}
					if ( uLen > 0 )
					{
						pilotConnector.userVarsQueue ( vmdToSend );
						_VisionOrientUpdateCommit ( );
					}
				}
				// ###################
			}
		}
		
		public function cameraViewClickRequest ( xy:ShortXY ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'cameraViewClickRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			// ##### TESTING #####
			if ( _bDebug )
				_debugOut ( 'Mcu camera view click command: ' + xy.messageString );
			// ###################
			
			mcuSendCommandByteArray ( xy.messageBytesForMcu );
		}
		
		public function customConfigDone ( ) : void
		{
			viewStatePop ( 'custom_config' );
			_callLater ( _CustomConfigValidate );
		}
		
		public function customConfigOpen ( ) : void
		{
			viewStatePush ( 'custom_config' );
		}
		
		public function customRequest ( mba:MessageByteArray ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'customRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			// ##### TESTING #####
			if ( _bDebug )
				_debugOut ( 'Custom command: ' + mba.messageString );
			// ###################
			
			if ( _custCmdMgr.suspend )
			{
				_debugOut ( 'customRequest discarded while Command Configuration in progress.' );
				return;
			}
			
			mcuSendCommandByteArray ( mba.messageBytes );
		}
		
		public function eepromConfigOpen ( ) : void
		{
			// Display capabilities configuration screen.
			viewStatePush ( 'eeprom_config' );
		}
		
		public function eepromConfigUserDone ( ) : void
		{
			viewStatePop ( 'eeprom_config' );
			_callLater ( _EepromConfigWrite );
		}
		
		public function emergencyAcknowledge ( ) : void
		{
			// Called when receive message from pilot acknowledging notice of emergency condition.
			// Can indicate that a latency problem has abated and we can resume activity if no other
			// emergency flags are set.
			_debugOut ( 'Emergency state acknowledged by Pilot Control Panel' );
			emergencyFlagsClear ( EmergencyFlags.LATENCY );
		}
		
		public function emergencyFlagsClear ( flags:uint, fromMcu:Boolean = false ) : void
		{
			var uFlags:uint = _uEmFlags & ~EmergencyFlags.ValidateFlags ( flags );
			if ( uFlags != _uEmFlags )
			{
				_uEmFlags = uFlags;
				_EmergencyStateUpdate ( );
			}
		}
		
		public function emergencyFlagsGet ( ) : uint
		{
			return _uEmFlags;
		}
		
		public function emergencyFlagsSet ( flags:uint, fromMcu:Boolean = false ) : void
		{
			if ( !testCfgEmFlagsAllow )
				return;
			
			var uFlags:uint = ( _uEmFlags | EmergencyFlags.ValidateFlags ( flags ) );
			if ( uFlags != _uEmFlags )
			{
				_uEmFlags = uFlags;
				_EmergencyStateUpdate ( );
				
				var bStop:Boolean = true;
				if ( ( _uEmFlags & EmergencyFlags.LATENCY ) == EmergencyFlags.LATENCY )
				{
					// latency flag set, so need to stop
				}
				else if ( ( _uEmFlags & EmergencyFlags.OBSTACLE ) == EmergencyFlags.OBSTACLE )
				{
					// obstacle flag set
					if ( _moveProps.leftRun == MotorStates.BACKWARD || _moveProps.rightRun == MotorStates.BACKWARD )
					{
						// we're already backing off or turning
						bStop = false;
					}
				}
				if ( bStop )
				{
					
					_moveProps = MoveProps.NewFromParameters ( );
					_IsMovingSet ( false );
					if ( !fromMcu )
					{
						// mcuSendCommandByteArray ( _moveProps.messageBytesForMcu ); // safe mode should now handle this
						// Mcu safe mode
						mcuSendCommandId ( McuMessage.SAFE_ROVER );
					}
				}
				
			}
		}
		
		public function exitConfirmed ( ) : void
		{
			if ( osAllowsExit )
			{
				_bExiting = true;
				
				_BatteryDeactivate ( true );
				
				_SystemsDeactivate ( );
				
				_McuConnectorDismiss ( );
				
				_PilotConnectorDismiss ( );
				
				_callLater ( _ExitStepExit );
			}
		}
		
		public function exitQuery ( ) : void
		{
			if ( !osAllowsExit )
				return;
			
			eventRelay.dispatchEvent (
				new DialogEvent (
					DialogEvent.DIALOG,
					'exit_confirm_msg',
					'exit_confirm_title',
					null,
					null,
					new DialogData (
						'exit',
						new <DialogOption> [
							new DialogOption ( 'y', 'yes_label' ),
							new DialogOption ( 'n', 'no_label' )
						],
						-1,
						_ExitQueryResponse
					)
				)
			);
		}
		
		public function expertModeToggle ( ) : void
		{
			_ExpertModeSet ( !expertModeOn );
			if ( !actionMenuOn )
			{
				actionMenuOn = true;
			}
		}
		
		public function initialize ( app:Application ) : void
		{
			this.app = app;
			// keep fully awake, until create ANE for Android PARTIAL_WAKE_LOCK
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			try
			{
				Core.init ( DISTRIQT_ANE_APP_KEY );
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_core_init', true, [ err.message ] );
			}
			switch ( Capabilities.version.substr ( 0, 3 ) )
			{
				case ( 'IOS' ):
					os = OS_IOS;
					osIsIOS = true;
					osAllowsExit = false;
					osStatusBarHeight = app.getStyle ( 'osStatusBarHeight' );
					break;
				default:
					// 'AND'
					os = OS_ANDROID;
					osIsAndroid = true;
					// NativeApplication.nativeApplication.exit() should work on anything except iOS
					osAllowsExit = true;
					NativeApplication.nativeApplication.addEventListener (
						KeyboardEvent.KEY_DOWN, _KeyDown, false, 0, true
					);
					NativeApplication.nativeApplication.addEventListener (
						KeyboardEvent.KEY_UP, _KeyUp, false, 0, true
					);
					
					try
					{
						AndroidSupportV4.init ( DISTRIQT_ANE_APP_KEY );
					}
					catch ( err:Error )
					{
						_debugOut ( 'error_android_support_init', true, [ err.message ] );
					}
					break;
				
				/*
				case ( 'AND' ):
					os = OS_ANDROID;
					break;
				case ( 'QNX' ):
					os = OS_BLACKBERRY;
					break;
				default:
					os = OS_OTHER;
					break;
				*/
			}
			
			// Get our version string from the application descriptor and add platform name
			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXml.namespace();
			// _sAppVersion = appXml.ns::filename[0] + ' (' + appXml.ns::versionLabel[0] + ')';
			_sAppVersion = _resourceManager.getString ( 'default', 'version_label_' + os, [ appXml.ns::filename[0], appXml.ns::versionLabel[0] ] );
			
			var nDpi:Number = app.runtimeDPI;
			// _debugOut ( 'runtime DPI: ' + nDpi );
			if ( nDpi != DESIGN_DPI )
			{
				guiDpiMult = nDpi / DESIGN_DPI
				guiGap = guiGap * guiDpiMult;
				guiGap2 = guiGap * 2;
				guiGap3 = guiGap * 3;
				guiGap4 = guiGap * 4;
			}
			/*
			var aMsgs:Array = McuConnectModes.ConfigureForDevice ( osIsAndroid );
			if ( aMsgs.length > 0 )
			{
				for each ( var i_aMsg:Array in aMsgs )
				{
					_debugOut ( i_aMsg [ 0 ], i_aMsg [ 1 ], i_aMsg [ 2 ] );
				}
			}
			*/
			_aEepromByAddr = [];
			_vEepromIdsToCheck = new <String> [];
			_oEepromById = {};
			
			_moveProps = MoveProps.NewFromParameters ( );
			
			_tmrEepromReadWait = new Timer ( EEPROM_READ_LIMIT, 1 );
			_tmrEepromReadWait.addEventListener ( TimerEvent.TIMER, _EepromReadTimedOut );
			
			_tmrEepromWrite = new Timer ( EEPROM_WRITE_INTERVAL, 0 );
			_tmrEepromWrite.addEventListener ( TimerEvent.TIMER, _EepromsWrite );
			
			// instantiate roverData value object
			_roverData = new RoverData();
			
			// make sure pilotConnector is never null
			pilotConnector = new PilotConnector ( ); // bare bones base class that implements IPilotConnector
			
			if ( osIsIOS )
			{
				permissionsChecker = PermissionsCheckerIOS.instance;
			}
			else
			{
				permissionsChecker = PermissionsCheckerAndroid.instance;
			}
			_camMgr = CameraManager.instance;
			_motMgr = MotionManager.instance;
			_wpsMgr = WaypointsManager.instance;
			
			_cwCamMgrEnabled = BindingUtils.bindSetter ( _CamMgrEnabledChanged, _camMgr, 'enabled' );
			_cwMotMgrEnabled = BindingUtils.bindSetter ( _MotMgrEnabledChange, _motMgr, 'enabled' );
			
			// read settings
			_LocalFilesInitialize ( );
			
			app.stage.addEventListener ( StageOrientationEvent.ORIENTATION_CHANGE, _StageOrientationChanged );
			if ( osIsAndroid )
			{
				app.addEventListener ( ResizeEvent.RESIZE, _StageResized );
			}
			
			_StageOrientationRestore ( );
			
			_callLater ( _PermsInit );
		}
		
		public function light ( on:Boolean ) : void
		{
			if ( !_bLightEnabled )
				return;
			
			lightOn = on;
			
			if ( lightExternal )
			{
				if ( on )
				{
					mcuSendCommandId ( McuMessage.HEADLIGHT_ON );
				}
				else
				{
					mcuSendCommandId ( McuMessage.HEADLIGHT_OFF );
				}
			}
			else
			{
				if ( on )
				{
					app.stage.displayState = StageDisplayState.FULL_SCREEN;
				}
				else
				{
					app.stage.displayState = StageDisplayState.NORMAL;
				}
			}
			
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'fl', lightOn ) ] );
		}
		
		public function lightCancel ( ) : void
		{
			light ( false );
		}
		
		public function mcuSendCommandByteArray ( ba:ByteArray ) : Boolean
		{
			if ( !mcuConnector )
				return false; // return
			
			return mcuConnector.sendCommand ( ba );
		}
		
		public function mcuSendCommandId ( value:int ) : Boolean
		{
			if ( !mcuConnector )
				return false; // return
			
			return mcuConnector.sendCommandId ( value );
		}
		
		public function motionRequest ( moveProps:MoveProps ) : void
		{
			/*
			if ( _bMoveIgnore )
			{
				_debugOut ( 'motionRequest discarded due to emergency flags: ' + _uEmFlags );
				return;
			}
			*/
			_moveProps = moveProps;
			
			var baSend:ByteArray = _moveProps.messageBytesForMcu;
			
			// ##### TESTING #####
			if ( _bDebug )
			{
				_debugOut ( 'Mcu motion: ' + _moveProps.messageString + '\n  sent to MCU: ' + HexStringUtil.HexStringFromByteArray ( baSend ) );
			}
			// ###################
			
			mcuSendCommandByteArray ( baSend );
			
			if ( _bMoving != _moveProps.isMoving )
			{
				// update camera config
				_IsMovingSet ( !_bMoving );
			}
		}
		
		public function motorCurrentLimitFromMcu ( step:uint ) : void
		{
			var uVmdLen:uint;
			var vmdToSend:Vector.<MessageData>;
			
			if ( _bCurrentLimDefRecd )
			{
				// Only accept first value received after connection as the MCU's default.
				// That way, user can always get back to original hard-coded default
				// by restarting both the MCU and this app.
				return;
			}
			if ( step > 128 || step < 1 )
			{
				// should never get here
				_debugOut ( 'Motor current limit default outside valid range (step value 1 to 128): ' + step.toString ( ) );
				return;
			}
			
			_bCurrentLimDefRecd = true;
			_debugOut ( 'Motor current limit default received (step value): ' + step.toString ( ) );
			
			if ( pilotConnector.isConnected )
			{
				uVmdLen = 0;
				vmdToSend = new <MessageData> [];
				if ( userState.motorCurrentLimitDefault < 1 )
				{
					// new install, so need to set active value to default also
					userState.motorCurrentLimitStep = step;
					// update smartfox server user var
					vmdToSend [ uVmdLen++ ] = new MessageData ( 'mcl', step );
				}
				userState.motorCurrentLimitDefault = step;
				// update smartfox server user var
				vmdToSend [ uVmdLen ] = new MessageData ( 'mcld', step );
				pilotConnector.userVarsQueue ( vmdToSend );
			}
			else
			{
				if ( userState.motorCurrentLimitDefault < 1 )
				{
					// new install, so need to set active value to default also
					userState.motorCurrentLimitStep = step;
				}
				userState.motorCurrentLimitDefault = step;
			}
			
			if ( userState.motorCurrentLimitStep != step )
			{
				// having just connected and received default,
				// now need to send user-adjusted limit to MCU
				_debugOut ( 'User-adjusted motor current limit sent to MCU (step value): ' + userState.motorCurrentLimitStep.toString ( ) );
				_MotorCurrentLimitToMcu ( userState.motorCurrentLimitStep );
			}
		}
		
		public function motorCurrentLimitRequest ( step:uint ) : void
		{
			_debugOut ( 'Motor current limit request (step value): ' + step.toString ( ) );
			if ( userState.motorCurrentLimitStep != step )
			{
				// update userState
				userState.motorCurrentLimitStep = step;
				
				if ( pilotConnector.isConnected )
				{
					// update smartfox server user var
					pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'mcl', step ) ] );
				}
				// send to MCU
				_MotorCurrentLimitToMcu ( step );
			}
		}
		
		public function opModeInit ( ) : void
		{
			var uMode:uint = userState.opMode;
			if ( _OpModeIsAvailable ( uMode ) )
			{
				opModeSelected ( uMode );
			}
			else
			{
				opModePrompt ( );
			}
		}
		
		public function opModePrompt ( ) : void
		{
			_ViewStateSetHome ( 'mode_prompt' );
		}
		
		public function opModeSelected ( mode:uint, clearViewStack:Boolean = false ) : void
		{
			var uMode:uint = OpModes.ValidateMode ( mode );
			var bShowPerms:Boolean;
			var sView:String;
			switch ( uMode )
			{
				case OpModes.RC:
				{
					sView = 'home_rc';
					break;
				}
				case OpModes.CS:
				{
					sView = 'home_cs';
					break;
				}
				case OpModes.PP:
				{
					sView = 'home_pp';
					break;
				}
				default:
				{
					// OpModes.NA
					sView = 'home';
					break;
				}
			}
			
			if ( _uOpMode == uMode )
			{
				// not changing, so we're done here
				_ViewStateSetHome ( sView, clearViewStack );
				return;
			}
			
			// second parameter is false here,
			// because new state will be revealed
			// by _ViewStateSetHome() call below
			// viewStatePop ( 'mode_prompt', false );
			
			// dismiss previous op Mode
			_PilotConnectorDismiss ( );
			
			_OpModeSet ( uMode );
			bShowPerms = !permissionsChecker.allPermitted;
			
			// instantiate
			if ( uMode == OpModes.RC )
			{
				// this device acts as simple remote control via Bluetooth
				if ( Multitouch.supportsTouchEvents )
				{
					Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
				}
				pilotConnector = new PilotConnectorRC ( );
				if ( bShowPerms )
				{
					_callLater ( permissionsOpen );
				}
			}
			else
			{
				if ( Multitouch.supportsTouchEvents )
				{
					Multitouch.inputMode = MultitouchInputMode.NONE;
				}
				if ( uMode == OpModes.NA )
				{
					pilotConnector = new PilotConnector ( );
				}
				else
				{
					if ( uMode == OpModes.PP )
					{
						// not actually implemented yet, but hope springs eternal
						pilotConnector = new PilotConnectorPP ( );
					}
					else
					{
						// OpModes.CS
						pilotConnector = new PilotConnectorCS ( );
						_DeviceMotionActivate ( );
						if ( bShowPerms )
						{
							_callLater ( permissionsOpen );
						}
						else
						{
							_GeoActivate ( );
						}
					}
				}
			}
			
			_ViewStateSetHome ( sView, clearViewStack );
		}
		
		public function permissionsClose ( ) : void
		{
			if ( !permissionsInited && _sAppVwState == 'permissions' )
			{
				permissionsContinue ( );
			}
			else
			{
				viewStatePop ( 'permissions' );
			}
		}
		
		public function permissionsContinue ( ) : void
		{
			if ( permissionsInited )
			{
				permissionsChecker.addEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsDone );
			}
			else
			{
				permissionsChecker.addEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsInitDone );
			}
			viewStatePop ( 'permissions' );
			permissionsChecker.request ( );
		}
		
		public function permissionsOpen ( ) : void
		{
			if ( _sAppVwState != 'permissions' )
			{
				viewStatePush ( 'permissions' );
			}
		}
		
		public function phoneConfigDone ( params:Object ) : void
		{
			viewStatePop ( 'phone_config' );
			// Bluetooth LE vs Bluetooth vs USB Microbridge vs USB Android as host
			userState.mcuConnectModeId = McuConnectModes.ValidateMode ( params.mcuConnectModeId as uint );
			// mcu watchdog setup mode
			userState.mcuWatchdogModeId = params.mcuWatchdogModeId as uint;
			// capabilities storage location
			userState.capabilitiesStorePhone = params.capabilitiesStorePhone as Boolean;
			// camera
			var cam:Camera = params.camera as Camera;
			if ( cam != null )
			{
				_camMgr.camera = cam;
				userState.cameraIndex = cam.index;
			}
			// camera flip
			var bMeta:Boolean = false;
			var bFlip:Boolean = params.cameraFlipH as Boolean;
			if ( bFlip != userState.cameraFlipHorizontal )
			{
				bMeta = true;
				userState.cameraFlipHorizontal = bFlip;
			}
			bFlip = params.cameraFlipV as Boolean;
			if ( bFlip != userState.cameraFlipVertical )
			{
				bMeta = true;
				userState.cameraFlipVertical = bFlip;
			}
			if ( bMeta )
			{
				dispatchEvent ( new Event ( AV_SENDER_METADATA_CHANGED ) );
			}
			// phone battery minimum
			userState.phoneBatteryMin = params.phoneBatteryMin as int;
			if ( pilotConnector.isConnected )
			{
				pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'pbtn', userState.phoneBatteryMin ) ] );
			}
			
			_McuConnectConfigure ( );
		}
		
		public function sleepRequest ( ) : void
		{
			if ( !_bSleep )
			{
				// ##### TESTING #####
				_debugOut ( 'Mcu sleep command: ' + McuMessage.SLEEP.toString ( 16 ) );
				// ###################
				_SystemsDeactivate ( );
			}
		}
		
		public function sleepWakeToggle ( ) : void
		{
			if ( _bSleep )
				_SystemsActivate ( );
			else
				_SystemsDeactivate ( );
		}
		
		public function stageOrientationLockToggle ( ) : void
		{
			if ( app.stage.autoOrients )
			{
				_StageOrientationLock ( );
			}
			else
			{
				_StageOrientationUnlock ( );
			}
			_RotationLockChangedDispatch ( );
		}
		
		public function statusClear ( ) : void
		{
			isBusy = false;
			_statusData = null;
			_StatusEventDispatch ( );
		}
		
		public function statusSet ( label:String, busy:Boolean = false, icon:Class = null ) : void
		{
			isBusy = busy;
			_statusData = new StatusData ( label, icon );
			_StatusEventDispatch ( );
		}
		
		public function statusSetResource ( rsrc:String, busy:Boolean = false, icon:Class = null, params:Array = null ) : void
		{
			isBusy = busy;
			_statusData = new StatusData ( _resourceManager.getString ( 'default', rsrc, params ), icon );
			_StatusEventDispatch ( );
		}
		
		public function steeringTrimRequest ( trim:Number ) : void
		{
			_debugOut ( 'Steering trim request (raw value): ' + trim.toFixed ( 3 ) );
			var nTrim:Number = MoveProps.SetSteeringTrim ( trim );
			if ( userState.steeringTrim != nTrim )
			{
				// update userState
				userState.steeringTrim = nTrim;
				// update pilot
				if ( pilotConnector.isConnected )
				{
					pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'stt', nTrim ) ] );
				}
				if ( _bMoving )
				{
					var baSend:ByteArray = _moveProps.messageBytesForMcu;
					
					// ##### TESTING #####
					if ( _bDebug )
					{
						_debugOut ( 'Current motion value is: ' + _moveProps.messageString + '\n  to MCU with new trim: ' + HexStringUtil.HexStringFromByteArray ( baSend ) );
					}
					// ###################
					
					mcuSendCommandByteArray ( baSend );
				}
			}
		}
		
		[Bindable]
		public var testCfgBatteryAllow:Boolean = true;
		public function testCfgBatteryToggle ( ) : void
		{
			testCfgBatteryAllow = !testCfgBatteryAllow;
			_debugOut ( 'test_cfg_battery_status', true, [ testCfgBatteryAllow ] );
			// if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
			// {
			if ( testCfgBatteryAllow )
			{
				_BatteryActivate ( );
			}
			else
			{
				_BatteryDeactivate ( );
			}
			// }
		}
		
		[Bindable]
		public var testCfgDevOrientAllow:Boolean = true;
		public function testCfgDevOrientToggle ( ) : void
		{
			testCfgDevOrientAllow = !testCfgDevOrientAllow;
			_debugOut ( 'test_cfg_dev_orient_status', true, [ testCfgDevOrientAllow ] );
			if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
			{
				if ( !_bSleep )
				{
					if ( testCfgDevOrientAllow )
					{
						_DeviceMotionActivate ( );
					}
					else
					{
						_DeviceMotionDeactivate ( );
					}
				}
			}
		}
		
		[Bindable]
		public var testCfgEmFlagsAllow:Boolean = true;
		public function testCfgEmFlagsToggle ( ) : void
		{
			testCfgEmFlagsAllow = !testCfgEmFlagsAllow;
			_debugOut ( 'test_cfg_em_flags_status', true, [ testCfgEmFlagsAllow ] );
			if ( !testCfgEmFlagsAllow )
			{
				// clear any flags currently set
				if ( _uEmFlags != 0 )
				{
					_uEmFlags = 0;
					_EmergencyStateUpdate ( );
				}
			}
		}
		
		[Bindable]
		public var testCfgGeoAllow:Boolean = true;
		public function testCfgGeoToggle ( ) : void
		{
			testCfgGeoAllow = !testCfgGeoAllow;
			_debugOut ( 'test_cfg_geo_status', true, [ testCfgGeoAllow ] );
			if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
			{
				if ( !_bSleep )
				{
					if ( testCfgGeoAllow )
					{
						_GeoActivate ( );
					}
					else
					{
						_GeoDeactivate ( );
					}
				}
			}
		}
		
		[Bindable]
		public var testCfgLagMonSfAllow:Boolean = true;
		public function testCfgLagMonSfToggle ( ) : void
		{
			testCfgLagMonSfAllow = !testCfgLagMonSfAllow;
			_debugOut ( 'test_cfg_lag_mon_sf_status', true, [ testCfgLagMonSfAllow ] );
			if ( _uOpMode == OpModes.CS )
			{
				( pilotConnector as PilotConnectorCS ).lagMonitorAllowed ( testCfgLagMonSfAllow );
			}
		}
		
		[Bindable]
		public var testCfgMcuDtlTrace:Boolean = false;
		public function testCfgMcuDtlTraceToggle ( ) : void
		{
			testCfgMcuDtlTrace = !testCfgMcuDtlTrace;
			_debugOut ( 'test_cfg_mcu_dtl_status', true, [ testCfgMcuDtlTrace ] );
		}
		
		[Bindable]
		public var testCfgMagDecAllow:Boolean = true;
		public function testCfgMagDecToggle ( ) : void
		{
			testCfgMagDecAllow = !testCfgMagDecAllow;
			_debugOut ( 'test_cfg_mag_dec_status', true, [ testCfgMagDecAllow ] );
			if ( _geo )
			{
				if ( _declinationUtil.active != testCfgMagDecAllow )
				{
					if ( testCfgMagDecAllow )
					{
						_declinationUtil.addEventListener ( UtilityEvent.DECLINATION, _DeclinationUpdated );
					}
					else
					{
						_declinationUtil.removeEventListener ( UtilityEvent.DECLINATION, _DeclinationUpdated );
					}
					_declinationUtil.activeSet ( testCfgMagDecAllow );
				}
			}
		}
		
		[Bindable]
		public var testCfgMediaStreamAllow:Boolean = true;
		public function testCfgMediaStreamToggle ( ) : void
		{
			testCfgMediaStreamAllow = !testCfgMediaStreamAllow;
			_debugOut ( 'test_cfg_media_status', true, [ testCfgMediaStreamAllow ] );
			if ( _uOpMode == OpModes.CS )
			{
				( pilotConnector as PilotConnectorCS ).mediaStreamAllowed ( testCfgMediaStreamAllow );
			}
		}
		
		[Bindable]
		public var testCfgWatchDogsAllow:Boolean = true;
		public function testCfgWatchDogsToggle ( ) : void
		{
			testCfgWatchDogsAllow = !testCfgWatchDogsAllow;
			_debugOut ( 'test_cfg_watch_dogs_status', true, [ testCfgWatchDogsAllow ] );
			if ( _uOpMode == OpModes.CS )
			{
				( pilotConnector as PilotConnectorCS ).watchDogsAllowed ( testCfgWatchDogsAllow );
				
			}
			// ##### TODO
		}
		
		public function viewReady ( ) : void
		{
			isBusy = false;
		}
		
		public function viewStatePop ( name:String = '', updateView:Boolean = true ) : void
		{
			var i:int;
			var iLast:int = _vViewStateStack.length - 1;
			if ( iLast > 0 )
			{
				if ( name.length < 1 )
				{
					// basic back button or nav back arrow
					_vViewStateStack.pop ( );
				}
				else
				{
					// remove any occurrence(s) of this name from the stack
					for ( i=iLast; i>0; i-- )
					{
						if ( _vViewStateStack [ i ] == name )
						{
							_vViewStateStack.removeAt ( i );
						}
					}
				}
				if ( updateView )
				{
					var sNew:String = _vViewStateStack [ _vViewStateStack.length - 1 ];
					if ( _VIEW_STATE_SLOW [ sNew ] && !isBusy )
					{
						_sAppVwStateDelayed = sNew;
						isBusy = true;
					}
					else
					{
						_AppViewStateSet ( sNew );
					}
				}
			}
			else if ( name.length < 1 )
			{
				_callLater ( exitQuery );
			}
		}
		
		public function viewStatePush ( name:String ) : void
		{
			var i:int;
			var iLen:int = _vViewStateStack.length
			var iLast:int = iLen - 1;
			var iRank:int = _VIEW_STATE_RANK [ name ] as int;
			if ( iLast > 0 )
			{
				// remove any old occurrence(s) of this name from the stack
				for ( i=iLast; i>0; i-- )
				{
					if ( _vViewStateStack [ i ] == name )
					{
						_vViewStateStack.removeAt ( i );
					}
				}
				// starting from the end, insert this
				// after the first item encountered
				// with rank <= this one
				iLast = _vViewStateStack.length - 1;
				for ( i=iLast; i>=0; i-- )
				{
					if ( ( _VIEW_STATE_RANK [ _vViewStateStack [ i ] ] as int ) <= iRank )
					{
						_vViewStateStack.insertAt ( i+1, name );
						break;
					}
				}
			}
			else
			{
				// only option is to add onto the end
				_vViewStateStack [ iLen ] = name;
			}
			var sNew:String = _vViewStateStack [ _vViewStateStack.length - 1 ];
			if ( _VIEW_STATE_SLOW [ sNew ] && !isBusy )
			{
				_sAppVwStateDelayed = sNew;
				isBusy = true;
			}
			else
			{
				_AppViewStateSet ( sNew );
			}
		}
		
		public function wakeRequest ( ) : void
		{
			if ( _bSleep )
			{
				// ##### TESTING #####
				_debugOut ( 'Mcu wake command: ' + McuMessage.WAKEUP.toString ( 16 ) );
				// ###################
				_SystemsActivate ( );
			}
		}
		
		// PRIVATE PROPERTIES
		
		private var _aEepromByAddr:Array;
		private var _batteryUtil:BatteryUtil;
		private var _bActMnOn:Boolean = false;
		private var _bBatterySupport:Boolean = false;
		private var _bBleSel:Boolean = false;
		private var _bCurrentLimDefRecd:Boolean = false;
		private var _bDebug:Boolean = true;
		private var _bDebugVis:Boolean = true;
		private var _bDevFaceBack:Boolean = false;
		private var _bDevMotionSupport:Boolean = false;
		private var _bEepromReadFail:Boolean = false;
		private var _bEepromsNeeded:Boolean = false;
		private var _bExiting:Boolean = false;
		private var _bFirstRun:Boolean = false;
		private var _bGeoSupport:Boolean = false;
		private var _bleMgr:BleManager;
		private var _bLightEnabled:Boolean = false;
		private var _bMcuConnected:Boolean = false;
		// private var _bMoveIgnore:Boolean = false;
		private var _bMoving:Boolean;
		private var _bPanDeviceEnabled:Boolean = false;
		private var _bPanEnabled:Boolean = false;
		private var _bPanOrTiltDeviceEnabled:Boolean = false;
		private var _bPanOrTiltEnabled:Boolean = false;
		private var _bSleep:Boolean = false;
		private var _bTiltDeviceEnabled:Boolean = false;
		private var _bTiltEnabled:Boolean = false;
		private var _camMgr:CameraManager;
		private var _cwCamMgrEnabled:ChangeWatcher;
		private var _cwMotMgrEnabled:ChangeWatcher;
		private var _currentCoords:CurrentCoordinates;
		private var _custCmdMgr:CustomCommandManager;
		private var _declinationUtil:DeclinationUtil;
		private var _fGpsRoomVarUpdate:Function = _NoOp;
		private var _fMcuGpsUpdate:Function = _NoOp;
		private var _fMcuHdgUpdate:Function = _NoOp;
		private var _geo:Geolocation;
		private var _gps:Gps;
		private var _iDevMountAngle:int = 0;
		private var _iPanHome:int = 0;
		private var _iPanNet:int = 0;
		private var _iPanReset:int = 0;
		private var _iRangerMinL:int = 40;
		private var _iRangerMinR:int = 40;
		private var _iTiltHome:int = 0;
		private var _iTiltNet:int = 0;
		private var _iTiltReset:int = 0;
		private var _iVideoActualHt:int;
		private var _iVideoActualWd:int;
		private var _iVidPodHt:int;
		private var _iVidPodWd:int;
		private var _motMgr:MotionManager;
		private var _moveProps:MoveProps; // stores most recent request
		private var _nBatteryPct:Number = 100;
		private var _nDcScale:Number = 112/255;
		private var _nFloatDifNeg:Number = -0.1;
		private var _nFloatDifPos:Number = 0.1;
		private var _nGpsDifNeg:Number = -0.000001;
		private var _nGpsDifPos:Number = 0.000001; // 0.000001 = about 4 inches at the equator
		private var _nNavGpsMsec:Number = NAV_GPS_MSEC_DEFAULT;
		private var _nNavGpsNextTime:Number = 0;
		private var _nNavHdgMsec:Number = NAV_HDG_MSEC_DEFAULT;
		private var _nNavHdgNextTime:Number = 0;
		private var _nQuatMsec:Number = QUAT_MSEC_DEFAULT;
		private var _nQuatNextTime:Number = 0;
		private var _nVidInsetFract:Number = 0.4; // adjust as GUI requires
		private var _nVidPodAspect:Number;
		private var _oEepromById:Object;
		private var _qBasis:Quaternion;
		private var _roverData:RoverData;
		private var _sAppVersion:String;
		private var _sAppVwState:String = 'home';
		private var _sAppVwStateDelayed:String = '';
		private var _sOrientStage:String = ''; // current orientation
		private var _statusData:StatusData;
		private var _tmrBattery:Timer; // battery check watchdog
		private var _tmrEepromReadWait:Timer // EEPROM read time limit
		private var _tmrEepromWrite:Timer; // EEPROM batch write interval timer
		private var _uEmFlags:uint = 0;
		private var _uHeading:uint = 360; // range is 0-359, so first value acquired won't assume to be unchanged
		private var _uOpMode:uint = OpModes.NA;
		private var _uVidSenderRot:uint = 0;
		private var _video:Video;
		private var _vEeproms:Vector.<McuEeprom>;
		private var _vEepromIdsToCheck:Vector.<String>;
		private var _vViewStateStack:Vector.<String> = new <String> ['home'];
		private var _wpsMgr:WaypointsManager;
		
		
		// PRIVATE METHODS
		
		private function _AppViewStateSetDelayed ( event:TimerEvent ) : void
		{
			var tmr:Timer = event.target as Timer;
			tmr.stop ( );
			tmr.removeEventListener ( TimerEvent.TIMER, _AppViewStateSetDelayed );
			if ( _sAppVwStateDelayed.length > 0 )
			{
				_AppViewStateSet ( _sAppVwStateDelayed );
				_sAppVwStateDelayed = '';
			}
		}
		
		private function _BatchVarsReport ( ) : void
		{
			if ( !pilotConnector.isConnected )
			{
				return;
			}
			
			_fGpsRoomVarUpdate = _GpsRoomVarUpdate; // from now on this method will be called when location changes
			var vmdRoomVars:Vector.<MessageData> = new <MessageData> [
				new MessageData ( 'gps', _gps, true ),
				new MessageData ( 'asd', userState.assetsDir ),
				new MessageData ( 'pip', userState.pilotNames )
			];
			pilotConnector.roomVarsQueue ( vmdRoomVars, true );
			
			var vmdUserVars:Vector.<MessageData> = new <MessageData> [
				new MessageData ( 'appv', _sAppVersion ),
				new MessageData ( 'ccfga', userState.cameraAdjustForMotion ),
				new MessageData ( 'fle', _bLightEnabled ),
				new MessageData ( 'mdc', _declinationUtil.declination ),
				new MessageData ( 'pbte', _bBatterySupport ),
				new MessageData ( 'pbtn', userState.phoneBatteryMin ),
				new MessageData ( 'pbt', _nBatteryPct ),
				new MessageData ( 'gps', _gps, true ),
				new MessageData ( 'pic', userState.pilotInsetConfig, true ),
				new MessageData ( 'pmc', userState.pilotMediaConfig, true ),
				new MessageData ( 'remex', osAllowsExit ),
				new MessageData ( 'ric', userState.robotInsetConfig, true ),
				new MessageData ( 'rmc', userState.robotMediaConfig, true ),
				new MessageData ( 'mcld', userState.motorCurrentLimitDefault ),
				new MessageData ( 'mcl', userState.motorCurrentLimitStep ),
				new MessageData ( 'stt', userState.steeringTrim ),
				new MessageData ( 'sleep', _bSleep ),
				new MessageData ( 'cus', _custCmdMgr, true ),
				new MessageData ( 'wdge', testCfgWatchDogsAllow ),
				new MessageData ( 'spde', ( _oEepromById.sne as McuEeprom ).value as Boolean )
			];
			var uLen:uint = vmdUserVars.length;
			var i_eep:McuEeprom;
			var i_sId:String;
			var i_ccc:CustomCommandConfig;
			var iLim:int = _custCmdMgr.commandConfigsCount;
			if ( iLim > 0 )
			{
				// add current custom values
				var vCccs:Vector.<CustomCommandConfig> = _custCmdMgr.commandConfigs;
				var i:int;
				for ( i=0; i<iLim; i++ )
				{
					i_ccc = vCccs [ i ];
					vmdUserVars [ uLen++ ] = new MessageData ( 'cu' + i_ccc.id, i_ccc, true );
				}
			}
			
			for ( i_sId in _oEepromById )
			{
				i_eep = _oEepromById [ i_sId ] as McuEeprom;
				if ( i_eep.reportable )
				{
					vmdUserVars [ uLen++ ] = new MessageData ( i_sId, i_eep.value );
				}
			}
			
			if ( batteryCleanEnabled )
			{
				vmdUserVars [ uLen++ ] = new MessageData ( 'cbt', batteryCleanPct );
			}
			
			if ( batteryDirtyEnabled )
			{
				vmdUserVars [ uLen++ ] = new MessageData ( 'dbt', batteryDirtyPct );
			}
			
			if ( _wpsMgr.enabled )
			{
				vmdUserVars [ uLen++ ] = _wpsMgr.getActiveMessage ( );
				vmdUserVars [ uLen++ ] = _wpsMgr.getListMessage ( );
			}
			
			if ( _bPanEnabled )
			{
				vmdUserVars [ uLen++ ] = new MessageData ( 'cp', _iPanHome + _iPanNet );
			}
			
			if ( _bTiltEnabled )
			{
				vmdUserVars [ uLen++ ] = new MessageData ( 'ct', _iTiltHome + _iTiltNet );
			}
			
			pilotConnector.userVarsQueue ( vmdUserVars );
		}
		
		private function _BatteryActivate ( ) : void
		{
			if ( !_bBatterySupport )
				return;
			
			if ( !testCfgBatteryAllow )
				return;
			
			if ( _batteryUtil.isRegistered )
				return;
				
			_batteryUtil.service.addEventListener ( BatteryEvent.BATTERY_INFO, _BatteryUpdated );
			if ( osIsIOS )
			{
				_tmrBattery = new Timer ( BATTERY_CHECK_MSECS, 0 );
				_tmrBattery.addEventListener ( TimerEvent.TIMER, _BatteryCheckIOS );
				_tmrBattery.start ( );
			}
			_batteryUtil.register();
		}
		
		private function _BatteryCheckIOS ( event:TimerEvent = null ) : void
		{
			_batteryUtil.check ( );
		}
		
		private function _BatteryDeactivate ( exiting:Boolean = false ) : void
		{
			if ( !_bBatterySupport )
				return;
			
			if ( _batteryUtil.isRegistered )
			{
				_batteryUtil.service.removeEventListener ( BatteryEvent.BATTERY_INFO, _BatteryUpdated );
				_batteryUtil.unregister ( );
				if ( osIsIOS )
				{
					if ( _tmrBattery )
					{
						_tmrBattery.stop ( );
						_tmrBattery.removeEventListener ( TimerEvent.TIMER, _BatteryCheckIOS );
						_tmrBattery = null;
					}
				}
			}
			
			if ( exiting )
			{
				_batteryUtil.dismiss ( );
				_batteryUtil = null;
				BatteryUtil.InstanceDispose ( );
			}
		}
		
		private function _BatteryUpdated ( event:BatteryEvent ) : void
		{
			var nBatRaw:Number = event.batteryLevel;
			// debugOut ( "Battery event raw level: " + nBatRaw ); // TESTING
			
			if ( nBatRaw <= 1 )
			{
				nBatRaw *= 100;
			}
			
			if ( nBatRaw == _nBatteryPct )
			{
				return;
			}
			
			_nBatteryPct = nBatRaw;
			
			if ( FlagsUtil.IsSet ( _uEmFlags, EmergencyFlags.BATTERY ) )
			{
				if ( _nBatteryPct >= userState.phoneBatteryMin )
				{
					emergencyFlagsClear ( EmergencyFlags.BATTERY );
				}
			}
			else
			{
				if ( _nBatteryPct < userState.phoneBatteryMin )
				{
					emergencyFlagsSet ( EmergencyFlags.BATTERY );
					_callLater ( _SystemsDeactivate );
				}
			}
			if ( !_bSleep )
			{
				pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'pbt', _nBatteryPct ) ] );
			}
		}
		
		private function _BleConfigEvent ( event:BleEvent ) : void
		{
			// for now only using this event type for requesting opening of bluetooth le config,
			// so no need to check params
			bleConfigOpen ( );
		}
		
		private function _BlePrConnected ( event:BleEvent ) : void
		{
			
		}
		
		private function _BlePrDisconnected ( event:BleEvent ) : void
		{
			
		}
		
		private function _BluetoothConfigEvent ( event:UtilityEvent ) : void
		{
			// for now only using this event type for requesting opening of bluetooth config,
			// so no need to check params
			bluetoothConfigOpen ( );
		}
		
		private function _BluetoothConnected ( event:UtilityEvent ) : void
		{
			userState.bluetoothAddress = event.params as String;
		}
		
		private function _CamMgrEnabledChanged ( value:Boolean ) : void
		{
			_CamMgrEnabledUpdate ( value, orientedPortrait );
		}
		
		private function _CamMgrEnabledUpdate ( isEnabled:Boolean, isPortrait:Boolean ) : void
		{
			if ( isEnabled )
			{
				if ( isPortrait )
				{
					camMgrEnabledLandscape = false;
					camMgrEnabledPortrait = true;
				}
				else
				{
					camMgrEnabledLandscape = true;
					camMgrEnabledPortrait = false;
				}
			}
			else
			{
				camMgrEnabledLandscape = false;
				camMgrEnabledPortrait = false;
			}
		}
		
		private function _CustomConfigValidate ( ) : void
		{
			if ( _custCmdMgr.validate ( ) )
			{
				// configuration okay
				statusSetResource ( 'status_custom_valid' );
				pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'cus', _custCmdMgr, true ) ] );
			}
			else
			{
				// return to configuration
				customConfigOpen ( );
			}
		}
		
		private function _CustomInit ( ) : void
		{
			// first request for instance will
			// initialize singleton and restore
			// custom command config data from dat file, if exists
			_custCmdMgr = CustomCommandManager.instance;
			
			_callLater ( _McuConnectConfigure );
		}
		
		private function _DeclinationUpdated ( event:UtilityEvent ) : void
		{
			var nDec:Number = event.params.declination;
			var vmdToSend:Vector.<MessageData> = new <MessageData> [ new MessageData ( 'mdc', nDec ) ];
			pilotConnector.userVarsQueue ( vmdToSend );
			_DeviceBasisUpdate ( );
		}
		
		// returns value between -180 and 180
		private function _DegreesRangeValidate ( value:Number ) : Number
		{
			var nVal:Number = value;
			if ( nVal > 180 )
			{
				do
					nVal -= 360;
				while ( nVal > 180 );
			}
			else if ( nVal < -180 )
			{
				do
					nVal += 360;
				while ( nVal < -180 );
			}
			return nVal;
		}
		
		private function _DeviceBasisUpdate ( ) : void
		{
			var nDegZ:Number = -_declinationUtil.declination;
			if ( _bPanDeviceEnabled )
			{
				nDegZ += _iPanNet;
			}
			var nDegX:Number = 90;
			var nRadZ:Number = nDegZ * MathConsts.DEGREES_TO_RADIANS;
			if ( _bDevFaceBack )
			{
				nDegX -= _iDevMountAngle;
				_bLightEnabled = lightExternal;
				if ( _bTiltDeviceEnabled )
				{
					nDegX += _iTiltNet;
				}
			}
			else
			{
				nDegX += _iDevMountAngle;
				nRadZ += Math.PI;
				_bLightEnabled = true;
				if ( _bTiltDeviceEnabled )
				{
					nDegX -= _iTiltNet;
				}
			}
			var nRadX:Number = nDegX * MathConsts.DEGREES_TO_RADIANS;
			var qZ:Quaternion = new Quaternion ( );
			qZ.fromEulerAngles ( 0, 0, nRadZ );
			var qX:Quaternion = new Quaternion ( );
			qX.fromEulerAngles ( nRadX, 0, 0 );
			_qBasis = new Quaternion ( );
			_qBasis.multiply ( qX, qZ );
		}
		
		private function _DeviceMotionActivate ( ) : void
		{
			if ( !_bDevMotionSupport )
				return;
			
			if ( !testCfgDevOrientAllow )
				return;
			
			var devMo:DeviceMotionUtil = DeviceMotionUtil.instance;
			if ( devMo.isRegistered )
				return;
			
			devMo.service.addEventListener ( DeviceMotionEvent.UPDATE_QUATERNION, _DeviceMotionQuaternionUpdated );
			devMo.register ( );
		}
		
		private function _DeviceMotionDeactivate ( ) : void
		{
			if ( !_bDevMotionSupport )
				return;
			
			var devMo:DeviceMotionUtil = DeviceMotionUtil.instance;
			if ( !devMo.isRegistered )
				return;
			
			devMo.unregister();
			devMo.service.removeEventListener ( DeviceMotionEvent.UPDATE_QUATERNION, _DeviceMotionQuaternionUpdated );
		}
		
		private function _DeviceMotionQuaternionUpdated ( event:DeviceMotionEvent ) : void
		{
			var nTime:Number = new Date().getTime();
			if ( nTime < _nQuatNextTime )
			{
				return;
			}
			_nQuatNextTime = nTime + _nQuatMsec;
			
			var aVals:Array = event.values;
			var qaOut:QuaternionArx = new QuaternionArx ( );
			var qDev:Quaternion = new Quaternion ( aVals [ 1 ], aVals [ 2 ], aVals [ 3 ], aVals [ 0 ] );
			qaOut.quaternion.multiply ( qDev, _qBasis );
			_fMcuHdgUpdate ( qaOut, nTime );
			pilotConnector.userVarsQueue ( new <MessageData> [
				new MessageData ( 'oq', qaOut, true )
			] );
		}
		
		private function _EepromCheckVersion ( ) : void
		{
			// get current capabilities schema version
			var i_eep:McuEeprom = _oEepromById [ 'eepv' ] as McuEeprom;
			if ( userState.capabilitiesStorePhone )
			{
				// values stored on phone
				var oStore:Object = _EepromsPhoneRestore ( );
				var bNew:Boolean = true;
				var i_sId:String;
				var i_val:*;
				var i:int;
				var iLim:int;
				if ( oStore != null )
				{
					if  ( 'eepv' in oStore )
					{
						i_val = oStore [ 'eepv' ];
						if ( i_val == i_eep.value )
						{
							// EEPROM schema is current
							bNew = false;
						}
						_vEepromIdsToCheck.removeAt ( _vEepromIdsToCheck.indexOf ( 'eepv' ) );
						iLim = _vEepromIdsToCheck.length;
						for ( i=0; i<iLim; i++ )
						{
							i_sId = _vEepromIdsToCheck.pop ( );
							if ( i_sId in oStore )
							{
								i_eep = _oEepromById [ i_sId ] as McuEeprom;
								i_eep.restoreValue ( oStore [ i_sId ] );
							}
						}
					}
				}
				_EepromConfigCaptionsSet ( bNew );
				_callLater ( _EepromConfigWrite );
			}
			else
			{
				// stored on Mcu
				if ( _bMcuConnected )
				{
					// try to read them now
					if ( mcuSendCommandByteArray ( i_eep.messageBytesForRead ) )
					{
						_EepromReadTimerReset ( );
						statusSetResource ( 'status_eeprom_read' );
					}
					else
					{
						_EepromReadTimedOut ( );
					}
				}
				else
				{
					// wait until get a connected event
					_bEepromsNeeded = true;
				}
			}
		}
		
		private function _EepromConfigCaptionsSet ( isNew:Boolean ) : void
		{
			// Display appropriate captions, depending upon whether or not we already have
			// stored capabilities configuration data compatible with the current schema.
			// If this is a new installation or an update with new schema version,
			// user will need to configure from scratch.  Otherwise their previous choices
			// will still be in force.
			if ( isNew )
			{
				eepromConfigCaptRsrc = 'eeprom_config_new_title';
				eepromWriteCaptRsrc = 'status_eeprom_write_new';
			}
			else
			{
				eepromConfigCaptRsrc = 'eeprom_config_title';
				eepromWriteCaptRsrc = 'status_eeprom_write';
			}
		}
		
		private function _EepromConfigWrite ( ) : void
		{
			_EepromsProcess ( );
			
			if ( _bEepromReadFail )
			{
				// no point in attempting to write if could not read
				_EepromsWriteDone ( );
				return;
			}
			
			// add to the queue any eeprom items that have changed values and are not already in the list
			var i_sId:String;
			var i_eep:McuEeprom;
			var uLen:uint = _vEepromIdsToCheck.length;
			for ( i_sId in _oEepromById )
			{
				i_eep = _oEepromById [ i_sId ] as McuEeprom;
				if ( i_eep.changed && _vEepromIdsToCheck.indexOf ( i_sId ) < 0 )
				{
					_vEepromIdsToCheck [ uLen++ ] = i_sId;
				}
			}
			if ( uLen < 1 )
			{
				_EepromsWriteDone ( );
			}
			else
			{
				// have something to write
				if ( userState.capabilitiesStorePhone )
				{
					_callLater ( _EepromsPhonePersist );
				}
				else
				{
					_callLater ( _EepromsWriteBegin ); 
				}
			}
		}
		
		private function _EepromReadTimedOut ( event:TimerEvent = null ) : void
		{
			_bEepromReadFail = true;
			var sStat:String = _resourceManager.getString ( 'default', 'error_eeprom_read' );
			statusSet ( sStat );
			_debugOut ( sStat );
			// use defaults for now, but set captions for later
			_EepromConfigCaptionsSet ( true );
			_EepromConfigWrite ( );
		}
		
		private function _EepromReadTimerReset ( ) : void
		{
			_tmrEepromReadWait.reset ( );
			_tmrEepromReadWait.start ( );
		}
		
		private function _EepromReadTimerStop ( ) : void
		{
			_tmrEepromReadWait.stop ( );
		}
		
		private function _EepromsPhonePersist ( ) : void
		{
			var oStore:Object = {};
			for ( var i_sId:String in _oEepromById )
			{
				oStore [ i_sId ] = ( _oEepromById [ i_sId ] as McuEeprom ).value;
			}
			
			try
			{
				var ba:ByteArray = new ByteArray ( );
				ba.writeObject ( oStore );
				
				var f:File = _dirSets.resolvePath ( 'Caps.dat' );
				if ( f.exists ) f.deleteFile ( );
				
				var fs:FileStream = new FileStream();
				// open
				fs.open ( f, FileMode.WRITE );
				// write
				fs.writeBytes ( ba );
				// close
				fs.close();
				
				var fBkp:File = _dirSetsBkp.resolvePath ( 'Caps.dat' );
				f.copyTo ( fBkp, true );
			}
			catch ( err:Error )
			{
				_debugOut ( err.message );
			}
			_EepromsWriteDone ( );
		}
		
		private function _EepromsPhoneRestore ( ) : Object
		{
			var oStore:Object;
			
			var f:File = _dirSets.resolvePath ( 'Caps.dat' );
			if ( !f.exists )
				return oStore; // not yet saved locally
			
			var fs:FileStream = new FileStream();
			// open
			fs.open ( f, FileMode.READ );
			// read
			var ba:ByteArray = new ByteArray();
			fs.readBytes ( ba );
			// close
			fs.close();
			
			try
			{
				oStore = ba.readObject ( );
			}
			catch ( err:Error )
			{
				_debugOut ( err.message );
				return oStore;
			}
			
			// if no backup copy, create one
			var fBkp:File = _dirSetsBkp.resolvePath ( 'Caps.dat' );
			if ( !fBkp.exists )
			{
				f.copyTo ( fBkp, true );
			}
			
			return oStore;
		}
		
		private function _EepromsProcess ( ) : void
		{
			// start with defaults
			_bPanEnabled = false;
			_bTiltEnabled = false;
			_bPanOrTiltEnabled = false;
			_bPanDeviceEnabled = false;
			_bTiltDeviceEnabled = false;
			_bPanOrTiltDeviceEnabled = false;
			_iDevMountAngle = 0;
			_iPanHome = 0;
			_iPanNet = 0;
			_iPanReset = 0;
			_iTiltHome = 0;
			_iTiltNet = 0;
			_iTiltReset = 0;
			_wpsMgr.enabled = false;
			_nNavGpsMsec = NAV_GPS_MSEC_DEFAULT;
			_nNavHdgMsec = NAV_HDG_MSEC_DEFAULT;
			_fMcuGpsUpdate = _NoOp;
			_fMcuHdgUpdate = _NoOp;
			var uMode:uint = CoordinatesMessage.COORDS_MODE_DOUBLE;
			try
			{
				_bDevFaceBack = ( _oEepromById.dfb as McuEeprom ).value;
				_iDevMountAngle = ( _oEepromById.dma as McuEeprom ).value;
				
				_bPanEnabled = ( _oEepromById.ccp as McuEeprom ).value;
				if ( _bPanEnabled )
				{
					_bPanOrTiltEnabled = true;
					_iPanHome = ( _oEepromById.ccph as McuEeprom ).value;
					_iPanReset = ( _oEepromById.ccpr as McuEeprom ).value;
				}
				
				_bTiltEnabled = ( _oEepromById.cct as McuEeprom ).value;
				if ( _bTiltEnabled )
				{
					_bPanOrTiltEnabled = true;
					_iTiltHome = ( _oEepromById.ccth as McuEeprom ).value;
					_iTiltReset = ( _oEepromById.cctr as McuEeprom ).value;
				}
				
				_bPanDeviceEnabled = ( _bPanEnabled && ( _oEepromById.ccpd as McuEeprom ).value );
				
				_bTiltDeviceEnabled = ( _bTiltEnabled && ( _oEepromById.cctd as McuEeprom ).value );
				
				_bPanOrTiltDeviceEnabled = ( _bPanDeviceEnabled || _bTiltDeviceEnabled );
				
				motionEnabled = ( _oEepromById.mve as McuEeprom ).value;
				// default testCfgWatchDogsAllow to match setting of motionEnabled
				testCfgWatchDogsAllow = motionEnabled;
				
				_wpsMgr.enabled = ( _oEepromById.wpe as McuEeprom ).value;
				if ( _wpsMgr.enabled )
				{
					
					if ( ( _oEepromById.wpf as McuEeprom ).value )
					{
						// float
						if ( ( _oEepromById.wpf32 as McuEeprom ).value )
						{
							// 32-bit
							uMode = CoordinatesMessage.COORDS_MODE_FLOAT;
						}
						else
						{
							// 64-bit
							uMode = CoordinatesMessage.COORDS_MODE_DOUBLE;
						}
					}
					else
					{
						// integer --> see reference:
						// http://sloblog.io/~pdc/kbGgQRBcYsk/latitude-and-longitude-in-32-bits
						uMode = CoordinatesMessage.COORDS_MODE_INTEGER;
					}
					CoordinatesMessage.SetCoordsDataMode ( uMode );
					_currentCoords = CurrentCoordinates.NewFromParameters ( );
					_nNavGpsMsec = ( _oEepromById.wpgi as McuEeprom ).value;
					_nNavHdgMsec = ( _oEepromById.wphi as McuEeprom ).value;
					_fMcuGpsUpdate = _McuGpsUpdate;
					_fMcuHdgUpdate = _McuHeadingUpdate;
				}
				MoveProps.SetPolarityCorrections ( ( _oEepromById.mlp as McuEeprom ).value, ( _oEepromById.mrp as McuEeprom ).value, false );
				MoveProps.SettingsApply ( );
				_iRangerMinL = ( _oEepromById.usln as McuEeprom ).value;
				_iRangerMinR = ( _oEepromById.usrn as McuEeprom ).value;
				lightExternal = ( _oEepromById.hle as McuEeprom ).value;
				batteryCleanEnabled = ( _oEepromById.cbte as McuEeprom ).value;
				batteryCleanMinSafe = ( _oEepromById.cbtn as McuEeprom ).value;
				batteryDirtyEnabled = ( _oEepromById.dbte as McuEeprom ).value;
				batteryDirtyMinSafe = ( _oEepromById.dbtn as McuEeprom ).value;
				if ( batteryCleanEnabled && batteryDirtyEnabled )
				{
					// will receive telemetry for separate batteries, so use specific icons and status messages
					// batteryCleanIcon = IconBatteryClean;
					// batteryDirtyIcon = IconBatteryDirty;
					batteryCleanRsrc = 'status_batt_clean_';
					// batteryDirtyRsrc = 'status_batt_dirty_';
				}
				else
				{
					// will get telemetry for one at most, so use generic robot battery icon and messages
					// batteryCleanIcon = IconBattery;
					// batteryDirtyIcon = IconBattery;
					batteryCleanRsrc = 'status_batt_';
					// batteryDirtyRsrc = 'status_batt_';
				}
				_DeviceBasisUpdate ( );
		}
		catch ( err:Error )
			{
				var sStat:String = _resourceManager.getString ( 'default', 'error_eeprom_item_nf', [ err.message ] );
				_debugOut ( sStat );
				statusSet ( sStat );
			}
		}
		
		private function _EepromsRead ( ) : void
		{
			if ( _vEepromIdsToCheck.length < 1 )
			{
				_EepromReadTimerStop ( );
				_EepromConfigCaptionsSet ( false );
				_EepromConfigWrite ( );
				return;
			}
			
			var eep:McuEeprom = _oEepromById [ _vEepromIdsToCheck [ 0 ] ] as McuEeprom;
			if ( mcuSendCommandByteArray ( eep.messageBytesForRead ) )
			{
				_EepromReadTimerReset ( );
			}
			else
			{
				_EepromReadTimedOut ( );
			}
		}
		
		private function _EepromsWrite ( event:TimerEvent = null ) : void
		{
			if ( _vEepromIdsToCheck.length < 1 )
			{
				_EepromsWriteDone ( );
				return;
			}
			
			var eep:McuEeprom = _oEepromById [ _vEepromIdsToCheck.pop ( ) ] as McuEeprom;
			var uLen:uint = eep.byteCount;
			var nMsecs:Number = EEPROM_WRITE_INTERVAL * uLen;
			_tmrEepromWrite.delay = nMsecs;
			// ##### TESTING #####
			_debugOut ( 'allowing ' + nMsecs + ' msecs to write ' + uLen + ' bytes to EEPROM at ' + eep.addressHex );
			// ###################
			mcuSendCommandByteArray ( eep.messageBytesForWrite );
		}
		
		private function _EepromsWriteBegin ( ) : void
		{
			statusSetResource ( eepromWriteCaptRsrc );
			_tmrEepromWrite.start ( );
		}
		
		private function _EepromsWriteDone ( ) : void
		{
			statusClear ( );
			_tmrEepromWrite.stop ( );
			if ( _uOpMode == OpModes.NA )
			{
				_callLater ( opModeInit );
			}
			else if ( _uOpMode == OpModes.CS )
			{
				batchVarsReportQueue ( );
			}
		}
		
		private function _EmergencyStateUpdate ( ) : void
		{
			// update user variable
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'ems', _uEmFlags ) ] );
			// If all clear, resume normal activity.
			// Mcu will prevent forward motion if ultrasonic range is too small?
			// _MoveIgnoreSet ( _uEmFlags != 0 && _uEmFlags != EmergencyFlags.OBSTACLE );
		}
		
		private function _ExitQueryResponse ( commit:Boolean, data:DialogData ) : void
		{
			if ( data.responseIndex == 0 )
			{
				exitConfirmed ( );
			}
		}
		
		private function _ExitStepExit ( ) : void
		{
			// this does not work on iOS
			NativeApplication.nativeApplication.exit ( );
		}
		
		private function _ExpertModeSet ( value:Boolean ) : void
		{
			expertModeOn = value;
			if ( expertModeOn )
			{
				actionMenuBtnStyleName = 'actionMenuExpert';
				actionMenuBgColor = 0x663214; // 0xcc6600
			}
			else
			{
				actionMenuBtnStyleName = 'actionMenu';
				actionMenuBgColor = 0x294a66; // 0x0066cc
				debugVisible = false;
			}
			userState.expertOn = expertModeOn;
		}
		
		private function _GeoActivate ( ) : void
		{
			if ( !_bGeoSupport )
				return;
			
			// NOTE: Flex is not able to detect if the location is coming from
			// the wifi, network, or the GPS. We would need an ANE to
			// detect if it is specifically the GPS that is turned on.
			
			if ( !testCfgGeoAllow )
				return;
			
			if ( _geo )
			{
				// already active
				return;
			}
			
			var sPermStatus:String = Geolocation.permissionStatus;
			if ( sPermStatus == PermissionStatus.GRANTED || sPermStatus == PermissionStatus.ONLY_WHEN_IN_USE )
			{
				try
				{
					_geo = new Geolocation();
					_geo.addEventListener ( GeolocationEvent.UPDATE, _GeolocationUpdated );
					_geo.setRequestedUpdateInterval ( 5000 );
				}
				catch ( err:Error )
				{
					_geo = null;
					_debugOut ( 'error_geo_init', true, [ err.message ] );
				}
			}
			
			if ( !_geo )
				return;
			
			// if get here, geo is okay
			
			// Magnetic Declination
			if ( !testCfgMagDecAllow )
				return;
			
			if ( !_declinationUtil.active )
			{
				_declinationUtil.addEventListener ( UtilityEvent.DECLINATION, _DeclinationUpdated );
				_declinationUtil.start ( );
			}
		}
		
		private function _GeoDeactivate ( ) : void
		{
			if ( !_bGeoSupport )
				return;
			
			if ( _geo )
			{
				_geo.removeEventListener ( GeolocationEvent.UPDATE, _GeolocationUpdated );
				_geo = null;
			}
			
			if ( _declinationUtil.active )
			{
				_declinationUtil.removeEventListener ( UtilityEvent.DECLINATION, _DeclinationUpdated );
				_declinationUtil.stop ( );
			}
		}
		
		private function _GeolocationUpdated ( event:GeolocationEvent ) : void
		{
			var bChange:Boolean = false;
			var nDif:Number = event.latitude - _gps.lat;
			if ( nDif < _nGpsDifNeg || nDif > _nGpsDifPos )
			{
				bChange = true;
				_gps.lat = event.latitude
			}
			nDif = event.longitude - _gps.lng;
			if ( nDif < _nGpsDifNeg || nDif > _nGpsDifPos )
			{
				bChange = true;
				_gps.lng = event.longitude;
			}
			_gps.accuracy = event.horizontalAccuracy;
			/*
			if ( event.horizontalAccuracy != _gps.accuracy )
			{
			bChange = true;
			_gps.accuracy = event.horizontalAccuracy;
			}
			if ( event.speed != _gps.speed )
			{
			bChange = true;
			_gps.speed = event.speed;
			}
			*/
			if ( bChange )
			{
				_declinationUtil.setCoordinates ( event.latitude, event.longitude );
				_fMcuGpsUpdate ( event.latitude, event.longitude );
				var vmdGps:Vector.<MessageData> = new <MessageData> [ new MessageData ( 'gps', _gps, true ) ];
				pilotConnector.userVarsQueue ( vmdGps );
				_fGpsRoomVarUpdate ( vmdGps );
			}
		}
		
		private function _GpsRoomVarUpdate ( vmdGps:Vector.<MessageData> ) : void
		{
			pilotConnector.roomVarsQueue ( vmdGps );
		}
		
		private function _KeyDown ( event:KeyboardEvent ) : void
		{
			if ( event.keyCode == Keyboard.BACK )
			{
				event.preventDefault ( );
				event.stopImmediatePropagation ( );
				// debugOut ( 'KeyDown BACK' );
			}
			else if ( event.keyCode == Keyboard.MENU )
			{
				// debugOut ( 'KeyDown MENU' );
			}
		}
		
		private function _KeyUp ( event:KeyboardEvent ) : void
		{
			
			if ( event.keyCode == Keyboard.BACK )
			{
				event.preventDefault ( );
				event.stopImmediatePropagation ( );
				_callLater ( backButton );
				// debugOut ( 'KeyUp BACK' );
			}
			else if ( event.keyCode == Keyboard.MENU )
			{
				_callLater ( actionMenuToggle );
				// debugOut ( 'KeyUp MENU' );
			}
		}
		
		private function _LocalEepromConfigLoad ( ) : void
		{
			var f:File = File.applicationDirectory.resolvePath ( 'config/eeprom.json' );
			var sStat:String;
			if ( !f.exists )
			{
				sStat = _resourceManager.getString ( 'default', 'error_eeprom_cfg' );
				_debugOut ( sStat );
				statusSet ( sStat );
				return; // return
			}
			
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
				
				// var sTest:String = '';
				var i_ae:McuEeprom;
				var i_oVal:Object;
				var i_sGrpId:String;
				var i_sId:String;
				var i_uAddr:uint;
				var aEeps:Array = [];
				var uEepsLen:uint = 0;
				// accumulate group IDs so can add group header items to config display
				var vGrpIds:Vector.<String> = new <String> [];
				var uGrpIdsLen:uint = 0;
				var uIdsCheckLen:uint = _vEepromIdsToCheck.length;
				for ( i_sId in oJson )
				{
					i_oVal = oJson [ i_sId ];
					i_ae = McuEeprom.NewFromJson ( i_sId, i_oVal );
					i_uAddr = i_ae.address;
					i_sGrpId = i_ae.groupId;
					_aEepromByAddr [ i_uAddr ] = i_ae;
					if ( vGrpIds.indexOf ( i_sGrpId ) < 0 )
					{
						// first encounter with this group ID
						vGrpIds [ uGrpIdsLen++ ] = i_sGrpId;
						aEeps [ uEepsLen++ ] = new McuEeprom ( 0, 0, i_sGrpId, 'group', null, false, i_sGrpId );
					}
					aEeps [ uEepsLen++ ] = i_ae;
					_vEepromIdsToCheck [ uIdsCheckLen++ ] = i_sId;
					_oEepromById [ i_sId ] = i_ae;
					// sTest += i_sId + '  addr: ' + i_ae.address + ',  bytes: ' + i_ae.byteCount + ',  value: ' + i_ae.value + ',  desc: ' + resourceManager.getString('default',i_ae.resource) + '\n';
				}
			}
			catch ( err:Error )
			{
				sStat = _resourceManager.getString ( 'default', 'error_eeprom_cfg_load', [ err.message ] );
				_debugOut ( sStat );
				statusSet ( sStat );
				return; // return
			}
			
			aEeps.sortOn ( [ 'groupId', 'address' ], [ Array.CASEINSENSITIVE, Array.NUMERIC ] );
			_vEeproms = Vector.<McuEeprom> ( aEeps );
			// debugOut ( sTest, false, null, false, '' );
			_callLater ( _EepromCheckVersion );
		}
		
		private function _LocalFilesInitialize ( ) : void
		{
			// storage directory
			_dirSets = File.applicationStorageDirectory.resolvePath ( 'settings' );
			_dirSets.createDirectory ( ); // no effect if already exists
			if ( osIsIOS )
			{
				_dirSetsBkp = File.documentsDirectory.resolvePath ( 'settings' );
			}
			else
			{
				_dirSetsBkp = File.userDirectory.resolvePath ( 'ArxRobotBkp/settings' );
			}
			_dirSetsBkp.createDirectory ( ); // no effect if already exists
			
			// get settings from previous session, if exist
			if ( !_UserStateRestore ( ) )
			{
				// first run
				_bFirstRun = true;
				userState = new UserState ( false );
			}
			if ( !userState.pilotInsetConfig )
			{
				userState.pilotInsetConfig = new InsetConfig ( );
			}
			if ( !userState.pilotMediaConfig )
			{
				userState.pilotMediaConfig = new MediaConfig ( );
			}
			if ( !userState.robotInsetConfig )
			{
				userState.robotInsetConfig = new InsetConfig ( );
			}
			if ( !userState.robotMediaConfig )
			{
				userState.robotMediaConfig = new MediaConfig ( );
			}
			
			permissionsChecker.userStateInit ( userState );
			_camMgr.userStateInit ( userState );
			_motMgr.userStateInit ( userState );
			
			userState.addEventListener ( UserState.USER_STATE_CHANGE, _UserStatePersist );
			userState.addEventListener ( UserState.PILOT_INSET_CONFIG_CHANGE, _PilotInsetConfigChange );
			userState.addEventListener ( UserState.PILOT_MEDIA_CONFIG_CHANGE, _PilotMediaConfigChange );
			userState.addEventListener ( UserState.ROBOT_INSET_CONFIG_CHANGE, _RobotInsetConfigChange );
			userState.addEventListener ( UserState.ROBOT_MEDIA_CONFIG_CHANGE, _RobotMediaConfigChange );
			
			MoveProps.SetSteeringTrim ( userState.steeringTrim, false );
			_ExpertModeSet ( userState.expertOn );
		}
		
		private function _McuConnectConfigure ( ) : void
		{
			
			// configure for device if this is first call
			if ( !McuConnectModes.IsConfigured )
			{
				var aMsgs:Array = McuConnectModes.ConfigureForDevice ( osIsAndroid );
				if ( aMsgs.length > 0 )
				{
					for each ( var i_aMsg:Array in aMsgs )
					{
						_debugOut ( i_aMsg [ 0 ], i_aMsg [ 1 ], i_aMsg [ 2 ] );
					}
				}
			}
			
			
			// first deal with existing connection, if any,
			// and check current op mode compatibility
			// with new Mcu mode
			if ( mcuConnector )
			{
				if ( mcuConnector.mode == userState.mcuConnectModeId )
				{
					// not changing, so we're done here, except to make sure has latest watchdog mode
					mcuConnector.watchdogModeApply ( );
					return;
				}
				
				// if we were in RC op mode
				// and will no longer be using a wireless mcu connection,
				// get out of RC mode
				if ( !_OpModeIsAvailable ( _uOpMode ) )
				{
					opModeSelected ( OpModes.NA );
				}
				// dismiss old connector
				_McuConnectorDismiss ( );
			}
			userState.mcuConnectModeId = McuConnectModes.ValidateMode ( userState.mcuConnectModeId );
			var bBle:Boolean = false;
			var bBlue:Boolean = false;
			switch ( userState.mcuConnectModeId )
			{
				case McuConnectModes.BLE:
				{
					// Bluetooth LE
					mcuConnector = McuConnectorBLE.instance;
					bBle = true;
					break;
				}
				case McuConnectModes.BLUETOOTH:
				{
					
					// Bluetooth
					mcuConnector = McuConnectorBluetooth.instance;
					mcuBluetooth = McuConnectorBluetooth.instance;
					mcuBluetooth.addEventListener ( UtilityEvent.BLUETOOTH_CONFIG, _BluetoothConfigEvent );
					mcuBluetooth.addEventListener ( UtilityEvent.BLUETOOTH_CONNECTED, _BluetoothConnected );
					mcuBluetooth.setAutoConnectionAddress ( userState.bluetoothAddress, _bFirstRun );
					bBlue = true;
					break;
				}
				case McuConnectModes.USB_ADB:
				{
					// USB adb
					// instantiate server socket to communicate with Mcu
					mcuConnector = McuConnectorSocket.instance;
					break;
				}
					/*
				case McuConnectModes.USB_HOST:
				{
					// USB Android as host
					// instantiate Primavera ANE to communicate with Mcu
					mcuConnector = McuConnectorPrimavera.instance;
					break;
				}
					*/
				default:
				{
					// NA
					mcuConnector = McuConnectorNone.instance;
					break;
				}
			}
			mcuConnector.addEventListener ( TelemetryEvent.PACKET_PAYLOADS, _McuDataReceived );
			mcuConnector.addEventListener ( UtilityEvent.MCU_CONNECTED, _McuConnected );
			mcuConnector.addEventListener ( UtilityEvent.MCU_DISCONNECTED, _McuDisconnected );
			
			bleSelected = bBle;
			bluetoothSelected = bBlue;
			
			statusSetResource ( 'status_eeprom_read', true );
			_callLater ( _LocalEepromConfigLoad );
		}
		
		private function _McuConnected ( event:UtilityEvent ) : void
		{
			_McuConnectedSet ( true );
		}
		
		private function _McuConnectorDismiss ( ) : void
		{
			if ( mcuConnector )
			{
				if ( mcuConnector.isBluetooth )
				{
					bluetoothSelected = false;
					mcuBluetooth.removeEventListener ( UtilityEvent.BLUETOOTH_CONFIG, _BluetoothConfigEvent );
					mcuBluetooth.removeEventListener ( UtilityEvent.BLUETOOTH_CONNECTED, _BluetoothConnected );
					mcuBluetooth = null;
				}
				mcuConnector.removeEventListener ( TelemetryEvent.PACKET_PAYLOADS, _McuDataReceived );
				mcuConnector.removeEventListener ( UtilityEvent.MCU_CONNECTED, _McuConnected );
				mcuConnector.removeEventListener ( UtilityEvent.MCU_DISCONNECTED, _McuDisconnected );
				mcuConnector.dismiss ( );
				mcuConnector = null;
				
				bleSelected = false;
				bluetoothSelected = false;
			}
		}
		
		private function _McuDataReceived ( event:TelemetryEvent ) : void
		{
			var vbaIn:Vector.<ByteArray> = event.payloads;
			
			// we're getting something, so evidently the Mcu is connected
			_McuConnectedSet ( true );
			
			// NOTE: ByteArray automatically changes its position property to the index immediately after the latest read or write operation.
			//       The bytesAvailable property contains the number of bytes left between the current position and the end.
			var bytes:ByteArray;
			var bytesOut:ByteArray;
			var vmdToSend:Vector.<MessageData> = new <MessageData> [];
			var uVmdLen:uint = 0;
			var bTurretChange:Boolean = false;
			var bRangeChange:Boolean = false;
			var bValid:Boolean;
			var ccc:CustomCommandConfig;
			var iDatum:int;
			// var iLoops:int = 0;
			var nDatum:Number;
			var sDbg:String;
			var sId:String;
			var uDatum:uint;
			var uId:uint;
			var uLen:uint;
			var eep:McuEeprom;
			
			while ( vbaIn.length > 0 )
			{
				/*
				if ( ++iLoops > 50 )
				{
				debugOut ( 'Mcu data loop limit exceeded' );
				break;
				}
				*/
				bytes = vbaIn.shift ( );
				bytes.position = 0;
				uId = bytes.readUnsignedByte ( );
				switch ( uId )
				{
					case McuConnectorBase.MOTOR1_CURRENT_ID:
						// motor 1 current
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.MOTOR1_CURRENT_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedShort ( ) * 34;
							if ( uDatum != _roverData.motor1Current )
							{
								// vmdToSend [ uVmdLen++ ] = new MessageData ( 'TBD', uDatum );
								_roverData.motor1Current = uDatum;
							}
						}
						break;
					case McuConnectorBase.MOTOR2_CURRENT_ID:
						// motor 2 current
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.MOTOR2_CURRENT_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedShort ( ) * 34;
							if ( uDatum != _roverData.motor2Current )
							{
								// vmdToSend [ uVmdLen++ ] = new MessageData ( 'TBD', uDatum );
								_roverData.motor2Current = uDatum;
							}
						}
						break;
					case McuConnectorBase.TEMP_SENSOR_ID:
						// temperature
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.TEMP_SENSOR_ID, 1 ) ] );
						}
						else
						{
							iDatum = bytes.readShort ( );
							if ( iDatum != _roverData.temperature )
							{
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'btm', iDatum );
								_roverData.temperature = iDatum;
							}
						}
						break;
					case McuConnectorBase.RANGE_LEFT_ID:
						// ultrasonic ranger left
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.RANGE_LEFT_ID, 1 ) ] );
						}
						else
						{
							iDatum = bytes.readShort ( );
							if ( iDatum != _roverData.usRangeLeft )
							{
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'usl', iDatum );
								_roverData.usRangeLeft = iDatum;
								bRangeChange = true;
							}
						}
						break;
					case McuConnectorBase.RANGE_RIGHT_ID:
						// ultrasonic ranger right
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.RANGE_RIGHT_ID, 1 ) ] );
						}
						else
						{
							iDatum = bytes.readShort ( );
							if ( iDatum != _roverData.usRangeRight )
							{
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'usr', iDatum );
								_roverData.usRangeRight = iDatum;
								bRangeChange = true;
							}
						}
						break;
					case McuConnectorBase.CLEAN_BATTERY_ID:
						// electronics battery
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.CLEAN_BATTERY_ID, 1 ) ] );
						}
						else
						{
							iDatum = bytes.readShort ( );
							if ( iDatum != _roverData.cleanBat )
							{
								batteryCleanPct = iDatum;
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'cbt', iDatum );
								_roverData.cleanBat = iDatum;
							}
						}
						break;
					case McuConnectorBase.DIRTY_BATTERY_ID:
						// motor battery
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.DIRTY_BATTERY_ID, 1 ) ] );
						}
						else
						{
							iDatum = bytes.readShort ( );
							if ( iDatum != _roverData.dirtyBat )
							{
								batteryDirtyPct = iDatum;
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'dbt', iDatum );
								_roverData.dirtyBat = iDatum;	
							}
						}
						break;
					case McuConnectorBase.PAN_POSITION_ID:
						// pan
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.PAN_POSITION_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedShort ( );
							if ( uDatum != _roverData.panAngle )
							{
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'cp', uDatum );
								_roverData.panAngle = uDatum;
								// ##### TESTING #####
								// debugOut ( 'pan degrees from Mcu: ' + uDatum );
								// ###################
								if ( _bPanEnabled )
								{
									if ( _VisionPanUpdate ( uDatum ) )
									{
										bTurretChange = true;
									}
								}
							}
						}
						break;
					case McuConnectorBase.TILT_POSITION_ID:
						// tilt
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.TILT_POSITION_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedShort ( );
							if ( uDatum != _roverData.tiltAngle )
							{
								vmdToSend [ uVmdLen++ ] = new MessageData ( 'ct', uDatum );
								_roverData.tiltAngle = uDatum;
								// ##### TESTING #####
								// debugOut ( 'tilt degrees from Mcu: ' + uDatum );
								// ###################
								if ( _bTiltEnabled )
								{
									if ( _VisionTiltUpdate ( uDatum ) )
									{
										bTurretChange = true;
									}
								}
							}
						}
						break;
					case McuConnectorBase.EEPROM_RESPONSE_ID:
						// EEPROM read result
						bValid = false;
						sId = '';
						eep = _aEepromByAddr [ bytes.readUnsignedShort ( ) ] as McuEeprom;
						if ( eep != null )
						{
							if ( bytes.bytesAvailable > 0 )
							{
								uLen = bytes.readUnsignedByte ( );
								sId = eep.id;
								if ( sId == 'eepv' )
								{
									// checking EEPROM schema version
									if ( bytes.bytesAvailable >= uLen )
									{
										bValid = true;
										uDatum = bytes.readUnsignedShort ( );
										if ( ( eep.value as uint ) == uDatum )
										{
											// EEPROM schema is current, so remove from list
											// and continue to read the rest
											_vEepromIdsToCheck.removeAt ( _vEepromIdsToCheck.indexOf ( sId ) );
											_callLater ( _EepromsRead );
										}
										else
										{
											// need to initialize EEPROM
											_debugOut ( 'status_eeprom_update', true, null, true );
											_EepromConfigCaptionsSet ( true );
										}
									}
								}
								else
								{
									// reading all other EEPROMs
									if ( eep.restoreValueFromByteArray ( bytes ) )
									{
										bValid = true;
										_vEepromIdsToCheck.removeAt ( _vEepromIdsToCheck.indexOf ( sId ) );
										_callLater ( _EepromsRead );
									}
								}
							}
						}
						if ( !bValid )
						{
							_debugOut ( 'error_mcu_eeprom_response', true, [ sId ] );
						}
						break;
					case McuConnectorBase.EMERGENCY_ID:
						sDbg = _resourceManager.getString ( 'default', 'mcu_emergency', [ HexStringUtil.HexStringFromByteArray ( bytes ) ] );
						_debugOut ( sDbg );
						statusSet ( sDbg );
						// ##### TODO
						// report to control panel?
						break;
					case McuConnectorBase.COMMAND_DUMP_ID:
						bytesOut = new ByteArray ( );
						bytes.readBytes ( bytesOut );
						_debugOut ( 'mcu_cmd_dump', true, [ HexStringUtil.HexStringFromByteArray ( bytesOut ) ] );
						break;
					case McuConnectorBase.EXCEPTION_ID:
						if ( bytes.bytesAvailable < 2 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.EXCEPTION_ID, 1 ) ] );
						}
						else
						{
							_debugOut ( 'error_mcu_cmd_pkt_' + bytes [ 1 ], true, [ HexStringUtil.HexNumberStringFromUintBytes ( bytes [ 2 ], 1 ) ] );
						}
						break;
					case McuConnectorBase.ROUTE_STATUS_ID:
						if ( bytes.bytesAvailable < 1 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.ROUTE_STATUS_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedByte ( );
							vmdToSend [ uVmdLen++ ] = new MessageData ( 'wpr', uDatum );
						}
						break;
					case McuConnectorBase.WAYPOINT_ARRIVE_ID:
						if ( bytes.bytesAvailable < 1 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.WAYPOINT_ARRIVE_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedByte ( );
							_wpsMgr.waypointArrived ( uDatum );
						}
						break;
					case McuConnectorBase.CURRENT_LIMIT_ID:
						if ( bytes.bytesAvailable < 1 )
						{
							_debugOut ( 'error_mcu_args', true, [ HexStringUtil.HexNumberStringFromUintBytes ( McuConnectorBase.CURRENT_LIMIT_ID, 1 ) ] );
						}
						else
						{
							uDatum = bytes.readUnsignedByte ( );
							_callLater ( motorCurrentLimitFromMcu, [ uDatum ] );
						}
						break;
					default:
						if ( _custCmdMgr.idIsInCustomRange ( uId ) )
						{
							// custom command status
							if ( _custCmdMgr.suspend )
							{
								// command interpretation unavailable due to configuration ongoing
								_debugOut ( 'error_mcu_custom_suspend', true, [ uId ] );
							}
							else
							{
								ccc = _custCmdMgr.getCommandConfigById ( uId );
								if ( ccc != null )
								{
									// valid ID
									if ( ccc.setCommandValueFromByteArray ( bytes ) )
									{
										// had enough bytes to update value, so update user variable
										vmdToSend [ uVmdLen++ ] = new MessageData ( 'cu' + uId, ccc, true );
									}
									else
									{
										// too few bytes available
										_debugOut ( 'error_mcu_custom_bytes', true, [ uId ] );
									}
								}
								else
								{
									// command not configured
									_debugOut ( 'error_mcu_custom_cfg', true, [ uId ] );
								}
							}
						}
						else
						{
							// unknown telemetry ID
							_debugOut ( 'error_mcu_id', true, [ uId ] );
						}
						break;
				} // end switch
				
				bytes.clear ( );
				
			} // end while loop
			
			if ( uVmdLen > 0 )
			{
				pilotConnector.userVarsQueue ( vmdToSend );
			}
			
			if ( bTurretChange )
			{
				_VisionOrientUpdateCommit ( );
			}
			
			if ( bRangeChange )
			{
				_UltraSonicRangeCheck ( );
			}
		}
		
		private function _McuDisconnected ( event:UtilityEvent ) : void
		{
			_McuConnectedSet ( false );
		}
		
		private function _McuGpsUpdate ( lat:Number, lng:Number ) : void
		{
			var nTime:Number = new Date().getTime();
			if ( nTime < _nNavGpsNextTime )
				return;
			
			_nNavGpsNextTime = nTime + _nNavGpsMsec;
			_currentCoords.latitude = lat;
			_currentCoords.longitude = lng;
			mcuSendCommandByteArray ( _currentCoords.messageBytesForMcu );
		}
		
		private function _McuHeadingUpdate ( qa:QuaternionArx, timeNow:Number ) : void
		{
			if ( timeNow < _nNavHdgNextTime )
			{
				return;
			}
			
			_nNavHdgNextTime = timeNow + _nNavHdgMsec;
			
			var v3d:Vector3D = qa.quaternion.toEulerAngles ( );
			var hdg:Number = v3d.z * MathConsts.RADIANS_TO_DEGREES;
			
			var uVal:uint = uint ( Math.round ( hdg ) );
			if ( uVal > 359 )
			{
				uVal = 0;
			}
			if ( uVal != _uHeading )
			{
				// value has changed, so update the Mcu
				_uHeading = uVal;
				var ba:ByteArray = new ByteArray ( );
				ba.writeByte ( McuMessage.HEADING );
				ba.writeShort ( _uHeading );
				mcuSendCommandByteArray ( ba );
			}
		}
		
		private function _MotMgrEnabledChange ( value:Boolean ) : void
		{
			_MotMgrEnabledUpdate ( value, orientedPortrait );
		}
		
		private function _MotMgrEnabledUpdate ( isEnabled:Boolean, isPortrait:Boolean ) : void
		{
			if ( isEnabled )
			{
				if ( isPortrait )
				{
					motMgrEnabledLandscape = false;
					motMgrEnabledPortrait = true;
				}
				else
				{
					motMgrEnabledLandscape = true;
					motMgrEnabledPortrait = false;
				}
			}
			else
			{
				motMgrEnabledLandscape = false;
				motMgrEnabledPortrait = false;
			}
		}
		
		private function _MotorCurrentLimitToMcu ( step:uint ) : void
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( McuMessage.CURRENT_LIMIT );
			ba.writeByte ( step );
			mcuSendCommandByteArray ( ba );
		}
		
		private function _NoOp ( ... args ) : void { }
		
		private function _OpModeIsAvailable ( mode:uint ) : Boolean
		{
			if ( mode == OpModes.RC && userState.mcuConnectModeId != McuConnectModes.BLUETOOTH && userState.mcuConnectModeId != McuConnectModes.BLE )
				return false;
			
			return true;
		}
		
		private function _PermsDone ( event:Event = null ) : void
		{
			permissionsChecker.removeEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsDone );
			if ( permissionsChecker.allPermitted )
			{
				if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
				{
					_GeoActivate ( );
				}
			}
			else
			{
				permissionsOpen ( );
			}
		}
		
		private function _PermsInit ( ) : void
		{
			if ( permissionsChecker.allPermitted )
			{
				permissionsInited = true;
				_callLater ( _SensorsInit );
			}
			else
			{
				permissionsOpen ( );
			}
		}
		
		private function _PermsInitDone ( event:Event = null ) : void
		{
			permissionsChecker.removeEventListener ( PermissionsCheckerBase.PERMISSIONS_DONE, _PermsInitDone );
			_PermsInit ( );
		}
		
		private function _PilotConnectorDismiss ( ) : void
		{
			// remove listeners and stop sensor polling
			// _BatteryDeactivate ( );
			_GeoDeactivate ( );
			_DeviceMotionDeactivate ( );
			
			if ( !pilotConnector )
				return;
			
			// dispose
			pilotConnector.dismiss ( );
			pilotConnector = null;
		}
		
		private function _PilotInsetConfigChange ( event:Event ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'pic', userState.pilotInsetConfig, true ) ] );
		}
		
		private function _PilotMediaConfigChange ( event:Event ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'pmc', userState.pilotMediaConfig, true ) ] );
		}
		
		private function _RobotInsetConfigChange ( event:Event ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'ric', userState.robotInsetConfig, true ) ] );
		}
		
		private function _RobotMediaConfigChange ( event:Event ) : void
		{
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'rmc', userState.robotMediaConfig, true ) ] );
		}
		
		private function _SensorsInit ( ) : void
		{
			// Battery
			_batteryUtil = BatteryUtil.instance;
			if ( _batteryUtil.isSupported )
			{
				_bBatterySupport = true;
				_debugOut ( 'status_phone_bat_support', true );
				_BatteryActivate ( ); // start it now and keep it going even when in RC mode
			}
			
			// DeviceMotion supported?
			var devMo:DeviceMotionUtil = DeviceMotionUtil.instance;
			if ( devMo.isSupported && devMo.isAlgorithmSupported ( ) )
			{
				_bDevMotionSupport = true;
				_debugOut ( 'status_dev_motion_support', true );
			}
			
			// Geolocation supported?
			_gps = new Gps ( );
			_bGeoSupport = Geolocation.isSupported;
			if ( _bGeoSupport )
			{
				_debugOut ( 'status_geo_support', true );
			}
			else
			{
				_debugOut ( 'error_geo_support', true );
			}
			
			_declinationUtil = DeclinationUtil.instance;
			
			_callLater ( _CustomInit );
		}
		
		private function _StageOrientationApply ( dims:Point = null ) : void
		{
			// configure compensation for GUI vs Device orientation
			var appWd:Number;
			var appHt:Number;
			if ( dims )
			{
				appWd = dims.x;
				appHt = dims.y;
			}
			else
			{
				appWd = app.width;
				appHt = app.height;
			}
			calloutContentWdMax = appWd - guiGap4;
			_debugOut ( 'orient: ' + _sOrientStage + ', wd: ' + appWd + ', ht: ' + appHt ); // TESTING
			orientedPortrait = ( appHt > appWd );
			_iVidPodWd = appWd;
			_iVidPodHt = appHt - osStatusBarHeight;
			
			// some of the following may change
			// after we change the _qBasis calibration procedure
			if ( !orientedPortrait )
			{
				_CamMgrEnabledUpdate ( _camMgr.enabled, false );
				_MotMgrEnabledUpdate ( _motMgr.enabled, false );
				_uVidSenderRot = 0;
			}
			else
			{
				_CamMgrEnabledUpdate ( _camMgr.enabled, true );
				_MotMgrEnabledUpdate ( _motMgr.enabled, true );
				if ( _sOrientStage == StageOrientation.ROTATED_LEFT )
				{
					_uVidSenderRot = 90;
				}
				else
				{
					if ( osIsIOS || ( osIsAndroid && _camMgr && _camMgr.camera && _camMgr.camera.position == CameraPosition.BACK ) )
					{
						_uVidSenderRot = 90;
					}
					else
					{
						// on Android front cam portrait
						_uVidSenderRot = 270;
					}
				}
			}
			_nVidPodAspect = 1.0 * _iVidPodHt / _iVidPodWd;
			
			dispatchEvent ( new Event ( APP_RESIZED ) );
		}
		
		private function _StageOrientationChanged ( event:StageOrientationEvent ) : void
		{
			_sOrientStage = event.afterOrientation;
			// _debugOut ( '_StageOrientationChanged:  event.afterOrientation == ' + _sOrientStage + '  app.stage.orientation == ' + app.stage.orientation ); // TESTING
			if ( osIsIOS )
			{
				_StageOrientationApply ( );
			}
		}
		
		private function _StageOrientationLock ( ) : void
		{
			_sOrientStage = app.stage.orientation;
			var xDims:Point = new Point ( app.width, app.height );
			// persist orientation for possible restoration at next startup
			userState.displayOrientation = _sOrientStage;
			userState.displayDimensions = xDims;
			app.stage.autoOrients = false;
			app.stage.setOrientation ( _sOrientStage );
			_StageOrientationApply ( xDims );
			statusSetResource ( 'status_rot_lock_1' );
		}
		
		
		// setOrientation seems to be broken on iOS (noticed 2019-04-04)
		// so not attempting to restore when running in iOS for now.
		private function _StageOrientationRestore ( ) : void
		{
			var vOrs:Vector.<String> = app.stage.supportedOrientations;
			var sOrientPrev:String = userState.displayOrientation;
			var xDims:Point = userState.displayDimensions;
			var sOrientCur:String = app.stage.orientation;
			if ( osIsIOS || sOrientPrev.length < 1 || vOrs.indexOf ( sOrientPrev ) < 0 || !xDims )
			{
				// either in iOS or empty string means was not locked
				// or invalid orientation or dimensions will be ignored
				_sOrientStage = sOrientCur
				_StageOrientationApply ( );
			}
			else
			{
				// was locked (and is running in Android)
				_sOrientStage = sOrientPrev;
				app.stage.autoOrients = false;
				app.stage.setOrientation ( sOrientPrev);
				_StageOrientationApply ( xDims );
				_RotationLockChangedDispatch ( );
			}
		}
		
		private function _StageOrientationUnlock ( ) : void
		{
			app.stage.autoOrients = true;
			userState.displayOrientation = '';
			statusSetResource ( 'status_rot_lock_0' );
		}
		
		private function _StageResized ( event:ResizeEvent ) : void
		{
			_debugOut ( '_StageResized:  _sOrientStage == ' + _sOrientStage + '  app.stage.orientation == ' + app.stage.orientation ); // TESTING
			_StageOrientationApply ( );
		}
		
		private function _StatusEventDispatch ( ) : void
		{
			dispatchEvent ( new StatusDataEvent ( StatusDataEvent.STATUS_DATA_MESSAGE, _statusData ) );
		}
		
		private function _SystemsActivate ( ) : void
		{
			// tasks necessary to resume full activity, such as
			// acquire wake lock, start streaming video/audio,
			// start or increase frequency of sensor polling,
			// resume magnetic declination checks
			_IsSleepingSet ( false );
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			
			pilotConnector.wake ( );
			
			if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
			{
				_GeoActivate ( );
				_DeviceMotionActivate ( );
			}
			
			mcuSendCommandId ( McuMessage.WAKEUP );
			
			pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'sleep', _bSleep ) ] );
		}
		
		private function _SystemsDeactivate ( ) : void
		{
			// tasks necessary to go dormant and converve power, such as
			// release wake lock, stop streaming video/audio,
			// stop or decrease frequency of sensor polling,
			// pause magnetic declination checks
			pilotConnector.sleep ( );
			
			if ( _uOpMode == OpModes.CS || _uOpMode == OpModes.PP )
			{
				_GeoDeactivate ( );
				_DeviceMotionDeactivate ( );
			}
			
			mcuSendCommandId ( McuMessage.SLEEP );
			
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			
			if ( !_bExiting )
			{
				_IsSleepingSet ( true );
				pilotConnector.userVarsQueue ( new <MessageData> [ new MessageData ( 'sleep', _bSleep ) ] );
			}
		}
		
		private function _UltraSonicRangeCheck ( ) : void
		{
			// if ( FlagsUtil.IsSet ( _uEmFlags, EmergencyFlags.OBSTACLE ) )
			if ( ( _uEmFlags & EmergencyFlags.OBSTACLE ) == _uEmFlags )
			{
				// flag is set -- can it be cleared?
				if ( _roverData.usRangeLeft >= _iRangerMinL && _roverData.usRangeRight >= _iRangerMinR )
				{
					emergencyFlagsClear ( EmergencyFlags.OBSTACLE );
				}
			}
			else
			{
				// should it be set?
				if ( _roverData.usRangeLeft < _iRangerMinL || _roverData.usRangeRight < _iRangerMinR )
				{
					emergencyFlagsSet ( EmergencyFlags.OBSTACLE );
				}
			}
		}
		
		private function _UserStatePersist ( event:Event = null ) : void
		{
			try
			{
				var ba:ByteArray = new ByteArray ( );
				ba.writeObject ( userState );
				
				var f:File = _dirSets.resolvePath ( 'UserState.dat' );
				if ( f.exists ) f.deleteFile ( );
				
				var fs:FileStream = new FileStream();
				// open
				fs.open ( f, FileMode.WRITE );
				// write
				fs.writeBytes ( ba );
				// close
				fs.close();
				var fBkp:File = _dirSetsBkp.resolvePath ( 'UserState.dat' );
				f.copyTo ( fBkp, true );
			}
			catch ( err:Error )
			{
				_debugOut ( err.message );
			}
		}
		
		private function _UserStateRestore ( ) : Boolean
		{
			registerClassAlias ( 'UserState', UserState as Class );
			registerClassAlias ( 'CameraConfig', CameraConfig as Class );
			// registerClassAlias ( 'Quaternion', Quaternion as Class );
			registerClassAlias ( 'SfsPreset', SfsPreset as Class );
			registerClassAlias ( 'MediaConfig', MediaConfig as Class );
			registerClassAlias ( 'InsetConfig', InsetConfig as Class );
			registerClassAlias ( 'Point', Point as Class );
			
			var f:File = _dirSets.resolvePath ( 'UserState.dat' );
			var fBkp:File = _dirSetsBkp.resolvePath ( 'UserState.dat' );
			if ( !f.exists )
			{
				// not yet saved locally or else app update wiped out app storage
				// is there a backup?
				if ( fBkp.exists )
				{
					// have backup
					try
					{
						_dirSetsBkp.copyTo ( _dirSets, true );
					}
					catch ( err:Error )
					{
						_debugOut ( 'error_userstate_restore', true, [ err.message ] );
						return false; // error copying backup directory, so return
					}
				}
				else
				{
					return false;  // no backup, so return
				}
			}
			
			try
			{
				var fs:FileStream = new FileStream();
				// open
				fs.open ( f, FileMode.READ );
				// read
				var ba:ByteArray = new ByteArray();
				fs.readBytes ( ba );
				// close
				fs.close();
				userState = ba.readObject ( );
				// if no backup copy, create one
				if ( !fBkp.exists )
				{
					f.copyTo ( fBkp, true );
				}
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_userstate_restore', true, [ err.message ] );
				return false; // error in restoring from file, so return
			}
			
			return true;
		}
		
		private function _ViewStateSetHome ( name:String, clearAll:Boolean = false ) : void
		{
			_vViewStateStack [ 0 ] = name;
			if ( clearAll )
			{
				_vViewStateStack.length = 1;
			}
			var sNew:String = _vViewStateStack [ _vViewStateStack.length - 1 ];
			if ( _VIEW_STATE_SLOW [ sNew ] && !isBusy )
			{
				_sAppVwStateDelayed = sNew;
				isBusy = true;
			}
			else
			{
				_AppViewStateSet ( sNew );
			}
		}
		
		private function _VisionOrientUpdateCommit ( ) : void
		{
			// compensate orientation interpretation only when
			// pan and tilt are implemented by moving the device
			
			if ( _bPanOrTiltDeviceEnabled )
			{
				_callLater ( _DeviceBasisUpdate );
			}
		}
		
		// return true if user var needs update
		private function _VisionPanUpdate ( val:int ) : Boolean
		{
			if ( _bPanEnabled )
			{
				var iNet:int = val - _iPanHome;
				if ( iNet != _iPanNet )
				{
					_iPanNet = iNet;
					return true;
				}
			}
			return false;
		}
		
		// return true if user var needs update
		private function _VisionTiltUpdate ( val:int  ) : Boolean
		{
			if ( _bTiltEnabled )
			{
				var iNet:int = val - _iTiltHome;
				if ( iNet != _iTiltNet )
				{
					_iTiltNet = iNet;
					return true;
				}
			}
			return false;
		}
	}
}
class SingletonEnforcer {}