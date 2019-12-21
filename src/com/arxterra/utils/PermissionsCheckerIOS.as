package com.arxterra.utils
{
	/**
	 * Singleton class extending PermissionsCheckerBase
	 * to implement permissions checking specific to iOS.
	 */
	public class PermissionsCheckerIOS extends PermissionsCheckerBase
	{
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */
		public function PermissionsCheckerIOS ( enforcer:SingletonEnforcer )
		{
			super();
			_osPrefix = 'ios_';
		}
		
		private static var __instance:PermissionsCheckerIOS
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : PermissionsCheckerIOS
		{
			if ( !__instance )
			{
				__instance = new PermissionsCheckerIOS ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		override public function dismiss ( ) : void
		{
			super.dismiss ( );
			__instance = null;
		}
	}
}
class SingletonEnforcer {}
