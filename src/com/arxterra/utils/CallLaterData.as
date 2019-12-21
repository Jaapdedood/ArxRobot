package com.arxterra.utils
{
	import flash.utils.clearTimeout;

	public class CallLaterData 
	{
		private var _uTimeId:uint;
		private var _oScope:Object;
		private var _aArgs:Array;
		private var _fFunc:Function;
		
		public function CallLaterData ( func:Function, args:Array, scope:Object, timeoutID:uint )
		{
			_oScope = scope;
			_aArgs = args;
			_fFunc = func;
			_uTimeId = timeoutID;
		}
		
		public function cancel ( ) : void
		{
			clearTimeout ( _uTimeId );
			_oScope = null;
			_aArgs = null;
			_fFunc = null;
		}
		
		public function call ( ) : void
		{
			// clearTimeout ( _uTimeId );
			_fFunc.apply ( _oScope, _aArgs );
			_oScope = null;
			_aArgs = null;
			_fFunc = null;
		}
	}
}