package com.smartfoxserver.v2.redbox.data
{
	/**
	 * The Clip class is a container for a/v clip data.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class Clip
	{
		private var _id:String;
		private var _username:String;
		private var _properties:Object;
		private var _rtmpURL:String;
		private var _size:int;
		private var _lastModified:String;
		
		/**
		 * The clip id.
		 * It corresponds to the .flv and .data files names, without the extension.
		 */
		public function get id():String
		{
			return _id;
		}
		
		/**
		 * The clip owner.
		 * This property contains the name of the user who submitted the clip.
		 * NOTE: only the clip owner can delete or update a clip.
		 */
		public function get username():String
		{
			return _username;
		}
		
		/**
		 * The properties associated with the clip.
		 * This object contains all the properties retrieved from the .prop file which accompanies the .flv file; only the "username" property is excluded, as it is explicitly declared.
		 * NOTE: the RedBox server-side extension considers valid .flv files only those which are accompanied by a .prop file, even if it's empty.
		 */
		public function get properties():Object
		{
			return _properties;
		}
		
		/**
		 * The full RMTP url of the clip.
		 * The RMTP url can be used with specific client-side video components like the Flex VideoDisplay control.
		 */
		public function get rtmpURL():String
		{
			return _rtmpURL;
		}
		
		/**
		 * The size in bytes of the clip.
		 */
		public function get size():int
		{
			return _size;
		}
		
		/**
		 * The date in which the clip was last modified.
		 * The default date format is "dd/MM/yyyy hh:mm:ss"; it can be modified in the server-side <i>redbox.properties</i> file.
		 */
		public function get lastModified():String
		{
			return _lastModified;
		}
		
		/**
		 * Clip contructor.
		 * 
		 * @exclude
		 */
		public function Clip(params:Object)
		{
			_id = params.id;
			_username = params.username;
			_properties = params.properties;
			_rtmpURL = params.rtmpURL;
			_size = params.size;
			_lastModified = params.lastModified;
		}
		
		/**
		 * Overwrite current clip properties (for update purposes).
		 * 
		 * @exclude
		 */
		public function setProperties(__properties:Object):void
		{
			_properties = __properties;
		}
		
		/**
		 * Trace clip attributes (for debug purposes).
		 * 
		 * @return	A string containing the clip's attributes.
		 */
		public function toString():String
		{
			var string:String = "";
			
			string += "CLIP: {";
			string += "ID: " + _id + ", ";
			string += "USERNAME: " + _username + ", ";
			string += "RTMP URL: " + _rtmpURL + ", ";
			string += "SIZE: " + _size + ", ";
			string += "LAST MODIFIED: " + _lastModified + ", ";
			string += "PROPERTIES: [";
			
			for (var s:String in _properties)
				string += s + ": " + _properties[s] + ", ";
			
			string = string.substr(0, string.length - 2);
			string += "]}";
			
			return string;
		}
	}
}