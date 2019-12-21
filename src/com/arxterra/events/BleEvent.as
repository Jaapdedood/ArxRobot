package com.arxterra.events
{
	import flash.events.Event;
	
	public class BleEvent extends Event
	{
		// EVENT TYPE CONSTANTS
		
		/**
		 * <b>id</b> protocol spec id or empty string, <b>params</b> caption string or null
		 */
		public static const BLE_CONFIG:String = 'ble_config';
		/**
		 * <b>id</b> protocol spec id, <b>params</b> null
		 */
		public static const BLE_CONNECTED:String = 'ble_connected';
		/**
		 * <b>id</b> protocol spec id, <b>params</b> null
		 */
		public static const BLE_DISCONNECTED:String = 'ble_disconnected';
		/**
		 * <b>id</b> extended device id, <b>params</b> device label
		 */
		public static const BLE_PERIPHERAL_CONNECTED:String = 'ble_peripheral_connected';
		/**
		 * <b>id</b> extended device id, <b>params</b> device label
		 */
		public static const BLE_PERIPHERAL_DISCONNECTED:String = 'ble_peripheral_disconnected';
		/**
		 * <b>id</b> protocol spec id, <b>params</b> null
		 */
		public static const BLE_PROTOCOL_SPEC_COMPATIBLE:String = 'ble_protocol_spec_compatible';
		/**
		 * <b>id</b> service spec id, <b>params</b> null
		 */
		public static const BLE_SERVICE_SPEC_COMPATIBLE:String = 'ble_service_spec_compatible';
		/**
		 * <b>id</b> characteristic spec id, <b>params</b> String status message
		 */
		public static const BLE_SUBSCRIBE_TIMEOUT:String = 'ble_subscribe_timeout';
		
		
		// EVENT CUSTOM PROPERTIES
		
		public var id:String;
		public var params:Object;
		
		
		// CONSTRUCTOR
		
		public function BleEvent(type:String, id:String='', params:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.id = id;
			this.params = params;
			super ( type, bubbles, cancelable );
		}
		
		
		// OVERRIDES
		
		public override function clone ( ) : Event
		{
			return new BleEvent ( type, this.id, this.params, bubbles, cancelable );
		}
		
		public override function toString ( ) : String
		{
			return formatToString ( 'BlePeripheralEvent', 'type', 'id', 'params', 'bubbles', 'cancelable' );
		}
		
	}
}