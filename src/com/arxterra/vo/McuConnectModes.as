package com.arxterra.vo
{
	import com.distriqt.extension.bluetooth.Bluetooth;
	import com.distriqt.extension.bluetoothle.BluetoothLE;

	public class McuConnectModes
	{
		// CONSTANTS
		
		/**
		 * Connect mode BLUETOOTH
		 */
		public static const BLUETOOTH:uint = 0;
		/**
		 * Connect mode USB_ADB
		 */
		public static const USB_ADB:uint = 1;
		/**
		 * Connect mode USB_HOST
		 */
		public static const USB_HOST:uint = 2;
		/**
		 * Connect mode BLE
		 */
		public static const BLE:uint = 3;
		/**
		 * Unspecified. Used only during startup and for testing.
		 */
		public static const NA:uint = 99;
		
		private static const _ALL_MODES:Array = [ BLUETOOTH, USB_ADB, USB_HOST, BLE ];
		
		// PUBLIC METHODS
		
		/**
		 * No need to instantiate.
		 */
		public function McuConnectModes()
		{
		}
		
		
		// PUBLIC STATIC PROPERTIES
		
		public static function get IsConfigured():Boolean
		{
			return __bCfgDone;
		}
		
		
		// STATIC METHODS
		
		public static function ConfigureForDevice ( osIsAndroid:Boolean ) : Array
		{
			var aMsgs:Array = [ ];
			if ( __bCfgDone )
			{
				return aMsgs; // return
			}
			
			__bCfgDone = true;
			var uMsgsLen:uint = 0;
			// var bOk:Boolean = true;
			var aModes:Array = [ ];
			var uModesLen:uint = 0;
			if ( osIsAndroid )
			{
				// check for Bluetooth LE support
				try
				{
					if ( BluetoothLE.isSupported )
					{
						aModes [ uModesLen++ ] = BLE;
					}
					else
					{
						aMsgs [ uMsgsLen++ ] = [ 'error_ble_support', true, null ];
					}
				}
				catch ( err:Error )
				{
					aMsgs [ uMsgsLen++ ] = [ 'error_ble_support_detect', true, [ err.message ] ];
				}
				
				// check for Bluetooth Classic support
				try
				{
					if ( Bluetooth.isSupported )
					{
						aModes [ uModesLen++ ] = BLUETOOTH;
					}
					else
					{
						aMsgs [ uMsgsLen++ ] = [ 'error_bt_support', true, null ];
					}
				}
				catch ( err:Error )
				{
					aMsgs [ uMsgsLen++ ] = [ 'error_bt_support_detect', true, [ err.message ] ];
				}
				
				aModes [ uModesLen++ ] = USB_ADB; // deprecated
				// aModes [ uModesLen++ ] = USB_HOST; // deprecated, currently not allowed
			}
			else
			{
				// iOS
				try
				{
					if ( BluetoothLE.isSupported )
					{
						aModes [ uModesLen++ ] = BLE;
					}
					else
					{
						aMsgs [ uMsgsLen++ ] = [ 'error_ble_support', true, null ];
					}
				}
				catch ( err:Error )
				{
					aMsgs [ uMsgsLen++ ] = [ 'error_ble_support_detect', true, [ err.message ] ];
				}
			}
			
			if ( uModesLen > 0 )
			{
				__uDefault = aModes [ 0 ];
				__aCompModes = aModes;
			}
			
			return aMsgs;
		}
		
		public static function GetCompatibleModeIds ( ) : Array
		{
			return __aCompModes;
		}
		
		public static function GetDefaultModeId ( ) : uint
		{
			return __uDefault;
		}
		
		public static function ValidateMode ( value:uint ) : uint
		{
			if ( __aCompModes.indexOf ( value ) < 0 )
				return __uDefault;
			return value;
		}
		
		private static var __aCompModes:Array = [];
		private static var __bCfgDone:Boolean = false;
		private static var __uDefault:uint = NA;
	}
}