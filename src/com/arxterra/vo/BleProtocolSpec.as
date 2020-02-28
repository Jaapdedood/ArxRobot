package com.arxterra.vo
{
	import com.arxterra.controllers.SessionManager;
	import com.arxterra.interfaces.IBleClient;
	import com.arxterra.utils.BlePeripheralAgent;
	import com.arxterra.utils.NonUIComponentBase;
	
	import flash.events.Event;
	
	[Event(name="ble_protocol_spec_ready_change", type="flash.events.Event")]
	
	public class BleProtocolSpec extends NonUIComponentBase
	{
		// CONSTANTS
		
		public static const BLE_PROTOCOL_SPEC_READY_CHANGE:String = 'ble_protocol_spec_ready_change';
		
		
		// PUBLIC PROPERTIES AND ACCESSORS/MUTATORS
		
		/**
		 * Vector of direct references to the characteristic specs
		 * within the service specs included in this spec
		 */
		public function get characteristicSpecs():Vector.<BleCharacteristicSpec>
		{
			return _vBcs;
		}
		
		public function get id():String
		{
			return _sId;
		}
		
		/*
		public function get isConnected():Boolean
		{
			return _bConn;
		}
		public function set isConnected(value:Boolean):void
		{
			if ( value != _bConn )
			{
				_bConn = value;
			}
		}
		*/
		
		public function get isEngaged():Boolean
		{
			return _bEng;
		}
		public function set isEngaged(value:Boolean):void
		{
			_bEng = value;
			if ( _bpe )
			{
				_bpe.isEngaged = value;
			}
		}
		
		[Bindable (event="ble_protocol_spec_ready_change")]
		public function get isReady():Boolean
		{
			return _bReady;
		}
		public function set isReady(value:Boolean):void
		{
			if ( value != _bReady )
			{
				_bReady = value;
				if ( _bEng )
				{
					for ( var i:int=0; i<_iIbcLen; i++ )
					{
						_vIbc [ i ].bleProtocolIsReady ( _sId, value );
					}
				}
				dispatchEvent ( new Event ( BLE_PROTOCOL_SPEC_READY_CHANGE ) );
			}
		}
		
		[Bindable]
		public var label:String;
		
		public var previousSelectedId:String = '';
		
		public var priorityNameExp:String = '';
		
		// may be set by spec itself when autoselecting
		// or by user toggle switch in BleConfigView -> BleAgentItemRenderer -> BleExecItemRenderer
		[Bindable]
		public function get selectedAgent():BlePeripheralAgent
		{
			return _bpa;
		}
		public function set selectedAgent(value:BlePeripheralAgent):void
		{
			if ( value !== _bpa )
			{
				if ( _bpa )
				{
					// deselect old one
					_bpa.protocolSpecDeselect ( this );
				}
				_bpa = value;
				if ( value )
				{
					value.protocolSpecSelect ( this );
				}
			}
		}
		
		/**
		 * Vector of service specs included in this spec
		 */
		public function get serviceSpecs():Vector.<BleServiceSpec>
		{
			return _vBss;
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @param id Our internal ID for this spec, which matches
		 * a client process, such as 'mcu'
		 * @param serviceSpecs Vector of required services
		 * @param label String default human-friendly label for this spec
		 * @param priorityNameExp String for constructing regular expression
		 * to test for expected peripheral names (case will be ignored)
		 * @param localeData Optional object with key:value pairs
		 * such as 'en_US': { 'label': 'Main MCU' } to be used in localization
		 */
		public function BleProtocolSpec (
			id:String,
			serviceSpecs:Vector.<BleServiceSpec>,
			label:String,
			priorityNameExp:String = '',
			localeData:Object = null
		)
		{
			super ( );
			_userState = SessionManager.instance.userState;
			_vIbc = new <IBleClient> [];
			_sId = id;
			this.label = label;
			this.priorityNameExp = priorityNameExp;
			_vBss = serviceSpecs;
			_vBcs = new <BleCharacteristicSpec> [];
			var i_bss:BleServiceSpec;
			var i_bcs:BleCharacteristicSpec;
			for each ( i_bss in _vBss )
			{
				_vBcs = _vBcs.concat ( i_bss.pathsInit ( _sId ) );
			}
			_oBcsPathHash = {};
			for each ( i_bcs in _vBcs )
			{
				_oBcsPathHash [ i_bcs.path ] = i_bcs;
			}
			_dynamicLocalePropsInit (
				localeData,
				new <String> [ 'label' ]
			);
		}
		
		override public function dismiss ( ) : void
		{
			_bpe = null;
			_oBcsPathHash = null;
			if ( _vBcs != null )
			{
				_vBcs.length = 0;
				_vBcs = null;
			}
			if ( _vBss != null )
			{
				while ( _vBss.length > 0 )
				{
					_vBss.pop().dismiss();
				}
				_vBss = null;
			}
			_vIbc = null;
			_userState = null;
			super.dismiss ( );
		}
		
		/**
		 * @param data Generic object (such as from JSON stream)
		 * @return Instance of BleProtocolSpec if data is valid, null otherwise
		 */
		public static function NewFromObject ( data:Object ) : BleProtocolSpec
		{
			var bps:BleProtocolSpec;
			var bOk:Boolean = false;
			
			var sId:String;
			var vBss:Vector.<BleServiceSpec>;
			var uBssLen:uint = 0;
			var sLabel:String;
			var sNameExp:String = '';
			var oLocData:Object;
			
			var aoBss:Array;
			
			var i_bss:BleServiceSpec;
			var i_oBss:Object;
			
			if (
				'id' in data &&
				'serviceSpecs' in data &&
				'label' in data
			)
			{
				// required keys are present
				sId = data.id as String;
				aoBss = data.serviceSpecs as Array;
				sLabel = data.label as String;
				if ( sId != null && aoBss != null && sLabel != null )
				{
					// values appear to be of correct type
					if ( 'priorityNameExp' in data )
					{
						sNameExp = data.priorityNameExp as String;
					}
					if ( 'localeData' in data )
					{
						// optional localeData object is also present
						oLocData = data.localeData as Object;
					}
					bOk = true;
					vBss = new <BleServiceSpec> [];
					for each ( i_oBss in aoBss )
					{
						i_bss = BleServiceSpec.NewFromObject ( i_oBss );
						if ( i_bss == null )
						{
							// problem somewhere in the data for the service spec
							bOk = false;
							break;
						}
						vBss [ uBssLen++ ] = i_bss;
					}
				}
			}
			
			if ( bOk )
			{
				bps = new BleProtocolSpec (
					sId,
					vBss,
					sLabel,
					sNameExp,
					oLocData
				);
			}
			
			return bps;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function characteristicSpecFromPath ( path:String ) : BleCharacteristicSpec
		{
			var bcs:BleCharacteristicSpec;
			if ( path in _oBcsPathHash )
			{
				bcs = _oBcsPathHash [ path ] as BleCharacteristicSpec;
			}
			return bcs;
		}
		
		// called by BlePeripheralAgent to report that its peripheral device is compatible with this spec
		public function compatibleAgentFound ( agent:BlePeripheralAgent ) : void
		{
			// if no current selection, check if autoselectable
			if ( !_bpa )
			{
				if ( _userState.bleAutoSelect ) // added 2019-10-08
				{
					if ( previousSelectedId == '' || previousSelectedId == agent.deviceId )
					{
						selectedAgent = agent;
					}
				}
			}
		}
		
		// called by BleManager upon request from client (implements IBleClient) such as McuConnectorBLE
		public function disengage ( client:IBleClient, characteristicCallbacks:Object = null ) : void
		{
			var i_sPath:String;
			var i_bcs:BleCharacteristicSpec;
			var iIdx:int = _vIbc.indexOf ( client );
			if ( iIdx >= 0 )
			{
				// remove client reference from list
				_vIbc.removeAt ( iIdx );
				_iIbcLen--;
				// remove callbacks from characteristicSpecs as needed
				if ( characteristicCallbacks )
				{
					for ( i_sPath in characteristicCallbacks )
					{
						if ( i_sPath in _oBcsPathHash )
						{
							i_bcs = _oBcsPathHash [ i_sPath ] as BleCharacteristicSpec;
							i_bcs.updateCallbackRemove ( characteristicCallbacks [ i_sPath ] as Function );
						}
					}
				}
				// update engaged flag
				isEngaged = ( _iIbcLen > 0 );
			}
		}
		
		// called by BleManager upon request from client (implements IBleClient) such as McuConnectorBLE
		public function engage ( client:IBleClient, characteristicCallbacks:Object = null ) : void
		{
			var i_sPath:String;
			var i_bcs:BleCharacteristicSpec;
			if ( _vIbc.indexOf ( client ) < 0 )
			{
				// add client reference to list
				_vIbc [ _iIbcLen ] = client;
				_iIbcLen++;
				// add callbacks to characteristicSpecs as needed
				if ( characteristicCallbacks )
				{
					for ( i_sPath in characteristicCallbacks )
					{
						if ( i_sPath in _oBcsPathHash )
						{
							i_bcs = _oBcsPathHash [ i_sPath ] as BleCharacteristicSpec;
							i_bcs.updateCallbackAdd ( characteristicCallbacks [ i_sPath ] as Function );
						}
					}
				}
				// update engaged flag
				isEngaged = true;
			}
		}
		
		// called by BleProtocolExec
		public function execDismiss ( bpe:BleProtocolExec ) : void
		{
			if ( _bpe === bpe )
			{
				_bpe = null;
				isReady = false;
			}
		}
		
		// called by BleProtocolExec
		public function execInit ( bpe:BleProtocolExec, ready:Boolean ) : Boolean
		{
			_bpe = bpe;
			isReady = ready;
			return _bEng;
		}
		
		
		// PRIVATE PROPERTIES
		
		// private var _bConn:Boolean = false;
		private var _bEng:Boolean = false;
		private var _bpa:BlePeripheralAgent;
		private var _bpe:BleProtocolExec;
		private var _bReady:Boolean = false;
		private var _iIbcLen:int = 0;
		private var _oBcsPathHash:Object; // key:value = path:characteristicSpec
		private var _sId:String;
		private var _userState:UserState;
		private var _vBcs:Vector.<BleCharacteristicSpec>;
		private var _vBss:Vector.<BleServiceSpec>;
		private var _vIbc:Vector.<IBleClient>;
	}
}