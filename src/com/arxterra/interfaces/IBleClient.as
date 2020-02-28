package com.arxterra.interfaces
{
	public interface IBleClient
	{
		/**
		 * Called by a BLE Protocol Spec to inform its clients of connection or disconnection
		 */
		function bleProtocolIsReady(id:String,value:Boolean):void;
	}
}