package com.arxterra.vo
{
	import com.arxterra.utils.BleBase;
	import com.arxterra.utils.BlePeripheralAgent;
	import com.arxterra.utils.NonUIComponentBase;
	import com.distriqt.extension.bluetoothle.events.CharacteristicEvent;
	import com.distriqt.extension.bluetoothle.objects.Characteristic;
	import com.distriqt.extension.bluetoothle.objects.Peripheral;
	
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	/**
	 * Evaluation and connection wrapper for BleCharacteristicSpec
	 */
	public class BleCharacteristicExec extends NonUIComponentBase
	{
		// PUBLIC PROPERTIES
		
		/**
		 * Reference to instance of associated BluetoothLE ANE Characteristic object 
		 */
		public function get characteristic():Characteristic
		{
			return _aneCr;
		}
		
		/**
		 * Spec to which the associated characteristic is compared 
		 */
		public function get characteristicSpec():BleCharacteristicSpec
		{
			return _bcs;
		}
		
		/**
		 * True if has had specified properties evaluated and determined to be compatible
		 */
		public function get isCompatible():Boolean
		{
			return _bComp;
		}
		
		public function get isReady():Boolean
		{
			return _bReady;
		}
		public function set isReady(value:Boolean):void
		{
			if ( value === _bReady )
			{
				return; // return
			}
			
			_bReady = value;
			
			if ( _bSel )
			{
				if ( _bReady )
				{
					_CrInit ( );
				}
				else
				{
					_CrDismiss ( );
				}
			}
		}
		
		public function get isSelected():Boolean
		{
			return _bSel;
		}
		public function set isSelected(value:Boolean):void
		{
			// _debugOut ( 'bce isSelected: ' + value );
			if ( value === _bSel )
			{
				return; // return
			}
			
			_bSel = value;
			
			if ( _bReady )
			{
				if ( _bSel )
				{
					_CrInit ( );
				}
				else
				{
					_CrDismiss ( );
				}
			}
		}
		
		public function get peripheral():Peripheral
		{
			return _bpa.peripheral;
		}
		
		public function get peripheralAgent():BlePeripheralAgent
		{
			return _bpa;
		}
		
		public function get uuid():String
		{
			return _sUuid;
		}
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function BleCharacteristicExec ( agent:BlePeripheralAgent, spec:BleCharacteristicSpec )
		{
			super ( );
			_bcs = spec;
			_bpa = agent;
		}
		
		override public function dismiss ( ) : void
		{
			// clear references
			_SubscribeTimerClear ( );
			isSelected = false;
			_aneCr = null;
			_bcs = null;
			_bpa = null;
			super.dismiss ( );
		}
		
		
		// OTHER PUBLIC METHODS
		
		/*
		public function disconnectPrep ( ) : void
		{
			isReady = false;
			
			_bcs.execDismiss ( this );
			_vUpdtFns = null;
			_CrListenersRemove ( );
			if ( _bcs.isSubscribeNeeded )
			{
				_Unsubscribe ( );
			}
		}
		*/
		
		public function evaluate ( aneCharacteristic:Characteristic ) : Boolean
		{
			// If not previously found compatible,
			// go ahead with the evaluation, otherwise
			// we'll just grab the fresh aneCharacteristic
			// reference needed after a reconnection.
			var bOk:Boolean = true;
			_aneCr = aneCharacteristic;
			_sUuid = aneCharacteristic.uuid;
			if ( !_bComp )
			{
				// check that all required properties are present
				var i_sPropSpec:String;
				var aPropsFound:Array = aneCharacteristic.properties;
				for each ( i_sPropSpec in _bcs.properties )
				{
					if ( aPropsFound.indexOf ( i_sPropSpec ) < 0 )
					{
						// missing at least one, so not compatible
						bOk = false;
						break;
					}
				}
			}
			_bComp = bOk;
			return _bComp;
		}
		
		public function subscribe ( value:Boolean ) : void
		{
			var bOk:Boolean;
			// _debugOut ( 'bce subscribe: ' + value );
			if ( _bReady )
			{
				if ( value != _bSub )
				{
					// current state does not match need
					if ( value )
					{
						_iRetries = 0;
						_Subscribe ( );
					}
					else
					{
						_Unsubscribe ( );
					}
				}
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _aneCr:Characteristic;
		private var _bComp:Boolean = false;
		// private var _bConn:Boolean = false;
		private var _bcs:BleCharacteristicSpec;
		private var _bpa:BlePeripheralAgent;
		private var _bReady:Boolean = false;
		private var _bSel:Boolean = false;
		private var _bSub:Boolean = false;
		private var _iRetries:int = 0;
		private var _sUuid:String = '';
		private var _tmrSub:Timer;
		private var _vUpdtFns:Vector.<Function>;
		
		
		// PRIVATE METHODS
		
		// handles CharacteristicEvent.SUBSCRIBE
		private function _AneCrSubscribe ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			
			_SubscribeTimerClear ( );
			_bSub = true;
			_debugOut ( 'status_ble_cr_sub', true, [ _bpa.label, _sUuid ] );
		}
		
		// handles CharacteristicEvent.SUBSCRIBE_ERROR
		private function _AneCrSubscribeError ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			
			_SubscribeTimerClear ( );
			_debugOut ( 'error_ble_cr_sub', true, [ _bpa.label, _sUuid, event.errorCode, event.error ] );
			if ( _bSel )
			{
				// keep trying, if possible
				_SubscribeRetry ( );
			}
		}
		
		// handles CharacteristicEvent.UNSUBSCRIBE
		private function _AneCrUnsubscribe ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			_bSub = false;
			_debugOut ( 'status_ble_cr_unsub', true, [ _bpa.label, _sUuid ] );
		}
		
		// handles CharacteristicEvent.UPDATE
		private function _AneCrUpdate ( event:CharacteristicEvent ) : void
		{
			var i:int;
			var iLen:int;
			var ba:ByteArray;
			var cr:Characteristic = event.characteristic;
			if ( cr.uuid != _sUuid )
			{
				return; // return
			}
			
			if ( _vUpdtFns )
			{
				// execute the client callbacks
				ba = cr.value;
				
				/*
				// vector length not stored, because elements
				// may be added or removed by bcs without notice
				iLen = _vUpdtFns.length;
				for ( i=0; i<iLen; i++ )
				{
					_vUpdtFns [ i ] ( ba );
				}
				*/
				
				function notify ( fnc:Function, idx:int, vFnc:Vector.<Function> ) : void
				{
					fnc ( ba );
				}
				
				_vUpdtFns.forEach ( notify );
			}
		}
		
		// handles CharacteristicEvent.UPDATE_ERROR
		private function _AneCrUpdateError ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			
			_debugOut ( 'error_ble_cr_update', true, [ _bpa.label, _sUuid, event.errorCode, event.error ] );
		}
		
		// handles CharacteristicEvent.WRITE_ERROR
		private function _AneCrWriteError ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			var iCode:int = event.errorCode;
			if ( iCode == 14 )
			{
				// ignore spurious 14 "Unlikely error" (hoping this is temporary)
				return;
			}
			_debugOut ( 'error_ble_cr_write', true, [ _bpa.label, _sUuid, iCode, event.error ] );
		}
		
		// handles CharacteristicEvent.WRITE_SUCCESS
		private function _AneCrWriteSuccess ( event:CharacteristicEvent ) : void
		{
			if ( event.characteristic.uuid != _sUuid )
			{
				return; // return
			}
			
			_debugOut ( 'status_ble_cr_write', true, [ _bpa.label, _sUuid ] );
		}
		
		private function _CrDismiss ( ) : void
		{
			_bcs.execDismiss ( this );
			_vUpdtFns = null;
			_CrListenersRemove ( );
			if ( _bcs.isSubscribeNeeded )
			{
				_Unsubscribe ( );
			}
		}
		
		private function _CrInit ( ) : void
		{
			_CrListenersAdd ( );
			_vUpdtFns = _bcs.execInit ( this );
			if ( _bcs.isSubscribeNeeded )
			{
				_iRetries = 0;
				_Subscribe ( );
			}
		}
		
		private function _CrListenersAdd ( ) : void
		{
			var anePr:Peripheral = _bpa.peripheral;
			if ( _bcs.canNotify )
			{
				anePr.addEventListener ( CharacteristicEvent.SUBSCRIBE, _AneCrSubscribe, false, 0, true );
				anePr.addEventListener ( CharacteristicEvent.SUBSCRIBE_ERROR, _AneCrSubscribeError, false, 0, true );
				anePr.addEventListener ( CharacteristicEvent.UNSUBSCRIBE, _AneCrUnsubscribe, false, 0, true );
			}
			anePr.addEventListener ( CharacteristicEvent.UPDATE, _AneCrUpdate, false, 0, true );
			anePr.addEventListener ( CharacteristicEvent.UPDATE_ERROR, _AneCrUpdateError, false, 0, true );
			anePr.addEventListener ( CharacteristicEvent.WRITE_ERROR, _AneCrWriteError, false, 0, true );
			// anePr.addEventListener ( CharacteristicEvent.WRITE_SUCCESS, _AneCrWriteSuccess, false, 0, true );
		}
		
		private function _CrListenersRemove ( ) : void
		{
			var anePr:Peripheral = _bpa.peripheral;
			if ( _bcs.canNotify )
			{
				anePr.removeEventListener ( CharacteristicEvent.SUBSCRIBE, _AneCrSubscribe );
				anePr.removeEventListener ( CharacteristicEvent.SUBSCRIBE_ERROR, _AneCrSubscribeError );
				anePr.removeEventListener ( CharacteristicEvent.UNSUBSCRIBE, _AneCrUnsubscribe );
			}
			anePr.removeEventListener ( CharacteristicEvent.UPDATE, _AneCrUpdate );
			anePr.removeEventListener ( CharacteristicEvent.UPDATE_ERROR, _AneCrUpdateError );
			anePr.removeEventListener ( CharacteristicEvent.WRITE_ERROR, _AneCrWriteError );
			// anePr.removeEventListener ( CharacteristicEvent.WRITE_SUCCESS, _AneCrWriteSuccess );
		}
		
		private function _Subscribe ( ) : void
		{
			// if subscribe not already pending,
			// set timeout and attempt to subscribe
			var bOk:Boolean;
			if ( !_tmrSub )
			{
				_tmrSub = new Timer ( BleBase.ACTION_CHECK_DELAY, 0 );
				_tmrSub.addEventListener ( TimerEvent.TIMER, _SubscribeTimeout );
				_tmrSub.start ( );
				bOk = _bpa.peripheral.subscribeToCharacteristic ( _aneCr );
				_debugOut ( 'status_ble_cr_sub_' + ( bOk ? 'init' : 'deny' ), true, [ _bpa.label, _sUuid ] );
			}
		}
		
		private function _SubscribeRetry ( ) : void
		{
			if ( ++ _iRetries < BleBase.ACTION_RETRIES_LIMIT )
			{
				_Subscribe ( );
			}
			else
			{
				// open config view
				_bpa.configRequest ( _bcs.protocolId, _resourceManager.getString ( 'default', 'status_ble_cfg_pr_capt_sub', [ _bpa.label, _sUuid ] ) );
			}
		}
		
		private function _SubscribeTimeout ( event:TimerEvent ) : void
		{
			_SubscribeTimerClear ( );
			_debugOut ( 'status_ble_cfg_pr_capt_sub', true, [ _bpa.label, _sUuid ] );
			if ( _bSel )
			{
				// keep trying, if possible
				_SubscribeRetry ( );
			}
		}
		
		private function _SubscribeTimerClear ( ) : void
		{
			if ( _tmrSub )
			{
				_tmrSub.stop ( );
				_tmrSub.removeEventListener ( TimerEvent.TIMER, _SubscribeTimeout );
				_tmrSub = null;
			}
		}
		
		private function _Unsubscribe ( ) : void
		{
			_bSub = false;
			var bOk:Boolean = _bpa.peripheral.unsubscribeToCharacteristic ( _aneCr );
			_debugOut ( 'status_ble_cr_unsub_' + ( bOk ? 'init' : 'deny' ), true, [ _bpa.label, _sUuid ] );
		}
	}
}