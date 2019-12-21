package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.utils.ByteArray;
	
	/**
	 * Used to transmit X, Y coordinates as 2-byte unsigned integers
	 * with messages such as CAMERA_VIEW_LOC.
	 * Note: Superclass implements IExternalizable.
	 */
	public class ShortXY extends McuMessage
	{
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		/**
		 * x coordinate
		 */
		public function get x ( ) : uint
		{
			_messageBytes.position = 1;
			return _messageBytes.readUnsignedShort ( );
		}
		public function set x ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes.position = 1;
			_messageBytes.writeShort ( value );
		}
		
		/**
		 * y coordinate
		 */
		public function get y ( ) : uint
		{
			_messageBytes.position = 3;
			return _messageBytes.readUnsignedShort ( );
		}
		public function set y ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes.position = 3;
			_messageBytes.writeShort ( value );
		}
		
		// CONSTRUCTOR
		
		/**
		 * Call static method <strong>newFromParameters</strong> or <strong>newFromSFSObject</strong>, as appropriate
		 * @param bytes
		 */		
		public function ShortXY ( bytes:ByteArray = null )
		{
			super ( bytes );
		}
		
		// PUBLIC STATIC METHODS
		
		public static function NewFromParameters (
			msgId:uint = CAMERA_VIEW_CLICK,
			x:uint = 0,
			y:uint = 0
		) : ShortXY
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( msgId );
			ba.writeShort ( x );
			ba.writeShort ( y );
			return new ShortXY ( ba );
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : ShortXY
		{
			return new ShortXY ( sfso.getByteArray ( 'b' ) );
		}
	}
}
