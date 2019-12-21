package com.smartfoxserver.v2.redbox.events
{
	import com.smartfoxserver.v2.core.SFSEvent;
	
	/**
	 * RedBoxConnectionEvent is the class representing all connection-related events dispatched by the RedBox managers ({@link AVChatManager}, {@link AVCastManager} and {@link AVClipManager}).
	 * The RedBoxConnectionEvent extends the SFSEvent class, which provides a public property called {@code params} of type {@code Object} containing event-related parameters.
	 * 
	 * @usage	Please refer to the specific events for usage examples and {@code params} object content.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class RedBoxConnectionEvent extends SFSEvent
	{
		/**
		 * Dispatched when the connection to Red5 server has been established.
		 * This event is dispatched after the used RedBox manager is instantiated, or when its <em>initAVConnection</em> method is called.
		 * The connection to Red5 must be available before any method related to a/v streaming is called.
		 * 
		 * No parameters are provided.
		 * 
		 * @example	The following example shows how to handle the "onAVConnectionInited" event.
		 * 			<code>
		 * 			var red5IpAddress:String = "127.0.0.1";
		 * 			var avChatMan:AVChatManager = new AVChatManager(smartFox, red5IpAddress);
		 * 			
		 * 			avChatMan.addEventListener(RedBoxChatEvent.AV_CONNECTION_INITIALIZED, onAVConnectionInited);
		 * 			
		 * 			function onAVConnectionInited(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace("Connection to Red5 established");
		 * 			}
		 * 			</code>
		 */
		public static const AV_CONNECTION_INITIALIZED:String = "onAVConnectionInited";
		
		
		/**
		 * Dispatched when the connection to Red5 server can't be established.
		 * This event is dispatched when an error or special condition (like "connection closed") occurred in the flash.net.NetConnection object used internally by the used RedBox manager to handle the connection to Red5.
		 * This kind of error is always related to the Red5 server connection, so you should check if the server is running and reachable.
		 * Also check the Red5 logs or console output for more details.
		 * NOTE: when a connection error occurs, all the existing chat sessions (whatever their status is) are stopped.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	errorCode:	(<b>String</b>) the description of the error condition; check the "code" property of the NetStatusEvent.info object in the ActionScript 3 Language Reference.
		 * 
		 * @example	The following example shows how to handle a Red5 connection error.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.AV_CONNECTION_ERROR, onAVConnectionError);
		 * 			
		 * 			function onAVConnectionError(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace("A connection error occurred: " + evt.params.errorCode);
		 * 			}
		 * 			</code>
		 */
		public static const AV_CONNECTION_ERROR:String = "onAVConnectionError";
		
		//-----------------------------------------------------------------------------------------------------
		
		
		/**
		 *	RedBoxChatEvent class constructor.
		 *
		 *	@param type: the event's type.
		 *	@param params: an object containing the event's parameters.
		 *	
		 *	@exclude
		 */
		public function RedBoxConnectionEvent(type:String, params:Object = null)
		{
			super(type, params);
		}
	}
}