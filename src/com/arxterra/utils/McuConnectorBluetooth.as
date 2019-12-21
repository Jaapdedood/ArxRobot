package com.arxterra.utils
{
	import com.distriqt.extension.bluetooth.Bluetooth;
	import com.distriqt.extension.bluetooth.BluetoothDevice;
	import com.distriqt.extension.bluetooth.events.BluetoothConnectionEvent;
	import com.distriqt.extension.bluetooth.events.BluetoothDeviceEvent;
	import com.distriqt.extension.bluetooth.events.BluetoothEvent;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import com.arxterra.controllers.SessionManager;
	
	import com.arxterra.events.UtilityEvent;
	
	import org.apache.flex.collections.VectorCollection;
	
	import com.arxterra.vo.McuConnectModes;
	
	[Event(name="bluetooth_icon_changed", type="flash.events.Event")]
	
	[Event(name="bluetooth_config", type="com.arxterra.events.UtilityEvent")]
	[Event(name="bluetooth_connected", type="com.arxterra.events.UtilityEvent")]
	[Event(name="bluetooth_disconnected", type="com.arxterra.events.UtilityEvent")]
	
	/**
	 * Singleton class extending McuConnector
	 * to implement connection via the distriqt Bluetooth ANE.
	 */
	[Bindable]
	public class McuConnectorBluetooth extends McuConnectorBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const BLUETOOTH_ICON_CHANGED:String = 'bluetooth_icon_changed';
		
		private static const _AUTO_CONNECT_DELAY:Number = 1000;
		private static const _AUTO_CONNECT_TRIES_MAX:int = 3;
		
		private static const _BLINK_DELAY:uint = 1000;
		
		private static const _BT_UUID:String = '00001101-0000-1000-8000-00805f9b34fb'; // standard serial port service ID
		private static const _BT_SECURE:Boolean = true;
		
		private static var __instance:McuConnectorBluetooth;
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : McuConnectorBluetooth
		{
			if ( !__instance )
			{
				__instance = new McuConnectorBluetooth ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */
		public function McuConnectorBluetooth ( enforcer:SingletonEnforcer )
		{
			super();
		}

		/*
		BluetoothConnectionEvent -- properties:  uuid:String, device:BluetoothDevice, message:String
		CONNECTION_CLOSE_ERROR
		CONNECTION_CONNECT_ERROR
		CONNECTION_CONNECT_FAILED
		CONNECTION_CONNECTED
		CONNECTION_CONNECTING
		CONNECTION_DISCONNECT_ERROR
		CONNECTION_DISCONNECTED
		CONNECTION_LISTEN_ERROR
		CONNECTION_LISTENING
		CONNECTION_RECEIVED_BYTES
		CONNECTION_REMOTE
		CONNECTION_WRITE_ERROR
		CONNECTION_WRITE_SUCCESS
		
		BluetoothDeviceEvent -- properties:  device:BluetoothDevice = null
		DEVICE_BONDED
		DEVICE_BONDING
		DEVICE_DISCONNECT_REQUESTED
		DEVICE_DISCONNECTED
		DEVICE_FOUND
		
		BluetoothEvent -- properties:  data:String
		NOT_SUPPORTED
		SCAN_FINISHED
		SCAN_MODE_CHANGED
		SCAN_STARTED
		STATE_CHANGED
		
		*/
		
		override public function dismiss ( ) : void
		{
			if ( _btService != null )
			{
				_AutoConnectTimerClear ( );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_CLOSE_ERROR, _ConnErrClose );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECT_ERROR, _ConnErrConnect );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECT_FAILED, _ConnFailed );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECTED, _ConnConnected );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECTING, _ConnStatus );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_DISCONNECT_ERROR, _ConnStatus );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_DISCONNECTED, _ConnDisconnected );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_LISTEN_ERROR, _ConnStatus );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_LISTENING, _ConnStatus );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_RECEIVED_BYTES, _ConnBytesReceived );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_REMOTE, _ConnRemote );
				_btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_WRITE_ERROR, _ConnStatus );
				// _btService.removeEventListener ( BluetoothConnectionEvent.CONNECTION_WRITE_SUCCESS, _ConnStatus );
				_btService.removeEventListener ( BluetoothDeviceEvent.DEVICE_BONDED, _DevStatus );
				_btService.removeEventListener ( BluetoothDeviceEvent.DEVICE_BONDING, _DevStatus );
				_btService.removeEventListener ( BluetoothDeviceEvent.DEVICE_DISCONNECT_REQUESTED, _DevStatus );
				_btService.removeEventListener ( BluetoothDeviceEvent.DEVICE_DISCONNECTED, _DevStatus );
				_btService.removeEventListener ( BluetoothDeviceEvent.DEVICE_FOUND, _DevStatus );
				_btService.removeEventListener ( BluetoothEvent.NOT_SUPPORTED, _Status );
				_btService.removeEventListener ( BluetoothEvent.SCAN_FINISHED, _ScanFinished );
				_btService.removeEventListener ( BluetoothEvent.SCAN_MODE_CHANGED, _Status );
				_btService.removeEventListener ( BluetoothEvent.SCAN_STARTED, _ScanStarted );
				_btService.removeEventListener ( BluetoothEvent.STATE_CHANGED, _Status );
				if ( _bEnabled )
				{
					disconnect ( );
					try
					{
						if ( _bDisabledAtStart )
						{
							// politely return device to its original state
							_btService.disable ( );
						}
					}
					catch ( err:Error )
					{
						_debugOut ( 'error_bt_dismiss', true, [ err.message ] );
					}
					connectedDevice = null;
					_vDevices = null;
					pairedList = null;
					isEnabled = false; // default to false
				}
				_btService = null;
			}
			super.dismiss ( );
			__instance = null;
		}
		
		override public function init ( ) : void
		{
			super.init ( );
			_modeSet ( McuConnectModes.BLUETOOTH );
			_bAutoConnect = false;
			_bDisabledAtStart = false;
			isEnabled = false;
			connectedDevice = null;
			try
			{
				// Bluetooth.init ( SessionManager.DISTRIQT_ANE_APP_KEY );
				if ( !Bluetooth.isSupported )
				{
					_debugOut ( 'error_bt_support', true );
				}
				else
				{
					_btService = Bluetooth.service;
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_CLOSE_ERROR, _ConnErrClose );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECT_ERROR, _ConnErrConnect );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECT_FAILED, _ConnFailed );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECTED, _ConnConnected );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_CONNECTING, _ConnStatus );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_DISCONNECT_ERROR, _ConnStatus );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_DISCONNECTED, _ConnDisconnected );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_LISTEN_ERROR, _ConnStatus );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_LISTENING, _ConnStatus );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_RECEIVED_BYTES, _ConnBytesReceived );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_REMOTE, _ConnRemote );
					_btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_WRITE_ERROR, _ConnStatus );
					// _btService.addEventListener ( BluetoothConnectionEvent.CONNECTION_WRITE_SUCCESS, _ConnStatus );
					_btService.addEventListener ( BluetoothDeviceEvent.DEVICE_BONDED, _DevStatus );
					_btService.addEventListener ( BluetoothDeviceEvent.DEVICE_BONDING, _DevStatus );
					_btService.addEventListener ( BluetoothDeviceEvent.DEVICE_DISCONNECT_REQUESTED, _DevStatus );
					_btService.addEventListener ( BluetoothDeviceEvent.DEVICE_DISCONNECTED, _DevStatus );
					_btService.addEventListener ( BluetoothDeviceEvent.DEVICE_FOUND, _DevStatus );
					_btService.addEventListener ( BluetoothEvent.NOT_SUPPORTED, _Status );
					_btService.addEventListener ( BluetoothEvent.SCAN_FINISHED, _ScanFinished );
					_btService.addEventListener ( BluetoothEvent.SCAN_MODE_CHANGED, _Status );
					_btService.addEventListener ( BluetoothEvent.SCAN_STARTED, _ScanStarted );
					_btService.addEventListener ( BluetoothEvent.STATE_CHANGED, _Status );
					_callLater ( _CheckEnabled, [ true ] );
				}
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_bt_init', true, [ err.message ] );
			}
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function get connectedDevice ( ) : BluetoothDevice
		{
			return _btDevConn;
		}
		protected function set connectedDevice ( value:BluetoothDevice ) : void
		{
			_btDevConn = value;
			if ( value == null )
			{
				connectedDeviceAddress = '';
				_isConnectedSet ( false );
			}
			else
			{
				connectedDeviceAddress = value.address;
				_isConnectedSet ( true );
				_iAutoCount = 0;
			}
			_IconStyleUpdate ( );
		}
		
		public function get connectedDeviceAddress():String
		{
			return _sDevConnAddr;
		}
		protected function set connectedDeviceAddress(value:String):void
		{
			_sDevConnAddr = value;
		}
		
		[Bindable (event="bluetooth_icon_changed")]
		public function get iconColor():uint
		{
			return _vIconColors [ 1 ];
		}
		
		[Bindable (event="bluetooth_icon_changed")]
		public function get iconColorBlink():uint
		{
			return _vIconColors [ _uBlinkIdx ];
		}
		
		/**
		 * Boolean true if Bluetooth device is currently
		 * scanning or attempting to connect,
		 * false otherwise
		 */
		public function get isBusy():Boolean
		{
			return _bBusy;
		}
		/**
		 * @private
		 */
		protected function set isBusy(value:Boolean):void
		{
			_bBusy = value;
		}
		
		/**
		 * Boolean true if Bluetooth device is currently trying to connect,
		 * false otherwise
		 */
		public function get isConnecting():Boolean
		{
			return _bConnecting;
		}
		/**
		 * @private
		 */
		protected function set isConnecting(value:Boolean):void
		{
			_bConnecting = value;
			_IconStyleUpdate ( );
			_BusyUpdate ( );
		}
		
		/**
		 * Boolean true if Bluetooth device is currently discoverable,
		 * false otherwise
		 */		
		public function get isDiscoverable ( ) : Boolean
		{
			return _bDiscoverable;
		}
		protected function set isDiscoverable ( discoverable:Boolean ) : void
		{
			_bDiscoverable = discoverable;
		}
		
		public function get isEnabled ( ) : Boolean
		{
			return _bEnabled;
		}
		protected function set isEnabled ( value:Boolean ) : void
		{
			_bEnabled = value;
			_IconStyleUpdate ( );
			_BusyUpdate ( );
		}
		
		/**
		 * Boolean true if Bluetooth device is currently scanning,
		 * false otherwise
		 */
		public function get isScanning ( ) : Boolean
		{
			return _bScanning;
		}
		protected function set isScanning ( value:Boolean ) : void
		{
			_bScanning = value;
			_IconStyleUpdate ( );
			_BusyUpdate ( );
		}
		
		public function get pairedList():VectorCollection
		{
			return _vcDevices;
		}
		protected function set pairedList(value:VectorCollection):void
		{
			_vcDevices = value;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function connect ( dev:BluetoothDevice ) : void
		{
			_btService.cancelScan ( );
			disconnect ( );
			_bAutoConnect = true;
			var sAddr:String = '';
			var sName:String = '';
			try
			{
				sAddr = dev.address;
				sName = dev.deviceName;
				if ( _btService.connect ( dev, _BT_UUID, _BT_SECURE ) )
				{
					isConnecting = true;
				}
				else
				{
					_debugOut ( 'status_bt_conn_connect_fail', true, [ sAddr, sName ] );
				}
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_bt_conn_connect_start', true, [ sAddr, sName, err.message ] );
			}
			
		}
		
		public function disconnect ( ) : void
		{
			_bAutoConnect = false;
			if ( isConnected && _btDevConn != null )
			{
				var sAddr:String = '';
				var sName:String = '';
				try
				{
					sAddr = _btDevConn.address;
					sName = _btDevConn.deviceName;
					if ( !_btService.disconnect ( _btDevConn, _BT_UUID ) )
					{
						_debugOut ( 'status_bt_conn_disconnect_fail', true, [ sAddr, sName ] );
					}
				}
				catch ( err:Error )
				{
					_debugOut ( 'error_bt_conn_disconnect_start', true, [ sAddr, sName, err.message ] );
				}
			}
		}
		
		/**
		 * @param value Boolean to set auto-connect to true or false
		 */		
		public function setAutoConnect ( value:Boolean ) : void
		{
			_bAutoConnect = value;
			if ( value )
			{
				_iAutoCount = 0;
				if ( _bEnabled )
				{
					_AutoConnectQueue ( );
				}
			}
			else if ( _bEnabled )
			{
				_callLater ( _ConfigOpen );
			}
		}
		
		/**
		 * @param address Bluetooth address of last device successfully connected
		 */
		public function setAutoConnectionAddress ( address:String, firstRun:Boolean ) : void
		{
			_sDevConnAddrAuto = address;
			// setAutoConnect ( firstRun || address.length > 0 );
			setAutoConnect ( address.length > 0 );
		}
		
		/**
		 * @param seconds Length of time to remain in discoverable mode
		 */		
		public function setDeviceDiscoverable ( seconds:int = 30 ) : void
		{
			if ( isDiscoverable )
				return; // return
			
			if ( _btService )
			{
				try
				{
					_btService.setDeviceDiscoverable ( true, seconds );
				}
				catch ( err:Error )
				{
					_debugOut ( 'error_bt_set_discover', true, [ err.message ] );
				}
			}
		}
		
		public function systemSettingsOpen ( ) : void
		{
			_btService.showSettings ( );
		}
		
		/**
		 * Turn scanning on/off
		 */
		public function toggleScan ( ) : void
		{
			if ( isScanning )
			{
				_btService.cancelScan ( );
			}
			else
			{
				_btService.startScan ( );
			}
		}
		
		
		// PROTECTED METHODS
		
		override protected function _send ( bytes:ByteArray ) : Boolean
		{
			if ( isConnected )
			{
				bytes.position = 0;
				try
				{
					_btService.writeBytes ( _BT_UUID, bytes );
				}
				catch ( err:Error )
				{
					_debugOut ( 'error_bt_send', true, [ err.message ] );
				}
			}
			super._send ( bytes ); // pass through for ping check
			return isConnected;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bAutoConnect:Boolean = false;
		private var _bBusy:Boolean = false;
		private var _bConnecting:Boolean = false;
		private var _bDisabledAtStart:Boolean = false;
		// private var _bListening:Boolean = false;
		private var _bDiscoverable:Boolean;
		private var _bEnabled:Boolean = false;
		private var _bScanning:Boolean;
		private var _btDevConn:BluetoothDevice; // reference to connected device
		private var _btService:Bluetooth; // reference to singleton instance of Bluetooth ANE
		private var _iAutoCount:int = 0;
		private var _sDevConnAddr:String = '';
		private var _sDevConnAddrAuto:String = '';
		private var _tmrAutoConn:Timer;
		private var _tmrBlink:Timer;
		private var _uBlinkIdx:uint = 1;
		private var _vcDevices:VectorCollection;
		private var _vDevices:Vector.<BluetoothDevice>;
		private var _vIconColors:Vector.<uint> = new <uint> [ 0x111111, 0xcc0000 ]; // [ "off" color when blinking, "current status" color ]
		
		
		// PRIVATE METHODS GENERAL
		
		private function _AutoConnectAttempt ( event:TimerEvent = null ) : void
		{
			var bConfig:Boolean = true;
			_AutoConnectTimerClear ( );
			// attempt connection if have previous address
			if ( _iAutoCount < _AUTO_CONNECT_TRIES_MAX && _sDevConnAddrAuto.length > 0 )
			{
				_iAutoCount++;
				var iLim:int = _vDevices.length;
				if ( iLim > 0 )
				{
					var i:int;
					var i_dev:BluetoothDevice;
					for ( i=0; i<iLim; i++ )
					{
						i_dev = _vDevices [ i ];
						if ( i_dev.address == _sDevConnAddrAuto )
						{
							bConfig = false;
							connect ( i_dev );
							break;
						}
					}
				}
			}
			if ( bConfig )
			{
				_ConfigOpen ( );
			}
		}
		
		private function _AutoConnectQueue ( immediate:Boolean = false ) : void
		{
			if ( !_bAutoConnect || isConnected || _bConnecting )
			{
				_AutoConnectTimerClear ( );
			}
			else if ( immediate )
			{
				_AutoConnectAttempt ( );
			}
			else
			{
				_AutoConnectTimerSet ( );
			}
		}
		
		private function _AutoConnectTimerClear ( ) : void
		{
			if ( !_tmrAutoConn )
				return;
			
			_tmrAutoConn.stop ( );
			_tmrAutoConn.removeEventListener ( TimerEvent.TIMER, _AutoConnectAttempt );
			_tmrAutoConn = null;
		}
		
		private function _AutoConnectTimerSet ( ) : void
		{
			_tmrAutoConn = new Timer ( _AUTO_CONNECT_DELAY, 0 );
			_tmrAutoConn.addEventListener ( TimerEvent.TIMER, _AutoConnectAttempt );
			_tmrAutoConn.start ( );
		}
		
		private function _Blink ( event:TimerEvent = null ) : void
		{
			_uBlinkIdx = 1 - _uBlinkIdx;
			dispatchEvent ( new Event ( BLUETOOTH_ICON_CHANGED ) );
		}
		
		private function _BlinkTimer ( busy:Boolean ) : void
		{
			if ( busy )
			{
				if ( !_tmrBlink )
				{
					_uBlinkIdx = 0;
					_tmrBlink = new Timer ( _BLINK_DELAY, 0 );
					_tmrBlink.addEventListener ( TimerEvent.TIMER, _Blink );
					_tmrBlink.start ( );
				}
			}
			else
			{
				_uBlinkIdx = 1
				if ( _tmrBlink )
				{
					_tmrBlink.stop ( );
					_tmrBlink.removeEventListener ( TimerEvent.TIMER, _Blink );
					_tmrBlink = null;
				}
			}
		}
		private function _BusyUpdate ( ) : void
		{
			var bNew:Boolean = _bScanning || _bConnecting;
			if ( bNew != _bBusy )
			{
				isBusy = bNew;
				_BlinkTimer ( bNew );
				dispatchEvent ( new Event ( BLUETOOTH_ICON_CHANGED ) );
			}
		}
		
		private function _CheckEnabled ( firstTime:Boolean = false ) : void
		{
			if ( _bEnabled )
			{
				return; // return
			}
			
			isEnabled = _btService.isEnabled ( );
			if ( _bEnabled )
			{
				_DevListUpdate ( );
				if ( _bAutoConnect )
				{
					_AutoConnectQueue ( );
				}
				else
				{
					_callLater ( _ConfigOpen );
				}
			}
			else if ( firstTime )
			{
				_bDisabledAtStart = true;
				// ask user to enable
				_btService.enableWithUI ( );
			}
		}
		
		private function _ConfigOpen ( ) : void
		{
			dispatchEvent ( new UtilityEvent ( UtilityEvent.BLUETOOTH_CONFIG ) );
		}
		
		private function _DevListUpdate ( ) : void
		{
			_vDevices = _btService.getPairedDevices ( );
			pairedList = new VectorCollection ( _vDevices );
		}
		
		private function _IconStyleUpdate ( ) : void
		{
			var uNew:uint;
			if ( isConnected )
			{
				uNew = 0x0099ff;
			}
			else if ( _bEnabled )
			{
				uNew = 0xffffff;
			}
			else
			{
				uNew = 0xcc0000;
			}
			if ( uNew != _vIconColors [ 1 ] )
			{
				_vIconColors [ 1 ] = uNew;
				dispatchEvent ( new Event ( BLUETOOTH_ICON_CHANGED ) );
			}
		}
		
		
		// PRIVATE METHODS EVENT HANDLERS
		
		private function _ConnBytesReceived ( event:BluetoothConnectionEvent ) : void
		{
			var ba:ByteArray;
			try
			{
				ba = _btService.readBytes ( _BT_UUID );
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_bt_receive', true, [ err.message ] );
				return; // return
			}
			
			if ( ba == null )
			{
				/*
				if ( _sessionMgr.testCfgMcuDtlTrace )
				{
					debugOut ( 'error_bt_receive_null', true );
				}
				*/
			}
			else if ( ba.length < 1 )
			{
				/*
				if ( _sessionMgr.testCfgMcuDtlTrace )
				{
					debugOut ( 'error_bt_receive_empty', true );
				}
				*/
			}
			else
			{
				_telemetryInputQueuePush ( ba );
			}
		}
		
		private function _ConnConnected ( event:BluetoothConnectionEvent ) : void
		{
			isConnecting = false;
			connectedDevice = event.device;
			_debugOut ( 'status_bt_conn_connected', true, [ _sDevConnAddr, _btDevConn.deviceName ] );
			dispatchEvent ( new UtilityEvent ( UtilityEvent.BLUETOOTH_CONNECTED, _sDevConnAddr ) );
		}
		
		private function _ConnDisconnected ( event:BluetoothConnectionEvent ) : void
		{
			isConnecting = false;
			var dev:BluetoothDevice = event.device;
			if ( dev != null )
			{
				var sAddr:String = dev.address;
				_debugOut ( 'status_bt_conn_disconnected', true, [ sAddr, dev.deviceName ] );
				if ( sAddr == _sDevConnAddr )
				{
					connectedDevice = null;
					dispatchEvent ( new UtilityEvent ( UtilityEvent.BLUETOOTH_DISCONNECTED ) );
				}
			}
			else
			{
				_debugOut ( 'status_bt_conn_disconnected', true, [ '?', '?' ] );
			}
			_AutoConnectQueue ( );
		}
		
		private function _ConnErrClose ( event:BluetoothConnectionEvent ) : void
		{
			connectedDevice = null;
			isConnecting = false;
			_debugOut ( 'error_bt_conn_close', true, [ event.message ] );
		}
		
		private function _ConnErrConnect ( event:BluetoothConnectionEvent ) : void
		{
			connectedDevice = null;
			isConnecting = false;
			_AutoConnectQueue ( );
			_debugOut ( 'error_bt_conn_connect', true, [ event.message ] );
		}
		
		private function _ConnFailed ( event:BluetoothConnectionEvent ) : void
		{
			connectedDevice = null;
			isConnecting = false;
			_AutoConnectQueue ( );
			_debugOut ( 'status_bt_conn_failed', true );
		}
		
		/*
		private function _ConnListenError ( event:BluetoothConnectionEvent ) : void
		{
			_bListening = false;
			debugOut ( 'error_bt_conn_listen', true, [ event.message ] );
		}
		
		private function _ConnListening ( event:BluetoothConnectionEvent ) : void
		{
			_bListening = true;
			debugOut ( 'status_bt_conn_listening', true );
		}
		*/
		
		private function _ConnRemote ( event:BluetoothConnectionEvent ) : void
		{
			connectedDevice = event.device;
			_debugOut ( 'status_bt_conn_remote', true, [ _btDevConn.address, _btDevConn.deviceName ] );
		}
		
		private function _ConnStatus ( event:BluetoothConnectionEvent ) : void
		{
			// catch-all for various connection status events
			_debugOut ( 'status_bt_conn_misc', true, [ event.type, event.message ] );
		}
		
		private function _DevStatus ( event:BluetoothDeviceEvent ) : void
		{
			// catch-all for various device status events
			var sName:String = '';
			var sState:String = '';
			var dev:BluetoothDevice = event.device;
			if ( dev )
			{
				sName = dev.deviceName;
				sState = dev.state;
			}
			_debugOut ( 'status_bt_device_misc', true, [ event.type, sName, sState ] );
			_DevListUpdate ( );
		}
		
		private function _ScanFinished ( event:BluetoothEvent ) : void
		{
			// debugOut ( 'status_bt_misc', true, [ event.type, event.data ] );
			isScanning = false;
		}
		
		private function _ScanStarted ( event:BluetoothEvent ) : void
		{
			// debugOut ( 'status_bt_misc', true, [ event.type, event.data ] );
			isScanning = true;
		}
		
		private function _Status ( event:BluetoothEvent ) : void
		{
			// catch-all for various status events
			// debugOut ( 'status_bt_misc', true, [ event.type, event.data ] );
			_CheckEnabled ( );
		}
	}
}
class SingletonEnforcer {}
