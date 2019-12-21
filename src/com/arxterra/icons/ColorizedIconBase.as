package com.arxterra.icons
{
	import mx.events.FlexEvent;
	
	import spark.components.Group;
	
	public class ColorizedIconBase extends Group
	{
		public function ColorizedIconBase()
		{
			super();
			super.addEventListener ( FlexEvent.CREATION_COMPLETE, _initialize );
		}
		
		override public function styleChanged ( styleProp:String ) : void
		{
			super.styleChanged ( styleProp );
			
			if ( styleProp == 'color' || styleProp == 'symbolColor' )
			{
				_bNeedStyleUpdate = true; 
				invalidateDisplayList ( );
			}
			
		}
		
		[Bindable]
		protected var iconColor:uint;
		
		[Bindable]
		protected var symbolColor:uint;
		
		protected function _initialize ( event:FlexEvent = null ) : void
		{
			super.removeEventListener ( FlexEvent.CREATION_COMPLETE, _initialize );
			iconColor = getStyle ( 'color' );
			symbolColor = getStyle ( 'symbolColor' );
		}
		
		override protected function updateDisplayList ( unscaledWidth:Number, unscaledHeight:Number ) : void
		{
			super.updateDisplayList ( unscaledWidth, unscaledHeight );
			
			// Check to see if style changed. 
			if ( _bNeedStyleUpdate ) 
			{
				_bNeedStyleUpdate = false;
				iconColor = getStyle ( 'color' );
				symbolColor = getStyle ( 'symbolColor' );
			}
		}
		
		private var _bNeedStyleUpdate:Boolean = true;
	}
}