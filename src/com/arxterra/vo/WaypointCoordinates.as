package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.utils.ByteArray;
	
	/**
	 * Used to send and store WAYPOINT_COORD or WAYPOINT_MOVE
	 * messages, which require not only latitude/longitude but
	 * also an admin ID.
	 * @copy CoordinatesMessage
	 */
	// Note: Superclass implements IExternalizable.
	public class WaypointCoordinates extends CoordinatesMessage
	{
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		/**
		 * Admin ID
		 */
		public function get adminId ( ) : uint
		{
			return getUnsignedByteAt ( 17 );
		}
		public function set adminId ( value:uint ) : void
		{
			setUnsignedByteAt ( value, 17 );
		}
		
		
		// CONSTRUCTOR
		
		/**
		 * If do not have bytes, call static method <strong>newFromParameters</strong>
		 * or <strong>newFromSFSObject</strong>, as appropriate
		 * @param bytes
		 */
		public function WaypointCoordinates ( bytes:ByteArray = null )
		{
			super ( bytes );
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function toString ( ) : String
		{
			return '{latitude: ' + latitude + ', longitude: ' + longitude + ',  adminId: ' + adminId + '}';
		}
		
		
		// PUBLIC STATIC METHODS
		
		/**
		 * @param messageId WAYPOINT_COORD or WAYPOINT_MOVE
		 * @param latitude
		 * @param longitude
		 * @param adminId If a value between 0 and 255 is not provided,
		 * a sequential one in that range will be assigned.
		 */
		public static function NewFromParameters (
			messageId:uint = WAYPOINT_COORD,
			lat:Number = 0,
			lng:Number = 0,
			adminId:int = -1
		) : WaypointCoordinates
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( messageId );
			ba.writeDouble ( lat );
			ba.writeDouble ( lng );
			ba.writeByte ( __AdminIdValidate ( adminId ) );
			return new WaypointCoordinates ( ba );
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : WaypointCoordinates
		{
			return new WaypointCoordinates ( sfso.getByteArray ( 'b' ) );
		}
		
		
		// PROTECTED METHODS
		
		/**
		 * Overrides the superclass method so that the <b>adminId</b>
		 * can be re-appended at the proper position after the customized coordinates bytes.
		 * @inheritDoc
		 */
		override protected function _messageBytesIntegerDmDegrees ( ) : ByteArray
		{
			var ba:ByteArray = super._messageBytesIntegerDmDegrees ( );
			ba.writeBytes ( _messageBytes, 17, 1 );
			return ba;
		}
		
		/**
		 * Overrides the superclass method so that the <b>adminId</b>
		 * can be re-appended at the proper position after the customized coordinates bytes.
		 * @inheritDoc
		 */
		override protected function _messageBytesSinglePrecision ( ) : ByteArray
		{
			var ba:ByteArray = super._messageBytesSinglePrecision ( );
			ba.writeBytes ( _messageBytes, 17, 1 );
			return ba;
		}
		
		
		// PRIVATE STATIC PROPERTIES
		
		private static var __uNextAdminId:uint = 0;
		
		
		// PRIVATE STATIC METHODS
		
		private static function __AdminIdValidate ( id:int ) : uint
		{
			if ( id >= 0 && id <= 255 )
			{
				return uint ( id ); // return
			}
			
			// if get here, need to assign the next ID in sequence
			var uId:uint = __uNextAdminId++;
			if ( __uNextAdminId > 255 )
			{
				__uNextAdminId = 0;
			}
			return uId;
		}
		
	}
}
