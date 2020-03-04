package com.arxterra.utils
{
	import com.arxterra.controllers.BleManager;
	import com.arxterra.interfaces.IBleClient;
	import com.arxterra.vo.BleCharacteristicSpec;
	import com.arxterra.vo.BleProtocolSpec;
	import com.arxterra.vo.McuConnectModes;
	
	import flash.utils.ByteArray;
	import com.arxterra.vo.UserState;

	/**
	 * Singleton class extending McuConnector
	 * to implement connection via BleManager
	 * which uses the distriqt BluetoothLE ANE.
	 */
	[Bindable]
	public class McuConnectorBLE extends McuConnectorBase implements IBleClient
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		//	{
		//		<protocol spec ID string>:
		//		{
		//			'send': <path of characteristic to write to>,
		//			'receive': <path of characteristic for notification subscription>
		//		},
		//		...
		//	}
		private static const __SPECS:Object = {
			'mcu_0':
			{
				'send': 'mcu_0' + BleBase.SPEC_ID_PATH_DELIMITER + 'serial' + BleBase.SPEC_ID_PATH_DELIMITER + 'w',
				'receive': 'mcu_0' + BleBase.SPEC_ID_PATH_DELIMITER + 'serial' + BleBase.SPEC_ID_PATH_DELIMITER + 'n'
			},
			'mcu_1':
			{
				'send': 'mcu_1' + BleBase.SPEC_ID_PATH_DELIMITER + 'serial' + BleBase.SPEC_ID_PATH_DELIMITER + 'nrw',
				'receive': 'mcu_1' + BleBase.SPEC_ID_PATH_DELIMITER + 'serial' + BleBase.SPEC_ID_PATH_DELIMITER + 'nrw'
			}
		};
		
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
			_sSpecProtocolId = 'mcu_' + _sessionMgr.userState.bleMcuModuleId;
			_bmgr = BleManager.instance;
			_MgrCommInit ( );
		}
		
		
		//  OTHER PUBLIC METHODS
		
		// called by BleConfigView when user changes mcu BLE module version
		public function bleMcuModuleSet ( id:uint ) : void
		{
			var sIdNew:String = 'mcu_' + id;
			if ( sIdNew == _sSpecProtocolId )
				return;
			
			// disengage old spec
			_MgrCommDismiss ( );
			// queue engaging new spec
			_sSpecProtocolId = sIdNew;
			_callLater ( _MgrCommInit );
		}
		
		// IBleClient implementation
		public function bleProtocolIsReady ( id:String, value:Boolean ) : void
		{
			_isConnectedSet ( value && ( id == _sSpecProtocolId ) &&  ( _bcsSend != null ) );
		}
		
		
		// PROTECTED METHODS
		
		override protected function _send ( bytes:ByteArray ) : Boolean
		{
			if ( isConnected )
			{
				_bcsSend.valueWrite ( bytes );
			}
			super._send ( bytes ); // pass through for ping check
			return isConnected;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bmgr:BleManager;
		private var _bps:BleProtocolSpec;
		private var _bcsSend:BleCharacteristicSpec;
		private var _sSpecProtocolId:String = 'mcu_1';
		
		
		// PRIVATE METHODS
		
		private function _MgrCommDismiss ( ) : void
		{
			// spec paths
			var oPaths:Object = __SPECS [ _sSpecProtocolId ];
			var sPathCrReceive:String = oPaths.receive;
			if ( _bps )
			{
				var oCbs:Object = {};
				oCbs [ sPathCrReceive ] = _telemetryInputQueuePush;
				_bmgr.clientDisengage ( this as IBleClient, _sSpecProtocolId, oCbs );
				_bps = null;
			}
			_bcsSend = null;
		}
		
		private function _MgrCommInit ( ) : void
		{
			// spec paths
			var oPaths:Object = __SPECS [ _sSpecProtocolId ];
			var sPathCrReceive:String = oPaths.receive;
			var sPathCrSend:String = oPaths.send;
			// callbacks hash
			var oCbs:Object = {};
			// only one callback for this protocol
			oCbs [ sPathCrReceive ] = _telemetryInputQueuePush;
			// become a client of this protocol
			_bps = _bmgr.clientEngage ( this as IBleClient, _sSpecProtocolId, oCbs );
			if ( _bps )
			{
				_bcsSend = _bps.characteristicSpecFromPath ( sPathCrSend );
				if ( _bcsSend )
				{
					// if the protocol spec is ready, then we are connected
					_isConnectedSet ( _bps.isReady );
				}
				else
				{
					// should never get here
					_debugOut ( 'error_ble_cr_spec', true, [ sPathCrSend ] );
				}
			}
			else
			{
				// should never get here
				_debugOut ( 'error_ble_protocol_spec', true, [ _sSpecProtocolId ] );
			}
		}
	}
}
class SingletonEnforcer {}
