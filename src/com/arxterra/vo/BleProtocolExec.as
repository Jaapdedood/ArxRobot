package com.arxterra.vo
{
	import com.arxterra.utils.BlePeripheralAgent;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import flash.events.Event;
	
	[Event(name="ble_exec_selected_change", type="flash.events.Event")]

	/**
	 * Executive evaluation and connection wrapper for BleProtocolSpec
	 */
	public class BleProtocolExec extends EventDispatcher
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const BLE_EXEC_SELECTED_CHANGE:String = 'ble_exec_selected_change';
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function get characteristicExecs():Vector.<BleCharacteristicExec>
		{
			return _vBce;
		}
		
		/**
		 * True if has had all specified services and characteristics discovered and determined to be compatible
		 */
		public function get isCompatible():Boolean
		{
			return _bComp;
		}
		
		public function get isConnected():Boolean
		{
			return _bConn;
		}
		public function set isConnected(value:Boolean):void
		{
			_bConn = value;
			/*
			var iLen:int = _vBce.length;
			var i:int;
			// inform characteristic exec(s)
			for ( i=0; i<iLen; i++ )
			{
				_vBce [ i ].isConnected = value;
			}
			// if selected, inform protocol spec
			if ( _bSel )
			{
				_bps.isConnected = value;
			}
			*/
		}
		
		public function get isEngaged():Boolean
		{
			return _bEng;
		}
		public function set isEngaged(value:Boolean):void
		{
			_bEng = value;
			_bpa.protocolExecEngagedChange ( );
		}
		
		public function get isReady():Boolean
		{
			return _bReady;
		}
		public function set isReady(value:Boolean):void
		{
			if ( value === _bReady )
			{
				return;
			}
			_bReady = value;
			var iLen:int = _vBce.length;
			var i:int;
			// inform characteristic exec(s)
			for ( i=0; i<iLen; i++ )
			{
				_vBce [ i ].isReady = _bReady;
			}
			// if selected, inform protocol spec
			if ( _bSel )
			{
				if ( _bReady )
				{
					isEngaged = _bps.execInit ( this, _bReady );
				}
				else
				{
					_bps.execDismiss ( this );
					isEngaged = false;
				}
			}
		}
		
		[Bindable (event="ble_exec_selected_change")]
		public function get isSelected():Boolean
		{
			return _bSel;
		}
		public function isSelectedSet(value:Boolean):void
		{
			if ( value === _bSel )
			{
				return; // return
			}
			
			_bSel = value;
			var iLen:int = _vBce.length;
			var i:int;
			for ( i=0; i<iLen; i++ )
			{
				_vBce [ i ].isSelected = _bSel;
			}
			if ( _bSel )
			{
				isEngaged = _bps.execInit ( this, _bReady );
			}
			else
			{
				_bps.execDismiss ( this );
				isEngaged = false;
			}
			dispatchEvent ( new Event ( BLE_EXEC_SELECTED_CHANGE ) );
		}
		
		[Bindable]
		public function get label():String
		{
			return _sLabel;
		}
		public function set label(value:String):void
		{
			_sLabel = value;
		}
		
		public function get peripheralAgent():BlePeripheralAgent
		{
			return _bpa;
		}
		
		/**
		 * Spec to which the peripheral is compared 
		 */
		public function get protocolSpec():BleProtocolSpec
		{
			return _bps;
		}
		
		public function get serviceExecs():Vector.<BleServiceExec>
		{
			return _vBse;
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function disconnectPrep ( ) : void
		{
			isReady = false;
			/*
			if ( _bSel )
			{
				var i_bce:BleCharacteristicExec;
				for each ( i_bce in _vBce )
				{
					i_bce.disconnectPrep ( );
				}
			}
			*/
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function BleProtocolExec ( agent:BlePeripheralAgent, spec:BleProtocolSpec, compatibleCallback:Function )
		{
			_fCbComp = compatibleCallback;
			_bps = spec;
			_bpa = agent;
			
			_sLabel = _bps.label;
			_cwLabel = BindingUtils.bindProperty ( this, 'label', _bps, 'label' );
			_vBse = new <BleServiceExec> [];
			_vBce = new <BleCharacteristicExec> [];
			var uBceLen:uint = 0;
			var uBseLen:uint = 0;
			var i_bse:BleServiceExec;
			var i_bss:BleServiceSpec;
			var j_bce:BleCharacteristicExec;
			for each ( i_bss in spec.serviceSpecs )
			{
				// instantiate executive wrapper for each service spec
				i_bse = new BleServiceExec ( agent, i_bss, _ServiceCompatible );
				_vBse [ uBseLen++ ] = i_bse;
				// service exec will have intantiated exec wrapper for each characteristic spec
				for each ( j_bce in i_bse.characteristicExecs )
				{
					// add to vector
					_vBce [ uBceLen++ ] = j_bce;
				}
			}
		}
		
		public function dismiss ( ) : void
		{
			if ( _cwLabel )
			{
				_cwLabel.unwatch ( );
			}
			
			_TimerEvalDismiss ( );
			
			_fCbComp = null;
			_bps = null;
			
			if ( _vBce )
			{
				// service execs will take care of dismissing their own characteristic execs,
				// so we just clear these references to them
				_vBce.length = 0;
				_vBce = null;
			}
			
			if ( _vBse )
			{
				// dismiss each service exec as we delete our reference to it
				while ( _vBse.length > 0 )
				{
					_vBse.pop ( ).dismiss ( );
				}
				_vBse = null;
			}
			
			_bpa = null;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bComp:Boolean = false;
		private var _bConn:Boolean = false;
		private var _bEng:Boolean = false;
		private var _bReady:Boolean = false;
		private var _bSel:Boolean = false;
		private var _bpa:BlePeripheralAgent;
		private var _bps:BleProtocolSpec;
		private var _cwLabel:ChangeWatcher;
		private var _fCbComp:Function;
		private var _sLabel:String;
		private var _tmrEval:Timer;
		private var _vBce:Vector.<BleCharacteristicExec>;
		private var _vBse:Vector.<BleServiceExec>;
		
		
		// PRIVATE METHODS
		
		private function _Evaluate ( event:TimerEvent ) : void
		{
			_TimerEvalDismiss ( );
			// check to see whether all services now compatible
			var bOk:Boolean = true;
			var i_bse:BleServiceExec;
			for each ( i_bse in _vBse )
			{
				if ( !i_bse.isCompatible )
				{
					bOk = false;
					break;
				}
			}
			_bComp = bOk;
			if ( _bComp )
			{
				_fCbComp ( _bps.id, _bps, this, _vBce );
				isReady = true;
			}
		}
		
		private function _ServiceCompatible ( ) : void
		{
			if ( _bReady || _tmrEval )
				return;
			
			_tmrEval = new Timer ( 20, 0 );
			_tmrEval.addEventListener ( TimerEvent.TIMER, _Evaluate );
			_tmrEval.start ( );
		}
		
		private function _TimerEvalDismiss ( ) : void
		{
			if ( _tmrEval )
			{
				_tmrEval.stop ( );
				_tmrEval.removeEventListener ( TimerEvent.TIMER, _Evaluate );
				_tmrEval = null;
			}
		}
		
	}
}