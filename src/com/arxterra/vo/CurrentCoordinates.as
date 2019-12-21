package com.arxterra.vo
{
	import flash.utils.ByteArray;
	
	/**
	 * Used to send current latitude/longitude to Mcu.
	 * @copy CoordinatesMessage
	 */
	// Note: Superclass implements IExternalizable.
	public class CurrentCoordinates extends CoordinatesMessage
	{
		// CONSTRUCTOR
		
		/**
		 * If do not have bytes, call static method <strong>NewFromParameters</strong>
		 * @param bytes
		 */
		public function CurrentCoordinates ( bytes:ByteArray = null )
		{
			super ( bytes );
		}
		
		
		// PUBLIC STATIC METHODS
		
		/**
		 * @param latitude
		 * @param longitude
		 */
		public static function NewFromParameters (
			lat:Number = 0,
			lng:Number = 0
		) : CurrentCoordinates
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( CURRENT_COORD );
			ba.writeDouble ( lat );
			ba.writeDouble ( lng );
			return new CurrentCoordinates ( ba );
		}
	}
}
