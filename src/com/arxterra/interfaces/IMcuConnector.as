package com.arxterra.interfaces
{
	import flash.utils.ByteArray;
	import flash.events.IEventDispatcher;

	public interface IMcuConnector extends IEventDispatcher
	{
		function dismiss():void;
		function init():void;
		function get isBLE():Boolean;
		function get isBluetooth():Boolean;
		function get isConnected():Boolean;
		function get isWireless():Boolean;
		function get mode():uint;
		function sendCommand(bytes:ByteArray):Boolean;
		function sendCommandId(id:int):Boolean;
		function watchdogModeApply():void;
	}
}