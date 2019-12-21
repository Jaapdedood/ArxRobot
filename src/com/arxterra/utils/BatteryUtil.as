package com.arxterra.utils
{
	import com.distriqt.extension.battery.Battery;
	
	import com.arxterra.controllers.SessionManager;
	
	public class BatteryUtil extends NonUIComponentBase
	{
		// static constants and properties
		
		private static var __instance:BatteryUtil;
		
		
		// constructor, destructor and instance
		
		/**
		 * singleton instance of BatteryUtil
		 */
		public static function get instance ( ) : BatteryUtil
		{
			if ( !__instance )
			{
				__instance = new BatteryUtil ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		public static function InstanceDispose ( ) : void
		{
			if ( !__instance )
				return;
			
			__instance = null;
			
			if ( Battery.isSupported )
				Battery.service.dispose ( );
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance,
		 * then add listeners to Battery service via instance.service.
		 */
		public function BatteryUtil ( enforcer:SingletonEnforcer )
		{
			super();
			try
			{
				// Battery.init ( SessionManager.DISTRIQT_ANE_APP_KEY );
				if ( !Battery.isSupported )
				{
					_debugOut ( 'error_battery_support', true );
				}
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_battery_init', true, [ err.message ] );
			}
			
		}
		
		override public function dismiss ( ) : void
		{
			super.dismiss ( );
		}
		
		
		// public properties and get/set methods
		
		public function get isRegistered ( ) : Boolean
		{
			return _bRegistered;
		}
		
		public function get isSupported ( ) : Boolean
		{
			return Battery.isSupported;
		}
		
		public function get service ( ) : Battery
		{
			return Battery.service;
		}
		
		// other public methods
		
		public function check ( ) : void
		{
			Battery.service.getBatteryInfo ( );
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
		
		
		// private methods
		
		private function _Register ( on:Boolean ) : void
		{
			// debugOut ( 'Battery register: ' + on ); // TESTING
			if ( !Battery.isSupported || on == _bRegistered )
				return;
			
			try
			{
				if ( on )
				{
					Battery.service.getBatteryInfo ( );
				}
				else
				{
					Battery.service.cancel ( );
				}
				_bRegistered = on;
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_battery_reg', true, [ err.message ] );
			}
		}
		
	}
}
class SingletonEnforcer {}
