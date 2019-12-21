package com.smartfoxserver.v2.redbox.data
{
	import flash.net.NetStream;
	
	/**
	 * The LiveCast class is a container for a/v live cast data.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class LiveCast
	{
		private var _id:String;
		private var _userId:int;
		private var _username:String;
		private var _stream:NetStream;
		
		/**
		 * The live cast id.
		 */
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * The id of the live cast owner.
		 * This property contains the SmartFoxServer's user id of the user who is transmitting the live a/v cast.
		 */
		public function get userId():int
		{
			return _userId;
		}
		
		/**
		 * The username of the live cast owner.
		 * This property contains the SmartFoxServer's user name of the user who is transmitting the live a/v cast.
		 */
		public function get username():String
		{
			return _username;
		}
		
		/**
		 * The incoming flash.net.NetStream object of the live a/v cast.
		 * This property is available only after the {@AVCastManager#subscribeLiveCast} method is called.
		 */
		public function get stream():NetStream
		{
			return _stream;
		}
		
		/**
		 * LiveCast contructor.
		 * 
		 * @exclude
		 */
		public function LiveCast(params:Object)
		{
			_id = params.id;
			_userId = params.uId;
			_username = params.uName;
		}
		
		/**
		 * Set the "stream" property.
		 * 
		 * @exclude
		 */
		public function setStream(__stream:NetStream):void
		{
			_stream = __stream;
		}
		
		/**
		 * Trace live cast attributes (for debug purposes).
		 * 
		 * @return	A string containing the live cast attributes.
		 */
		public function toString():String
		{
			var string:String = "";
			
			string += "LIVE CAST: {";
			string += "ID: " + _id + ", ";
			string += "USER ID: " + _userId + ", ";
			string += "USER NAME: " + _username + ", ";
			string += "USER STREAM IS SET: " + (_stream != null) + "]}";
			
			return string;
		}
	}
}