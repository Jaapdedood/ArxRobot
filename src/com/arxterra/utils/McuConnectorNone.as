package com.arxterra.utils
{
	import com.arxterra.vo.McuConnectModes;

	/**
	 * Singleton class extending McuConnector
	 * to provide dummy connector when none of our modes is supported.
	 */
	[Bindable]
	public class McuConnectorNone extends McuConnectorBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		private static var __instance:McuConnectorNone;
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : McuConnectorNone
		{
			if ( !__instance )
			{
				__instance = new McuConnectorNone ( new SingletonEnforcer () );
			}
			return __instance;
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */	
		public function McuConnectorNone ( enforcer:SingletonEnforcer )
		{
			super();
		}
		
		override public function dismiss ( ) : void
		{
			super.dismiss ( );
			__instance = null;
		}
		
		override public function init ( ) : void
		{
			super.init ( );
			_modeSet ( McuConnectModes.NA );
		}
	}
}
class SingletonEnforcer {}
