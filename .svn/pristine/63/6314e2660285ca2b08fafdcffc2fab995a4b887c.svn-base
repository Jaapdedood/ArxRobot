package com.smartfoxserver.v2.redbox.events
{
	import com.smartfoxserver.v2.core.SFSEvent;
	
	/**
	 * RedBoxChatEvent is the class representing all events dispatched by the RedBox's {@link AVChatManager} instance, except the connection events (see the {@link RedBoxConnectionEvent} class).
	 * The RedBoxChatEvent extends the SFSEvent class, which provides a public property called {@code params} of type {@code Object} containing event-related parameters.
	 * 
	 * @usage	Please refer to the specific events for usage examples and {@code params} object content.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class RedBoxChatEvent extends SFSEvent
	{
		/**
		 * Dispatched when a chat request is sent, but the recipient is not available.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the same {@link ChatSession} object returned by the AVChatManager instance when the {@link AVChatManager#sendChatRequest} method was called.
		 * 
		 * @example	The following example shows how to handle the "onRecipientMissing" event.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.RECIPIENT_MISSING, onRecipientMissing);
		 * 			
		 * 			avChatMan.sendChatRequest(AVChatManager.REQ_TYPE_SEND_RECEIVE, buddyId, true, true);
		 * 			
		 * 			function onRecipientMissing(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace ("Request '" + evt.params.chatSession.id + "' error: the recipient is not available!");
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#sendChatRequest
		 */
		public static const RECIPIENT_MISSING:String = "onRecipientMissing";
		
		
		/**
		 * Dispatched when a chat request is sent, but a mutual request has already been sent by the recipient.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the same {@link ChatSession} object returned by the AVChatManager instance when the {@link AVChatManager#sendChatRequest} method was called.
		 * 
		 * @example	The following example shows how to handle the "onDuplicateRequest" event.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.DUPLICATE_REQUEST, onDuplicateRequest);
		 * 			
		 * 			avChatMan.sendChatRequest(AVChatManager.REQ_TYPE_SEND_RECEIVE, buddyId, true, true);
		 * 			
		 * 			function onDuplicateRequest(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace ("Request '" + evt.params.chatSession.id + "' error: a mutual request has already been sent by the recipient!");
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#sendChatRequest
		 */
		public static const DUPLICATE_REQUEST:String = "onDuplicateRequest";
		
		
		/**
		 * Dispatched when an a/v chat request is received.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the {@link ChatSession} object created by the AVChatManager instance when the request is received.
		 * 
		 * @example	The following example shows how to handle an incoming chat request.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.CHAT_REQUEST, onChatRequest);
		 * 			
		 * 			// Another user sends a chat request...
		 * 			
		 * 			function onChatRequest(evt:RedBoxChatEvent):void
		 * 			{
		 * 				var chatData:ChatSession = evt.params.chatSession;
		 * 				
		 * 				trace ("Chat request received ->", chatData.toString());
		 * 				
		 * 				// Enable "accept" and "decline" buttons
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#sendChatRequest
		 */
		public static const CHAT_REQUEST:String = "onChatRequest";
		
		
		/**
		 * Dispatched when an a/v chat request has been refused by the recipient.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the {@link ChatSession} object created by the AVChatManager instance when the request was sent.
		 * 
		 * @example	The following example shows how to handle a chat request refusal.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.CHAT_REFUSED, onChatRefused);
		 * 			
		 * 			// The recipient refuses the chat request...
		 * 			
		 * 			function onChatRefused(evt:RedBoxChatEvent):void
		 * 			{
		 * 				var chatData:ChatSession = evt.params.chatSession;
		 * 				
		 * 				trace ("Chat request refused by user", chatData.mateName);
		 * 				
		 * 				// Show message and reset start/stop chat buttons states
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#refuseChatRequest
		 */
		public static const CHAT_REFUSED:String = "onChatRefused";
		
		
		/**
		 * Dispatched when an a/v chat session is started, after the recipient accepted the requester's invitation.
		 * This event is fired on both the requester and the recipient clients.
		 * In order to display the connected users' a/v streams, the {@link ChatSession#myStream} and {@link ChatSession#mateStream} properties should be used. These two properties are set depending on the request type and on who is the requester.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the {@link ChatSession} object created by the AVChatManager instance when the request was sent/received.
		 * 
		 * @example	The following example shows how to handle a chat starting.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.CHAT_STARTED, onChatStarted);
		 * 			
		 * 			// I'm the recipient accepting the chat request...
		 * 			avChatMan.acceptChatRequest(chatSessionId);
		 * 			
		 * 			function onChatStarted(evt:RedBoxChatEvent):void
		 * 			{
		 * 				var chatData:ChatSession = evt.params.chatSession;
		 * 				
		 * 				var myStream:NetStream = chatData.myStream;
		 * 				var mateStream:NetStream = chatData.mateStream;
		 * 				
		 * 				// Attach streams to Video objects on stage
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#acceptChatRequest
		 */
		public static const CHAT_STARTED:String = "onChatStarted";
		
		
		/**
		 * Dispatched when an a/v chat session is stopped.
		 * This event is not fired on the client of the user who stopped the chat session, but only on his/her mate's client.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	chatSession:	(<b>ChatSession</b>) the {@link ChatSession} object created by the AVChatManager instance when the request was sent/received.
		 * 
		 * @example	The following example shows how to handle a chat being stopped.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.CHAT_STOPPED, onChatStopped);
		 * 			
		 * 			avChatMan.stopChat(chatSessionId);
		 * 			
		 * 			function onChatStopped(evt:RedBoxChatEvent):void
		 * 			{
		 * 				var chatData:ChatSession = evt.params.chatSession;
		 * 				
		 * 				// Detach streams from Video objects on stage
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		AVChatManager#stopChat
		 */
		public static const CHAT_STOPPED:String = "onChatStopped";
		
		//-----------------------------------------------------------------------------------------------------
		
		
		/**
		 *	RedBoxChatEvent class constructor.
		 *
		 *	@param type: the event's type.
		 *	@param params: an object containing the event's parameters.
		 *	
		 *	@exclude
		 */
		public function RedBoxChatEvent(type:String, params:Object = null)
		{
			super(type, params);
		}
	}
}