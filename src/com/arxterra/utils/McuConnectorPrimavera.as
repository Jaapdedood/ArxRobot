package com.arxterra.utils
{
	import flash.utils.ByteArray;
	
	import com.arxterra.events.DebugEventEx;
	import com.arxterra.events.RoverEvent;
	
	import com.arxterra.vo.McuConnectModes;
	
	/**
	 * Singleton class extending McuConnector
	 * to implement connection with USB OTG (Android as Host)
	 * via Primavera ANE.
	 */
	[Bindable]
	public class McuConnectorPrimavera extends McuConnectorBase
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		private static var __instance:McuConnectorPrimavera;
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * singleton instance
		 */
		public static function get instance ( ) : McuConnectorPrimavera
		{
			if ( !__instance )
			{
				__instance = new McuConnectorPrimavera ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		/**
		 * Singleton: use static property <b>instance</b> to access singleton instance.
		 */	
		public function McuConnectorPrimavera ( enforcer:SingletonEnforcer )
		{
			super ( );
		}
		
		override public function dismiss ( ) : void
		{
			if ( _pvi != null )
			{
				_pvi.removeEventListener ( RoverEvent.ROVER_DATA, _DataReceived );
				_pvi.removeEventListener ( DebugEventEx.DEBUG_OUT, _debugEventRelay );
				_pvi.dispose ( );
				_pvi = null;
			}
			super.dismiss ( );
			__instance = null;
		}
		
		override public function init ( ) : void
		{
			super.init ( );
			_modeSet ( McuConnectModes.USB_HOST );
			_pvi = PrimaveraInterface.instance;
			_pvi.addEventListener ( RoverEvent.ROVER_DATA, _DataReceived );
			_pvi.addEventListener ( DebugEventEx.DEBUG_OUT, _debugEventRelay );
		}
		
		
		// PROTECTED METHODS
		
		override protected function _send ( bytes:ByteArray ) : Boolean
		{
			if ( _pvi != null )
			{
				try
				{
					_pvi.sendCommand ( bytes );
				}
				catch ( err:Error )
				{
					_debugOut ( 'error_pv_send', true, [ err.message ] );
				}
				super._send ( bytes ); // pass through for ping check
				return true;
			}
			super._send ( bytes ); // pass through for ping check
			return false;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _pvi:PrimaveraInterface;
		
		
		// PRIVATE METHODS
		
		private function _DataReceived ( event:RoverEvent ) : void
		{
			var ba:ByteArray = new ByteArray ( );
			try
			{
				event.roverData.position = 0;
				ba.writeBytes ( event.roverData );
				_telemetryInputQueuePush ( ba );
			}
			catch ( err:Error )
			{
				_debugOut ( 'error_pv_receive', true, [ err.message ] );
			}
		}
		
	}
}
class SingletonEnforcer {}
