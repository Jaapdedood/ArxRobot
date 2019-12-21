package com.arxterra.vo
{
	[Bindable]
	public class CustomSelectOption
	{
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function get configLabel ( ) : String
		{
			return idHexDec + ' ' + label;
		}
		
		public var id:uint;
		
		public function get idHexDec ( ) : String
		{
			var s:String = id.toString ( 16 ).toUpperCase ( );
			if ( s.length < 2 )
				s = '0' + s;
			
			return '0x' + s + ' (' + id.toString() + ')';
		}
		
		public var label:String;
		public var sortIndex:uint;
		public var tip:String;
		
		// CONSTRUCTOR
		
		public function CustomSelectOption ( id:uint = 0, label:String = '', tip:String = '', sortIndex:uint = 0 )
		{
			this.id = id;
			this.label = label;
			this.tip = tip;
			this.sortIndex = sortIndex;
		}
	}
}