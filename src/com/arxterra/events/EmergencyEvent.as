package com.arxterra.events
{
	import flash.events.Event;
	
	import com.arxterra.utils.FlagsUtil;
	
	import com.arxterra.vo.EmergencyFlags;

	public class EmergencyEvent extends Event
	{
		// event type constants
		public static const EMERGENCY_FLAGS_CLEAR:String = 'emergencyFlagsClear';
		public static const EMERGENCY_FLAGS_SET:String = 'emergencyFlagsSet';
		public static const EMERGENCY_FLAGS_UPDATE:String = 'emergencyFlagsUpdate';
		
		// event properties
		public var flags:uint = 0;
		public var flagsCount:int = 0;
		public var flagsVector:Vector.<uint>;
		
		// constructor
		public function EmergencyEvent ( type:String, flags:uint = 0, bubbles:Boolean = false, cancelable:Boolean = false )
		{
			super ( type, bubbles, cancelable );
			this.flags = flags;
			if ( flags == 0 )
			{
				flagsVector = new <uint> [];
			}
			else
			{
				flagsVector = FlagsUtil.ToVector ( flags, EmergencyFlags.FLAGS_SETTABLE );
				flagsCount = flagsVector.length;
			}
		}
		
		// overrides
		public override function clone ( ) : Event
		{
			return new EmergencyEvent ( type, this.flags, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'EmergencyEvent', 'type', 'flags', 'bubbles', 'cancelable' );
		}
	}
}