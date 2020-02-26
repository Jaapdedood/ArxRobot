package com.arxterra.utils
{
	import flash.utils.ByteArray;
	
	public class HexStringUtil
	{
		public function HexStringUtil()
		{
		}
		
		
		// PUBLIC STATIC METHODS
		
		public static function HexNumberStringFromUintBytes ( val:uint, byteCount:uint = 1 ) : String
		{
			var ba:ByteArray = new ByteArray ( );
			if ( byteCount < 2 )
			{
				ba.writeByte ( val );
			}
			else if ( byteCount > 2 )
			{
				ba.writeUnsignedInt ( val );
			}
			else
			{
				ba.writeShort ( val );
			}
			return '0x' + HexStringFromByteArray ( ba, '' );
		}
		
		/**
		 * @param bytes ByteArray to be represented as hex string
		 * @param delimiter String to be inserted between bytes, which defaults to a single space character
		 * @return String representation of supplied ByteArray
		 */
		public static function HexStringFromByteArray ( bytes:ByteArray, delimiter:String = ' ' ) : String
		{
			var sHex:String = '';
			if ( bytes != null )
			{
				var iLim:int = bytes.length;
				if ( iLim > 0 )
				{
					var i_uByte:uint;
					i_uByte = bytes [ 0 ];
					if ( i_uByte < 0x10 )
					{
						sHex += '0';
					}
					sHex += i_uByte.toString ( 16 );
					for ( var i:int=1; i<iLim; i++ )
					{
						i_uByte = bytes [ i ];
						sHex += delimiter;
						if ( i_uByte < 0x10 )
						{
							sHex += '0';
						}
						sHex += i_uByte.toString ( 16 );
					}
				}
			}
			return sHex.toUpperCase ( );
		}
	}
}