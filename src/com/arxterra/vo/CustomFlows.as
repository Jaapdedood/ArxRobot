package com.arxterra.vo
{
	public class CustomFlows
	{
		// CONSTANTS
		
		/**
		 * Command and Telemetry State
		 */
		public static const COMMAND:uint = 0;
		
		/**
		 * Telemetry State
		 */
		public static const STATE:uint = 1;
		
		/**
		 * Telemetry Stream
		 */
		public static const STREAM:uint = 2;
		
		private static const __FLOWS:Array = [ COMMAND, STATE, STREAM ];
		
		public function CustomFlows()
		{
		}
		
		public static function ValidateFlow ( value:uint ) : uint
		{
			if ( __FLOWS.indexOf ( value ) < 0 )
				return COMMAND
			return value;
		}
	}
}