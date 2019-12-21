package com.arxterra.events
{
	import flash.events.Event;
	import com.arxterra.vo.MessageData;
	
	public class MessageDataEvent extends Event
	{
		// event type constants
		public static const CONTROL_MESSAGE:String = 'control_message';
		
		// event properties
		public var messageData:MessageData;
		
		// constructor
		public function MessageDataEvent ( type:String, messageData:MessageData, bubbles:Boolean = false, cancelable:Boolean = false )
		{
			super ( type, bubbles, cancelable );
			this.messageData = messageData;
		}
		
		// overrides
		public override function clone ( ) : Event
		{
			return new MessageDataEvent ( type, this.messageData, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'MessageDataEvent', 'type', 'messageData', 'bubbles', 'cancelable' );
		}
	}
}