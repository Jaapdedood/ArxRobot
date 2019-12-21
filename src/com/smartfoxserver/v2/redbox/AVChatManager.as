package com.smartfoxserver.v2.redbox
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.redbox.data.ChatSession;
	import com.smartfoxserver.v2.redbox.events.RedBoxChatEvent;
	import com.smartfoxserver.v2.redbox.events.RedBoxConnectionEvent;
	import com.smartfoxserver.v2.redbox.exceptions.BadRequestException;
	import com.smartfoxserver.v2.redbox.exceptions.InvalidChatSessionIdException;
	import com.smartfoxserver.v2.redbox.exceptions.InvalidParamsException;
	import com.smartfoxserver.v2.redbox.exceptions.NoAVConnectionException;
	import com.smartfoxserver.v2.redbox.utils.Constants;
	import com.smartfoxserver.v2.redbox.utils.Logger;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.NetStream;
	
	/**
	 * SmartFoxServer 2X RedBox Audio/Video Chat Manager.
	 * This class is responsible for audio/video chat implementation by means of the connection to the Red5 server.
	 * The AVChatManager handles the chat workflow (send request, accept or refuse it, establish or stop connection, etc.) and the live streaming to/from the Red5 server.
	 * 
	 * <b>NOTE</b>: in the provided examples, {@code avChatMan} always indicates an AVChatManager instance.
	 * 
	 * @usage	The <b>AVChatManager</b> class is useful to create one-on-one audio/video chats. Three chat modes are supported: receive-only, send-only or send-and-receive.
	 * 			In send-only and receive-only modes, the a/v chat requests are distinct: a user can watch a friend without sending his own stream, and vice versa (just like in Windows Live Messenger, when you click the webcam icons near the users' pictures).
	 * 			In send-and-receive mode, a single request includes both sending the user's own stream and receiving the friend's stream.
	 * 			The following workflow is suggested (to make it simpler the send-and-receive mode is considered; for the other modes the flow is the same, but two separate requests are needed).
	 * 			<ol>
	 * 				<li>The current user click on an interface element to send the a/v chat request to a friend; usually a button in a private chat window is used.</li>
	 * 				<li>An invitation is sent to the recipient user by means of the {@link #sendChatRequest} method; of course the recipient must be connected to SmartFoxServer 2X (but not necessarily in the same Room of the requester), otherwise the {@link RedBoxChatEvent#RECIPIENT_MISSING} event is fired on the requester's client.</li>
	 * 				<li>On the recipient's client the {@link RedBoxChatEvent#CHAT_REQUEST} event is fired: an invitation to send and receive the a/v stream is displayed, together with the interface elements to accept or decline it.
	 * 				If the recipient refuses the invitation, the {@link #refuseChatRequest} method is called, which causes the {@link RedBoxChatEvent#CHAT_REFUSED} event to be fired on the requester's client and the interface to be adjusted accordingly.</li>
	 * 				<li>The recipient accepts the invitation: the {@link #acceptChatRequest} method is called, which causes the {@link RedBoxChatEvent#CHAT_STARTED} event to be fired on both the requester's and the recipient's clients.</li>
	 * 				<li>On both the requester's and the recipient's clients two Video objects are added to the stage to display the incoming stream and the user's own camera output.</li>
	 * 				<li>One of the two users involved in the chat clicks on an interface element to stop the a/v chat: the {@link #stopChat} method is called and the {@link RedBoxChatEvent#CHAT_STOPPED} event is fired on the connected user's client, so that the Video objects can be removed from stage.</li>
	 * 			</ol>
	 * 
	 * @version	1.0.0 for SmartFoxServer 2X
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class AVChatManager extends BaseAVManager
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		// Chat request types
		
		/**
		 * Audio/video chat request type: "stream from requester to recipient".
		 * The requester would like to send his own live a/v stream to the recipient.
		 * 
		 * @see	#sendChatRequest
		 */
		public static const REQ_TYPE_SEND:String = "send";
		
		/**
		 * Audio/video chat request type: "stream from recipient to requester".
		 * The requester would like to receive the recipient's live a/v stream.
		 * 
		 * @see	#sendChatRequest
		 */
		public static const REQ_TYPE_RECEIVE:String = "receive";
		
		/**
		 * Audio/video chat request type: "bi-directional stream".
		 * The requester would like to establish a mutual live a/v connection.
		 * 
		 * @see	#sendChatRequest
		 */
		public static const REQ_TYPE_SEND_RECEIVE:String = "send&rcv";
		
		// Outgoing extension commands
		private const CMD_REQUEST:String = "req";		// Send request to start an a/v chat session
		private const CMD_ACCEPT:String = "accept";		// Accept invitation to start an a/v chat session
		private const CMD_REFUSE:String = "refuse";		// Refuse invitation to start an a/v chat session
		private const CMD_STOP:String = "stop";			// Stop an a/v chat session
		
		// Incoming extension responses
		private const RES_REQUEST:String = "req";		// Incoming request to start an a/v chat session
		private const RES_START:String = "start";		// a/v chat session started
		private const RES_REFUSED:String = "refused";	// Invitation to start an a/v chat session refused
		private const RES_STOP:String = "stop";			// a/v chat session stopped
		
		// Incoming extension errors
		private const ERR_NO_RECIPIENT:String = "err_noRcp";
		private const ERR_DUPLICATE_REQUEST:String = "err_dup";
		
		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------
		
		private var chatSessions:Array;
		
		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * AVChatManager contructor.
		 * 
		 * @param	sfs:		the SmartFox API main class instance.
		 * @param	red5Ip:		the Red5 server IP address (include the port number if the default one is not used).
		 * @param	useRTMPT:	connect to Red5 server using the HTTP-tunnelled RTMP protocol (optional, default is {@code false}); Red5 must be configured accordingly.
		 * @param	debug:		turn on the debug messages (optional, default is {@code false}).
		 *
		 * @example	The following example shows how to instantiate the AVChatManager class.
		 * 			<code>
		 * 			var smartFox:SmartFox = new SmartFox();
		 * 			var red5IpAddress:String = "127.0.0.1";
		 * 			
		 * 			var avChatMan:AVChatManager = new AVChatManager(smartFox, red5IpAddress);
		 * 			</code>
		 */
		function AVChatManager(sfs:SmartFox, red5Ip:String, useRTMPT:Boolean = false, debug:Boolean = false)
		{
			super(sfs, red5Ip, useRTMPT, debug);
			
			// Initialize properties
			chatSessions = new Array();
			
			// Add SmartFoxServer event listeners
			smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onRedBoxExtensionResponse);
		}
		
		// -------------------------------------------------------
		// PUBLIC METHODS
		// -------------------------------------------------------
		
		/**
		 * Destroy the AVChatManager instance.
		 * Calling this method causes the interruption of all chat sessions currently in progress (if any) and the disconnection from Red5.
		 * This method should always be called before deleting the AVChatManager instance.
		 * 
		 * @example	The following example shows how to destroy the AVChatManager instance.
		 * 			<code>
		 * 			avChatMan.destroy();
		 * 			avChatMan = null;
		 * 			</code>
		 */
		override public function destroy():void
		{
			super.destroy();
			
			// Remove SmartFoxServer event listeners
			smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onRedBoxExtensionResponse);
			
			// Stop all streams
			if (chatSessions != null)
			{
				// Stop all sessions and close their streams
				for each (var session:ChatSession in chatSessions)
					stopChat(session.id);
				
				chatSessions = new Array();
			}
			
			// Disconnect from Red5 server
			if (netConn.connected)
				netConn.close();
			
			Logger.log("AVChatManager instance destroyed");
		}
		
		/**
		 * Retrieve a {@link ChatSession} object instance.
		 * 
		 * @param	sessionId:	the id of the chat session to be retrieved (see {@link ChatSession#id} property).
		 * 
		 * @return	The {@link ChatSession} object.
		 * 
		 * @example	The following example shows how to get a chat session.
		 * 			<code>
		 * 			var chatData:ChatSession = avChatMan.getChatSession(sessionId);
		 * 			
		 * 			if (chatData != null)
		 * 				trace (chatData.toString());
		 * 			</code>
		 * 
		 * @see		ChatSession
		 */
		public function getChatSession(sessionId:String):ChatSession
		{
			if (chatSessions != null)
				return chatSessions[sessionId];
			else
				return null;
		}
		
		/**
		 * Send a request to start an audio/video chat.
		 * When this method is called, a "chat session" is created (see the {@link ChatSession} class description) and an invitation to start the a/v chat is sent to the selected user id, causing the {@link RedBoxChatEvent#CHAT_REQUEST} event to be fired on the recipient's client.
		 * If the recipient is not available (for example he disconnects while the request is being sent), the {@link RedBoxChatEvent#RECIPIENT_MISSING} event is fired in response.
		 * If the mutual request has already been sent by the recipient, the {@link RedBoxChatEvent#DUPLICATE_REQUEST} is fired in response.
		 * Audio and video recording mode/quality should be set before calling this method. In order to alter these settings, please refer to the flash.media.Microphone and flash.media.Camera classes documentation.
		 * 
		 * @param	type:				the request type; valid values are: {@link #REQ_TYPE_SEND}, {@link #REQ_TYPE_RECEIVE} and {@link #REQ_TYPE_SEND_RECEIVE}.
		 * @param	recipientId:		the SmartFoxServer user id of the recipient.
		 * @param	enableCamera:		enable video live streaming; default value is {@code true}.
		 * @param	enableMicrophone:	enable audio live streaming; default value is {@code true}.
		 * 
		 * @return	The {@link ChatSession} object created, or {@code null} if the same request type has already been sent to the same recipient (and it's still pending or already accepted).
		 * 
		 * @sends	RedBoxChatEvent#CHAT_REQUEST
		 * @sends	RedBoxChatEvent#RECIPIENT_MISSING
		 * @sends	RedBoxChatEvent#DUPLICATE_REQUEST
		 * 
		 * @throws	NoAVConnectionException if the connection to Red5 is not available.
		 * @throws	InvalidParamsException if both <i>enableCamera</i> and <i>enableMicrophone</i> parameters are set to {@code false}.
		 * @throws	BadRequestException if the wrong request type is passed when calling this method.
		 * 
		 * @example	The following example shows how to send a request to start an a/v chat.
		 * 			<code>
		 * 			avChatMan.addEventListener(RedBoxChatEvent.RECIPIENT_MISSING, onRecipientMissing);
		 * 			avChatMan.addEventListener(RedBoxChatEvent.DUPLICATE_REQUEST, onDuplicateRequest);
		 * 			
		 * 			avChatMan.sendChatRequest(AVChatManager.REQ_TYPE_SEND_RECEIVE, buddyId, true, true);
		 * 			
		 * 			function onRecipientMissing(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace ("Request '" + evt.params.chatSession.id + "' error: the recipient is not available!");
		 * 			}
		 * 			
		 * 			function onDuplicateRequest(evt:RedBoxChatEvent):void
		 * 			{
		 * 				trace ("Request '" + evt.params.chatSession.id + "' error: a mutual request has already been sent by the recipient!");
		 * 			}
		 * 			</code>
		 * 
		 * @see		ChatSession
		 * @see		RedBoxChatEvent#CHAT_REQUEST
		 * @see		RedBoxChatEvent#RECIPIENT_MISSING
		 * @see		RedBoxChatEvent#DUPLICATE_REQUEST
		 * @see		NoAVConnectionException
		 * @see		InvalidParamsException
		 * @see		BadRequestException
		 * @see		flash.media.Camera
		 * @see		flash.media.Microphone
		 */
		public function sendChatRequest(type:String, recipientId:int, enableCamera:Boolean = true, enableMicrophone:Boolean = true):ChatSession
		{
			// If cam & mic are both null, why sending this type of request?
			if (!enableCamera && !enableMicrophone)
				throw new InvalidParamsException(Constants.ERROR_INVALID_PARAMS);
			
			// Check request type
			if (type != REQ_TYPE_SEND && type != REQ_TYPE_RECEIVE && type != REQ_TYPE_SEND_RECEIVE)
				throw new BadRequestException(Constants.ERROR_BAD_REQUEST + ": " + type);
			
			// Check Red5 connection availability
			if (!netConn.connected)
				throw new NoAVConnectionException(Constants.ERROR_NO_CONNECTION + " [sendChatRequest method]");
			
			//------------------------------
			
			// Set session id based on type, requesterId and recipientId parameters
			// NOTE: the RedBox server-side extension the same rule to validate the request id
			var id:String = type + "-" + smartFox.mySelf.id + "-" + recipientId;
			
			// Check if the same request has already been submitted; if yes, discard the new request
			if (chatSessions[id] == null)
			{
				// Create new session
				var sParams:ISFSObject = new SFSObject();
				sParams.putUtfString("id", id);
				sParams.putUtfString("type", type);
				sParams.putBool("cam", enableCamera);
				sParams.putBool("mic", enableMicrophone);
				sParams.putInt("uId", recipientId);
				
				var chatSession:ChatSession = new ChatSession(sParams, true);
				chatSession.setStatus(ChatSession.STATUS_PENDING);
				
				// Send request to RedBox extension
				sendCommand(Constants.CHAT_MANAGER_KEY, CMD_REQUEST, sParams);
				
				Logger.log("Chat request of type '" + type + "' sent to user id " + recipientId);
				
				// Add session to chat sessions' list
				chatSessions[id] = chatSession;
				
				return chatSession;
			}
			
			return null;
		}
		
		/**
		 * Refuse an incoming request to start an audio/video chat.
		 * Calling this method causes the {@link RedBoxChatEvent#CHAT_REFUSED} event to be fired on the requester's client.
		 * 
		 * @param	sessionId:	the id of the chat session request to be refused (see {@link ChatSession#id} property).
		 * 
		 * @sends	RedBoxChatEvent#CHAT_REFUSED
		 * 
		 * @throws	InvalidChatSessionIdException if the passed session id is unknown or the chat session is not in a {@link ChatSession#STATUS_PENDING} status.
		 * 
		 * @example	The following example shows how to refuse a chat request.
		 * 			<code>
		 * 			bt_decline.addEventListener(MouseEvent.CLICK, onDeclineBtClick);
		 * 			
		 * 			// After receiving a chat request, its session id is saved and a "decline" button activated...
		 * 			
		 * 			function onDeclineBtClick(evt:MouseEvent):void
		 * 			{
		 * 				avChatMan.refuseChatRequest(chatSessionId);
		 * 			}
		 * 			</code>
		 * 
		 * @see		RedBoxChatEvent#CHAT_REFUSED
		 * @see		ChatSession
		 * @see		InvalidChatSessionIdException
		 */
		public function refuseChatRequest(sessionId:String):void
		{
			var session:ChatSession = chatSessions[sessionId];
			
			// Check if passed session id is valid
			if (session == null)
				throw new InvalidChatSessionIdException(Constants.ERROR_SESSION_UNKNOWN + " [refuseChatRequest method]");
			else
			{
				if (session.status != ChatSession.STATUS_PENDING)
					throw new InvalidChatSessionIdException(Constants.ERROR_SESSION_WRONG_STATUS + " [refuseChatRequest method]");
			}
			
			//------------------------------
			
			// Send refusal to requester
			var params:ISFSObject = new SFSObject();
			params.putUtfString("id", session.id);
			
			sendCommand(Constants.CHAT_MANAGER_KEY, CMD_REFUSE, params);
			
			// Remove session
			delete chatSessions[session.id];
			
			Logger.log("Chat request refused:", session.id);
		}
		
		/**
		 * Accept an incoming request to start an audio/video chat.
		 * Calling this method causes the {@link RedBoxChatEvent#CHAT_STARTED} event to be fired on both the requester and the recipient clients.
		 * 
		 * @param	sessionId:	the id of the chat session request to be accepted (see {@link ChatSession#id} property).
		 * 
		 * @sends	RedBoxChatEvent#CHAT_STARTED
		 * 
		 * @throws	NoAVConnectionException if the connection to Red5 is not available.
		 * @throws	InvalidChatSessionIdException if the passed session id is unknown or the chat session is not in a {@link ChatSession#STATUS_PENDING} status.
		 * 
		 * @example	The following example shows how to accept a chat request.
		 * 			<code>
		 * 			bt_accept.addEventListener(MouseEvent.CLICK, onAcceptBtClick);
		 * 			
		 * 			// After receiving a chat request, its session id is saved and an "accept" button activated...
		 * 			
		 * 			function onAcceptBtClick(evt:MouseEvent):void
		 * 			{
		 * 				avChatMan.acceptChatRequest(chatSessionId);
		 * 			}
		 * 			</code>
		 * 
		 * @see		RedBoxChatEvent#CHAT_STARTED
		 * @see		ChatSession
		 * @see		NoAVConnectionException
		 * @see		InvalidChatSessionIdException
		 */
		public function acceptChatRequest(sessionId:String):void
		{
			// Check Red5 connection availability
			if (!netConn.connected)
				throw new NoAVConnectionException(Constants.ERROR_NO_CONNECTION + " [acceptChatRequest method]");
			
			var session:ChatSession = chatSessions[sessionId];
			
			// Check if passed session id is valid
			if (session == null)
				throw new InvalidChatSessionIdException(Constants.ERROR_SESSION_UNKNOWN + " [acceptChatRequest method]");
			else
			{
				if (session.status != ChatSession.STATUS_PENDING)
					throw new InvalidChatSessionIdException(Constants.ERROR_SESSION_WRONG_STATUS + " [acceptChatRequest method]");
			}
			
			//------------------------------
			
			// Set session as accepted
			session.setStatus(ChatSession.STATUS_ACCEPTED);
			
			// Send acceptance to requester
			var params:ISFSObject = new SFSObject();
			params.putUtfString("id", session.id);
			
			sendCommand(Constants.CHAT_MANAGER_KEY, CMD_ACCEPT, params);
			
			Logger.log("Chat request accepted:", session.id);
		}
		
		/**
		 * Stop an a/v chat session currently in progress.
		 * Calling this method causes the {@link RedBoxChatEvent#CHAT_STOPPED} event to be fired on the connected user (mate) clients.
		 * 
		 * @param	sessionId:	the id of the chat session to be stopped (see {@link ChatSession#id} property).
		 * 
		 * @sends	RedBoxChatEvent#CHAT_STOPPED
		 * 
		 * @example	The following example shows how to stop a chat session.
		 * 			<code>
		 * 			bt_stop.addEventListener(MouseEvent.CLICK, onStopBtClick);
		 * 			
		 * 			// After the chat session started, a "stop" button is activated...
		 * 			
		 * 			function onStopBtClick(evt:MouseEvent):void
		 * 			{
		 * 				avChatMan.stopChat(chatSessionId);
		 * 			}
		 * 			</code>
		 * 
		 * @see		RedBoxChatEvent#CHAT_STOPPED
		 * @see		ChatSession
		 */
		public function stopChat(sessionId:String):void
		{
			var session:ChatSession = chatSessions[sessionId];
			
			if (session != null)
			{
				// Close streams
				stopStreams(session);
				
				if (smartFox.isConnected)
				{
					// Send stop command
					var params:ISFSObject = new SFSObject();
					params.putUtfString("id", session.id);
					
					sendCommand(Constants.CHAT_MANAGER_KEY, CMD_STOP, params);
				}
				
				// Remove session
				delete chatSessions[session.id];
				
				Logger.log("Chat stopped:", session.id);
			}
		}
		
		// -------------------------------------------------------
		// SMARTFOXSERVER & RED5 EVENT HANDLERS
		// -------------------------------------------------------
		
		/**
		 * Handle incoming server responses.
		 * 
		 * @exclude
		 */
		public function onRedBoxExtensionResponse(evt:SFSEvent):void
		{
			var dataObj:Object = evt.params;
			var cmdArray:Array = dataObj.cmd.split(".");
			
			// Retrieve manager key from the command string to filter responses addressed to the AVChatManager only
			var managerKey:String = cmdArray[0];
			var responseKey:String = cmdArray[1];
			
			if (managerKey == Constants.CHAT_MANAGER_KEY)
			{
				Logger.log("Extension response received:", responseKey);
				
				var params:ISFSObject = evt.params.params as ISFSObject;
				
				// Chat request error
				if (responseKey == ERR_NO_RECIPIENT || responseKey == ERR_DUPLICATE_REQUEST)
					handleChatRequestError(responseKey, params);
					
					// Chat request received
				else if (responseKey == RES_REQUEST)
					handleChatRequest(params);
					
					// Chat request refused by the recipient
				else if (responseKey == RES_REFUSED)
					handleChatRequestRefused(params);
					
					// Chat startied
				else if (responseKey == RES_START)
					handleChatStarted(params);
					
					// Chat stopped
				else if (responseKey == RES_STOP)
					handleChatStopped(params);
			}
		}
		
		// -------------------------------------------------------
		// PRIVATE METHODS
		// -------------------------------------------------------
		
		override protected function handleRed5ConnectionError(errorCode:String):void
		{
			// Stop all streams
			if (chatSessions != null)
			{
				for each (var session:ChatSession in chatSessions);
				stopChat(session.id);
				
				chatSessions = new Array();
			}
		}
		
		/**
		 * Dispatch AVChatManager events.
		 */
		private function dispatchAVChatEvent(type:String, params:Object = null):void
		{
			var event:RedBoxChatEvent = new RedBoxChatEvent(type, params);
			dispatchEvent(event);
		}
		
		/**
		 * Handle a chat request error due to server-side validation.
		 */
		private function handleChatRequestError(error:String, data:ISFSObject):void
		{
			var sessionId:String = data.getUtfString("id");
			var session:ChatSession = chatSessions[sessionId];
			
			if (session != null)
			{
				// Dispatch event
				var params:Object = {};
				params.chatSession = session;
				
				var eventType:String = "";
				
				if (error == ERR_DUPLICATE_REQUEST)
					eventType = RedBoxChatEvent.DUPLICATE_REQUEST;
				else if (error == ERR_NO_RECIPIENT)
					eventType = RedBoxChatEvent.RECIPIENT_MISSING;
				
				if (eventType != "")
				{
					dispatchAVChatEvent(eventType, params);
					Logger.log("Chat request error, event dispatched");
				}
				else
					Logger.log("Unknown chat request error type!");
						
				// Remove session
				delete chatSessions[sessionId];
			}
		}
		
		/**
		 * Handle an incoming chat request.
		 */
		private function handleChatRequest(data:ISFSObject):void
		{
			// Create new chat session
			var chatSession:ChatSession = new ChatSession(data, false);
			chatSession.setStatus(ChatSession.STATUS_PENDING);
			
			// Add session to chat sessions' list
			chatSessions[chatSession.id] = chatSession;
			
			Logger.log("Chat request received -->", chatSession.toString());
			Logger.log("Session stored while waiting for acceptance or refusal; now dispatching event");
			
			// Dispatch event
			var params:Object = {};
			params.chatSession = chatSession;
			
			dispatchAVChatEvent(RedBoxChatEvent.CHAT_REQUEST, params);
		}
		
		/**
		 * Handle an incoming chat request refusal.
		 */
		private function handleChatRequestRefused(data:ISFSObject):void
		{
			// Retrieve session
			var sessionId:String = data.getUtfString("id");
			var chatSession:ChatSession = chatSessions[sessionId];
			
			if (chatSession != null)
			{
				Logger.log("Chat request refused:", chatSession.id);
				
				// Update mate name
				chatSession.setMateName(data.getUtfString("uName"));
				
				// Dispatch event
				var params:Object = {};
				params.chatSession = chatSession;
				
				dispatchAVChatEvent(RedBoxChatEvent.CHAT_REFUSED, params);
				
				// Remove pending session
				delete chatSessions[chatSession.id];
			}
		}
		
		/**
		 * Handle chat start.
		 */
		private function handleChatStarted(data:ISFSObject):void
		{
			// Retrieve session
			var sessionId:String = data.getUtfString("id");
			var chatSession:ChatSession = chatSessions[sessionId];
			
			if (chatSession != null && netConn.connected)
			{
				Logger.log("Chat started:", chatSession.id);
				
				var myStreamId:String = data.getUtfString("stream");
				var mateStreamId:String = data.getUtfString("mStream");
				
				// Publish user own stream
				var myStream:NetStream = null;
				
				if (myStreamId != null)
				{
					myStream = new NetStream(netConn);
					
					// Attach cam and mic to the stream
					if (chatSession.enableCamera)
						myStream.attachCamera(Camera.getCamera());
					
					if (chatSession.enableMicrophone)
						myStream.attachAudio(Microphone.getMicrophone());
					
					// Publish stream for broadcasting
					myStream.publish(myStreamId, Constants.BROADCAST_TYPE_LIVE);
					
					Logger.log("User' stream published");
				}
				
				// Play mate' stream
				var mateStream:NetStream = null;
				
				if (mateStreamId != null)
				{
					mateStream = new NetStream(netConn);
					mateStream.play(mateStreamId, -1);
					
					Logger.log("Mate' stream playing");
				}
				
				// Update session data
				chatSession.setStatus(ChatSession.STATUS_ACCEPTED);
				chatSession.setMateName(data.getUtfString("mName"));
				chatSession.setMyStream(myStream);
				chatSession.setMateStream(mateStream);
				
				// Dispatch event
				var params:Object = {};
				params.chatSession = chatSession;
				
				dispatchAVChatEvent(RedBoxChatEvent.CHAT_STARTED, params);
			}
		}
		
		/**
		 * Handle chat stop.
		 */
		private function handleChatStopped(data:ISFSObject):void
		{
			// Retrieve session
			var sessionId:String = data.getUtfString("id");
			var chatSession:ChatSession = chatSessions[sessionId];
			
			if (chatSession != null)
			{
				// Update session data
				if (chatSession.mateName == null)
					chatSession.setMateName(data.getUtfString("mName"));
				
				// Close streams
				stopStreams(chatSession);
				
				// Dispatch event
				var params:Object = {};
				params.chatSession = chatSession;
				
				dispatchAVChatEvent(RedBoxChatEvent.CHAT_STOPPED, params);
				
				// Remove session
				delete chatSessions[chatSession.id];
				
				Logger.log("Chat stopped:", chatSession.id);
			}
		}
		
		private function stopStreams(session:ChatSession):void
		{
			if (session.myStream != null)
			{
				session.myStream.attachCamera(null);
				session.myStream.attachAudio(null);
				session.myStream.close();
				session.setMyStream(null);
			}
			
			if (session.mateStream != null)
			{
				session.mateStream.close();
				session.setMateStream(null);
			}
		}
	}
}