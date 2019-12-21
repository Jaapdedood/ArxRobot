package com.arxterra.vo
{
	public class StatusData
	{
		public var icon:Class;
		public var label:String;
		
		public function StatusData ( label:String, icon:Class = null )
		{
			this.label = label;
			this.icon = icon;
		}
	}
}