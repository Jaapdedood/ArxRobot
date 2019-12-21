package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.utils.ByteArray;
	
	/**
	 * Used with Move message to transmit requested left and right motor settings.
	 * Note: Superclass implements IExternalizable.
	 */		
	public class MoveProps extends McuMessage
	{
		// CONSTANTS
		
		private static const __SELF:Class = MoveProps;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function set bothRun ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 1 ] = value;
			_messageBytes [ 3 ] = value;
		}
		
		public function set bothSpeed ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 2 ] = value;
			_messageBytes [ 4 ] = value;
		}
		
		public function get isMoving ( ) : Boolean
		{
			return ( _messageBytes [ 1 ] < 3 || _messageBytes [ 3 ] < 3 );
		}
		
		public function get isMovingLeft ( ) : Boolean
		{
			return ( _messageBytes [ 1 ] < 3 );
		}
		
		public function get isMovingRight ( ) : Boolean
		{
			return ( _messageBytes [ 3 ] < 3 );
		}
		
		//   These should be validated elsewhere before assignment,
		//   so there should be no need to validate again here within setters.
		
		/**
		 * Left motor run state. Use MotorStates constants to supply value in range 1 to 4
		 */
		public function get leftRun ( ) : uint
		{
			return _messageBytes [ 1 ];
		}
		public function set leftRun ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 1 ] = value;
		}
		
		/**
		 * Left motor unscaled duty cycle 0 to 255
		 */
		public function get leftSpeed ( ) : uint
		{
			return _messageBytes [ 2 ];
		}
		public function set leftSpeed ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 2 ] = value;
		}
		
		override public function get messageBytesForMcu ( ) : ByteArray
		{
			var ba:ByteArray = _messageBytesClone ( );
			__fMcuMsg ( ba ); // passed by reference and modified as needed
			return ba;
		}
		
		/**
		 * Right motor run state. Use MotorStates constants to supply value in range 1 to 4
		 */
		public function get rightRun ( ) : uint
		{
			return _messageBytes [ 3 ];
		}
		public function set rightRun ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 3 ] = value;
		}
		
		/**
		 * Right motor unscaled duty cycle 0 to 255
		 */
		public function get rightSpeed ( ) : uint
		{
			return _messageBytes [ 4 ];
		}
		public function set rightSpeed ( value:uint ) : void
		{
			_messageStringClear ( );
			_messageBytes [ 4 ] = value;
		}
		
		
		// CONSTRUCTOR
		
		/**
		 * If do not have bytes, call static method <strong>NewFromParameters</strong>
		 * or <strong>NewFromSFSObject</strong>, as appropriate
		 * @param bytes
		 */
		public function MoveProps ( bytes:ByteArray = null )
		{
			super ( bytes );
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function clone ( ) : MoveProps
		{
			return new MoveProps ( _messageBytesClone ( ) );
		}
		
		
		// PUBLIC STATIC METHODS
		
		/**
		 * @param leftRun Left motor run state. Use MotorStates constants to supply value in range 1 to 4
		 * @param leftSpeed Left motor unscaled duty cycle 0 to 255
		 * @param rightRun Right motor run state. Use MotorStates constants to supply value in range 1 to 4
		 * @param rightSpeed Right motor unscaled duty cycle 0 to 255
		 */
		public static function NewFromParameters (
			leftRun:uint = 4,
			leftSpeed:uint = 0,
			rightRun:uint = 4,
			rightSpeed:uint = 0
		) : MoveProps
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( MOVE );
			ba.writeByte ( leftRun );
			ba.writeByte ( leftSpeed );
			ba.writeByte ( rightRun );
			ba.writeByte ( rightSpeed );
			return new MoveProps ( ba );
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : MoveProps
		{
			return new MoveProps ( sfso.getByteArray ( 'b' ) );
		}
		
		/**
		 * @param flipL Boolean true to reverse left motor polarity
		 * @param flipR Boolean true to reverse right motor polarity
		 * @param apply Boolean false if will call SettingsApply separately later
		 */
		public static function SetPolarityCorrections ( flipL:Boolean, flipR:Boolean, apply:Boolean = true ) : void
		{
			var bChg:Boolean = false;
			if ( flipL != __bFlipL )
			{
				bChg = true;
				__bFlipL = flipL;
			}
			if ( flipR != __bFlipR )
			{
				bChg = true;
				__bFlipR = flipR;
			}
			if ( bChg && apply )
			{
				SettingsApply ( );
			}
		}
		
		/**
		 * @param trim Number between -1 and 1
		 * @param apply Boolean false if calling SettingsApply separately later
		 * @return validated trim value
		 */
		public static function SetSteeringTrim ( trim:Number, apply:Boolean = true ) : Number
		{
			var nNew:Number;
			if ( trim > 1 )
			{
				nNew = 1;
			}
			else if ( trim < -1 )
			{
				nNew = -1;
			}
			else
			{
				nNew = trim;
			}
			if ( nNew != __nTrimRaw )
			{
				__nTrimRaw = nNew;
				if ( apply )
				{
					SettingsApply ( );
				}
			}
			return __nTrimRaw;
		}
		
		public static function SettingsApply ( ) : void
		{
			var vs:Vector.<String> = new <String> [ '__Msg' ];
			var uLen:uint = 1;
			if ( __bFlipL && __bFlipR )
			{
				// reverse both
				vs [ uLen++ ] = '_FlipB';
			}
			else if ( __bFlipL )
			{
				// reverse left
				vs [ uLen++ ] = '_FlipL';
			}
			else if (__bFlipR )
			{
				// reverse right
				vs [ uLen++ ] = '_FlipR';
			}
			__nTrimApply = 1 - __nTrimRaw * __nTrimRaw;
			if ( __nTrimRaw < 0 )
			{
				// scale left
				vs [ uLen++ ] = '_TrimL';
			}
			else if ( __nTrimRaw > 0 )
			{
				// scale right
				vs [ uLen++ ] = '_TrimR';
			}
			__fMcuMsg = __SELF [ vs.join ( '' ) ];
		}
		
		
		// PRIVATE STATIC PROPERTIES
		
		private static var __bFlipL:Boolean = false;
		private static var __bFlipR:Boolean = false;
		private static var __nTrimRaw:Number = 0;
		private static var __nTrimApply:Number = 1;
		private static var __fMcuMsg:Function = __Msg;
		
		
		// PRIVATE STATIC METHODS
		
		// change nothing
		private static function __Msg ( ba:ByteArray ) : void
		{
		}
		
		// reverse both motor polarities
		private static function __Msg_FlipB ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
			}
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
			}
		}
		
		// reverse both motor polarities and scale left
		private static function __Msg_FlipB_TrimL ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
				// scale left
				ba [ 2 ] = Math.round ( __nTrimApply * ba [ 2 ] );
			}
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
			}
		}
		
		// reverse both motor polarities and scale right
		private static function __Msg_FlipB_TrimR ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
			}
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
				// scale right
				ba [ 4 ] = Math.round ( __nTrimApply * ba [ 4 ] );
			}
		}
		
		// reverse left motor polarity
		private static function __Msg_FlipL ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
			}
		}
		
		// reverse left motor polarity and scale left
		private static function __Msg_FlipL_TrimL ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
				// scale left
				ba [ 2 ] = Math.round ( __nTrimApply * ba [ 2 ] );
			}
		}
		
		// reverse left motor polarity and scale right
		private static function __Msg_FlipL_TrimR ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 1 ];
			if ( uState < 3 )
			{
				// reverse left
				ba [ 1 ] = 3 - uState;
			}
			if ( ba [ 3 ] < 3 )
			{
				// scale right
				ba [ 4 ] = Math.round ( __nTrimApply * ba [ 4 ] );
			}
		}
		
		// reverse right motor polarity
		private static function __Msg_FlipR ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
			}
		}
		
		// reverse right motor polarity and scale left
		private static function __Msg_FlipR_TrimL ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
			}
			if ( ba [ 1 ] < 3 )
			{
				// scale left
				ba [ 2 ] = Math.round ( __nTrimApply * ba [ 2 ] );
			}
		}
		
		// reverse right motor polarity and scale right
		private static function __Msg_FlipR_TrimR ( ba:ByteArray ) : void
		{
			var uState:uint;
			uState = ba [ 3 ];
			if ( uState < 3 )
			{
				// reverse right
				ba [ 3 ] = 3 - uState;
				// scale right
				ba [ 4 ] = Math.round ( __nTrimApply * ba [ 4 ] );
			}
		}
		
		// scale left
		private static function __Msg_TrimL ( ba:ByteArray ) : void
		{
			if ( ba [ 1 ] < 3 )
			{
				// scale left
				ba [ 2 ] = Math.round ( __nTrimApply * ba [ 2 ] );
			}
		}
		
		// scale right
		private static function __Msg_TrimR ( ba:ByteArray ) : void
		{
			if ( ba [ 3 ] < 3 )
			{
				// scale right
				ba [ 4 ] = Math.round ( __nTrimApply * ba [ 4 ] );
			}
		}
		
	}
}