package com.arxterra.utils
{
	import com.arxterra.controllers.BleManager;
	import com.arxterra.interfaces.IBleClient;
	import com.arxterra.vo.BleCharacteristicSpec;
	import com.arxterra.vo.BleProtocolSpec;
	import com.arxterra.vo.McuConnectModes;
	
	import flash.utils.ByteArray;

	/**
	 * Singleton class extending McuConnector
	 * to implement connection via BleManager
	 * which uses the distriqt BluetoothLE ANE.
	 */
	[Bindable]
	public class McuConnectorBLE extends McuConnectorBase implements IBleClient
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		// spec ID of the protocol
		private static const __SPEC_ID_PR:String = 'mcu';
		// spec path of the characteristic
		private static const __SPEC_PATH_CR:String = 'mcu' + BleBase.SPEC_ID_PATH_DELIMITER + 'serial' + BleBase.SPEC_ID_PATH_DELIMITER + 'nrw';
		
		private static var __instance:McuConnectorBLE;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : McuConnectorBLE
		{
			if ( !__instance )
			{
				__instance = new McuConnectorBLE ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */
		public function McuConnectorBLE ( enforcer:SingletonEnforcer )
		{
			// do not call init here, because it will be called by superclass constructor
			super();
		}
		
		override public function dismiss ( ) : void
		{
			_isConnectedSet ( false );
			_MgrCommDismiss ( );
			_bmgr = null;
			super.dismiss ( );
			__instance = null;
		}
		
		override public function init ( ) : void
		{
			super.init ( );
			_modeSet ( McuConnectModes.BLE );
			_bmgr = BleManager.instance;
			_MgrCommInit ( );
		}
		
		
		//  OTHER PUBLIC METHODS
		
		// IBleClient implementation
		public function bleProtocolIsReady ( value:Boolean ) : void
		{
			_isConnectedSet ( value && _bcs != null );
		}
		
		
		// PROTECTED METHODS
		
		override protected function _send ( bytes:ByteArray ) : Boolean
		{
			if ( isConnected )
			{
				_bcs.valueWrite ( bytes );
			}
			super._send ( bytes ); // pass through for ping check
			return isConnected;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bmgr:BleManager;
		private var _bps:BleProtocolSpec;
		private var _bcs:BleCharacteristicSpec;
		
		
		// PRIVATE METHODS
		
		private function _MgrCommDismiss ( ) : void
		{
			_bcs = null;
			if ( _bps )
			{
				var oCbs:Object = {};
				oCbs [ __SPEC_PATH_CR ] = _telemetryInputQueuePush;
				_bmgr.clientDisengage ( this as IBleClient, __SPEC_ID_PR, oCbs );
				_bps = null;
			}
		}
		
		private function _MgrCommInit ( ) : void
		{
			// callbacks hash
			var oCbs:Object = {};
			// only one callback for this protocol
			oCbs [ __SPEC_PATH_CR ] = _telemetryInputQueuePush;
			// become a client of this protocol
			_bps = _bmgr.clientEngage ( this as IBleClient, __SPEC_ID_PR, oCbs );
			if ( _bps )
			{
				_bcs = _bps.characteristicSpecFromPath ( __SPEC_PATH_CR );
				if ( _bcs )
				{
					// if the protocol spec is ready, then we are connected
					_isConnectedSet ( _bps.isReady );
				}
			}
		}
	}
}
class SingletonEnforcer {}
