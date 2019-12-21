package com.arxterra.utils
{
	public class CallLaterData 
	{
		protected var _oScope:Object;
		protected var _aArgs:Array;
		protected var _fFunc:Function;
		
		public function CallLaterData ( a_function:Function, a_args:Array, a_scope:Object ) 
		{
			_oScope = a_scope;
			_aArgs = a_args;
			_fFunc = a_function;
		}
		
		public function call ( ) : void
		{
			_fFunc.apply ( _oScope, _aArgs );
		}
	}
}