package com.arxterra.controllers
{
	import com.arxterra.events.BleEvent;
	import com.arxterra.interfaces.IBleClient;
	import com.arxterra.utils.BleBase;
	import com.arxterra.utils.BlePeripheralAgent;
	import com.arxterra.vo.BleCharacteristicSpec;
	import com.arxterra.vo.BleProtocolSpec;
	import com.arxterra.vo.BleServiceSpec;
	import com.arxterra.vo.UserState;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.BluetoothLEState;
	import com.distriqt.extension.bluetoothle.events.AuthorisationEvent;
	import com.distriqt.extension.bluetoothle.events.CentralManagerEvent;
	import com.distriqt.extension.bluetoothle.events.PeripheralEvent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Peripheral;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.apache.flex.collections.VectorCollection;
	import org.apache.flex.collections.VectorList;
	import com.distriqt.extension.bluetoothle.AuthorisationStatus;
	
	[Event(name="ble_enabled_change", type="flash.events.Event")]
	[Event(name="ble_filter_labels_change", type="flash.events.Event")]
	[Event(name="ble_greedy_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_agents_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_agents_collection_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_agents_filter_change", type="flash.events.Event")]
	[Event(name="ble_peripheral_spec_ids_change", type="flash.events.Event")]
	[Event(name="ble_scanning_changed", type="flash.events.Event")]
	
	[Event(name="ble_peripheral_connected", type="com.arxterra.events.BleEvent")]
	[Event(name="ble_peripheral_disconnected", type="com.arxterra.events.BleEvent")]

	/**
	 * Singleton class to serve as clearing house for Bluetooth LE device agents.
	 */
	public class BleManager extends BleBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const BLE_ENABLED_CHANGE:String = 'ble_enabled_change';
		public static const BLE_FILTER_LABELS_CHANGE:String = 'ble_filter_labels_change';
		public static const BLE_GREEDY_CHANGE:String = 'ble_greedy_change';
		public static const BLE_PERIPHERAL_AGENTS_CHANGE:String = 'ble_peripheral_agents_change';
		public static const BLE_PERIPHERAL_AGENTS_COLLECTION_CHANGE:String = 'ble_peripheral_agents_collection_change';
		public static const BLE_PERIPHERAL_AGENTS_FILTER_CHANGE:String = 'ble_peripheral_agents_filter_change';
		public static const BLE_SCANNING_CHANGED:String = 'ble_scanning_changed';
		
		private static const __FLAG_VC_FILTER:uint = 1;
		private static const __FLAG_VC_SOURCE:uint = 1 << 1;
		
		private static const __SCAN_WINDOW:int = 10000;
		
		private static var __instance:BleManager;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : BleManager
		{
			if ( !__instance )
			{
				__instance = new BleManager ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		public function BleManager ( enforcer:SingletonEnforcer )
		{
			super();
			
			var userState:UserState = _sessionMgr.userState;
			var i:int;
			var iLen:int = 0;
			var i_sId:String;
			var i_bps:BleProtocolSpec;
			var i_sExp:String;
			var i_iExpLen:int;
			var sRegExp:String = '';
			
			// support for Bluetooth LE already checked by vo.McuConnectModes
			_ane = BluetoothLE.service;
			_aneCentralMgr = _ane.centralManager;
			
			_vBpa = new <BlePeripheralAgent> [];
			_vBpa1 = new <BlePeripheralAgent> [];
			_vBpa2 = new <BlePeripheralAgent> [];
			
			_oBpaDevIdHash = {};
			_oBpaExtIdHash = {};
			_oBpsIdHash = {};
			
			_vFiltIds = new <String> [ ];
			_vBps = new <BleProtocolSpec> [];
			
			// test of instantiation based on object from runtime source, such as JSON stream
			/*
			var oBpsMcu:Object = {
				'id': 'mcu',
				'serviceSpecs': [
					{
						'id': 'serial',
						'uuids': [
							'ffe0',
							'0000ffe0-0000-1000-8000-00805f9b34fb'
						],
						'characteristicSpecs': [
							{
								'id': 'nrw',
								'uuids': [
									'ffe1',
									'0000ffe1-0000-1000-8000-00805f9b34fb'
								],
								'properties': [
									'notify',
									'read',
									'writeWithoutResponse'
								],
								'permissions': [
								]
							}
						]
					}
				],
				'label': 'Main MCU',
				'priorityNameExp': '(^3dot)|(^hmsoft)|(^dsd tech)|(^bt05-a)'
			};
			var bps:BleProtocolSpec = BleProtocolSpec.NewFromObject ( oBpsMcu );
			if ( bps != null )
			{
				_vBps [ iLen++ ] = bps;
			}
			*/
			
			// hardcoded instantiation
			
			// EH-MC17
			_vBps [ iLen++ ] = new BleProtocolSpec (
				'mcu_0',
				new <BleServiceSpec> [
					new BleServiceSpec (
						'serial',
						new <String> [
							'e0ff',
							'0000e0ff-3c17-d293-8e48-14fe2e4da212'
						],
						new <BleCharacteristicSpec> [
							new BleCharacteristicSpec (
								'w',
								new <String> [
									'ffe1',
									'0000ffe1-0000-1000-8000-00805f9b34fb'
								],
								new <String> [
									Characteristic.PROPERTY_WRITEWITHOUTRESPONSE
								],
								new <String> []
							),
							new BleCharacteristicSpec (
								'n',
								new <String> [
									'ffe2',
									'0000ffe2-0000-1000-8000-00805f9b34fb'
								],
								new <String> [
									Characteristic.PROPERTY_NOTIFY
								],
								new <String> []
							)
						]
					)
				],
				_resourceManager.getString ( 'default', 'ble_module_mcu_0_label' ),
				_resourceManager.getString ( 'default', 'ble_module_mcu_0_regexp' )
			);
			
			// HM-11
			_vBps [ iLen++ ] = new BleProtocolSpec (
				'mcu_1',
				new <BleServiceSpec> [
					new BleServiceSpec (
						'serial',
						new <String> [
							'ffe0',
							'0000ffe0-0000-1000-8000-00805f9b34fb'
						],
						new <BleCharacteristicSpec> [
							new BleCharacteristicSpec (
								'nrw',
								new <String> [
									'ffe1',
									'0000ffe1-0000-1000-8000-00805f9b34fb'
								],
								new <String> [
									Characteristic.PROPERTY_NOTIFY,
									Characteristic.PROPERTY_READ,
									Characteristic.PROPERTY_WRITEWITHOUTRESPONSE
								],
								new <String> []
							)
						]
					)
				],
				_resourceManager.getString ( 'default', 'ble_module_mcu_1_label' ),
				_resourceManager.getString ( 'default', 'ble_module_mcu_1_regexp' )
			);
			
			for ( i=0; i<iLen; i++ )
			{
				i_bps = _vBps [ i ];
				i_bps.addEventListener ( BleProtocolSpec.BLE_PROTOCOL_SPEC_READY_CHANGE, _BpsReadyChange );
				i_sId = i_bps.id;
				// add to config view filter options
				_vFiltIds [ i ] = i_sId;
				// add protocol spec(s) to ID hash
				_oBpsIdHash [ i_sId ] = i_bps;
				// get previously connected deviceId, if any
				i_bps.previousSelectedId = userState.getBleSpecAddress ( i_sId );
				// add priority name expression, if any, to regular expression string
				i_sExp = i_bps.priorityNameExp;
				i_iExpLen = i_sExp.length;
				if ( i_iExpLen > 0 )
				{
					if ( ( i_sExp.charAt ( 0 ) != '(' ) || ( i_sExp.charAt ( i_iExpLen - 1 ) != ')' ) )
					{
						i_sExp = '(' + i_sExp + ')';
					}
					if ( sRegExp.length > 0 )
					{
						sRegExp += '|';
					}
					sRegExp += i_sExp;
				}
			}
			// instantiate the regular expression
			_rePriority = new RegExp ( sRegExp, 'i' );
			// make "show all" the first option
			_vFiltIds.insertAt ( 0, '' );
			// previously initialized filtering view to 'mcu'
			// _iFiltIdx = 1;
			// _sFiltId = 'mcu';
			// stopped that as of 2019-10-08
			_LocaleFilterLabelsUpdate ( false );
			
			// add adapter and centralManager's event listeners
			_ane.addEventListener ( AuthorisationEvent.CHANGED, _AneAuthChanged );
			_aneCentralMgr.addEventListener ( CentralManagerEvent.STATE_CHANGED, _AneStateChanged );
			_aneCentralMgr.addEventListener ( PeripheralEvent.DISCOVERED, _AnePrDiscovered );
			
			_callLater ( _StateCheck );
		}
		
		override public function dismiss ( ) : void
		{
			var i_prAgt:BlePeripheralAgent;
			var i_bps:BleProtocolSpec;
			if ( _ane != null )
			{
				/*
				if ( _bEnabled )
				{
				}
				*/
				
				// remove adapter and centralManager's event listeners
				_ane.removeEventListener ( AuthorisationEvent.CHANGED, _AneAuthChanged );
				_aneCentralMgr.removeEventListener ( CentralManagerEvent.STATE_CHANGED, _AneStateChanged );
				_aneCentralMgr.removeEventListener ( PeripheralEvent.DISCOVERED, _AnePrDiscovered );
				
				if ( _vBpa != null )
				{
					_oBpaDevIdHash = null;
					_oBpaExtIdHash = null;
					_vBpa1.length = 0;
					_vBpa1 = null;
					_vBpa2.length = 0;
					_vBpa2 = null;
					while ( _vBpa.length > 0 )
					{
						i_prAgt = _vBpa.pop();
						// remove listeners
						i_prAgt.removeEventListener ( BlePeripheralAgent.BLE_PERIPHERAL_DISCOVERY_DONE, _BlePrDiscoveryDone );
						i_prAgt.removeEventListener ( BlePeripheralAgent.BLE_PERIPHERAL_SPEC_IDS_CHANGE, _BlePrSpecIdsChange );
						i_prAgt.removeEventListener ( BleEvent.BLE_CONFIG, _BlePrConfigRequest );
						i_prAgt.removeEventListener ( BleEvent.BLE_PERIPHERAL_CONNECTED, _BlePrConnected ); // relay
						i_prAgt.removeEventListener ( BleEvent.BLE_PERIPHERAL_DISCONNECTED, _BlePrDisconnected ); // relay
						i_prAgt.dismiss();
					}
					i_prAgt = null;
					_vBpa = null;
				}
				
				if ( _vBps != null )
				{
					_oBpsIdHash = null;
					while ( _vBps.length > 0 )
					{
						i_bps = _vBps.pop();
						i_bps.removeEventListener ( BleProtocolSpec.BLE_PROTOCOL_SPEC_READY_CHANGE, _BpsReadyChange );
						i_bps.dismiss();
					}
					_vBps = null;
				}
				
				_aneCentralMgr = null;
				_ane = null;
				BluetoothLE.service.dispose ( );
			}
			
			super.dismiss ( );
			__instance = null;
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="ble_enabled_change")]
		public function get isEnabled():Boolean
		{
			return _bEnabled;
		}
		private function _IsEnabledSet(value:Boolean):void
		{
			if ( value !== _bEnabled )
			{
				_bEnabled = value;
				dispatchEvent ( new Event ( BLE_ENABLED_CHANGE ) );
			}
		}
		
		[Bindable (event="ble_greedy_change")]
		public function get isGreedy():Boolean
		{
			return _bGreedy;
		}
		
		[Bindable (event="ble_scanning_changed")]
		public function get isScanning():Boolean
		{
			if ( _aneCentralMgr )
			{
				return _aneCentralMgr.isScanning; // return
			}
			
			return false;
		}
		
		[Bindable (event="ble_peripheral_agents_change")]
		public function get peripheralAgents():Vector.<BlePeripheralAgent>
		{
			return _vBpa;
		}
		
		[Bindable (event="ble_peripheral_agents_collection_change")]
		public function get peripheralAgentsCollection():VectorCollection
		{
			// wait to create this until actually needed
			if ( _vcBpa == null )
			{
				_vcBpa = new VectorCollection ( _vBpa );
				if ( _sFiltId != '' )
				{
					_vcBpa.filterFunction = _VcBpaFilterBySpecId;
					_vcBpa.refresh ( );
				}
			}
			return _vcBpa;
		}
		
		[Bindable (event="ble_filter_labels_change")]
		public function get peripheralAgentsFilterLabels():VectorList
		{
			if ( !_vlFiltLabs )
			{
				_vlFiltLabs = new VectorList ( _vFiltLabs );
			}
			return _vlFiltLabs;
		}
		
		[Bindable (event="ble_peripheral_agents_filter_change")]
		public function get peripheralAgentsFilterOn():Boolean
		{
			return ( _sFiltId != '' );
		}
		
		[Bindable (event="ble_peripheral_agents_filter_change")]
		public function get peripheralAgentsFilterSelectedIndex():int
		{
			return _iFiltIdx;
		}
		public function set peripheralAgentsFilterSelectedIndex(value:int):void
		{
			if ( value >= 0 && value < _vFiltIds.length )
			{
				_iFiltIdx = value;
				_VcBpaFilterIdSet ( _vFiltIds [ value ] );
			}
		}
		
		[Bindable (event="ble_peripheral_agents_filter_change")]
		public function get peripheralAgentsFilterSelectedLabel():String
		{
			return _vFiltLabs [ _iFiltIdx ];
		}
		
		[Bindable (event="ble_filter_labels_change")]
		public function get peripheralAgentsFilterTypicalLabel():String
		{
			return _sFiltLabTyp;
		}
		
		// OTHER PUBLIC METHODS
		
		// called by client (implements IBleClient) such as McuConnectorBLE
		public function clientDisengage ( client:IBleClient, specId:String, characteristicCallbacks:Object = null ) : void
		{
			if ( specId in _oBpsIdHash )
			{
				( _oBpsIdHash [ specId ] as BleProtocolSpec ).disengage ( client, characteristicCallbacks );
			}
		}
		
		// called by client (implements IBleClient) such as McuConnectorBLE
		public function clientEngage ( client:IBleClient, specId:String, characteristicCallbacks:Object = null ) : BleProtocolSpec
		{
			var bps:BleProtocolSpec;
			if ( specId in _oBpsIdHash )
			{
				bps = _oBpsIdHash [ specId ] as BleProtocolSpec;
				bps.engage ( client, characteristicCallbacks );
			}
			return bps;
		}
		
		public function configViewReady ( ) : void
		{
			if ( _iAuthRequest > 1 )
			{
				_callLater ( _EnableWithUI );
			}
			else if ( _iAuthRequest > 0 )
			{
				_callLater ( _AuthRequest );
			}
			else
			{
				var sAuthState:String = _ane.authorisationStatus ( );
				if ( sAuthState == AuthorisationStatus.DENIED || sAuthState == AuthorisationStatus.RESTRICTED )
				{
					_callLater ( _AuthRequest );
				}
			}
			_iAuthRequest = 0;
		}
		
		public function getProtocolSpecById ( specId:String ) : BleProtocolSpec
		{
			if ( specId in _oBpsIdHash )
			{
				return _oBpsIdHash [ specId ] as BleProtocolSpec; // return
			}
			
			return null;
		}
		
		public function getPeripheralAgentByDeviceId ( deviceId:String ) : BlePeripheralAgent
		{
			if ( deviceId in _oBpaDevIdHash )
			{
				return _oBpaDevIdHash [ deviceId ] as BlePeripheralAgent; // return
			}
			
			return null;
		}
		
		public function getPeripheralAgentByExtendedId ( extId:String ) : BlePeripheralAgent
		{
			if ( extId in _oBpaExtIdHash )
			{
				return _oBpaExtIdHash [ extId ] as BlePeripheralAgent; // return
			}
			
			return null;
		}
		
		public function getPeripheralAgentsBySpecId ( specId:String ) : Vector.<BlePeripheralAgent>
		{
			function bpaFilter ( bpa:BlePeripheralAgent, idx:int, vBpa:Vector.<BlePeripheralAgent> ) : Boolean
			{
				return ( bpa.compatibleSpecIds.indexOf ( specId ) >= 0 );
			}
			return _vBpa.filter ( bpaFilter );
		}
		
		public function getSpecSelectedAgent ( specId:String ) : BlePeripheralAgent
		{
			if ( specId in _oBpsIdHash )
			{
				return ( _oBpsIdHash [ specId ] as BleProtocolSpec ).selectedAgent;
			}
			return null;
		}
		
		/**
		 * Turn greedy scanning mode on/off
		 */
		public function greedyToggle ( ) : void
		{
			_bGreedy = !_bGreedy;
			// pause or resume discovery as needed
			if ( _bGreedy )
			{
				_DiscoveryResume ( );
			}
			else
			{
				if ( _BpsAllReady ( ) )
				{
					_DiscoveryPause ( );
				}
			}
			dispatchEvent ( new Event ( BLE_GREEDY_CHANGE ) );
		}
		
		/**
		 * Turn scanning for peripherals on/off
		 */
		public function scanToggle ( ) : void
		{
			if ( isScanning )
			{
				_ScanEnd ( );
			}
			else
			{
				_ScanBegin ( );
			}
		}
		
		
		// PROTECTED METHODS
		
		override protected function _actionCheckTimeout ( event:TimerEvent = null ) : void
		{
			super._actionCheckTimeout ( );
			
			// have not been able to progress automatically
			var sRsrc:String = 'status_ble_cfg_capt_' + _actionId;
			if ( _actionId == _ACT_ENABLE )
			{
				_statusCaptionSet ( _resourceManager.getString ( 'default', sRsrc, [ _aneCentralMgr.state ] ) );
				_iAuthRequest = 2;
			}
			else if ( _bSomeConn && _actionId == _ACT_PRS_SCAN )
			{
				// peripherals already connected are not advertising,
				// so no need to raise alarm, open config, etc.
				return; // return
			}
			else
			{
				_statusCaptionSet ( _resourceManager.getString ( 'default', sRsrc ) );
			}
			_configOpen ( );
		}
		
		override protected function _configOpen ( id:String = '', params:Object = null ) : void
		{
			// set index if id is valid
			peripheralAgentsFilterSelectedIndex = _vFiltIds.indexOf ( id );
			// pass on validated id
			super._configOpen ( _sFiltId, params );
		}
		
		override protected function _localeUpdate ( event:Event = null ) : void
		{
			super._localeUpdate ( event );
			_callLater ( _LocaleFilterLabelsUpdate );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bDiscPaused:Boolean = false;
		private var _bDiscPend:Boolean = false;
		private var _bEnabled:Boolean = false;
		private var _bGreedy:Boolean = false;
		private var _bSomeConn:Boolean = false;
		private var _iAuthRequest:int = 0;
		private var _iFiltIdx:int = 0;
		private var _oBpaDevIdHash:Object; 
		private var _oBpaExtIdHash:Object; // BlePeripheralAgent instances keyed to our extended device ID, which is UUID + '_' + the extension's internal numerical identifier
		private var _oBpsIdHash:Object; // key:value = spec ID:BleProtocolSpec instance
		private var _rePriority:RegExp;
		private var _sFiltId:String = '';
		private var _sFiltLabTyp:String;
		private var _tmrScan:Timer;
		private var _vBpa:Vector.<BlePeripheralAgent>; // vector of BlePeripheralAgent instances for all peripherals discovered by Bluetooth LE ANE
		private var _vBpa1:Vector.<BlePeripheralAgent>; // vector of BlePeripheralAgent instances for peripherals to query first
		private var _vBpa2:Vector.<BlePeripheralAgent>; // vector of BlePeripheralAgent instances for peripherals to query last
		private var _vBps:Vector.<BleProtocolSpec>;
		private var _vFiltIds:Vector.<String>;
		private var _vFiltLabs:Vector.<String>;
		private var _vlFiltLabs:VectorList;
		private var _vcBpa:VectorCollection; // collection with _vBpa as its source
		
		
		// PRIVATE METHODS
		
		// AuthorisationEvent.CHANGED from ANE
		private function _AneAuthChanged ( event:AuthorisationEvent ) : void
		{
			_StateCheck ( );
		}
		
		// PeripheralEvent.DISCOVERED from CentralManager
		private function _AnePrDiscovered ( event:PeripheralEvent ) : void
		{
			_actionCheckTimerClear ( _ACT_PRS_SCAN, true );
			var prAgt:BlePeripheralAgent;
			var pr:Peripheral = event.peripheral;
			var xid:String = _xidCreate ( pr.uuid, pr.identifier );
			if ( xid in _oBpaExtIdHash )
			{
				// one we're already aware of
				( _oBpaExtIdHash [ xid ] as BlePeripheralAgent ).rediscovered ( pr, event.RSSI );
			}
			else
			{
				// new
				prAgt = new BlePeripheralAgent ( pr, event.RSSI, xid, _vBps );
				_vBpa [ _vBpa.length ] = prAgt;
				if ( _rePriority.test ( pr.name ) )
				{
					// a high priority device
					_vBpa1 [ _vBpa1.length ] = prAgt;
					_callLater ( _DiscoveryNext );
				}
				else
				{
					_vBpa2 [ _vBpa2.length ] = prAgt;
				}
				_oBpaDevIdHash [ pr.uuid ] = prAgt;
				_oBpaExtIdHash [ xid ] = prAgt;
				_VcBpaRefresh ( __FLAG_VC_SOURCE );
				prAgt.addEventListener ( BlePeripheralAgent.BLE_PERIPHERAL_DISCOVERY_DONE, _BlePrDiscoveryDone );
				prAgt.addEventListener ( BlePeripheralAgent.BLE_PERIPHERAL_SPEC_IDS_CHANGE, _BlePrSpecIdsChange );
				prAgt.addEventListener ( BleEvent.BLE_CONFIG, _BlePrConfigRequest );
				prAgt.addEventListener ( BleEvent.BLE_PERIPHERAL_CONNECTED, _BlePrConnected ); // relay
				prAgt.addEventListener ( BleEvent.BLE_PERIPHERAL_DISCONNECTED, _BlePrDisconnected ); // relay
				dispatchEvent ( new Event ( BLE_PERIPHERAL_AGENTS_CHANGE ) );
			}
		}
		
		// CentralManagerEvent.STATE_CHANGED from CentralManager
		private function _AneStateChanged ( event:CentralManagerEvent ) : void
		{
			_StateCheck ( );
		}
		
		private function _AuthRequest ( ) : void
		{
			_ane.requestAuthorisation ( );
		}
		
		// BleEvent.BLE_CONFIG from BlePeripheralAgent
		private function _BlePrConfigRequest ( event:BleEvent ) : void
		{
			_statusCaptionSet ( event.params as String );
			_configOpen ( event.id, event.params );
		}
		
		// BleEvent.BLE_PERIPHERAL_CONNECTED from BlePeripheralAgent
		private function _BlePrConnected ( event:BleEvent ) : void
		{
			_bSomeConn = true;
			_IconStyleUpdate ( );
			dispatchEvent ( event ); // relay
		}
		
		// BleEvent.BLE_PERIPHERAL_DISCONNECTED from BlePeripheralAgent
		private function _BlePrDisconnected ( event:BleEvent ) : void
		{
			function bpaConnected ( bpa:BlePeripheralAgent, idx:int, vBpa:Vector.<BlePeripheralAgent> ) : Boolean
			{
				return bpa.isConnected;
			}
			_bSomeConn = _vBpa.some ( bpaConnected );
			// ##### TODO
			// could the above be replaced by the following line?
			// _bSomeConn = ( _aneCentralMgr.peripherals.length > 0 );
			// ##########
			_IconStyleUpdate ( );
			dispatchEvent ( event ); // relay
		}
		
		// BlePeripheralAgent.BLE_PERIPHERAL_DISCOVERY_DONE
		private function _BlePrDiscoveryDone ( event:Event ) : void
		{
			_bDiscPend = false;
			_callLater ( _DiscoveryNext );
		}
		
		// BlePeripheralAgent.BLE_PERIPHERAL_SPEC_IDS_CHANGE
		private function _BlePrSpecIdsChange ( event:Event ) : void
		{
			_VcBpaRefresh ( );
			// relay event onward
			dispatchEvent ( event );
		}
		
		private function _BpsAllReady ( ) : Boolean
		{
			var i:int;
			var iLen:int = _vBps.length;
			if ( iLen < 1 )
			{
				// should never happen
				// _debugOut ( '_BpsAllReady false 1' );
				return false; // return
			}
			for ( i=0; i<iLen; i++ )
			{
				if ( !_vBps [ i ].isReady )
				{
					// at least one is not ready
					// _debugOut ( '_BpsAllReady false 2' );
					return false; // return
				}
			}
			// if get here, all are ready
			// _debugOut ( '_BpsAllReady true' );
			return true;
		}
		
		private function _BpsAllReadyCheck ( ) : void
		{
			if ( _BpsAllReady ( ) )
			{
				// stop scanning and pause further discovery unless greedy flag is set
				if ( !_bGreedy )
				{
					// pause any ongoing discovery or scanning
					_DiscoveryPause ( );
				}
				_sessionMgr.bleConfigSuccess ( );
			}
			else
			{
				_DiscoveryResume ( );
			}
		}
		
		// BleProtocolSpec.BLE_PROTOCOL_SPEC_READY_CHANGE
		private function _BpsReadyChange ( event:Event ) : void
		{
			_callLater ( _BpsAllReadyCheck );
		}
		
		private function _BusyUpdate ( ) : void
		{
			_isBusySet ( isScanning || !_bEnabled );
		}
		
		private function _DiscoveryNext ( ) : void
		{
			if ( _bDiscPaused || _bDiscPend )
			{
				return; // return
			}
			if ( _vBpa1.length > 0 )
			{
				_bDiscPend = true;
				_vBpa1.shift ( ).discoveryStart ( );
			}
			else if ( !_bGreedy )
			{
				_DiscoveryPause ( );
			}
		}
		
		private function _DiscoveryPause ( ) : void
		{
			if ( !_bDiscPaused )
			{
				// stop servicing discovery queue
				_bDiscPaused = true;
				_ScanEnd ( );
			}
		}
		
		// if not already doing so, start checking any further available peripherals
		private function _DiscoveryResume ( ) : void
		{
			if ( _bDiscPaused )
			{
				_bDiscPaused = false;
				// start servicing discovery queue
				_callLater ( _DiscoveryNext );
			}
		}
		
		private function _EnableWithUI ( ) : void
		{
			_ane.enableWithUI ( );
		}
		
		private function _IconStyleUpdate ( ) : void
		{
			var uNew:uint;
			if ( _bSomeConn )
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
			_iconColorSet ( uNew );
		}
		
		private function _LocaleFilterLabelsUpdate ( notify:Boolean = true ) : void
		{
			var i:int;
			var i_sId:String;
			var iLim:int;
			var iMax:int = 0;
			var sMax:String = '';
			var i_sLabel:String;
			var i_iLen:int;
			iLim = _vBps.length;
			_vFiltLabs = new <String> [ ];
			for ( i=0; i<iLim; i++ )
			{
				i_sLabel = _vBps [ i ].label;
				_vFiltLabs [ i ] = i_sLabel;
				i_iLen = i_sLabel.length;
				if ( i_iLen > iMax )
				{
					iMax = i_iLen;
					sMax = i_sLabel;
				}
			}
			i_sLabel = _resourceManager.getString ( 'default', 'ble_filter_0_label' );
			i_iLen = i_sLabel.length;
			if ( i_iLen > iMax )
			{
				sMax = i_sLabel;
			}
			_sFiltLabTyp = sMax;
			_vFiltLabs.insertAt ( 0, i_sLabel );
			if ( _vlFiltLabs )
			{
				_vlFiltLabs.source = _vFiltLabs;
			}
			if ( notify )
			{
				dispatchEvent ( new Event ( BLE_FILTER_LABELS_CHANGE ) );
				dispatchEvent ( new Event ( BLE_PERIPHERAL_AGENTS_FILTER_CHANGE ) );
			}
		}
		
		private function _ScanBegin ( ) : void
		{
			if ( !_aneCentralMgr.isScanning )
			{
				_actionCheckTimerSet ( _ACT_PRS_SCAN );
				var bOk:Boolean = _aneCentralMgr.scanForPeripherals ( );
				_ScanTimer ( bOk );
				_debugOut ( 'status_ble_scan_' + ( bOk ? 'init' : 'deny' ), true  )
			}
			dispatchEvent ( new Event ( BLE_SCANNING_CHANGED ) );
		}
		
		private function _ScanEnd ( ) : void
		{
			_ScanTimer ( false );
			if ( _aneCentralMgr.isScanning )
			{
				var bOk:Boolean = _aneCentralMgr.stopScan ( );
			}
			dispatchEvent ( new Event ( BLE_SCANNING_CHANGED ) );
			if ( _vBpa2.length > 0 )
			{
				_vBpa1 = _vBpa1.concat ( _vBpa2 );
				_vBpa2.length = 0;
				_callLater ( _DiscoveryNext );
			}
		}
		
		private function _ScanTimeout ( event:TimerEvent = null ) : void
		{
			_ScanEnd ( );
		}
		
		private function _ScanTimer ( scan:Boolean ) : void
		{
			if ( scan )
			{
				if ( !_tmrScan )
				{
					_tmrScan = new Timer ( __SCAN_WINDOW, 1 );
					_tmrScan.addEventListener ( TimerEvent.TIMER, _ScanTimeout );
					_tmrScan.start ( );
				}
			}
			else
			{
				if ( _tmrScan )
				{
					_tmrScan.stop ( );
					_tmrScan.removeEventListener ( TimerEvent.TIMER, _ScanTimeout );
					_tmrScan = null;
				}
			}
		}
		
		private function _StateCheck ( ) : void
		{
			_actionCheckTimerClear ( );
			
			var sAuthState:String = _ane.authorisationStatus ( );
			var sState:String = _ane.state;
			
			_debugOut ( 'status_ble_state', true, [ sState ] );
			_debugOut ( 'status_ble_state_auth', true, [ sAuthState ] );
			
			_IsEnabledSet ( _ane.isEnabled );
			_iAuthRequest = 0;
			_statusCaptionSet ( '' );
			
			if ( _bEnabled )
			{
				_ScanBegin ( );
				// added 2019-10-09
				if ( !_sessionMgr.userState.bleAutoSelect )
				{
					_configOpen ( );
				}
				//
			}
			else
			{
				// not (yet) enabled
				switch ( sAuthState )
				{
					case AuthorisationStatus.NOT_DETERMINED:
					case AuthorisationStatus.SHOULD_EXPLAIN:
						// request user to permit use of bluetooth
						_statusCaptionSet ( _resourceManager.getString ( 'default', 'status_ble_cfg_capt_unauth' ) );
						_iAuthRequest = 1;
						_callLater ( _configOpen );
						break;
					case AuthorisationStatus.UNKNOWN:
						// may be temporary, so set timer and
						// only report to user if time expires
						_actionCheckTimerSet ( _ACT_ENABLE );
						break;
					case AuthorisationStatus.DENIED:
					case AuthorisationStatus.RESTRICTED:
						// user must go to settings app to fix this
						_statusCaptionSet ( _resourceManager.getString ( 'default', 'status_ble_cfg_capt_denied' ) );
						_iAuthRequest = 2;
						_callLater ( _configOpen );
						break;
					default:
						// AuthorisationStatus.AUTHORISED:
						// If get here, BLE adapter may be disabled
						if ( sState != BluetoothLEState.STATE_ON )
						{
							_statusCaptionSet ( _resourceManager.getString ( 'default', 'status_ble_cfg_capt_off' ) );
							_iAuthRequest = 2;
							_callLater ( _configOpen );
						}
						break;
				}
			}
		}
		
		// Filter function for VectorCollection that serves as data provider
		// for list views of discovered peripherals.
		private function _VcBpaFilterBySpecId ( item:Object ) : Boolean
		{
			return ( ( item as BlePeripheralAgent ).compatibleSpecIds.indexOf ( _sFiltId ) >= 0 );
		}
		
		private function _VcBpaFilterIdSet ( value:String ) : void
		{
			_sFiltId = value;
			_callLater ( _VcBpaRefresh, [ __FLAG_VC_FILTER ] );
			dispatchEvent ( new Event ( BLE_PERIPHERAL_AGENTS_FILTER_CHANGE ) );
			// _VcBpaRefresh ( __FLAG_VC_FILTER );
		}
		
		private function _VcBpaRefresh ( flags:uint = 0 ) : void
		{
			if ( _vcBpa != null )
			{
				if ( ( flags & __FLAG_VC_SOURCE ) > 0 )
				{
					_vcBpa.source = _vBpa;
				}
				if ( ( flags & __FLAG_VC_FILTER ) > 0 )
				{
					_vcBpa.filterFunction = ( _sFiltId == '' ? null : _VcBpaFilterBySpecId );
				}
				_vcBpa.refresh ( );
				dispatchEvent ( new Event ( BLE_PERIPHERAL_AGENTS_COLLECTION_CHANGE ) );
			}
		}
		
	}
}
class SingletonEnforcer {}
