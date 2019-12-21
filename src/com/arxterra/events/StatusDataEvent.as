package com.arxterra.events
{
	import flash.events.Event;
	import com.arxterra.vo.StatusData;
	
	public class StatusDataEvent extends Event
	{
		// event type constants
		public static const STATUS_BG_MESSAGE:String = 'status_bg_message';
		public static const STATUS_DATA_MESSAGE:String = 'status_data_message';
		
		// event properties
		public var statusData:StatusData;
		
		// constructor
		public function StatusDataEvent ( type:String, statusData:StatusData = null, bubbles:Boolean = false, cancelable:Boolean = false )
		{
			super ( type, bubbles, cancelable );
			this.statusData = statusData;
		}
		
		// overrides
		public override function clone ( ) : Event
		{
			return new StatusDataEvent ( type, this.statusData, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'StatusDataEvent', 'type', 'statusData', 'bubbles', 'cancelable' );
		}
	}
}