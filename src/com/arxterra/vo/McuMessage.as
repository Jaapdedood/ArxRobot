package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.utils.ByteArray;

	public class McuMessage extends MessageByteArray
	{
		// CONSTANTS
		
		//   Command (outgoing) IDs
		//											Data[0] =  CMD TYPE | Qual | Arguments
		//													bit  7654321   0    Bytes    N = 1 + bytes
		public static const MOVE:uint =					0x01; // 0000000   1     4      
		public static const CAMERA_MOVE:uint =			0x02; // 0000001   0     4 (unsigned short) pan degrees (unsigned short) tilt degrees
		public static const CAMERA_HOME:uint =			0x04; // 0000010   0     0
		public static const CAMERA_RESET:uint =			0x05; // 0000010   1     0
		public static const READ_EEPROM:uint =			0x06; // 0000011   0     3
		public static const WRITE_EEPROM:uint =			0x07; // 0000011   1     3 + b
		public static const SAFE_ROVER:uint =			0x08; // 0000100   0     0
		public static const SLEEP:uint =				0x0A; // 0000101   0     0
		public static const WAKEUP:uint =				0x0B; // 0000101   1     0
		public static const HEADLIGHT_OFF:uint =		0x0C; // 0000110   0     0
		public static const HEADLIGHT_ON:uint =			0x0D; // 0000110   1     0
		public static const COMM_SETUP:uint =			0x10; // 0001000   0     1 (unsigned byte) mode ID (see McuWatchdogModes)
		public static const PING:uint =					0x11; // 0001000   1     0
		public static const HEADING:uint =				0x12; // 0001001   0     2 (unsigned short) degrees
		public static const CURRENT_COORD:uint =		0x13; // 0001001   1     8 (float) lat (float) lon
		public static const WAYPOINT_COORD:uint =		0x14; // 0001010   0     9 (float) lat (float) lon (unsigned byte) admin ID
		public static const WAYPOINTS_OFF:uint =		0x16; // 0001011   0     0
		public static const WAYPOINTS_ON:uint =			0x17; // 0001011   1     0
		public static const WAYPOINTS_CLEAR:uint =		0x18; // 0001100   0     0
		public static const WAYPOINT_MOVE:uint =		0x19; // 0001100   1     9 (float) lat (float) lon (unsigned byte) admin ID
		public static const WAYPOINT_DELETE:uint =		0x1A; // 0001101   0     1 (unsigned byte) admin ID
		public static const CAMERA_VIEW_CLICK:uint =	0x1B; // 0001101   1     4 (unsigned short) x (unsigned short) y
		// public static const SERVO_MOVE:uint =			0x1C; // 0001110   0     1 (unsigned byte) index (unsigned short) position
		public static const CURRENT_LIMIT:uint =		0x1D; // 0001110   1     1 (unsigned byte) current limit steps N (1 <= N <= 128)
		
		//   Telemetry (incoming) IDs are constants of the utils.McuConnector class
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		/**
		 * This accesses a copy of the message byte array with any final
		 * modifications required before it is to be sent to the MCU.
		 * Use messageBytes to access a copy of the unmodified byte array.
		 * In most cases these will be the same, but this accessor is used so that subclasses
		 * can override it when necessary. For examples, see MoveProps and CoordinatesMessage.
		 */
		public function get messageBytesForMcu ( ) : ByteArray
		{
			return _messageBytesClone ( );
		}
		
		
		// CONSTRUCTOR
		
		/**
		 * If do not have bytes, call static method <strong>NewFromSFSObject</strong>
		 * @param bytes
		 */		
		public function McuMessage ( bytes:ByteArray = null )
		{
			super ( bytes );
		}
		
		
		// PUBLIC STATIC METHODS
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : McuMessage
		{
			return new McuMessage ( sfso.getByteArray ( 'b' ) );
		}
	}
}