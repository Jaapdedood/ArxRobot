package com.smartfoxserver.v2.redbox
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.redbox.events.RedBoxConnectionEvent;
	import com.smartfoxserver.v2.redbox.utils.Constants;
	import com.smartfoxserver.v2.redbox.utils.Logger;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	
	/**
	 * SmartFoxServer 2X RedBox base class for Audio/Video managers.
	 * This class is responsible for all base tasks common to the RedBox managers.
	 * 
	 * @see AVChatManager
	 * @see AVClipManager
	 * @see AVCastManager
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class BaseAVManager extends EventDispatcher
	{
		protected var smartFox:SmartFox;
		protected var red5AppURL:String;
		protected var netConn:NetConnection;
		
		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * BaseAVManager contructor.
		 * 
		 * @param	sfs:		the SmartFox API main class instance.
		 * @param	red5Ip:		the Red5 server IP address (include the port number if the default one is not used).
		 * @param	useRTMPT:	connect to Red5 server using the HTTP-tunnelled RTMP protocol (optional, default is {@code false}); Red5 must be configured accordingly.
		 * @param	debug:		turn on the debug messages (optional, default is {@code false}).
		 * 
		 * @exclude
		 */
		public function BaseAVManager(sfs:SmartFox, red5Ip:String, useRTMPT:Boolean = false, debug:Boolean = false)
		{
			// Set reference to SmartFox API instance
			smartFox = sfs;
			
			// Initialize properties
			var protocol:String = (useRTMPT ? "rtmpt" : "rtmp");
			red5AppURL = protocol + "://" + red5Ip + "/" + Constants.RED5_APPLICATION;
			
			Logger.enableLog = debug;
			netConn = new NetConnection();
			
			// Add Red5 connection event listener
			netConn.addEventListener(NetStatusEvent.NET_STATUS, onRed5ConnectionStatus);
			
			// Add SmartFoxServer event listeners
			smartFox.addEventListener(SFSEvent.CONNECTION_LOST, onUserDisconnection);
			smartFox.addEventListener(SFSEvent.LOGOUT, onUserDisconnection);
			
			// Establish connection to Red5
			initAVConnection();
		}
		
		//--------------------------------------
		//  GETTERS/SETTERS
		//--------------------------------------
		
		/**
		 * The status of the connection to the Red5 server.
		 * If {@code true}, the connection to Red5 is currently available.
		 */
		public final function get isConnected():Boolean
		{
			return netConn.connected;
		}
		
		// -------------------------------------------------------
		// OVERRIDABLE METHODS
		// -------------------------------------------------------
		
		/**
		 * Initialize the audio/video connection.
		 * Calling this method causes the connection to Red5 to be established and the {@link RedBoxConnectionEvent#AV_CONNECTION_INITIALIZED} event to be fired in response.
		 * If the connection can't be established, the {@link RedBoxConnectionEvent#AV_CONNECTION_ERROR} event is fired in response.
		 * <b>NOTE</b>: this method is called automatically when the used RedBox manager is instantiated.
		 * 
		 * @sends	RedBoxConnectionEvent#AV_CONNECTION_INITIALIZED
		 * @sends	RedBoxConnectionEvent#AV_CONNECTION_ERROR
		 * 
		 * @see		#isConnected
		 * @see		RedBoxConnectionEvent#AV_CONNECTION_INITIALIZED
		 * @see		RedBoxConnectionEvent#AV_CONNECTION_ERROR
		 */
		public function initAVConnection():void
		{
			// Connect to Red5 if a connection is not yet available
			if (!netConn.connected)
			{
				netConn.connect(red5AppURL);
			}
			else
			{
				// Dispatch "onAVConnectionInited" event
				var event:RedBoxConnectionEvent = new RedBoxConnectionEvent(RedBoxConnectionEvent.AV_CONNECTION_INITIALIZED);
				dispatchEvent(event);
				
				Logger.log("Red5 connection initialized");
			}
		}
		
		/**
		 * Destroy the used RedBox manager's instance.
		 * Depending on the used manager, calling this method can cause the interruption of all the playing streams and chat sessions and the disconnection from Red5.
		 * This method should always be called before deleting the manager's instance.
		 */
		public function destroy():void
		{
			// Remove Red5 connection event listener
			netConn.removeEventListener(NetStatusEvent.NET_STATUS, onRed5ConnectionStatus);
			
			// Remove SmartFoxServer event listeners
			smartFox.removeEventListener(SFSEvent.CONNECTION_LOST, onUserDisconnection);
			smartFox.removeEventListener(SFSEvent.LOGOUT, onUserDisconnection);
			
			// NetConnection closed by the overriding method in one of the managers
		}
		
		// -------------------------------------------------------
		// SMARTFOXSERVER & RED5 EVENT HANDLERS
		// -------------------------------------------------------
		
		/**
		 * Handle user logout and disconnection events.
		 * 
		 * @exclude
		 */
		private function onUserDisconnection(evt:SFSEvent):void
		{
			// Reset AVChatManager instance
			destroy();
		}
		
		/**
		 * Handle Red5 connection status events.
		 * 
		 * @exclude
		 */
		private function onRed5ConnectionStatus(evt:NetStatusEvent):void
		{
			var code:String = evt.info.code;
			var level:String = evt.info.level;
			
			Logger.log("NetStatusEvent response received");
			Logger.log("Level: " + level, "| Code:" + code);
			
			switch (code)
			{
				case "NetConnection.Connect.Success":
					
					Logger.log("NetConnection successful");
					
					// Call the "initialize" method which will dispatch the "onAVConnectionInited" event
					initAVConnection();
					
					break
				
				case "NetConnection.Connect.Closed":
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Rejected":
				case "NetConnection.Connect.AppShutDown":
				case "NetConnection.Connect.InvalidApp":
					
					Logger.log("NetConnection error, dispatching event...")
					
					handleRed5ConnectionError(code);
					
					// Dispatch connection error event
					var params:Object = {};
					params.errorCode = code;
					
					var event:RedBoxConnectionEvent = new RedBoxConnectionEvent(RedBoxConnectionEvent.AV_CONNECTION_ERROR, params);
					dispatchEvent(event);
					
					break;
			}
		}
		
		// -------------------------------------------------------
		// PRIVATE METHODS
		// -------------------------------------------------------
		
		protected function handleRed5ConnectionError(errorCode:String):void
		{
			// TO BE OVERRIDDEN
		}
		
		/**
		 * Send command to RedBox extension.
		 */
		protected function sendCommand(managerKey:String, commandKey:String, params:ISFSObject = null):void
		{
			var cmd:String = managerKey + "." + commandKey;
			smartFox.send(new ExtensionRequest(cmd, params));
		}
	}
}