package com.arxterra.vo
{
	import com.arxterra.utils.BleBase;

	public class BleServiceSpec
	{
		// PUBLIC PROPERTIES AND ACCESSORS
		
		public function get characteristicSpecs():Vector.<BleCharacteristicSpec>
		{
			return _vBcs;
		}
		
		public function get id():String
		{
			return _sId;
		}
		
		public function get path():String
		{
			return _sPath;
		}
		
		public function get uuids():Vector.<String>
		{
			return _vUuids;
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @param serviceId Our internal ID for this spec
		 * @param compatibleUuids Vector of compatible UUID(s)
		 * @param characteristicSpecs Vector of specs for required characteristics
		 */
		public function BleServiceSpec (
			serviceId:String,
			compatibleUuids:Vector.<String>,
			characteristicSpecs:Vector.<BleCharacteristicSpec>
		)
		{
			_sId = serviceId;
			_vUuids = compatibleUuids;
			_vBcs = characteristicSpecs;
		}
		
		public function dismiss ( ) : void
		{
			_vUuids = null;
			if ( _vBcs != null )
			{
				while ( _vBcs.length > 0 )
				{
					_vBcs.pop().dismiss();
				}
				_vBcs = null;
			}
		}
		
		/**
		 * @param data Generic object (such as from JSON stream)
		 * @return Instance of BleServiceSpec if data is valid, null otherwise
		 */
		public static function NewFromObject ( data:Object ) : BleServiceSpec
		{
			var bss:BleServiceSpec;
			var bOk:Boolean = false;
			
			var sId:String;
			var vUuids:Vector.<String>;
			var vBcs:Vector.<BleCharacteristicSpec>;
			var uBcsLen:uint = 0;
			var aUuids:Array;
			var aoBcs:Array;
			
			var i_bcs:BleCharacteristicSpec;
			var i_oBcs:Object;
			
			if (
				'id' in data &&
				'uuids' in data &&
				'characteristicSpecs' in data
			)
			{
				// expected keys are present
				sId = data.id as String;
				aUuids = data.uuids as Array;
				aoBcs = data.characteristicSpecs as Array;
				if ( sId != null && aUuids != null && aoBcs != null )
				{
					// values appear to be of correct type
					try
					{
						vUuids = Vector.<String> ( data.uuids );
						bOk = true;
					}
					catch ( err:Error )
					{
						// array contained an element that did not cast to the expected type
					}
				}
			}
			
			if ( bOk )
			{
				// so far, so good
				vBcs = new <BleCharacteristicSpec> []
				for each ( i_oBcs in aoBcs )
				{
					i_bcs = BleCharacteristicSpec.NewFromObject ( i_oBcs );
					if ( i_bcs == null )
					{
						// problem somewhere in the data for the characteristic spec
						bOk = false;
						break;
					}
					vBcs [ uBcsLen++ ] = i_bcs;
				}
			}
			
			if ( bOk )
			{
				bss = new BleServiceSpec (
					sId,
					vUuids,
					vBcs
				);
			}
			
			return bss;
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Initializes internal ID path of this service spec, which is then passed on
		 * to initialize the ID paths of its child characteristic spec(s)
		 * @param parentPath String internal ID of parent peripheral spec
		 * @return Vector of child characteristic spec(s)
		 */
		public function pathsInit ( protocolId:String ) : Vector.<BleCharacteristicSpec>
		{
			_sPath = [ protocolId, _sId ].join ( BleBase.SPEC_ID_PATH_DELIMITER );
			for each ( var i_bcs:BleCharacteristicSpec in _vBcs )
			{
				i_bcs.pathInit ( protocolId, _sPath );
			}
			return _vBcs;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _sId:String;
		private var _sPath:String;
		private var _vBcs:Vector.<BleCharacteristicSpec>;
		private var _vUuids:Vector.<String>;
	}
}