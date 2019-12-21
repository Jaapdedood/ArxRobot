package com.arxterra.utils
{
	import com.arxterra.controllers.SessionManager;
	import com.distriqt.extension.devicemotion.Algorithm;
	import com.distriqt.extension.devicemotion.DeviceMotion;
	import com.distriqt.extension.devicemotion.DeviceMotionOptions;
	import com.distriqt.extension.devicemotion.OutputFormat;
	import com.distriqt.extension.devicemotion.ReferenceFrame;
	import com.distriqt.extension.devicemotion.SensorRate;
	
	public class DeviceMotionUtil extends NonUIComponentBase
	{
		// static constants and properties
		
		private static var __instance:DeviceMotionUtil;
		
		// constructor and instance
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : DeviceMotionUtil
		{
			if ( !__instance )
			{
				__instance = new DeviceMotionUtil ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance,
		 * then add listeners to DeviceMotion service via instance.service.
		 */	
		public function DeviceMotionUtil ( enforcer:SingletonEnforcer )
		{
			super();
			_dmo = new DeviceMotionOptions ( );
			_dmo.algorithm = Algorithm.NATIVE;
			_dmo.referenceFrame = ReferenceFrame.Y_MAGNETICNORTH_Z_VERTICAL;
			_dmo.format = OutputFormat.QUATERNION;
			_dmo.autoOrient = true;
			_dmo.rate = SensorRate.SENSOR_DELAY_NORMAL;
			try
			{
				// DeviceMotion.init ( SessionManager.DISTRIQT_ANE_APP_KEY );
				if ( !DeviceMotion.isSupported )
				{
					_debugOut ( 'error_dev_motion_support', true );
				}
				else if ( !DeviceMotion.service.isAlgorithmSupported ( _dmo.algorithm, _dmo.format ) )
				{
					_debugOut ( 'error_dev_motion_algo_support', true, [ _dmo.algorithm, _dmo.format ] );
				}
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_dev_motion_init', true, [ err.message ] );
			}
			
		}
		
		
		// public properties and get/set methods
		
		public function get isRegistered ( ) : Boolean
		{
			return _bRegistered;
		}
		
		public function get isSupported ( ) : Boolean
		{
			return DeviceMotion.isSupported;
		}
		
		public function get service ( ) : DeviceMotion
		{
			return DeviceMotion.service;
		}
		
		// other public methods
		
		public function isAlgorithmSupported ( algorithm:String = '', format:String = '' ) : Boolean
		{
			if ( algorithm.length < 1 )
				algorithm = _dmo.algorithm;
			if ( format.length < 1 )
				format = _dmo.format;
			return DeviceMotion.service.isAlgorithmSupported ( algorithm, format );
		}
		
		public function register ( ) : void
		{
			_Register ( true );
		}
		
		public function unregister ( ) : void
		{
			_Register ( false );
		}
		
		// private properties
		
		private var _bRegistered:Boolean = false;
		private var _dmo:DeviceMotionOptions;
		
		// private methods
		
		private function _Register ( on:Boolean ) : void
		{
			if ( !DeviceMotion.isSupported || on == _bRegistered )
				return;
			
			try
			{
				if ( on )
				{
					DeviceMotion.service.register ( _dmo );
				}
				else
				{
					DeviceMotion.service.unregister ( );
				}
				_bRegistered = on;
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_dev_motion_reg', true, [ err.message ] );
			}
		}
		
	}
}
class SingletonEnforcer {}
