package com.arxterra.interfaces
{
	import flash.events.IEventDispatcher;
	import com.arxterra.vo.MessageData;
	
	public interface IPilotConnector extends IEventDispatcher
	{
		function dismiss():void;
		function init():void;
		function get hasValidLogin():Boolean;
		function get icon():Object;
		function get isConnected():Boolean;
		function get isPending():Boolean;
		function get isReady():Boolean;
		function avReceiverClear():void;
		function avReceiverSubscribe():void;
		function avSenderClear():Boolean;
		function avSenderPublish():void;
		function roomVarsQueue(vars:Vector.<MessageData>, immediate:Boolean = false):void;
		function sleep():void;
		function userVarsQueue(vars:Vector.<MessageData>, immediate:Boolean = false):void;
		function wake():void;
	}
}