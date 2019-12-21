package com.arxterra.utils
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import com.arxterra.events.TelemetryEvent;
	import com.arxterra.events.UtilityEvent;
	
	import com.arxterra.interfaces.IMcuConnector;
	
	import com.arxterra.vo.McuConnectModes;
	import com.arxterra.vo.McuMessage;
	import com.arxterra.controllers.SessionManager;
	import com.arxterra.vo.McuWatchdogModes;
	import com.arxterra.vo.UserState;
	
	[Event(name="mcu_mode_changed", type="flash.events.Event")]
	[Event(name="mcu_connection_changed", type="flash.events.Event")]
	
	[Event(name="packet_payloads", type="com.arxterra.events.TelemetryEvent")]
	[Event(name="mcu_connected", type="com.arxterra.events.UtilityEvent")]
	[Event(name="mcu_disconnected", type="com.arxterra.events.UtilityEvent")]
	
	/**
	 * Base class for serial connection to exchange
	 * byte arrays with Mcu. Must be extended by subclasses
	 * specific to the various connection modes, such as
	 * Bluetooth, Bluetooth LE, USB Microbridge, and USB Android as Host.
	 */
	[Bindable]
	public class McuConnectorBase extends NonUIComponentBase implements IMcuConnector
	{
		// PUBLIC CONSTANTS
		
		//   Events
		
		public static const MCU_CONNECTION_CHANGED:String = 'mcu_connection_changed';
		public static const MCU_MODE_CHANGED:String = 'mcu_mode_changed';
		
		//   Packet IDs
		public static const COMMAND_PACKET_ID:uint =	0xA5;
		public static const TELEMETRY_PACKET_ID:uint =	0xCA;
		
		//   Command (outgoing) IDs are constants of the vo.McuMessage class
		
		//   Telemetry (incoming) IDs
		public static const MOTOR1_CURRENT_ID:uint =	0x01; // motor 1 is left motor
		public static const MOTOR2_CURRENT_ID:uint =	0x02; // motor 2 is right motor
		public static const TEMP_SENSOR_ID:uint =		0x03; // temperature sensor
		public static const RANGE_LEFT_ID:uint =		0x04; // ultrasonic range 1 is left
		public static const RANGE_RIGHT_ID:uint =		0x05; // ultrasonic range 2 is right
		public static const CLEAN_BATTERY_ID:uint =		0x06; // Mcu battery
		public static const DIRTY_BATTERY_ID:uint =		0x07; // motors and servos battery 
		public static const PAN_POSITION_ID:uint =		0x08; // camera view pan position
		public static const TILT_POSITION_ID:uint =		0x09; // camera view tilt position
		public static const EEPROM_RESPONSE_ID:uint =	0x0A; // sent in response to EEPROM Read Command
		public static const EMERGENCY_ID:uint =			0x0B;
		public static const COMMAND_DUMP_ID:uint =		0x0D;
		public static const EXCEPTION_ID:uint =			0x0E;
		public static const PONG_ID:uint =				0x11; // no argument bytes
		public static const ROUTE_STATUS_ID:uint =		0x12; // 1 argument byte for status code
		public static const WAYPOINT_ARRIVE_ID:uint =	0x13; // 1 argument byte for admin ID
		public static const CURRENT_LIMIT_ID:uint =		0x1D; // 1 (unsigned byte) current limit steps N (1 <= N <= 128)
		
		
		// PRIVATE CONSTANTS
		
		private static const _ERR_START:String =		'1'; // error_mcu_telem_pkt_1	Telemetry packet exception 0x01: start byte 0xCA expected [{0}]
		private static const _ERR_LENGTH:String =		'2'; // error_mcu_telem_pkt_2	Telemetry packet exception 0x02: payload length out of range 1 - 20 [{0}]
		private static const _ERR_CHECKSUM:String =		'3'; // error_mcu_telem_pkt_3	Telemetry packet exception 0x03: LPC checksum error [{0}]
		private static const _ERR_UNDEFINED:String =	'4'; // error_mcu_telem_pkt_4	Telemetry packet exception 0x04: undefined decoder FSM state [{0}]
		private static const _ERR_OVERFLOW:String =		'5'; // error_mcu_telem_pkt_5	Telemetry packet exception 0x05: potential data buffer overflow [{0}]
		
		private static const _FSM_START:uint =		0;
		private static const _FSM_LENGTH:uint =		1;
		private static const _FSM_PAYLOAD:uint =	2;
		private static const _FSM_CHECKSUM:uint =	3;
		private static const _FSM_EXCEPTION:uint =	4;
		
		private static const _DISCONNECT_ASSUMED_MS:uint = 5000;
		private static const _PING_PAD_MCU_MS:uint = 500;
		private static const _PONG_OVERDUE_MS:uint = 1000;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function McuConnectorBase()
		{
			super ( );
			init ( );
		}
		
		/**
		 * Overrides must call super.dismiss().
		 */
		override public function dismiss ( ) : void
		{
			_tmrQueueIn.stop ( );
			_tmrQueueIn.removeEventListener ( TimerEvent.TIMER, _TelemetryInputQueueService );
			_tmrQueueIn = null;
			_tmrQueueOut.stop ( );
			_tmrQueueOut.removeEventListener ( TimerEvent.TIMER, _TelemetryOutputQueueService );
			_tmrQueueOut = null;
			_baIn.clear ( );
			_baIn = null;
			_baPayload.clear ( );
			_baPayload = null;
			var i_ba:ByteArray;
			for ( var i:int = _uOutLen; i>0; i-- )
			{
				i_ba = _vbaOut.pop ( );
				i_ba.clear ( );
				i_ba = null;
			}
			_vbaOut = null;
			_uOutLen = 0;
			_sessionMgr = null;
			super.dismiss ( );
		}
		
		/**
		 * Called automatically during instantiation,
		 * but may also be called manually to reactivate
		 * if object was previously dismissed.
		 * Overrides must call super.init().
		 */
		public function init ( ) : void
		{
			_sessionMgr = SessionManager.instance;
			_baIn = new ByteArray ( );
			_baPayload = new ByteArray ( );
			_vbaOut = new <ByteArray> [ ];
			_uOutLen = 0;
			_tmrQueueIn = new Timer ( 20, 0 ); // 20ms is shortest interval considered safe in AS3 docs
			_tmrQueueIn.addEventListener ( TimerEvent.TIMER, _TelemetryInputQueueService );
			_tmrQueueOut = new Timer ( 20, 0 ); // 20ms is shortest interval considered safe in AS3 docs
			_tmrQueueOut.addEventListener ( TimerEvent.TIMER, _TelemetryOutputQueueService );
			watchdogModeApply ( );
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="mcu_mode_changed")]
		final public function get isBLE():Boolean
		{
			return ( _uMode == McuConnectModes.BLE );
		}
		
		[Bindable (event="mcu_mode_changed")]
		final public function get isBluetooth():Boolean
		{
			return ( _uMode == McuConnectModes.BLUETOOTH );
		}
		
		/**
		 * Boolean true if device is currently connected,
		 * false otherwise
		 */
		[Bindable (event="mcu_connection_changed")]
		public function get isConnected ( ) : Boolean
		{
			return _bConnected;
		}
		protected function _isConnectedSet ( value:Boolean ) : void
		{
			if ( value == _bConnected )
				return;
			
			_bConnected = value;
			
			if ( value )
			{
				// comm setup
				_WatchdogSetup ( );
				// start pinging (if applicable)
				_PingEnable ( );
				dispatchEvent ( new UtilityEvent ( UtilityEvent.MCU_CONNECTED ) );
			}
			else
			{
				// stop pinging (if applicable)
				_PingDisable ( );
				dispatchEvent ( new UtilityEvent ( UtilityEvent.MCU_DISCONNECTED ) );
			}
			dispatchEvent ( new Event ( MCU_CONNECTION_CHANGED ) );
		}
		
		[Bindable (event="mcu_mode_changed")]
		final public function get isWireless():Boolean
		{
			return ( _uMode == McuConnectModes.BLE || _uMode == McuConnectModes.BLUETOOTH );
		}
		
		[Bindable (event="mcu_mode_changed")]
		final public function get mode():uint
		{
			return _uMode;
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Wraps Command ByteArray data in command packet and sends to Mcu.
		 * @param bytes Command data to send to Mcu.
		 * @return true if connected or unknown status,
		 * false if known not to be connected.
		 */
		final public function sendCommand ( bytes:ByteArray ) : Boolean
		{
			if ( _send ( _commandPacketFromByteArray ( bytes ) ) )
			{
				
				return true;
			}
			return false;
		}
		
		/**
		 * Wraps single byte command ID in command packet and sends to Mcu.
		 * @param id uint representation of byte value to be sent to Mcu.
		 * @return true if connected or unknown status,
		 * false if known not to be connected.
		 */		
		final public function sendCommandId ( id:int ) : Boolean
		{
			if ( _send ( _commandPacketFromId ( id ) ) )
			{
				
				return true;
			}
			return false;
		}
		
		public function watchdogModeApply ( ) : void
		{
			_uWatchdogModeId = _sessionMgr.userState.mcuWatchdogModeId;
			_bMcuWatchdogOn = ( _uWatchdogModeId != McuWatchdogModes.OFF );
			_uPingSendMs = McuWatchdogModes.GetModeMsecsById ( _uWatchdogModeId ) - _PING_PAD_MCU_MS;
			if ( isConnected )
			{
				_WatchdogSetup ( );
				_PingEnable ( );
			}
		}
		
		
		// PROTECTED PROPERTIES
		
		protected var _sessionMgr:SessionManager;
		
		// PROTECTED METHODS
		
		/**
		 * Wraps command ByteArray payload in command packet and returns the resulting ByteArray.
		 * @param bytes ByteArray command payload to be converted to command packet.
		 */		
		final protected function _commandPacketFromByteArray ( bytes:ByteArray ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			var i:int;
			var iLen:int = bytes.length;
			var iCheckSum:int = COMMAND_PACKET_ID ^ iLen;
			ba.writeByte ( COMMAND_PACKET_ID );
			ba.writeByte ( iLen );
			ba.writeBytes ( bytes );
			for ( i=0; i<iLen; i++ )
			{
				iCheckSum ^= bytes [ i ];
			}
			ba.writeByte ( iCheckSum );
			return ba;
		}
		
		/**
		 * Wraps single byte command ID in command packet and returns the resulting ByteArray.
		 * @param id uint representation of byte value to be converted to command packet.
		 */		
		final protected function _commandPacketFromId ( id:int ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( COMMAND_PACKET_ID );
			ba.writeByte ( 1 );
			ba.writeByte ( id );
			ba.writeByte ( COMMAND_PACKET_ID ^ 1 ^ id );
			return ba;
		}
		
		final protected function _modeSet ( value:uint ) : void
		{
			if ( value !== _uMode )
			{
				_uMode = value;
				dispatchEvent ( new Event ( MCU_MODE_CHANGED ) );
			}
		}
		
		/**
		 * Subclass must BOTH override this
		 * to implement sending of command packet as required by
		 * the specific type of connection AND
		 * call super._send ( bytes ) to trigger ping status check.
		 * @param bytes ByteArray command packet
		 * @return true if connected or unknown status,
		 * false if known not to be connected.
		 */
		protected function _send ( bytes:ByteArray ) : Boolean
		{
			_fPingCheck ( 1 );
			return false;
		}
		
		// all messages from Mcu come through here
		final protected function _telemetryInputQueuePush ( ba:ByteArray ) : void
		{
			// ##### TESTING #####
			if ( _sessionMgr.testCfgMcuDtlTrace )
			{
				_debugByteArrayOut ( 'mcu_data_in', ba );
			}
			// ###################
			
			_isConnectedSet ( true );
			
			// add to decoding queue
			_baIn.writeBytes ( ba );
			
			// start decoding queue service timer, if not already running
			_tmrQueueIn.start ( );
			
			_fPingCheck ( 2 );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _baIn:ByteArray;
		private var _baPayload:ByteArray;
		private var _baPingPacket:ByteArray;
		private var _bConnected:Boolean = false;
		private var _bMcuWatchdogOn:Boolean;
		private var _fPingCheck:Function = _NoOp;
		// private var _iLastInMarkMs:int = 0;
		private var _iPingMarkMs:int = 0;
		private var _tmrPingSend:Timer;
		private var _tmrPongOverdue:Timer;
		private var _tmrQueueIn:Timer;
		private var _tmrQueueOut:Timer;
		private var _uCheckSum:uint = 0;
		private var _uLength:uint = 0;
		private var _uMode:uint = McuConnectModes.NA; // default to unknown
		private var _uOutLen:uint = 0;
		private var _uPingFlags:uint = 0;
		private var _uPingSendMs:uint;
		private var _uState:uint = _FSM_START;
		private var _uWatchdogModeId:uint;
		private var _vbaOut:Vector.<ByteArray>;
		
		
		// PRIVATE METHODS
		
		private function _NoOp ( ... args ) : void { }
		
		// flags
		// 1 = send
		// 2 = receive
		// extend ping timer after both have occurred
		private function _PingCheck ( flag:uint ) : void
		{
			_uPingFlags |= flag;
			if ( _uPingFlags < 3 )
			{
				return;
			}
			_uPingFlags = 0;
			_tmrPingSend.reset ( );
			_tmrPingSend.start ( );
		}
		
		private function _PingDisable ( ) : void
		{
			_fPingCheck = _NoOp;
			if ( _tmrPingSend )
			{
				_tmrPingSend.stop ( );
				_tmrPingSend.removeEventListener ( TimerEvent.TIMER, _PingSend );
				_tmrPingSend = null;
			}
			if ( _tmrPongOverdue )
			{
				_tmrPongOverdue.stop ( );
				_tmrPongOverdue.removeEventListener ( TimerEvent.TIMER, _PongOverdue );
				_tmrPongOverdue = null;
			}
			_baPingPacket.clear ( );
			_baPingPacket = null;
		}
		
		private function _PingEnable ( ) : void
		{
			if ( _bMcuWatchdogOn )
			{
				_fPingCheck = _PingCheck;
				_uPingFlags = 0;
				if ( !_baPingPacket )
				{
					_baPingPacket = _commandPacketFromId ( McuMessage.PING );
				}
				if ( _tmrPingSend )
				{
					_tmrPingSend.reset ( );
					_tmrPingSend.delay = _uPingSendMs;
				}
				else
				{
					_tmrPingSend = new Timer ( _uPingSendMs, 0 );
					_tmrPingSend.addEventListener ( TimerEvent.TIMER, _PingSend );
				}
				if ( _tmrPongOverdue )
				{
					_tmrPongOverdue.reset ( );
				}
				else
				{
					_tmrPongOverdue = new Timer ( _PONG_OVERDUE_MS, 1 );
					_tmrPongOverdue.addEventListener ( TimerEvent.TIMER, _PongOverdue );
				}
				// have already sent Watchdog Setup already should have been sent, so expecting a Pong
				_iPingMarkMs = getTimer ( );
				_tmrPongOverdue.start ( );
				_tmrPingSend.start ( );
			}
			else
			{
				_PingDisable ( );
			}
		}
		
		private function _PingSend ( event:TimerEvent = null ) : void
		{
			_send ( _baPingPacket );
			_iPingMarkMs = getTimer ( );
			_tmrPongOverdue.start ( );
		}
		
		private function _PongOverdue ( event:TimerEvent ) : void
		{
			// problem with connection
			_tmrPongOverdue.reset ( );
			
			// for now, just check if total time since any
			// incoming message is long enough to assume
			// we are probably disconnected
			/*
			if ( getTimer ( ) - _iLastInMarkMs > _DISCONNECT_ASSUMED_MS )
			{
				_isConnectedSet ( false );
			}
			*/
			
			_debugOut ( 'error_mcu_pong_overdue', true );
			// what can we do if not disconnected completely,
			// but having latency issues?
			// ##### TODO
		}
		
		private function _PongReceived ( ) : void
		{
			if ( !_tmrPongOverdue )
				return;
			
			if ( _tmrPongOverdue.running )
			{
				// all is well
				_tmrPongOverdue.reset ( );
			}
			else
			{
				// was overdue, so report how long it took Pong to arrive
				_debugOut ( 'status_mcu_pong_ms', true, [ getTimer ( ) - _iPingMarkMs ] );
			}
		}
		
		
		private function _TelemetryInputQueueService ( event:TimerEvent = null ) : void
		{
			_tmrQueueIn.stop ( );
			_baIn.position = 0;
			
			// FSM
			var uNextState:uint;
			var i_uByte:uint;
			
			function errorReset ( sErr:String, uByte:uint ) : void
			{
				var sHexDec:String = '0x';
				if ( uByte < 0x10 )
					sHexDec += '0';
				sHexDec += uByte.toString ( 16 ).toUpperCase ( ) + ' (' + uByte.toString() + ')';
				
				_debugOut ( 'error_mcu_telem_pkt_' + sErr, true, [ sHexDec ] );
				
				_baPayload.clear ( );
				_uCheckSum = 0;
				uNextState = _FSM_EXCEPTION;
			}
			
			// out of bounds check
			if ( _baPayload.length > 22 )
			{
				errorReset ( _ERR_OVERFLOW, _baPayload [ 22 ] );
				_uState = _FSM_EXCEPTION;
			}
			
			// FSM loop
			while ( _baIn.bytesAvailable > 0 )
			{
				i_uByte = _baIn.readUnsignedByte ( );
				_uCheckSum ^= i_uByte;
				
				switch ( _uState )
				{
					case _FSM_PAYLOAD:
						// should hit this one more often than any other, so deal with it first
						_baPayload.writeByte ( i_uByte );
						if ( _baPayload.length < _uLength )
						{
							// still accumulating payload bytes
							uNextState = _FSM_PAYLOAD;
						}
						else
						{
							// done with payload and ready to check the lpc
							uNextState = _FSM_CHECKSUM;
						}
						break;
					case _FSM_START:
						if ( i_uByte == TELEMETRY_PACKET_ID )
						{
							// found expected start ID, so look for length byte next
							uNextState = _FSM_LENGTH;
						}
						else
						{
							// not the expected start byte
							errorReset ( _ERR_START, i_uByte );
						}
						break;
					case _FSM_LENGTH:
						_uLength = i_uByte;
						if ( 0 < _uLength && _uLength <= 20 )
						{
							// length value is in range, so start reading payload
							uNextState = _FSM_PAYLOAD;
						}
						else
						{
							// length byte out of range
							errorReset ( _ERR_LENGTH, _uLength );
						}
						break;
					case _FSM_CHECKSUM:
						if ( _uCheckSum == 0 )
						{
							// packet is complete, with valid lpc
							if ( _baPayload [ 0 ] == PONG_ID )
							{
								// handle pong here
								_PongReceived ( );
							}
							else
							{
								// queue the payload for output
								var ba:ByteArray = new ByteArray ( );
								ba.writeBytes ( _baPayload );
								_TelemetryOutputQueuePush ( ba );
							}
							_baPayload.clear ( );
							_uCheckSum = 0;
							uNextState = _FSM_START;
						}
						else
						{
							// lpc invalid
							errorReset ( _ERR_CHECKSUM, _uCheckSum );
						}
						break;
					case _FSM_EXCEPTION:
						if ( i_uByte == TELEMETRY_PACKET_ID )
						{
							// found a possible new start
							uNextState = _FSM_LENGTH;
						}
						else
						{
							// keep looking for new start
							_uCheckSum = 0;
							uNextState = _FSM_EXCEPTION;
						}
						break;
					default:
						// should never get here!
						errorReset ( _ERR_UNDEFINED, i_uByte );
						break;
				} // end switch
				
				_uState = uNextState; // update FSM
				
			} // end FSM loop
			
			_baIn.clear ( ); // free up memory
			
		} // end _TelemetryInputQueueService
		
		private function _TelemetryOutputQueuePush ( ba:ByteArray ) : void
		{
			_vbaOut [ _uOutLen++ ] = ba;
			_tmrQueueOut.start ( );
		}
		
		private function _TelemetryOutputQueueService ( event:TimerEvent = null ) : void
		{
			_tmrQueueOut.stop ( );
			dispatchEvent ( new TelemetryEvent ( TelemetryEvent.PACKET_PAYLOADS, _vbaOut ) );
			_vbaOut = new <ByteArray> [];
			_uOutLen = 0;
		}
		
		private function _WatchdogSetup ( ) : void
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( McuMessage.COMM_SETUP );
			ba.writeByte ( _uWatchdogModeId );
			sendCommand ( ba );
		}
		
	}
}