package com.arxterra.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class RoverEvent extends Event
	{
		// event type constants
		public static const ROVER_DATA:String = "roverData";
		
		// event properties
		public var roverData:ByteArray;
		
		// constructor
		public function RoverEvent(type:String, roverData:ByteArray, bubbles:Boolean = false, cancelable:Boolean = false )
		{
			super(type, bubbles, cancelable);
			this.roverData = roverData;
		}
				
		// overrides
		public override function clone ( ) : Event
		{
			return new RoverEvent ( type, this.roverData, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'RoverEvent', 'type', 'roverData', 'bubbles', 'cancelable' );
		}
	}
}