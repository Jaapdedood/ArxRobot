package com.arxterra.icons
{
	import mx.events.FlexEvent;

	public class ValueIconBase extends ColorizedIconBase
	{
		public function ValueIconBase()
		{
			super();
		}
		
		override public function styleChanged ( styleProp:String ) : void
		{
			super.styleChanged ( styleProp );
			
			if ( styleProp == 'iconValue' )
			{
				_bNeedStyleUpdate = true; 
				invalidateDisplayList ( );
			}
			
		}
		
		[Bindable]
		protected var iconValue:Number = 0.6;
		
		override protected function _initialize ( event:FlexEvent = null ) : void
		{
			super._initialize ( );
			iconValue = getStyle ( 'iconValue' ) as Number;
		}
		
		override protected function updateDisplayList ( unscaledWidth:Number, unscaledHeight:Number ) : void
		{
			super.updateDisplayList ( unscaledWidth, unscaledHeight );
			
			// Check to see if style changed. 
			if ( _bNeedStyleUpdate ) 
			{
				_bNeedStyleUpdate = false;
				iconValue = getStyle ( 'iconValue' ) as Number;
			}
			
		}
		
		private var _bNeedStyleUpdate:Boolean = true;
	}
}