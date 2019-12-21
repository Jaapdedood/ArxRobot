package com.arxterra.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class DebugByteArrayEvent extends Event
	{
		// event type constants
		public static const DEBUG_BYTE_ARRAY:String = 'debug_byte_array';
		
		// event properties
		/**
		 * String to be passed to resourceManager.getString()
		 */
		public var messageResource:String = '';
		
		public var bytes:ByteArray;
		
		// constructor
		public function DebugByteArrayEvent ( type:String, messageResource:String, bytes:ByteArray, bubbles:Boolean = false, cancelable:Boolean = false )
		{
			super ( type, bubbles, cancelable );
			this.messageResource = messageResource;
			this.bytes = bytes;
		}
		
		// overrides
		public override function clone ( ) : Event
		{
			return new DebugByteArrayEvent ( type, this.messageResource, this.bytes, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'DebugByteArrayEvent', 'type', 'messageResource', 'bytes', 'bubbles', 'cancelable' );
		}
	}
}