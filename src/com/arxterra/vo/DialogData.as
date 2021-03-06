package com.arxterra.vo
{

	public class DialogData
	{
		public var id:String;
		public var options:Vector.<DialogOption>;
		public var responseIndex:int = -1;
		public var callback:Function;
		
		/**
		 * 
		 * @param id String identifier for this dialog
		 * @param options Vector of DialogOption instances, providing button ids and label strings
		 * @param defaultIndex optional integer default selected option index,
		 * to be returned if dialog is canceled without an option selected
		 * (defaults to -1, which means no selection)
		 * @param callback optional Function to be called when the dialog closes,
		 * passing the commit value and the DialogData instance with final values
		 * 
		 */
		public function DialogData ( id:String, options:Vector.<DialogOption>, defaultIndex:int = -1, callback:Function = null )
		{
			this.id = id;
			this.options = options;
			if ( ( defaultIndex >= -1 ) && ( defaultIndex < options.length ) ) this.responseIndex = defaultIndex;
			this.callback = callback;
		}
	}
}