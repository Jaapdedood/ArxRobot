package com.smartfoxserver.v2.redbox.utils
{
	/**
	 * RedBox constants.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 
	 * @exclude
	 */
	public class Constants
	{
		public static const RED5_APPLICATION:String = "SFS_RedBox";	// Red5 application to connect to, for streaming purposes
		
		public static const EXTENSION_KEY:String = "$RB";			// Required to filter extension responses coming from the RedBox extension only
		public static const CLIP_MANAGER_KEY:String = "rb_avClip";	// Required to filter extension responses addressed to the AVClipManager class only
		public static const CHAT_MANAGER_KEY:String = "rb_avChat";	// Required to filter extension responses addressed to the AVChatManager class only
		public static const CAST_MANAGER_KEY:String = "rb_avCast";	// Required to filter extension responses addressed to the AVCastManager class only
		
		public static const BROADCAST_TYPE_LIVE:String = "live";
		public static const BROADCAST_TYPE_RECORD:String = "record";
		
		public static const ERROR_INVALID_PARAMS:String = "'enableCamera' and 'enableMicrophone' parameters can't be both false";
		public static const ERROR_NO_CONNECTION:String = "Red5 connection not available";
		public static const ERROR_DELETE_NOT_ALLOWED:String = "User not allowed to delete the selected clip";
		public static const ERROR_UPDATE_NOT_ALLOWED:String = "User not allowed to update clip's properties for the selected clip";
		public static const ERROR_BAD_REQUEST:String = "Unknown request type";
		public static const ERROR_SESSION_UNKNOWN:String = "Invalid chat session id: session unknown";
		public static const ERROR_SESSION_WRONG_STATUS:String = "Invalid chat session id: session status not matching";
		public static const ERROR_NO_ROOM_JOINED:String = "A SmartFoxServer Room must be joined in order to publish a live cast";
	}
}