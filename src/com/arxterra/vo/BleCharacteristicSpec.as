package com.arxterra.vo
{
	import com.arxterra.utils.BleBase;
	import com.arxterra.utils.BlePeripheralAgent;
	import com.arxterra.utils.NonUIComponentBase;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	
	import flash.utils.ByteArray;

	public class BleCharacteristicSpec extends NonUIComponentBase
	{
		// PUBLIC PROPERTIES AND ACCESSORS
		
		public function get canNotify():Boolean
		{
			return _bNotify;
		}
		
		public function get id():String
		{
			return _sId;
		}
		
		public function get path():String
		{
			return _sPath;
		}
		
		public function get permissions():Vector.<String>
		{
			return _vPerms;
		}
		
		public function get properties():Vector.<String>
		{
			return _vProps;
		}
		
		public function get protocolId():String
		{
			return _sProtoId;
		}
		
		public function get isSubscribeNeeded():Boolean
		{
			return _bSub;
		}
		
		public function get uuids():Vector.<String>
		{
			return _vUuids;
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @param characteristicId Our internal ID for this spec
		 * @param compatibleUuids Vector of compatible UUID string(s)
		 * @param properties Vector of required propertie strings (use constants from
		 * com.distriqt.extension.bluetoothle.objects.Characteristic)
		 * @param permissions Vector of required permissions strings, which may be empty (use constants from
		 * com.distriqt.extension.bluetoothle.objects.Characteristic)
		 */
		public function BleCharacteristicSpec (
			characteristicId:String,
			compatibleUuids:Vector.<String>,
			properties:Vector.<String>,
			permissions:Vector.<String>
		)
		{
			super ( );
			_sId = characteristicId;
			_vPerms = permissions;
			_vProps = properties;
			_vUuids = compatibleUuids;
			_vUpdtFns = new <Function> [];
			_bNotify = ( properties.indexOf ( Characteristic.PROPERTY_NOTIFY ) >= 0 );
		}
		
		override public function dismiss ( ) : void
		{
			_bpa = null;
			_bce = null;
			_vUpdtFns = null;
			_vPerms = null;
			_vProps = null;
			_vUuids = null;
			super.dismiss ( );
		}
		
		/**
		 * @param data Generic object (such as from JSON stream)
		 * @return Instance of BleCharacteristicSpec if data is valid, null otherwise
		 */
		public static function NewFromObject ( data:Object ) : BleCharacteristicSpec
		{
			var bcs:BleCharacteristicSpec;
			var bOk:Boolean = false;
			
			var sId:String;
			var vUuids:Vector.<String>;
			var vProps:Vector.<String>;
			var vPerms:Vector.<String>;
			
			var aUuids:Array;
			var aProps:Array;
			var aPerms:Array;
			
			if (
				'id' in data &&
				'uuids' in data &&
				'properties' in data &&
				'permissions' in data
			)
			{
				// expected keys are present
				sId = data.id as String;
				aUuids = data.uuids as Array;
				aProps = data.properties as Array;
				aPerms = data.permissions as Array;
				if ( sId != null && aUuids != null && aProps != null && aPerms != null )
				{
					// values appear to be of correct type
					try
					{
						vUuids = Vector.<String> ( aUuids );
						vProps = Vector.<String> ( aProps );
						vPerms = Vector.<String> ( aPerms );
						bOk = true;
					}
					catch ( err:Error )
					{
						// at least one of the arrays contained an element that did not cast to the expected type
					}
				}
			}
			
			if ( bOk )
			{
				bcs = new BleCharacteristicSpec (
					sId,
					vUuids,
					vProps,
					vPerms
				);
			}
			
			return bcs;
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Dismisses association of BleCharacteristicExec with this BleCharacteristicSpec
		 * @param bce Reference to the calling BleCharacteristicExec
		 */		
		public function execDismiss ( bce:BleCharacteristicExec ) : void
		{
			if ( _bce === bce )
			{
				_bpa = null;
				_bce = null;
			}
		}
		
		/**
		 * Initializes association of BleCharacteristicExec with this BleCharacteristicSpec
		 * @param bce Reference to the calling BleCharacteristicExec
		 * @return Reference to vector of update callback functions
		 */
		public function execInit ( bce:BleCharacteristicExec ) : Vector.<Function>
		{
			_bce = bce;
			_bpa = bce.peripheralAgent;
			return _vUpdtFns;
		}
		
		/**
		 * Initializes internal ID path of this characteristic spec
		 * @param parentPath String internal ID path of parent service spec
		 */
		public function pathInit ( protocolId:String, parentPath:String ) : void
		{
			_sProtoId = protocolId;
			_sPath = [ parentPath, _sId ].join ( BleBase.SPEC_ID_PATH_DELIMITER );
		}
		
		// called by BleProtocolSpec.engage
		public function updateCallbackAdd ( callback:Function ) : void
		{
			// _debugOut ( 'bcs updateCallbackAdd' );
			if ( _vUpdtFns.indexOf ( callback ) < 0 )
			{
				_vUpdtFns [ _vUpdtFns.length ] = callback;
				if ( _bNotify )
				{
					_SubscribeNeededSet ( true );
				}
			}
		}
		
		// called by BleProtocolSpec.disengage
		public function updateCallbackRemove ( callback:Function ) : void
		{
			var iIdx:int;
			iIdx = _vUpdtFns.indexOf ( callback );
			if ( iIdx >= 0 )
			{
				_vUpdtFns.removeAt ( iIdx );
				if ( _bNotify )
				{
					_SubscribeNeededSet ( _vUpdtFns.length > 0 );
				}
			}
		}
		
		// called by client
		public function valueRead ( ) : Boolean
		{
			var bOk:Boolean = false;
			if ( _bpa && _bpa.isConnected )
			{
				bOk = _bpa.peripheral.readValueForCharacteristic ( _bce.characteristic );
				if ( !bOk )
				{
					_debugOut ( 'status_ble_cr_read_deny', true, [ _bpa.label, _bce.uuid ] );
				}
			}
			return bOk;
		}
		
		// called by client
		public function valueWrite ( bytes:ByteArray ) : Boolean
		{
			var bOk:Boolean = false;
			if ( _bpa && _bpa.isConnected )
			{
				bOk = _bpa.peripheral.writeValueForCharacteristic ( _bce.characteristic, bytes );
				if ( !bOk )
				{
					_debugOut ( 'status_ble_cr_write_deny', true, [ _bpa.label, _bce.uuid ] );
				}
			}
			return bOk;
		}
		
		// PRIVATE PROPERTIES
		
		private var _bce:BleCharacteristicExec;
		private var _bNotify:Boolean = false;
		private var _bpa:BlePeripheralAgent;
		private var _bSub:Boolean = false;
		private var _sId:String;
		private var _sPath:String;
		private var _sProtoId:String;
		private var _vUpdtFns:Vector.<Function>;
		private var _vPerms:Vector.<String>;
		private var _vProps:Vector.<String>;
		private var _vUuids:Vector.<String>;
		
		
		// PRIVATE METHODS
		
		private function _SubscribeNeededSet ( value:Boolean ) : void
		{
			// _debugOut ( 'bcs _SubscribeNeededSet: ' + value );
			if ( value !== _bSub )
			{
				_bSub = value;
				if ( _bce )
				{
					_bce.subscribe ( value );
				}
			}
		}
	}
}