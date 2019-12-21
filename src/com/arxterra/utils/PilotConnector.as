package com.arxterra.utils
{
	import com.arxterra.controllers.SessionManager;
	import com.arxterra.icons.IconModeSelect;
	import com.arxterra.interfaces.IPilotConnector;
	import com.arxterra.vo.MessageData;
	
	import flash.events.Event;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	
	[Event(name="pilot_connected_changed", type="flash.events.Event")]
	[Event(name="pilot_connect_pending_changed", type="flash.events.Event")]
	[Event(name="pilot_connect_ready_changed", type="flash.events.Event")]
	[Event(name="pilot_login_valid_changed", type="flash.events.Event")]
	
	/**
	 * PilotConnector base class. Usually extended by
	 * subclasses specific to the operational modes.
	 */	
	[Bindable]
	public class PilotConnector extends NonUIComponentBase implements IPilotConnector
	{
		// CONSTANTS
		
		public static const PILOT_CONNECTED_CHANGED:String = 'pilot_connected_changed';
		public static const PILOT_CONNECT_PENDING_CHANGED:String = 'pilot_connect_pending_changed';
		public static const PILOT_CONNECT_READY_CHANGED:String = 'pilot_connect_ready_changed';
		public static const PILOT_LOGIN_VALID_CHANGED:String = 'pilot_login_valid_changed';
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="pilot_login_valid_changed")]
		public function get hasValidLogin():Boolean
		{
			return _bLoginValid;
		}
		protected function _hasValidLoginSet(value:Boolean):void
		{
			if ( value != _bLoginValid )
			{
				_bLoginValid = value;
				dispatchEvent ( new Event ( PILOT_LOGIN_VALID_CHANGED ) );
			}
		}
		
		[Bindable (event="icon_changed")]
		public function get icon ( ) : Object
		{
			return IconModeSelect;
		}
		
		[Bindable (event="pilot_connected_changed")]
		public function get isConnected():Boolean
		{
			return _bConn;
		}
		protected function _isConnectedSet(value:Boolean):void
		{
			if ( value != _bConn )
			{
				_bConn = value;
				dispatchEvent ( new Event ( PILOT_CONNECTED_CHANGED ) );
			}
		}
		
		[Bindable (event="pilot_connect_pending_changed")]
		public function get isPending():Boolean
		{
			return _bPend;
		}
		protected function _isPendingSet(value:Boolean):void
		{
			if ( value != _bPend )
			{
				_bPend = value;
				dispatchEvent ( new Event ( PILOT_CONNECT_PENDING_CHANGED ) );
			}
		}
		
		[Bindable (event="pilot_connect_ready_changed")]
		public function get isReady():Boolean
		{
			return _bReady;
		}
		protected function _isReadySet(value:Boolean):void
		{
			if ( value != _bReady )
			{
				_bReady = value;
				dispatchEvent ( new Event ( PILOT_CONNECT_READY_CHANGED ) );
			}
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @copy PilotConnector
		 */
		public function PilotConnector ( )
		{
			super ( );
			init ( );
		}
		
		/**
		 * Overrides <b>must</b> call super.dismiss().
		 */
		override public function dismiss ( ) : void
		{
			if ( _cwDebug )
			{
				_cwDebug.unwatch ( );
				_cwDebug = null;
			}
			_sessionMgr = null;
			_roomVarsQueued = null;
			_userVarsQueued = null;
			super.dismiss ( );
		}
		
		/**
		 * Called automatically during instantiation,
		 * but may also be called manually to reactivate
		 * if object was previously dismissed.
		 * Overrides <b>must</b> call super.init().
		 */
		public function init ( ) : void
		{
			_roomVarsQueued = {};
			_userVarsQueued = {};
			_sessionMgr = SessionManager.instance;
			_cwDebug = BindingUtils.bindSetter ( _debugChanged, _sessionMgr, 'debugOn' );
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 */
		public function avReceiverClear ( ) : void
		{
		}
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 */
		public function avReceiverSubscribe ( ) : void
		{
		}
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 * @return Boolean <b>true</b> if stream was on
		 */
		public function avSenderClear ( ) : Boolean
		{
			return false;
		}
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 */
		public function avSenderPublish ( ) : void
		{
		}
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 */
		public function roomVarsQueue ( vars:Vector.<MessageData>, immediate:Boolean = false ) : void
		{
		}
		
		/**
		 * Overrides should include call to super
		 */
		public function sleep ( ) : void
		{
			_sleeping = true;
		}
		
		/**
		 * Treat as abstract method. Subclass must override to implement
		 * appropriately depending upon the operational mode.
		 */
		public function userVarsQueue ( vars:Vector.<MessageData>, immediate:Boolean = false ) : void
		{
		}
		
		/**
		 * Overrides should include call to super
		 */
		public function wake ( ) : void
		{
			_sleeping = false;
		}
		
		
		// PROTECTED PROPERTIES
		
		protected var _sessionMgr:SessionManager;
		protected var _sleeping:Boolean = false;
		protected var _roomVarsQueued:Object;
		protected var _userVarsQueued:Object;
		
		
		// PROTECTED METHODS
		
		/**
		 * Subclass may override to respond to changes in debug
		 */
		protected function _debugChanged ( value:Boolean ) : void
		{
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bConn:Boolean = false;
		private var _bLoginValid:Boolean = false;
		private var _bPend:Boolean = false;
		private var _bReady:Boolean = false;
		private var _cwDebug:ChangeWatcher;
	}
}