package com.arxterra.utils
{
	import com.arxterra.controllers.SessionManager;
	import com.arxterra.events.BleEvent;
	import com.distriqt.extension.bluetoothle.BluetoothLE;
	import com.distriqt.extension.bluetoothle.CentralManager;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	[Event(name="ble_busy_changed", type="flash.events.Event")]
	[Event(name="ble_icon_changed", type="flash.events.Event")]
	[Event(name="ble_status_caption_change", type="flash.events.Event")]
	[Event(name="ble_status_caption_on_change", type="flash.events.Event")]
	
	[Event(name="ble_config", type="com.arxterra.events.BleEvent")]
	
	public class BleBase extends NonUIComponentBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		public static const ACTION_CHECK_DELAY:int = 2000;
		public static const ACTION_RETRIES_LIMIT:int = 2;
		
		public static const BLE_BUSY_CHANGED:String = 'ble_busy_changed';
		public static const BLE_ICON_CHANGED:String = 'ble_icon_changed';
		public static const BLE_STATUS_CAPTION_CHANGE:String = 'ble_status_caption_change';
		public static const BLE_STATUS_CAPTION_ON_CHANGE:String = 'ble_status_caption_on_change';
		
		public static const SPEC_ID_PATH_DELIMITER:String = ':';
		
		protected static const _ACT_NONE:uint = 0;
		protected static const _ACT_ENABLE:uint = 1;
		protected static const _ACT_PRS_SCAN:uint = 2;
		protected static const _ACT_PR_CONNECT:uint = 3;
		protected static const _ACT_PR_SRVS_QUERY:uint = 4;
		protected static const _ACT_PR_CRS_QUERY:uint = 5;
		protected static const _ACT_CR_SUBSCRIBE:uint = 6;
		
		protected static const _BLINK_DELAY:uint = 500;
		
		protected static var _ane:BluetoothLE; // reference to ANE's BluetoothLE.service
		protected static var _aneCentralMgr:CentralManager; // reference to ANE's BluetoothLE.service.centralManager
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @copy BleBase
		 */
		public function BleBase()
		{
			super();
			_sessionMgr = SessionManager.instance;
			_callLaterDelaySet ( 100 ); // allow more cushion between calls to BLE manager and peripherals
		}
		
		/**
		 * Overrides <b>must</b> call super.dismiss().
		 */
		override public function dismiss ( ) : void
		{
			_actionCheckTimerClear ( );
			_BlinkTimer ( false );
			_sessionMgr = null;
			super.dismiss();
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="ble_icon_changed")]
		public function get iconColor():uint
		{
			return _vIconColors [ 1 ];
		}
		
		[Bindable (event="ble_icon_changed")]
		public function get iconColorBlink():uint
		{
			return _vIconColors [ _uBlinkIdx ];
		}
		
		[Bindable (event="ble_busy_changed")]
		public function get isBusy():Boolean
		{
			return _busy;
		}
		
		[Bindable (event="ble_status_caption_change")]
		public function get statusCaption():String
		{
			return _sCapt;
		}
		protected function _statusCaptionSet(value:String):void
		{
			if ( value !== _sCapt )
			{
				_sCapt = value;
				dispatchEvent ( new Event ( BLE_STATUS_CAPTION_CHANGE ) );
				_statusCaptionOnSet ( value != '' );
			}
		}
		
		[Bindable (event="ble_status_caption_on_change")]
		public function get statusCaptionOn():Boolean
		{
			return _bCapt;
		}
		protected function _statusCaptionOnSet(value:Boolean):void
		{
			if ( value !== _bCapt )
			{
				_bCapt = value;
				dispatchEvent ( new Event ( BLE_STATUS_CAPTION_ON_CHANGE ) );
			}
		}
		
		// PROTECTED PROPERTIES
		
		protected var _actionId:uint;
		protected var _busy:Boolean = false;
		protected var _retries:int = 0;
		protected var _sessionMgr:SessionManager;
		
		
		// PROTECTED METHODS
		
		/**
		 * Subclass override should call this first
		 */
		protected function _actionCheckTimeout ( event:TimerEvent = null ) : void
		{
			_actionCheckTimerClear ( );
		}
		
		protected function _actionCheckTimerClear ( actionId:uint = _ACT_NONE, resetRetries:Boolean = false ) : void
		{
			if ( resetRetries )
			{
				_retries = 0;
			}
			
			if ( _tmrActCheck )
			{
				if ( actionId == _ACT_NONE || actionId == _actionId )
				{
					_tmrActCheck.stop ( );
					_tmrActCheck.removeEventListener ( TimerEvent.TIMER, _actionCheckTimeout );
					_tmrActCheck = null;
				}
			}
		}
		
		/**
		 * Subclass overrides should call this
		 */
		protected function _actionCheckTimerSet ( actionId:uint ) : void
		{
			_actionId = actionId;
			_statusCaptionSet ( '' );
			if ( !_tmrActCheck )
			{
				_tmrActCheck = new Timer ( ACTION_CHECK_DELAY, 1 );
				_tmrActCheck.addEventListener ( TimerEvent.TIMER, _actionCheckTimeout );
				_tmrActCheck.start ( );
			}
			else
			{
				_tmrActCheck.reset ( );
				_tmrActCheck.start ( );
			}
		}
		
		protected function _actionPending ( ) : Boolean
		{
			return ( _tmrActCheck != null );
		}
		
		protected function _configOpen ( id:String = '', params:Object = null ) : void
		{
			dispatchEvent ( new BleEvent ( BleEvent.BLE_CONFIG, id, params ) );
		}
		
		protected function _iconColorSet ( color:uint ) : void
		{
			if ( color != _vIconColors [ 1 ] )
			{
				_vIconColors [ 1 ] = color;
				dispatchEvent ( new Event ( BLE_ICON_CHANGED ) );
			}
		}
		
		protected function _isBusySet ( busy:Boolean ) : void
		{
			if ( busy != _busy )
			{
				_busy = busy;
				_BlinkTimer ( _busy );
				dispatchEvent ( new Event ( BLE_BUSY_CHANGED ) );
				dispatchEvent ( new Event ( BLE_ICON_CHANGED ) );
			}
		}
		
		protected function _retryCountReset ( ) : void
		{
			_retries = 0;
		}
		
		protected function _retryOk ( ) : Boolean
		{
			if ( ++ _retries < ACTION_RETRIES_LIMIT )
			{
				return true; // return
			}
			
			_retries = 0;
			return false;
		}
		
		protected function _xidCreate ( uuid:String, identifier:int ) : String
		{
			return uuid + '_' + identifier;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bCapt:Boolean = false;
		private var _sCapt:String = '';
		private var _tmrActCheck:Timer;
		private var _tmrBlink:Timer;
		private var _uBlinkIdx:uint = 1;
		private var _vIconColors:Vector.<uint> = new <uint> [ 0x111111, 0xffffff ]; // [ "off" color when blinking, "current status" color ]
		
		
		// PRIVATE METHODS
		
		private function _Blink ( event:TimerEvent = null ) : void
		{
			_uBlinkIdx = 1 - _uBlinkIdx;
			dispatchEvent ( new Event ( BLE_ICON_CHANGED ) );
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
		
	}
}