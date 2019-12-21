package com.arxterra.vo
{	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import mx.utils.ObjectUtil;
	
	[Event(name="pilot_inset_config_change", type="flash.events.Event")]
	[Event(name="pilot_media_config_change", type="flash.events.Event")]
	[Event(name="robot_inset_config_change", type="flash.events.Event")]
	[Event(name="robot_media_config_change", type="flash.events.Event")]
	[Event(name="user_state_change", type="flash.events.Event")]
	
	// This class is designated as dynamic to avoid errors during deserialization
	// when the previously serialized version contained a property that has since been deleted.
	
	[Bindable]
	public dynamic class UserState extends EventDispatcher
	{
		public static const PILOT_INSET_CONFIG_CHANGE:String = 'pilot_inset_config_change';
		public static const PILOT_MEDIA_CONFIG_CHANGE:String = 'pilot_media_config_change';
		public static const ROBOT_INSET_CONFIG_CHANGE:String = 'robot_inset_config_change';
		public static const ROBOT_MEDIA_CONFIG_CHANGE:String = 'robot_media_config_change';
		public static const USER_STATE_CHANGE:String = 'user_state_change';
		
		private var _sAssetsDir:String = '';
		public function get assetsDir():String
		{
			return _sAssetsDir;
		}
		public function set assetsDir(value:String):void
		{
			if ( value == _sAssetsDir )
				return;
			_QueueSave ( );
			_sAssetsDir = value;
		}
		
		private var _oBleAddrs:Object = {};
		public function get bleAddresses():Object
		{
			return _oBleAddrs;
		}
		public function set bleAddresses(value:Object):void
		{
			if ( value == _oBleAddrs )
				return;
			_QueueSave ( );
			_oBleAddrs = value;
		}
		
		// added 2019-10-08
		private var _bBleAuto:Boolean = false;
		public function get bleAutoSelect():Boolean
		{
			return _bBleAuto;
		}
		public function set bleAutoSelect(value:Boolean):void
		{
			if ( value == _bBleAuto )
				return;
			_QueueSave ( );
			_bBleAuto = value;
		}
		
		public function getBleSpecAddress ( id:String ) : String
		{
			if ( id in _oBleAddrs )
			{
				return _oBleAddrs [ id ];
			}
			return '';
		}
		public function setBleSpecAddress ( id:String, addr:String ) : void
		{
			if ( id in _oBleAddrs )
			{
				if ( _oBleAddrs [ id ] == addr )
				{
					return;
				}
			}
			_QueueSave ( );
			_oBleAddrs [ id ] = addr;
		}
		
		private var _sBtAddr:String = '';
		public function get bluetoothAddress():String
		{
			return _sBtAddr;
		}
		public function set bluetoothAddress(value:String):void
		{
			if ( value == _sBtAddr )
				return;
			_QueueSave ( );
			_sBtAddr = value;
		}
		
		private var _bCamAdjustMot:Boolean = false;
		public function get cameraAdjustForMotion():Boolean
		{
			return _bCamAdjustMot;
		}
		public function set cameraAdjustForMotion(value:Boolean):void
		{
			if ( value == _bCamAdjustMot )
				return;
			_QueueSave ( );
			_bCamAdjustMot = value;
		}
		
		private var _ccDef:CameraConfig;
		public function get cameraConfigDefault():CameraConfig
		{
			return _ccDef;
		}
		public function set cameraConfigDefault(value:CameraConfig):void
		{
			if ( ObjectUtil.compare ( value, _ccDef ) == 0 )
				return;
			_QueueSave ( );
			_ccDef = value;
		}
		
		private var _ccMot:CameraConfig;
		public function get cameraConfigMotion():CameraConfig
		{
			return _ccMot;
		}
		public function set cameraConfigMotion(value:CameraConfig):void
		{
			if ( ObjectUtil.compare ( value, _ccMot ) == 0 )
				return;
			_QueueSave ( );
			_ccMot = value;
		}
		
		private var _bCamFlipH:Boolean;
		public function get cameraFlipHorizontal():Boolean
		{
			return _bCamFlipH;
		}
		public function set cameraFlipHorizontal(value:Boolean):void
		{
			if ( value == _bCamFlipH )
				return;
			_QueueSave ( );
			_bCamFlipH = value;
		}
		
		private var _bCamFlipV:Boolean;
		public function get cameraFlipVertical():Boolean
		{
			return _bCamFlipV;
		}
		public function set cameraFlipVertical(value:Boolean):void
		{
			if ( value == _bCamFlipV )
				return;
			_QueueSave ( );
			_bCamFlipV = value;
		}
		
		private var _iCamIdx:int;
		public function get cameraIndex():int
		{
			return _iCamIdx;
		}
		public function set cameraIndex(value:int):void
		{
			if ( value == _iCamIdx )
				return;
			_QueueSave ( );
			_iCamIdx = value;
		}
		
		private var _uCamRot:uint = 271;
		/**
		 * Rotation override manually set by user. Set values are 0, 90, 180, 270.
		 * Any value over 270 indicates value has not been set. If value is unset
		 * or displayOrientation is not locked, this value is ignored, and the
		 * rotation default for the current display orientation is used.
		 * Otherwise this value is used to force rotation to that set by user.
		 */
		public function get cameraRotation():uint
		{
			return _uCamRot;
		}
		/**
		 * @private
		 */
		public function set cameraRotation(value:uint):void
		{
			_uCamRot = value;
		}
		
		private var _bCapsStorePhone:Boolean = true;
		public function get capabilitiesStorePhone():Boolean
		{
			return _bCapsStorePhone;
		}
		public function set capabilitiesStorePhone(value:Boolean):void
		{
			if ( value == _bCapsStorePhone )
				return;
			_QueueSave ( );
			_bCapsStorePhone = value;
		}
		
		private var _uContMode:uint = 0;
		public function get controlMode():uint
		{
			return _uContMode;
		}
		public function set controlMode(value:uint):void
		{
			if ( value == _uContMode )
				return;
			_QueueSave ( );
			_uContMode = value;
		}
		
		/*
		private var _bQBasisUse:Boolean = false;
		//		/**
		//		 * True when using stored deviceOrientationBasis
		//		 *
		public function get deviceOrientationBasisOn():Boolean
		{
			return _bQBasisUse;
		}
		//		/**
		//		 * @private
		//		 *
		public function set deviceOrientationBasisOn(value:Boolean):void
		{
			if ( value == _bQBasisUse )
				return;
			_QueueSave ( );
			_bQBasisUse = value;
		}
		
		private var _qBasis:Quaternion;
		//		/**
		//		 * Quaternion stored when user calibrates device position
		//		 *
		public function get deviceOrientationBasis():Quaternion
		{
			return _qBasis;
		}
		//		/**
		//		 * @private
		//		 *
		public function set deviceOrientationBasis(value:Quaternion):void
		{
			if ( ObjectUtil.compare ( value, _qBasis ) == 0 )
				return;
			_QueueSave ( );
			_qBasis = value;
		}
		*/
		
		private var _xDispDims:Point;
		/**
		 * Stores point with width, height of stage to match locked display orientation
		 */
		public function get displayDimensions():Point
		{
			return _xDispDims;
		}
		/**
		 * @private
		 */
		public function set displayDimensions(value:Point):void
		{
			if ( ObjectUtil.compare ( value, _xDispDims ) == 0 )
			{
				return; // return
			}
			_QueueSave ( );
			_xDispDims = value;
		}
		
		private var _sDispOrient:String = '';
		/**
		 * Empty string indicates allow free rotation with device position,
		 * Otherwise lock at stored orientation.
		 */
		public function get displayOrientation():String
		{
			return _sDispOrient;
		}
		/**
		 * @private
		 */
		public function set displayOrientation(value:String):void
		{
			if ( value == _sDispOrient )
				return;
			_QueueSave ( );
			_sDispOrient = value;
		}
		
		
		private var _bExpert:Boolean = false;
		public function get expertOn():Boolean
		{
			return _bExpert;
		}
		public function set expertOn(value:Boolean):void
		{
			if ( value == _bExpert )
				return;
			_QueueSave ( );
			_bExpert = value;
		}
		
		private var _uHandPref:uint = 0;
		public function get handPref():uint
		{
			return _uHandPref;
		}
		public function set handPref(value:uint):void
		{
			if ( value == _uHandPref )
				return;
			_QueueSave ( );
			_uHandPref = value;
		}
		
		private var _uMcuModeId:uint = McuConnectModes.NA;
		public function get mcuConnectModeId():uint
		{
			return _uMcuModeId;
		}
		public function set mcuConnectModeId(value:uint):void
		{
			if ( value == _uMcuModeId )
				return;
			_QueueSave ( );
			_uMcuModeId = value;
		}
		
		private var _uMcuWdogModeId:uint = McuWatchdogModes.DEFAULT;
		public function get mcuWatchdogModeId():uint
		{
			return _uMcuWdogModeId;
		}
		public function set mcuWatchdogModeId(value:uint):void
		{
			if ( value == _uMcuWdogModeId )
				return;
			_QueueSave ( );
			_uMcuWdogModeId = value;
		}
		
		private var _bOkCam:Boolean = true;
		public function get mayRequestCamera():Boolean
		{
			return _bOkCam;
		}
		public function set mayRequestCamera(value:Boolean):void
		{
			if ( value == _bOkCam )
				return;
			_QueueSave ( );
			_bOkCam = value;
		}
		
		private var _bOkFile:Boolean = true;
		public function get mayRequestFile():Boolean
		{
			return _bOkFile;
		}
		public function set mayRequestFile(value:Boolean):void
		{
			if ( value == _bOkFile )
				return;
			_QueueSave ( );
			_bOkFile = value;
		}
		
		private var _bOkGeo:Boolean = true;
		public function get mayRequestGeolocation():Boolean
		{
			return _bOkGeo;
		}
		public function set mayRequestGeolocation(value:Boolean):void
		{
			if ( value == _bOkGeo )
				return;
			_QueueSave ( );
			_bOkGeo = value;
		}
		
		private var _bOkMic:Boolean = true;
		public function get mayRequestMicrophone():Boolean
		{
			return _bOkMic;
		}
		public function set mayRequestMicrophone(value:Boolean):void
		{
			if ( value == _bOkMic )
				return;
			_QueueSave ( );
			_bOkMic = value;
		}
		
		private var _uCurrentLimDef:uint = 0;
		/**
		 * 0 value (out of range) indicates waiting for default value to be
		 * sent from MCU
		 */
		public function get motorCurrentLimitDefault():uint
		{
			return _uCurrentLimDef;
		}
		/**
		 * @private
		 */
		public function set motorCurrentLimitDefault(value:uint):void
		{
			if ( value == _uCurrentLimDef )
				return;
			_QueueSave ( );
			_uCurrentLimDef = value;
		}
		
		private var _uCurrentLim:uint = 84;
		public function get motorCurrentLimitStep():uint
		{
			return _uCurrentLim;
		}
		public function set motorCurrentLimitStep(value:uint):void
		{
			if ( value == _uCurrentLim )
				return;
			_QueueSave ( );
			_uCurrentLim = value;
		}
		
		private var _uOpMode:uint = OpModes.RC;
		public function get opMode():uint
		{
			return _uOpMode;
		}
		public function set opMode(value:uint):void
		{
			if ( value == _uOpMode )
				return;
			_QueueSave ( );
			_uOpMode = value;
		}
		
		private var _iPhoneBattMin:int = 10;
		public function get phoneBatteryMin():int
		{
			return _iPhoneBattMin;
		}
		public function set phoneBatteryMin(value:int):void
		{
			if ( value == _iPhoneBattMin )
				return;
			_QueueSave ( );
			_iPhoneBattMin = value;
		}
		
		private var _icPilot:InsetConfig;
		public function get pilotInsetConfig():InsetConfig
		{
			return _icPilot;
		}
		public function set pilotInsetConfig(value:InsetConfig):void
		{
			if ( ObjectUtil.compare ( value, _icPilot ) == 0 )
			{
				return; // return
			}
			if ( _icPilot != null )
			{
				_icPilot.removeEventListener ( InsetConfig.INSET_CONFIG_CHANGE, _PilotInsetConfigChange );
			}
			if ( value != null )
			{
				// listen for event reporting that properties have changed within InsetConfig instance
				value.addEventListener ( InsetConfig.INSET_CONFIG_CHANGE, _PilotInsetConfigChange );
			}
			_QueueSave ( );
			_icPilot = value;
		}
		
		private var _mcPilot:MediaConfig;
		public function get pilotMediaConfig():MediaConfig
		{
			return _mcPilot;
		}
		public function set pilotMediaConfig(value:MediaConfig):void
		{
			if ( ObjectUtil.compare ( value, _mcPilot ) == 0 )
			{
				return; // return
			}
			if ( _mcPilot != null )
			{
				_mcPilot.removeEventListener ( MediaConfig.MEDIA_CONFIG_CHANGE, _PilotMediaConfigChange );
			}
			if ( value != null )
			{
				// listen for event reporting that properties have changed within MediaConfig instance
				value.addEventListener ( MediaConfig.MEDIA_CONFIG_CHANGE, _PilotMediaConfigChange );
			}
			_QueueSave ( );
			_mcPilot = value;
		}
		
		private var _sPilotNames:String = '';
		public function get pilotNames():String
		{
			return _sPilotNames;
		}
		public function set pilotNames(value:String):void
		{
			if ( value == _sPilotNames )
			{
				return; // return
			}
			_QueueSave ( );
			_sPilotNames = value;
		}
		
		private var _icRobot:InsetConfig;
		public function get robotInsetConfig():InsetConfig
		{
			return _icRobot;
		}
		public function set robotInsetConfig(value:InsetConfig):void
		{
			if ( ObjectUtil.compare ( value, _icRobot ) == 0 )
			{
				return; // return
			}
			if ( _icRobot != null )
			{
				_icRobot.removeEventListener ( InsetConfig.INSET_CONFIG_CHANGE, _RobotInsetConfigChange );
			}
			if ( value != null )
			{
				// listen for event reporting that properties have changed within InsetConfig instance
				value.addEventListener ( InsetConfig.INSET_CONFIG_CHANGE, _RobotInsetConfigChange );
			}
			_QueueSave ( );
			_icRobot = value;
		}
		
		private var _mcRobot:MediaConfig;
		public function get robotMediaConfig():MediaConfig
		{
			return _mcRobot;
		}
		public function set robotMediaConfig(value:MediaConfig):void
		{
			if ( ObjectUtil.compare ( value, _mcRobot ) == 0 )
			{
				return; // return
			}
			if ( _mcRobot != null )
			{
				_mcRobot.removeEventListener ( MediaConfig.MEDIA_CONFIG_CHANGE, _RobotMediaConfigChange );
			}
			if ( value != null )
			{
				// listen for event reporting that properties have changed within MediaConfig instance
				value.addEventListener ( MediaConfig.MEDIA_CONFIG_CHANGE, _RobotMediaConfigChange );
			}
			_QueueSave ( );
			_mcRobot = value;
		}
		
		private var _sRobotName:String = '';
		public function get robotName():String
		{
			return _sRobotName;
		}
		public function set robotName(value:String):void
		{
			if ( value == _sRobotName )
				return;
			_QueueSave ( );
			_sRobotName = value;
		}
		
		private var _sfsCfg:SfsPreset;
		public function get sfsConfig():SfsPreset
		{
			return _sfsCfg;
		}
		public function set sfsConfig(value:SfsPreset):void
		{
			if ( ObjectUtil.compare ( value, _sfsCfg ) == 0 )
				return;
			_QueueSave ( );
			_sfsCfg = value;
		}
		
		private var _nStrTrim:Number = 0;
		public function get steeringTrim():Number
		{
			return _nStrTrim;
		}
		public function set steeringTrim(value:Number):void
		{
			if ( value == _nStrTrim )
				return;
			_QueueSave ( );
			_nStrTrim = value;
		}
		
		public function UserState ( deserialized:Boolean = true )
		{
			_bDeserialized = deserialized;
		}
		
		private var _bDeserialized:Boolean = true;
		private var _tmr:Timer;
		
		private function _PilotInsetConfigChange ( event:Event ) : void
		{
			_QueueSave ( );
			dispatchEvent ( new Event ( PILOT_INSET_CONFIG_CHANGE ) );
		}
		
		private function _PilotMediaConfigChange ( event:Event ) : void
		{
			_QueueSave ( );
			dispatchEvent ( new Event ( PILOT_MEDIA_CONFIG_CHANGE ) );
		}
		
		private function _QueueSave ( ) : void
		{
			if ( _tmr )
				return;
			
			_tmr = new Timer ( 20, 1 );
			_tmr.addEventListener ( TimerEvent.TIMER, _RequestSave );
			_tmr.start ( );
		}
		
		private function _RequestSave ( event:TimerEvent ) : void
		{
			_tmr.stop ( );
			_tmr.removeEventListener ( TimerEvent.TIMER, _RequestSave );
			_tmr = null;
			if ( _bDeserialized )
			{
				// skip first time
				_bDeserialized = false;
				return;
			}
			dispatchEvent ( new Event ( USER_STATE_CHANGE ) );
		}
		
		private function _RobotInsetConfigChange ( event:Event ) : void
		{
			_QueueSave ( );
			dispatchEvent ( new Event ( ROBOT_INSET_CONFIG_CHANGE ) );
		}
		
		private function _RobotMediaConfigChange ( event:Event ) : void
		{
			_QueueSave ( );
			dispatchEvent ( new Event ( ROBOT_MEDIA_CONFIG_CHANGE ) );
		}
	}
}