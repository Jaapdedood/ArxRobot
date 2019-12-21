package com.arxterra.interfaces
{
	import com.arxterra.vo.UserState;
	
	import flash.events.IEventDispatcher;
	
	public interface IPermissionsChecker extends IEventDispatcher
	{
		function dismiss():void;
		function get allPermitted():Boolean;
		function get cameraChangeable():Boolean;
		function get cameraDone():Boolean;
		function get cameraPermitted():Boolean;
		function get cameraStatus():String;
		function get done():Boolean;
		function get fileChangeable():Boolean;
		function get fileDone():Boolean;
		function get filePermitted():Boolean;
		function get fileStatus():String;
		function get geolocationChangeable():Boolean;
		function get geolocationDone():Boolean;
		function get geolocationPermitted():Boolean;
		function get geolocationStatus():String;
		function get microphoneChangeable():Boolean;
		function get microphoneDone():Boolean;
		function get microphonePermitted():Boolean;
		function get microphoneStatus():String;
		function get viewHeaderResource():String;
		function request():void;
		function userStateInit(userState:UserState):void;
	}
}