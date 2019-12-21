package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.arxterra.interfaces.IPilotMessageSerialize;
	
	public class Gps implements IPilotMessageSerialize
	{
		public var accuracy:Number;
		public var lat:Number;
		public var lng:Number;
		public var speed:Number;
		
		public function Gps (
			lat:Number = 0,
			lng:Number = 0,
			speed:Number = 0,
			accuracy:Number = 0
		) 
		{
			this.lat = lat;
			this.lng = lng;
			this.speed = speed;
			this.accuracy = accuracy;
		}
		
		public function toSFSObject ( ) : ISFSObject
		{
			var sfso:ISFSObject = new SFSObject ( );
			
			sfso.putDouble ( 'lt', lat );
			sfso.putDouble ( 'lg', lng );
			sfso.putFloat ( 's', speed );
			sfso.putFloat ( 'a', accuracy );
			return sfso;
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : Gps
		{
			//	var ni:NotificationInterface = new NotificationInterface();
			//	ni.notify("created");
			return new Gps (
				sfso.getDouble ( 'lt' ),
				sfso.getDouble ( 'lg' ),
				sfso.getFloat ( 's' ),
				sfso.getFloat ( 'a' )
			);
		}
	}
}