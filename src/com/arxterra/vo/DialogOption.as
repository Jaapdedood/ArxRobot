package com.arxterra.vo
{
	public class DialogOption
	{
		public var id:String;
		public var label:String;
		public var params:Array;
		
		/**
		 * 
		 * @param id String unambiguous identifier for this option
		 * @param label String value or resourceName to use as option label
		 * @param params optional Array of parameters that are substituted for
		 * placeholders if <code>label</code> is a resourceName.
		 * 
		 */
		public function DialogOption ( id:String, label:String, params:Array = null )
		{
			this.id = id;
			this.label = label;
			this.params = params;
		}
	}
}