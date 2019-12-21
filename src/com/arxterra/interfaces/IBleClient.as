package com.arxterra.interfaces
{
	public interface IBleClient
	{
		/**
		 * Called by a BLE Protocol Spec to inform its clients of connection or disconnection
		 */
		function bleProtocolIsReady(value:Boolean):void;
	}
}