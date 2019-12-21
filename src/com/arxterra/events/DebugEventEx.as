package com.arxterra.events
{
	import flash.events.Event;
	
	// Jeff Gomes
	public class DebugEventEx extends Event
	{
		// event type constants
		public static const DEBUG_OUT:String = 'debugOut';
		
		// event properties
		/**
		 * Message to display
		 */
		public var message:String = '';
		/**
		 * Indicates that the message string is to be passed to
		 * resourceManager.getString()
		 */
		public var isResource:Boolean = false;
		/**
		 * Parameters (if any) to pass to resourceManager.getString()
		 * if isResource is true
		 */
		public var resourceParams:Array;
		/**
		 * If debug mode is off, display an Alert
		 */		
		public var alertOk:Boolean = false;
		/**
		 * String (if any) to add at end of debug output
		 * (defaults to new line character)
		 */		
		public var end:String = '\n';
		
		// constructor
		/**
		 * @param type Use static constant
		 * @param message Message to display
		 * @param isResource Indicates that the message string is to be passed to
		 * resourceManager.getString()
		 * @param resourceParams Parameters (if any) to pass to resourceManager.getString()
		 * if isResource is true
		 * @param alertOk If debug mode is off, display an Alert
		 * @param end String (if any) to add at end of debug output
		 * (defaults to new line character)
		 * @param bubbles
		 * @param cancelable
		 */
		public function DebugEventEx (
			type:String,
			message:String = '',
			isResource:Boolean = false,
			resourceParams:Array = null,
			alertOk:Boolean = false,
			end:String = '\n',
			bubbles:Boolean = false,
			cancelable:Boolean = false
		)
		{
			super ( type, bubbles, cancelable );
			this.message = message;
			this.isResource = isResource;
			this.resourceParams = resourceParams;
			this.alertOk = alertOk;
			this.end = end;
		}
		
		// overrides
		public override function clone ( ) : Event
		{
			return new DebugEventEx ( type, this.message, this.isResource, this.resourceParams, this.alertOk, this.end, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'DebugEventEx', 'type', 'message', 'isResource', 'resourceParams', 'alertOk', 'end', 'bubbles', 'cancelable' );
		}
	}
}