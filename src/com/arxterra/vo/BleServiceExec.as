package com.arxterra.vo
{
	import com.arxterra.utils.BlePeripheralAgent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Service;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
	 * Evaluation wrapper for BleServiceSpec
	 */
	public class BleServiceExec
	{
		// PUBLIC PROPERTIES AND ACCESSORS
		
		public function get characteristicExecs():Vector.<BleCharacteristicExec>
		{
			return _vBce;
		}
		
		/**
		 * True if has had all specified characteristics discovered and determined to be compatible
		 */
		public function get isCompatible():Boolean
		{
			return _bComp;
		}
		
		/**
		 * Reference to instance of associated BluetoothLE ANE Service object 
		 */
		public function get service():Service
		{
			return _aneSvc;
		}
		public function set service(value:Service):void
		{
			_aneSvc = value;
			if ( value )
			{
				_sUuid = value.uuid;
			}
		}
		
		/**
		 * Spec to which the associated service is compared 
		 */
		public function get serviceSpec():BleServiceSpec
		{
			return _bss;
		}
		
		/**
		 * UUID of associated BluetoothLE ANE Service object
		 */
		public function get uuid():String
		{
			return _sUuid;
		}
		public function set uuid(value:String):void
		{
			_sUuid = value;
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function BleServiceExec ( agent:BlePeripheralAgent, spec:BleServiceSpec, compatibleCallback:Function )
		{
			_fCbComp = compatibleCallback;
			_bss = spec;
			_bpa = agent;
			
			_vBce = new <BleCharacteristicExec> [];
			_oBceUuidHash = {};
			var uBceLen:uint = 0;
			var i_bce:BleCharacteristicExec;
			var i_bcs:BleCharacteristicSpec;
			var j_sUuid:String;
			for each ( i_bcs in spec.characteristicSpecs )
			{
				// instantiate evaluation wrapper for each characteristic spec
				i_bce = new BleCharacteristicExec ( agent, i_bcs );
				_vBce [ uBceLen++ ] = i_bce;
				// add to hash
				for each ( j_sUuid in i_bcs.uuids )
				{
					_oBceUuidHash [ j_sUuid ] = i_bce;
				}
			}
		}
		
		public function dismiss ( ) : void
		{
			_TimerCompDismiss ( );
			
			// clear references
			_fCbComp = null;
			_bss = null;
			_aneSvc = null;
			_oBceUuidHash = null;
			
			if ( _vBce != null )
			{
				// dismiss each characteristic eval as we delete our reference to it
				while ( _vBce.length > 0 )
				{
					_vBce.pop().dismiss();
				}
				_vBce = null;
			}
			_bpa = null;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function evaluate ( aneService:Service ) : Boolean
		{
			var i_aneCr:Characteristic;
			var i_sUuid:String;
			var i_bce:BleCharacteristicExec;
			var bOk:Boolean = true;
			service = aneService;
			// Determine whether a discovered characteristic is one we want
			// by attempting to lookup up the associated characteristic eval
			// instance from the uuid hash. If found, submit it for evaluation.
			for each ( i_aneCr in _aneSvc.characteristics )
			{
				i_sUuid = i_aneCr.uuid;
				if ( i_sUuid in _oBceUuidHash )
				{
					// this has a uuid we need, so BleCharacteristicExec will check it further
					// (if previously found compatible, will just save the fresh
					// reference to the ANE's Characteristic object)
					i_bce = _oBceUuidHash [ i_sUuid ] as BleCharacteristicExec;
					if ( !i_bce.evaluate ( i_aneCr ) )
					{
						// required characteristic not compatible,
						// so service not compatible
						bOk = false;
						break;
					}
				}
			}
			if ( !_bComp )
			{
				// Has not previously been found compatible, so must do further tests
				if ( bOk )
				{
					// Everything we've seen so far looks good.
					// Now check to make sure no required characteristic is missing.
					for each ( i_bce in _vBce )
					{
						if ( !i_bce.isCompatible )
						{
							// at least one characteristic we require was not found,
							// so service not compatible
							bOk = false;
							break;
						}
					}
				}
			}
			if ( bOk )
			{
				_tmrComp = new Timer ( 20, 0 );
				_tmrComp.addEventListener ( TimerEvent.TIMER, _ReportCompatible );
				_tmrComp.start ( );
			}
			_bComp = bOk;
			return _bComp;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _aneSvc:Service;
		private var _bComp:Boolean = false;
		private var _bpa:BlePeripheralAgent;
		private var _bss:BleServiceSpec;
		private var _fCbComp:Function;
		private var _oBceUuidHash:Object; // key:value = uuid:characteristicEval
		private var _sUuid:String = '';
		private var _tmrComp:Timer;
		private var _vBce:Vector.<BleCharacteristicExec>;
		
		
		// PRIVATE METHODS
		
		private function _ReportCompatible ( event:TimerEvent ) : void
		{
			_TimerCompDismiss ( );
			_fCbComp ( );
		}
		
		private function _TimerCompDismiss ( ) : void
		{
			if ( _tmrComp )
			{
				_tmrComp.stop ( );
				_tmrComp.removeEventListener ( TimerEvent.TIMER, _ReportCompatible );
				_tmrComp = null;
			}
		}
	}
}