package com.arxterra.vo
{
	public class MessageData
	{
		public var message:String;
		public var data:Object;
		public var typeIsComplex:Boolean;
		public function MessageData ( message:String = '', data:Object = null, typeIsComplex:Boolean = false )
		{
			this.message = message;
			this.data = data;
			this.typeIsComplex = typeIsComplex;
		}
	}
}