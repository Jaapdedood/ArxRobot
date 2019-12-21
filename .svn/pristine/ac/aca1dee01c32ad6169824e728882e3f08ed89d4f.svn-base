package com.smartfoxserver.v2.redbox.data
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.net.NetStream;
	
	/**
	 * The ChatSession class is a container for a/v chat session data.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class ChatSession
	{
		/**
		 * Chat session status: "pending".
		 * The chat request has been sent or received: waiting for acceptance or refusal.
		 * 
		 * @see	#status
		 */
		public static const STATUS_PENDING:String = "pending";
		
		/**
		 * Chat session status: "accepted".
		 * The chat request has been accepted: waiting for streaming to start.
		 * 
		 * @see	#status
		 */
		public static const STATUS_ACCEPTED:String = "accepted";
		
		/**
		 * Chat session status: "active".
		 * Chat session currently in progress.
		 * 
		 * @see	#status
		 */
		public static const STATUS_ACTIVE:String = "active";
		
		private var _id:String;
		private var _status:String;
		private var _requestType:String;
		private var _iAmRequester:Boolean;
		private var _enableCamera:Boolean;
		private var _enableMicrophone:Boolean;
		private var _myStream:NetStream;
		private var _mateId:int;
		private var _mateName:String;
		private var _mateStream:NetStream;
		
		/**
		 * The chat session id.
		 * This id should be used to identify the proper chat window when the acceptance or refusal to start an a/v chat is received.
		 * 
		 * @usage	When a user sends a request to start an a/v chat to his, usually from within a private chat window, the returned session id should be saved properly so that the window instance can be retrieved easily when the reply to that invitation is received.
		 * 			In this way it is possible to show the mate's stream (in case of invitation accepted) or a refusal message.
		 */
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * The chat session status.
		 * The following statuses are available: {@link #STATUS_PENDING}, {@link #STATUS_ACCEPTED} and {@link #STATUS_ACTIVE}.
		 */
		public function get status():String
		{
			return _status;
		}
		
		/**
		 * The a/v chat request type.
		 * This property indicates what the requester wants to achieve: send his own live stream, receive his mate's stream, or both.
		 * It can have the following values: {@link AVChatManager#REQ_TYPE_SEND}, {@link AVChatManager#REQ_TYPE_RECEIVE} or {@link AVChatManager#REQ_TYPE_SEND_RECEIVE}.
		 * The request type can be useful to make proper user interface changes when accepting an invitation to start an a/v chat.
		 * 
		 * @usage	User A sends a chat invitation to user B, of type {@link AVChatManager#REQ_TYPE_RECEIVE}: this means that user A would like to receive user B's a/v stream.
		 * 			If user B accepts the invitation, due to the request type, his own Camera output should be attached to the user interface in order to let user B know that he is transmitting a live stream to user A.
		 * 			On the contrary, if user A sends a chat invitation of type {@link AVChatManager#REQ_TYPE_SEND} (he wants to show his own live video to user B), user B doesn't need to see his own Camera output as he is not sending a stream to user A.
		 */
		public function get requestType():String
		{
			return _requestType;
		}
		
		/**
		 * A flag indicating if the current user is the requester of the a/v chat session.
		 * This property, in conjunction with the {@link #requestType} property, indicates which streams are available once the a/v chat is started (after the invitation is accepted).
		 * See the {@link RedBoxChatEvent#CHAT_STARTED} event documentation for more details.
		 */
		public function get iAmRequester():Boolean
		{
			return _iAmRequester;
		}
		
		/**
		 * A flag indicating if the video stream for the current a/v chat session is enabled.
		 * The value of this property matches the <i>enableCamera</i> parameter passed to the {@link AVChatManager#sendChatRequest} method by the a/v chat requester.
		 */
		public function get enableCamera():Boolean
		{
			return _enableCamera;
		}
		
		/**
		 * A flag indicating if the audio stream for the current a/v chat session is enabled.
		 * The value of this property matches the <i>enableMicrophone</i> parameter passed to the {@link AVChatManager#sendChatRequest} method by the a/v chat requester.
		 */
		public function get enableMicrophone():Boolean
		{
			return _enableMicrophone;
		}
		
		/**
		 * The outgoing flash.net.NetStream object of the current user.
		 * Accessing the user's outgoing stream can be useful to pause/resume the live stream. Pausing and resuming the live stream can be achieved using the <b>NetStream.attachCamera</b> method, passing {@code null} to pause and {@code Camera.getCamera()} to resume.
		 * Depending on the {@link #iAmRequester} and {@link #requestType} properties, this NetStream object could be {@code null}. See the {@link RedBoxChatEvent#CHAT_STARTED} event documentation for more details.
		 */
		public function get myStream():NetStream
		{
			return _myStream;
		}
		
		/**
		 * The SmartFoxServer's user id of the chat mate.
		 */
		public function get mateId():int
		{
			return _mateId;
		}
		
		/**
		 * The SmartFoxServer's user name of the chat mate.
		 */
		public function get mateName():String
		{
			return _mateName;
		}
		
		/**
		 * The incoming flash.net.NetStream object of the chat mate.
		 * Depending on the {@link #iAmRequester} and {@link #requestType} properties, this NetStream object could be {@code null}. See the {@link RedBoxChatEvent#CHAT_STARTED} event documentation for more details.
		 */
		public function get mateStream():NetStream
		{
			return _mateStream;
		}
		
		/**
		 * ChatSession contructor.
		 * 
		 * @exclude
		 */
		public function ChatSession(params:ISFSObject, iAmReq:Boolean)
		{
			_id = params.getUtfString("id");
			_requestType = params.getUtfString("type");
			_enableCamera = params.getBool("cam");
			_enableMicrophone = params.getBool("mic");
			_mateId = params.getInt("uId");
			_mateName = params.getUtfString("uName");
			
			_iAmRequester = iAmReq;
		}
		
		/**
		 * Set the "status" property.
		 * 
		 * @exclude
		 */
		public function setStatus(sts:String):void
		{
			_status = sts;
		}
		
		/**
		 * Set the "myStream" property.
		 * 
		 * @exclude
		 */
		public function setMyStream(stream:NetStream):void
		{
			_myStream = stream;
		}
		
		/**
		 * Set the "mateStream" property.
		 * 
		 * @exclude
		 */
		public function setMateStream(stream:NetStream):void
		{
			_mateStream = stream;
		}
		
		/**
		 * Set the "mateName" property.
		 * 
		 * @exclude
		 */
		public function setMateName(name:String):void
		{
			_mateName = name;
		}
		
		/**
		 * Trace chat session attributes (for debug purposes).
		 * 
		 * @return	A string containing the chat session's attributes.
		 */
		public function toString():String
		{
			var string:String = "";
			
			string += "CHAT SESSION: {";
			string += "ID: " + _id + ", ";
			string += "STATUS: " + _status + ", ";
			string += "REQUEST TYPE: " + _requestType + ", ";
			string += "I'M REQUESTER: " + _iAmRequester + ", ";
			string += "ENABLE CAMERA: " + _enableCamera + ", ";
			string += "ENABLE MIC: " + _enableMicrophone + ", ";
			string += "MY STREAM IS SET: " + (_myStream != null) + ", ";
			string += "MATE ID: " + _mateId + ", ";
			string += "MATE NAME: " + _mateName + ", ";
			string += "MATE STREAM IS SET: " + (_mateStream != null) + "]}";
			
			return string;
		}
	}
}