package com.arxterra.vo
{
	import com.smartfoxserver.v2.util.ConfigData;
	
	[Bindable]
	public class SfsPreset
	{
		// PUBLIC PROPERTIES AND GET/SET METHODS
		
		// blueBoxPollingRate
		public function get blueBoxPollingRate():int
		{
			return _configData.blueBoxPollingRate;
		}
		public function set blueBoxPollingRate(value:int):void
		{
			_configData.blueBoxPollingRate = value;
		}
		
		// configData
		public function get configData():ConfigData
		{
			return _configData;
		}
		
		// debug
		public function get debug():Boolean
		{
			return _configData.debug;
		}
		public function set debug(value:Boolean):void
		{
			_configData.debug = value;
		}
		
		// host
		public function get host():String
		{
			return _configData.host;
		}
		public function set host(value:String):void
		{
			_configData.host = value;
		}
		
		// httpPort
		public function get httpPort():int
		{
			return _configData.httpPort;
		}
		public function set httpPort(value:int):void
		{
			_configData.httpPort = value;
		}
		
		// httpsPort
		public function get httpsPort():int
		{
			return _configData.httpsPort;
		}
		public function set httpsPort(value:int):void
		{
			_configData.httpsPort = value;
		}
		
		// id
		public var id:String;
		
		// port
		public function get port():int
		{
			return _configData.port;
		}
		public function set port(value:int):void
		{
			_configData.port = value;
		}
		
		// udpHost
		public function get udpHost():String
		{
			return _configData.udpHost;
		}
		public function set udpHost(value:String):void
		{
			_configData.udpHost = value;
		}
		
		// udpPort
		public function get udpPort():int
		{
			return _configData.udpPort;
		}
		public function set udpPort(value:int):void
		{
			_configData.udpPort = value;
		}
		
		// useBlueBox
		public function get useBlueBox():Boolean
		{
			return _configData.useBlueBox;
		}
		public function set useBlueBox(value:Boolean):void
		{
			_configData.useBlueBox = value;
		}
		
		// zone
		public function get zone():String
		{
			return _configData.zone;
		}
		public function set zone(value:String):void
		{
			_configData.zone = value;
		}
		
		
		// PUBLIC METHODS
		
		public function SfsPreset ( id:String = '', json:Object = null )
		{
			_configData = new ConfigData ( );
			this.id = id;
			if ( json )
			{
				var i_sProp:String;
				for ( i_sProp in json )
				{
					if ( i_sProp in this )
					{
						this [ i_sProp ] = json [ i_sProp ];
					}
				}
			}
		}
		
		public function clone ( ) : SfsPreset
		{
			var prst:SfsPreset = new SfsPreset ( );
			prst.id = id;
			prst.blueBoxPollingRate = _configData.blueBoxPollingRate;
			prst.debug = _configData.debug;
			prst.host = _configData.host;
			prst.httpPort = _configData.httpPort;
			prst.httpsPort = _configData.httpsPort;
			prst.port = _configData.port;
			prst.udpHost = _configData.udpHost;
			prst.udpPort = _configData.udpPort;
			prst.useBlueBox = _configData.useBlueBox;
			prst.zone = _configData.zone;
			return prst;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _configData:ConfigData;
		
	}
}