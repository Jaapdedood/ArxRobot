package com.arxterra.vo
{
	public class EmergencyFlags
	{
		// CONSTANTS
		
		public static const ALL_CLEAR:uint = 0;
		public static const LATENCY:uint = 1;
		public static const OBSTACLE:uint = 2;
		public static const STALL:uint = 4;
		public static const POSITION:uint = 8;
		public static const BATTERY:uint = 16;
		public static const TEMPERATURE:uint = 32;
		
		public static const FLAGS_ALL_SET:uint = LATENCY | OBSTACLE | STALL | POSITION | BATTERY | TEMPERATURE;
		public static const FLAGS_SETTABLE:Vector.<uint> = new <uint> [
			LATENCY,
			OBSTACLE,
			STALL,
			POSITION,
			BATTERY,
			TEMPERATURE
		];
		
		
		//  PUBLIC METHODS
		
		public function EmergencyFlags()
		{
		}
		
		public static function ValidateFlags ( flags:uint ) : uint
		{
			return FLAGS_ALL_SET & flags;
		}
	}
}