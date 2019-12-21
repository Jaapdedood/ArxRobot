package com.arxterra.utils
{
	import com.arxterra.events.BleEvent;
	import com.arxterra.vo.BleCharacteristicExec;
	import com.arxterra.vo.BleProtocolExec;
	import com.arxterra.vo.BleProtocolSpec;
	import com.arxterra.vo.BleServiceExec;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Peripheral;
	import com.distriqt.extension.bluetoothle.objects.PeripheralState;
	import com.distriqt.extension.bluetoothle.objects.Service;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import org.apache.flex.collections.VectorCollection;
	import flash.utils.Timer;
	
	[Event(name="ble_peripheral_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_connected_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_connecting_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_discovery_done", type="flash.events.Event")]
	[Event(name="ble_peripheral_label_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_querying_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_rssi_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_spec_ids_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_state_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_usable_change", type="flash.events.Event")]
	
	[Event(name="ble_peripheral_connected", type="com.arxterra.events.BleEvent")]
	[Event(name="ble_peripheral_disconnected", type="com.arxterra.events.BleEvent")]
	
	/**
	 * Stores a reference to a discovered BluetoothLE ANE Peripheral instance,
	 * briefly connects to query its services and characteristics, tracks which,
	 * if any, of our specs it meets, and connects thereafter as required to serve
	 * the client class(es) that engage(s) it, or disconnects if/when not needed.
	 */
	public class BlePeripheralAgent extends BleBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const BLE_PERIPHERAL_CHANGE:String = 'ble_peripheral_change';
		public static const BLE_PERIPHERAL_CONNECTED_CHANGE:String = 'ble_peripheral_connected_change';
		public static const BLE_PERIPHERAL_CONNECTING_CHANGE:String = 'ble_peripheral_connecting_change';
		public static const BLE_PERIPHERAL_DISCOVERY_DONE:String = 'ble_peripheral_discovery_done';
		public static const BLE_PERIPHERAL_LABEL_CHANGE:String = 'ble_peripheral_label_change';
		public static const BLE_PERIPHERAL_QUERYING_CHANGE:String = 'ble_peripheral_querying_change';
		public static const BLE_PERIPHERAL_RSSI_CHANGE:String = 'ble_peripheral_rssi_change';
		public static const BLE_PERIPHERAL_SPEC_IDS_CHANGE:String = 'ble_peripheral_spec_ids_change';
		public static const BLE_PERIPHERAL_STATE_CHANGE:String = 'ble_peripheral_state_change';
		public static const BLE_PERIPHERAL_USABLE_CHANGE:String = 'ble_peripheral_usable_change';
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @param peripheral Reference to the peripheral object discovered by the BluetoothLE ANE
		 * @param rssi Signal strength reported with discovery event
		 * @param extendedId Extended device ID, which is reported UUID concatenated with '_' and the BluetoothLE ANE's internal numerical identifier
		 * @param protocolSpecs Reference to vector containing BleProtocolSpec instance(s) for the peripheral(s) needed
		 */
		public function BlePeripheralAgent ( peripheral:Peripheral, rssi:Number, extendedId:String, protocolSpecs:Vector.<BleProtocolSpec> )
		{
			super();
			
			_vBps = protocolSpecs;
			_sXid = extendedId;
			_nRssi = rssi;
			
			_anePr = peripheral;
			
			_iAneId = _anePr.identifier;
			_sName = _anePr.name;
			_sState = _anePr.state;
			_sDevId = _anePr.uuid;
			
			_vBpsIdsComp = new <String> [];
			_vBpe = new <BleProtocolExec> [];
			
			// postpone instantiating execs... will call _ExecsInit in discoveryStart
			
			_LocaleLabelUpdate ( false );
			_LocaleStateUpdate ( false );
			
			// _debugOut ( 'status_ble_pr_discov', true, [ _sLabel ] );
			
			// _callLater ( _Connect );
		}
		
		override public function dismiss ( ) : void
		{
			_Disconnect ( );
			
			_ListenersPeripheralRemoveAll ( );
			_ListenersCentralRemoveAll ( );
			
			_vBseQueryQueue = null;
			_oBcePathHash = null;
			_dBceAneCrHash = null;
			_oBseUuidHash = null;
			_vBpsIdsComp = null;
			
			if ( _vBpe )
			{
				for ( var i:int=_vBpe.length-1; i>=0; i-- )
				{
					_vBpe.pop ( ).dismiss ( );
				}
			}
			
			_vBps = null;
			_anePr = null;
			
			super.dismiss ( );
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="ble_peripheral_spec_ids_change")]
		public function get compatibleProtocolExecs():VectorCollection
		{
			function bpeComp ( bpe:BleProtocolExec, idx:int, vBpe:Vector.<BleProtocolExec> ) : Boolean
			{
				return bpe.isCompatible;
			}
			return new VectorCollection ( _vBpe.filter ( bpeComp ) );
		}
		
		[Bindable (event="ble_peripheral_spec_ids_change")]
		public function get compatibleSpecIds():Vector.<String>
		{
			return _vBpsIdsComp;
		}
		
		[Bindable(event="ble_peripheral_change")]
		/**
		 * Peripheral device's ID as exposed by the OS.
		 * <p>Android provides the (usually) unvarying MAC address
		 * advertised by the peripheral (e.g., "f4:b8:5e:b3:f9:68").
		 * <p>iOS conceals the MAC address and instead assigns a temporary UUID
		 * that naturally differs from one iOS device to another, and may also
		 * change from session to session on the same iOS device
		 * (e.g., "fa42c790-fd7d-9afd-b076-d9f154f035d9").
		 */
		public function get deviceId():String
		{
			return _sDevId;
		}
		
		[Bindable(event="ble_peripheral_discovery_done")]
		public function get discoveryDone():Boolean
		{
			return _bDiscoveryDone;
		}
		
		[Bindable(event="ble_peripheral_change")]
		/**
		 * Our extended device ID, which is deviceId concatenated with '_' and the ANE's internal numerical identifier
		 */
		public function get extendedId():String
		{
			return _sXid;
		}
		
		[Bindable (event="ble_peripheral_change")]
		/**
		 * Internal identifier assigned to peripheral by the Bluetooth LE ANE
		 */
		public function get identifier():int
		{
			return _iAneId;
		}
		
		[Bindable (event="ble_peripheral_connected_change")]
		/**
		 * True when peripheral is connected
		 */
		public function get isConnected():Boolean
		{
			return _bConnected;
		}
		private function _IsConnectedSet(value:Boolean, busyUpdate:Boolean = true):void
		{
			var i:int;
			var iLen:int;
			
			if ( value !== _bConnected )
			{
				_bConnected = value;
				iLen = _vBpe.length;
				for ( i=0; i<iLen; i++ )
				{
					// update protocol exec, which will update its characteristic exec(s) and, if currently selected, its protocol spec
					_vBpe [ i ].isConnected = value;
				}
				dispatchEvent ( new Event ( BLE_PERIPHERAL_CONNECTED_CHANGE ) );
				if ( value )
				{
					dispatchEvent ( new BleEvent ( BleEvent.BLE_PERIPHERAL_CONNECTED, _sXid, _sLabel ) );
				}
				else
				{
					dispatchEvent ( new BleEvent ( BleEvent.BLE_PERIPHERAL_DISCONNECTED, _sXid, _sLabel ) );
				}
				// _IconStyleUpdate ( );
				if ( busyUpdate )
				{
					_BusyUpdate ( );
				}
			}
		}
		
		[Bindable (event="ble_peripheral_connecting_change")]
		/**
		 * True while attempting to connect with peripheral
		 */
		public function get isConnecting():Boolean
		{
			return _bConnecting;
		}
		private function _IsConnectingSet(value:Boolean, busyUpdate:Boolean = true):void
		{
			if ( value !== _bConnecting )
			{
				_bConnecting = value;
				if ( busyUpdate )
				{
					_BusyUpdate ( );
				}
				dispatchEvent ( new Event ( BLE_PERIPHERAL_CONNECTING_CHANGE ) );
			}
		}
		
		[Bindable (event="ble_peripheral_querying_change")]
		/**
		 * True while querying peripheral for its services and characteristics
		 */
		public function get isQuerying():Boolean
		{
			return _bQuerying;
		}
		private function _IsQueryingSet(value:Boolean):void
		{
			if ( value !== _bQuerying )
			{
				_bQuerying = value;
				_BusyUpdate ( );
				dispatchEvent ( new Event ( BLE_PERIPHERAL_QUERYING_CHANGE ) );
			}
		}
		
		[Bindable (event="ble_peripheral_usable_change")]
		public function get isUsable():Boolean
		{
			return _bUsable;
		}
		private function _IsUsableSet(value:Boolean):void
		{
			if ( value !== _bUsable )
			{
				_bUsable = value;
				dispatchEvent ( new Event ( BLE_PERIPHERAL_USABLE_CHANGE ) );
				_IconStyleUpdate ( );
			}
		}
		
		[Bindable (event="ble_peripheral_label_change")]
		public function get label():String
		{
			return _sLabel;
		}
		
		[Bindable (event="ble_peripheral_change")]
		public function get name():String
		{
			return _sName;
		}
		
		[Bindable (event="ble_peripheral_change")]
		/**
		 * Reference to the peripheral object discovered
		 * by the Bluetooth LE ANE
		 */
		public function get peripheral():Peripheral
		{
			return _anePr;
		}
		
		[Bindable (event="ble_peripheral_rssi_change")]
		public function get rssi():Number
		{
			return _nRssi;
		}
		private function _RssiSet(value:Number):void
		{
			if ( value !== _nRssi )
			{
				_nRssi = value;
				if ( _nRssi == 127 )
				{
					_sRssiDisp = '';
				}
				else
				{	
					_sRssiDisp = _nRssi.toString();
				}
				dispatchEvent ( new Event ( BLE_PERIPHERAL_RSSI_CHANGE ) );
			}
		}
		
		[Bindable (event="ble_peripheral_rssi_change")]
		public function get rssiDisplay():String
		{
			return _sRssiDisp;
		}
		
		[Bindable(event="ble_peripheral_state_change")]
		/**
		 * State of the peripheral as reported by the Bluetooth LE ANE
		 */
		public function get state():String
		{
			return _sState;
		}
		private function _StateSet(value:String):void
		{
			_sState = value;
			_LocaleStateUpdate ( );
		}
		
		[Bindable(event="ble_peripheral_state_change")]
		public function get stateDisplay():String
		{
			return _sStateDisp;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function characteristicFromPath ( path:String ) : Characteristic
		{
			if ( path in _oBcePathHash )
			{
				return ( _oBcePathHash [ path ] as BleCharacteristicExec ).characteristic;
			}
			
			return null;
		}
		
		public function characteristicExecFromPath ( path:String ) : BleCharacteristicExec
		{
			if ( path in _oBcePathHash )
			{
				return _oBcePathHash [ path ] as BleCharacteristicExec;
			}
			
			return null;
		}
		
		public function configRequest ( id:String, caption:String ) : void
		{
			_statusCaptionSet ( caption );
			_configOpen ( id, caption );
		}
		
		public function discoveryStart ( ) : void
		{
			if ( _ExecsInit ( ) )
			{
				_callLater ( _Connect );
			}
			else
			{
				_bDiscoveryDone = false;
				_bQueriesDone = false;
				if ( _bConnected )
				{
					_ServicesDiscover ( );
				}
				else
				{
					_Connect ( );
				}
			}
		}
		
		public function protocolExecEngagedChange ( ) : void
		{
			// _callLater ( _RetentionUpdate );
			_RetentionUpdate ( );
		}
		
		// called by BleProtocolSpec when this one is no longer its selectedAgent
		public function protocolSpecDeselect ( bps:BleProtocolSpec ) : void
		{
			var bpe:BleProtocolExec;
			var sId:String = bps.id;
			if ( sId in _oBpeIdHash )
			{
				bpe = _oBpeIdHash [ sId ] as BleProtocolExec;
				bpe.isSelectedSet ( false );
				_sessionMgr.userState.setBleSpecAddress ( sId, '' );
				_RetentionUpdate ( );
			}
		}
		
		// called by BleProtocolSpec when this one becomes its selectedAgent
		public function protocolSpecSelect ( bps:BleProtocolSpec ) : void
		{
			var bpe:BleProtocolExec;
			var sId:String = bps.id;
			if ( sId in _oBpeIdHash )
			{
				bpe = _oBpeIdHash [ sId ] as BleProtocolExec;
				bpe.isSelectedSet ( true );
				_sessionMgr.userState.setBleSpecAddress ( sId, _sDevId );
				_RetentionUpdate ( );
			}
		}
		
		public function rediscovered ( peripheral:Peripheral, rssi:Number ) : void
		{
			// fresh reference
			_anePr = peripheral;
			
			_StatusUpdate ( peripheral, rssi );
		}
		
		
		// PROTECTED METHODS
		
		override protected function _actionCheckTimeout ( event:TimerEvent = null ) : void
		{
			super._actionCheckTimeout ( );
			_statusCaptionSet ( _resourceManager.getString ( 'default', 'status_ble_cfg_pr_capt_' + _actionId ) );
			switch ( _actionId )
			{
				case _ACT_PR_CONNECT:
				{
					_ConnectFailed ( true );
					break;
				}
				case _ACT_PR_CRS_QUERY:
				{
					_CharacteristicsDiscoveryTimedOut ( );
					break;
				}
				case _ACT_PR_SRVS_QUERY:
				{
					_ServicesDiscoveryTimedOut ( );
					break;
				}
				default:
				{
					break;
				}
			}
		}
		
		override protected function _localeUpdate ( event:Event = null ) : void
		{
			super._localeUpdate ( );
			_LocaleLabelUpdate ( );
			_LocaleStateUpdate ( );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _anePr:Peripheral;
		private var _bConnected:Boolean = false;
		private var _bConnecting:Boolean = false;
		private var _bConnectQueued:Boolean = false;
		private var _bDisconnecting:Boolean = false;
		private var _bDiscoveryDone:Boolean = false;
		private var _bKeepConnected:Boolean = false;
		private var _bQueriesDone:Boolean = false;
		private var _bQuerying:Boolean = false;
		private var _bUsable:Boolean = false;
		private var _dBceAneCrHash:Dictionary; // key:value = ANE characteristic instance : BleCharacteristicExec instance
		private var _iAneId:Number;
		private var _nRssi:Number = 0;
		private var _oBcePathHash:Object; // key:value = spec ID path string : BleCharacteristicExec instance
		private var _oBpeIdHash:Object; // key:value = spec ID string : BleProtocolExec instance
		private var _oBseUuidHash:Object; // key:value = spec acceptable service UUID string : BleServiceExec instance
		private var _sDevId:String = '';
		private var _sLabel:String = '';
		private var _sName:String = '';
		private var _sRssiDisp:String = '0';
		private var _sState:String = '';
		private var _sStateDisp:String = '';
		private var _sXid:String = '';
		private var _tmrDisc:Timer;
		// private var _vClientIds:Vector.<String>; // attempt to stay connected if length > 0
		private var _vBpe:Vector.<BleProtocolExec>;
		private var _vBps:Vector.<BleProtocolSpec>;
		// vector of compatible spec ids
		private var _vBpsIdsComp:Vector.<String>; // for convenient filtering in list views of discovered peripherals
		private var _vBseQueryQueue:Vector.<BleServiceExec>;
		
		
		// PRIVATE METHODS
		
		// PeripheralEvent.CONNECT_FAIL from CentralManager
		private function _AnePrConnectFailed ( event:PeripheralEvent ) : void
		{
			if ( _IsNotMine ( event.peripheral ) )
				return; // return
			
			_actionCheckTimerClear ( _ACT_PR_CONNECT );
			
			_StatusUpdate ( event.peripheral, event.RSSI );
			
			_ConnectFailed ( );
		}
		
		// PeripheralEvent.CONNECT from CentralManager
		private function _AnePrConnectSucceeded ( event:PeripheralEvent ) : void
		{
			if ( _IsNotMine ( event.peripheral ) )
				return; // return
			
			_actionCheckTimerClear ( _ACT_PR_CONNECT, true ); // reset retry counter
			
			// keep reference
			_anePr = event.peripheral;
			
			_StatusUpdate ( _anePr, event.RSSI );
			
			// remove connect listeners
			_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT, _AnePrConnectSucceeded );
			_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT_FAIL, _AnePrConnectFailed );
			// add disconnect listener
			_aneCentralMgr.addEventListener ( PeripheralEvent.DISCONNECT, _AnePrDisconnected );
			
			_callLater ( _ServicesDiscover );
			
			_IsConnectingSet ( false, false );
			_IsConnectedSet ( true, false );
			_BusyUpdate ( );
		}
		
		// PeripheralEvent.DISCONNECT from CentralManager
		private function _AnePrDisconnected ( event:PeripheralEvent ) : void
		{
			if ( _IsNotMine ( event.peripheral ) )
				return; // return
			
			_StatusUpdate ( event.peripheral, event.RSSI );
			
			// remove any listeners that might be lingering
			_ListenersPeripheralRemoveAll ( );
			_ListenersCentralRemoveAll ( );
			
			_IsConnectedSet ( false );
			
			if ( _bDisconnecting )
			{
				// intentional
				_bDisconnecting = false;
			}
			else
			{
				// attempt reconnect
				_ConnectIfNeededQueue ( );
			}
		}
		
		// PeripheralEvent.DISCOVER_CHARACTERISTICS from Peripheral
		private function _AnePrDiscoveredCharacteristics ( event:PeripheralEvent ) : void
		{
			var aneSvc:Service;
			var bOk:Boolean;
			var bse:BleServiceExec;
			var i_aneCr:Characteristic;
			var i_aneSvc:Service;
			var sSvcUuid:String;
			var uLen:uint;
			var vAneSvc:Vector.<Service>;
			var vAneCr:Vector.<Characteristic>;
			var vCrUuids:Vector.<String>;
			
			_actionCheckTimerClear ( _ACT_PR_CRS_QUERY, true );
			
			// fresh reference
			_anePr = event.peripheral;
			
			_StatusUpdate ( _anePr, event.RSSI );
			
			if ( _vBseQueryQueue.length < 1 )
			{
				// should not happen, but just in case
				_anePr.removeEventListener ( PeripheralEvent.DISCOVER_CHARACTERISTICS, _AnePrDiscoveredCharacteristics );
				_QueriesDone ( );
				return; // return
			}
			
			// take next service exec from queue
			bse = _vBseQueryQueue.shift ( );
			aneSvc = bse.service; // old reference which should be replaced with new
			sSvcUuid = bse.uuid;
			vAneSvc = _anePr.services;
			// find the associated ANE peripheral's service object by uuid
			for each ( i_aneSvc in vAneSvc )
			{
				if ( i_aneSvc.uuid == sSvcUuid )
				{
					aneSvc = i_aneSvc;
					break;
				}
			}
			// get that service's vector of characteristics
			vAneCr = aneSvc.characteristics;
			if ( vAneCr && vAneCr.length > 0 )
			{
				// we got a vector with at least one characteristic, so can proceed to evaluate
				vCrUuids = new <String> [];
				uLen = 0;
				for each ( i_aneCr in vAneCr )
				{
					vCrUuids [ uLen++ ] = i_aneCr.uuid;
				}
				_debugOut ( 'status_ble_crs_discov', true, [ _sLabel, sSvcUuid, vCrUuids.join ( '\n   ' ) ] );
				bOk = bse.evaluate ( aneSvc );
				_debugOut ( 'status_ble_crs_discov_cp' + ( bOk ? '1' : '0' ), true, [ _sLabel, sSvcUuid ] );
			}
			else
			{
				_debugOut ( 'status_ble_crs_discov_none', true, [ _sLabel, sSvcUuid ] );
			}
			
			_callLater ( _CharacteristicsDiscover );
		}
		
		// PeripheralEvent.DISCOVER_SERVICES from Peripheral
		private function _AnePrDiscoveredServices ( event:PeripheralEvent ) : void
		{
			_actionCheckTimerClear ( _ACT_PR_SRVS_QUERY );
			
			// fresh reference
			_anePr = event.peripheral;
			
			_StatusUpdate ( _anePr, event.RSSI );
			
			// remove services listener
			_anePr.removeEventListener ( PeripheralEvent.DISCOVER_SERVICES, _AnePrDiscoveredServices );
			
			var vAneSvc:Vector.<Service> = _anePr.services;
			var i_aneSvc:Service;
			var i_bse:BleServiceExec;
			var i_sUuid:String;
			var vUuids:Vector.<String> = new <String> [];
			var uUuidsLen:uint = 0;
			var uQueueLen:uint = 0;
			_vBseQueryQueue.length = 0; // in case disconnected in middle of previous queries for characteristics
			if ( vAneSvc.length > 0 )
			{
				for each ( i_aneSvc in vAneSvc )
				{
					i_sUuid = i_aneSvc.uuid;
					vUuids [ uUuidsLen++ ] = i_sUuid;
					if ( i_sUuid in _oBseUuidHash )
					{
						i_bse = _oBseUuidHash [ i_sUuid ] as BleServiceExec;
						i_bse.service = i_aneSvc;
						if ( _vBseQueryQueue.indexOf ( i_bse ) < 0 )
						{
							_vBseQueryQueue [ uQueueLen++ ] = i_bse;
						}
					}
				}
				_debugOut ( 'status_ble_srvs_discov', true, [ _sLabel, vUuids.join ( '\n   ' ) ] );
				if ( uQueueLen > 0 )
				{
					// have at least one possibly compatible service to query
					_anePr.addEventListener ( PeripheralEvent.DISCOVER_CHARACTERISTICS, _AnePrDiscoveredCharacteristics, false, 0 , true );
					_callLater ( _CharacteristicsDiscover );
				}
				else
				{
					// nothing here for us
					_QueriesDone ( );
					_debugOut ( 'status_ble_srvs_discov_nc', true, [ _sLabel ] );
				}
			}
			else
			{
				// nothing here at all
				_QueriesDone ( );
				_debugOut ( 'status_ble_srvs_discov_none', true, [ _sLabel ] );
			}
		}
		
		private function _BusyUpdate ( ) : void
		{
			_isBusySet ( _bConnecting || _bQuerying );
		}
		
		private function _CharacteristicsDiscover ( ) : void
		{
			if ( _vBseQueryQueue.length < 1 )
			{
				_anePr.removeEventListener ( PeripheralEvent.DISCOVER_CHARACTERISTICS, _AnePrDiscoveredCharacteristics );
				_QueriesDone ( );
				return; // return
			}
			
			_actionCheckTimerSet ( _ACT_PR_CRS_QUERY );
			var srv:Service = _vBseQueryQueue [ 0 ].service;
			_IsQueryingSet ( _anePr.discoverCharacteristics ( srv ) );
			_debugOut ( 'status_ble_crs_discov_' + ( _bQuerying ? 'init' : 'deny' ), true, [ _sLabel, srv.uuid ] );
		}
		
		private function _CharacteristicsDiscoveryTimedOut ( ) : void
		{
			var sUuid:String = '?';
			if ( _vBseQueryQueue.length > 0 )
			{
				sUuid = _vBseQueryQueue [ 0 ].uuid;
			}
			_debugOut ( 'status_ble_crs_discov_to', true, [ _sLabel, sUuid ] );
			
			if ( _retryOk ( ) )
			{
				_callLater ( _CharacteristicsDiscover );
			}
			else
			{
				_anePr.removeEventListener ( PeripheralEvent.DISCOVER_CHARACTERISTICS, _AnePrDiscoveredCharacteristics );
				_DiscoveryDone ( );
			}
		}
		
		private function _Connect ( ) : void
		{
			if ( _bConnected || _bConnecting )
			{
				// already connected or trying to be
				return; // return
			}
			
			_bDisconnecting = false;
			_actionCheckTimerSet ( _ACT_PR_CONNECT );
			_aneCentralMgr.addEventListener ( PeripheralEvent.CONNECT, _AnePrConnectSucceeded );
			_aneCentralMgr.addEventListener ( PeripheralEvent.CONNECT_FAIL, _AnePrConnectFailed );
			
			_IsConnectingSet ( _aneCentralMgr.connect ( _anePr ) );
			
			_debugOut ( 'status_ble_pr_conn_' + ( _bConnecting ? 'init' : 'deny' ), true, [ _sLabel ] );
		}
		
		private function _ConnectFailed ( timedOut:Boolean = false ) : void
		{
			_IsConnectingSet ( false );
			
			// remove connect listeners
			_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT, _AnePrConnectSucceeded );
			_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT_FAIL, _AnePrConnectFailed );
			
			_debugOut ( 'status_ble_pr_conn_' + ( timedOut ? 'to' : 'fail' ), true, [ _sLabel ] );
			
			// try again?
			if ( _retryOk ( ) )
			{
				_ConnectIfNeededQueue ( );
			}
			else
			{
				_DiscoveryDone ( );
			}
		}
		
		private function _ConnectIfNeeded ( ) : void
		{
			_bConnectQueued = false;
			if ( _bKeepConnected || !_bDiscoveryDone )
			{
				_Connect ( );
			}
		}
		
		private function _ConnectIfNeededQueue ( ) : void
		{
			if ( !_bConnectQueued )
			{
				_bConnectQueued = true;
				_callLater ( _ConnectIfNeeded );
			}
		}
		
		private function _Disconnect ( ) : void
		{
			if ( _bDisconnecting || ( !_bConnecting && !_bConnected ) )
			{
				return; // return
			}
			
			if ( _bConnecting )
			{
				_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT, _AnePrConnectSucceeded );
				_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT_FAIL, _AnePrConnectFailed );
				_aneCentralMgr.addEventListener ( PeripheralEvent.DISCONNECT, _AnePrDisconnected );
				_IsConnectingSet ( false );
			}
			
			var i_bpe:BleProtocolExec;
			for each ( i_bpe in _vBpe )
			{
				i_bpe.disconnectPrep ( );
			}
			
			_bDisconnecting = _aneCentralMgr.disconnect ( _anePr );
			
			if ( _bDisconnecting )
			{
				_debugOut ( 'status_ble_pr_disconn_init', true, [ _sLabel ] );
			}
			else
			{
				_debugOut ( 'status_ble_pr_disconn_deny', true, [ _sLabel ] );
				
			}
		}
		
		private function _DisconnectIfFree ( event:TimerEvent ) : void
		{
			if ( _tmrDisc )
			{
				_tmrDisc.stop ( );
				_tmrDisc.removeEventListener ( TimerEvent.TIMER, _DisconnectIfFree );
				_tmrDisc = null;
			}
			if ( !_bDiscoveryDone )
			{
				_bDiscoveryDone = true;
				_IconStyleUpdate ( );
				dispatchEvent ( new Event ( BLE_PERIPHERAL_DISCOVERY_DONE ) );
			}
			if ( !_bKeepConnected )
			{
				_Disconnect ( );
			}
		}
		
		private function _DisconnectIfFreeQueue ( ) : void
		{
			if ( !_tmrDisc )
			{
				_tmrDisc = new Timer ( ACTION_CHECK_DELAY, 0 );
				_tmrDisc.addEventListener ( TimerEvent.TIMER, _DisconnectIfFree );
				_tmrDisc.start ( );
			}
		}
		
		private function _DiscoveryDone ( ) : void
		{
			_IsQueryingSet ( false );
			_DisconnectIfFreeQueue ( );
		}
		
		/**
		 * Instantiates exec objects and discovery queue
		 * @return Boolean false if already initialized, true if had to do it now
		 */
		private function _ExecsInit ( ) : Boolean
		{
			if ( _oBseUuidHash != null )
			{
				// already initialized
				return false; // return
			}
			
			_vBseQueryQueue = new <BleServiceExec> [];
			_oBseUuidHash = {};
			
			// hashes that will be populated with reference(s) to compatible
			// characteristic(s) if found
			_oBcePathHash = {};
			_dBceAneCrHash = new Dictionary ( );
			// instantiate evaluation wrapper(s) for peripheral spec(s)
			// and populate vector and id hashes
			_oBpeIdHash = {};
			
			var iLen:int = 0;
			var i_bpe:BleProtocolExec;
			var i_bps:BleProtocolSpec;
			var j_bse:BleServiceExec;
			var k_sUuid:String;
			for each ( i_bps in _vBps )
			{
				// instantiate evaluation wrapper for each peripheral spec
				i_bpe = new BleProtocolExec ( this, i_bps, _ProtocolSpecMet );
				// add to peripheral evals vector
				_vBpe [ iLen++ ] = i_bpe;
				// add to peripheral evals ID hash
				_oBpeIdHash [ i_bps.id ] = i_bpe;
				for each ( j_bse in i_bpe.serviceExecs )
				{
					for each ( k_sUuid in j_bse.serviceSpec.uuids )
					{
						// add to service evals UUID hash
						_oBseUuidHash [ k_sUuid ] = j_bse;
					}
				}
			}
			return true;
		}
		
		private function _IconStyleUpdate ( ) : void
		{
			var uColor:uint;
			/*if ( _bConnected )
			{
				uColor = 0x0099ff;
			}
			else*/ 
			if ( _bUsable )
			{
				uColor = 0x009900;
			}
			else if ( _bQueriesDone )
			{
				uColor = 0xffff00;
			}
			else if ( _bDiscoveryDone )
			{
				uColor = 0xcc0000;
			}
			else
			{
				uColor = 0xffffff;
			}
			_iconColorSet ( uColor );
		}
		
		private function _IsMine ( pr:Peripheral ) : Boolean
		{
			return ( pr.identifier == _iAneId && pr.uuid == _sDevId );
		}
		
		private function _IsNotMine ( pr:Peripheral ) : Boolean
		{
			return ( pr.identifier != _iAneId || pr.uuid != _sDevId );
		}
		
		private function _ListenersCentralRemoveAll ( ) : void
		{
			if ( _aneCentralMgr )
			{
				_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT, _AnePrConnectSucceeded );
				_aneCentralMgr.removeEventListener ( PeripheralEvent.CONNECT_FAIL, _AnePrConnectFailed );
				_aneCentralMgr.removeEventListener ( PeripheralEvent.DISCONNECT, _AnePrDisconnected );
			}
		}
		
		private function _ListenersPeripheralRemoveAll ( ) : void
		{
			if ( _anePr )
			{
				_anePr.removeEventListener ( PeripheralEvent.DISCOVER_CHARACTERISTICS, _AnePrDiscoveredCharacteristics );
				_anePr.removeEventListener ( PeripheralEvent.DISCOVER_SERVICES, _AnePrDiscoveredServices );
			}
		}
		
		private function _LocaleLabelUpdate ( notify:Boolean = true ) : void
		{
			var sNew:String = _resourceManager.getString ( 'default', 'ble_pr_item_label', [ _sName, identifier.toString() ] );
			if ( sNew == _sLabel )
				return;
			
			_sLabel = sNew;
			if ( notify )
			{
				dispatchEvent ( new Event ( BLE_PERIPHERAL_LABEL_CHANGE ) );
			}
		}
		
		private function _LocaleStateUpdate ( notify:Boolean = true ) : void
		{
			var sSfx:String;
			if ( !_sState || _sState == PeripheralState.UNKNOWN )
			{
				sSfx = 'unknown';
			}
			else
			{
				sSfx = _sState;
			}
			_sStateDisp = _resourceManager.getString ( 'default', 'ble_pr_state_' + sSfx );
			if ( notify )
			{
				dispatchEvent ( new Event ( BLE_PERIPHERAL_STATE_CHANGE ) );
			}
		}
		
		private function _ProtocolSpecMet (
			specId:String,
			bps:BleProtocolSpec,
			bpe:BleProtocolExec,
			vBce:Vector.<BleCharacteristicExec>
		) : void
		{
			if ( _vBpsIdsComp.indexOf ( specId ) < 0 )
			{
				
				// add to list of specs met
				_vBpsIdsComp [ _vBpsIdsComp.length ] = specId;
				
				// add its characteristic(s) to path hash
				var i_bce:BleCharacteristicExec;
				for each ( i_bce in vBce )
				{
					_oBcePathHash [ i_bce.characteristicSpec.path ] = i_bce;
					_dBceAneCrHash [ i_bce.characteristic ] = i_bce;
				}
				
				_IsUsableSet ( true );
				
				dispatchEvent ( new Event ( BLE_PERIPHERAL_SPEC_IDS_CHANGE ) );
			}
			
			// inform the protocol spec
			bps.compatibleAgentFound ( this );
		}
		
		private function _QueriesDone ( ) : void
		{
			_bQueriesDone = true;
			_DiscoveryDone ( );
			_IconStyleUpdate ( );
		}
		
		private function _RetentionUpdate ( ) : void
		{
			var bNew:Boolean;
			function bpeNeeded ( bpe:BleProtocolExec, idx:int, vBpe:Vector.<BleProtocolExec> ) : Boolean
			{
				return ( bpe.isEngaged );
			}
			
			bNew = _vBpe.some ( bpeNeeded );
			if ( bNew == _bKeepConnected )
			{
				// no change
				return; // return
			}
			
			_bKeepConnected = bNew;
			
			if ( _bKeepConnected )
			{
				_Connect ( );
			}
			else
			{
				_DisconnectIfFreeQueue ( );
			}
		}
		
		private function _ServicesDiscover ( ) : void
		{
			if ( !_bConnected )
			{
				return; // return
			}
			
			_actionCheckTimerSet ( _ACT_PR_SRVS_QUERY );
			
			// add services listener
			_anePr.addEventListener ( PeripheralEvent.DISCOVER_SERVICES, _AnePrDiscoveredServices, false, 0 , true );
			
			_IsQueryingSet ( _anePr.discoverServices ( /* _vSvcUuids */ ) );
			
			_debugOut ( 'status_ble_srvs_discov_' + ( _bQuerying ? 'init' : 'deny' ), true, [ _sLabel ] );
			
		}
		
		private function _ServicesDiscoveryTimedOut ( ) : void
		{
			// remove services listener
			_anePr.removeEventListener ( PeripheralEvent.DISCOVER_SERVICES, _AnePrDiscoveredServices );
			
			_debugOut ( 'status_ble_srvs_discov_to', true, [ _sLabel ] );
			
			if ( _retryOk ( ) )
			{
				_callLater ( _ServicesDiscover );
			}
			else
			{
				_DiscoveryDone ( );
			}
		}
		
		private function _StatusUpdate ( peripheral:Peripheral, rssi:Number ) : void
		{
			_RssiSet ( rssi );
			_StateSet ( peripheral.state );
		}
	}
}