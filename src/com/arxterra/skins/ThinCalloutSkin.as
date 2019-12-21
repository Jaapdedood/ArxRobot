
package com.arxterra.skins
{
	import mx.core.DPIClassification;
	
	import spark.skins.mobile.CalloutSkin;
	
	public class ThinCalloutSkin extends CalloutSkin
	{
				
		public function ThinCalloutSkin()
		{
			super();
			
			dropShadowVisible = false;
			useBackgroundGradient = false;
			
			switch (applicationDPI)
			{
				case DPIClassification.DPI_640:
				{
					backgroundCornerRadius = 32;
					borderThickness = 4;
					frameThickness = 24;
					arrowWidth = 80;
					arrowHeight = 40;
					contentCornerRadius = 24;
					
					break;
				}
				case DPIClassification.DPI_480:
				{
					backgroundCornerRadius = 24;
					borderThickness = 3;
					frameThickness = 18;
					arrowWidth = 60;
					arrowHeight = 30;
					contentCornerRadius = 18;
					
					break;
				}
				case DPIClassification.DPI_320:
				{
					backgroundCornerRadius = 16;
					borderThickness = 2;
					frameThickness = 12;
					arrowWidth = 40;
					arrowHeight = 20;
					contentCornerRadius = 12;
					
					break;
				}
				case DPIClassification.DPI_240:
				{
					backgroundCornerRadius = 12;
					borderThickness = 2;
					frameThickness = 9;
					arrowWidth = 30;
					arrowHeight = 15;
					contentCornerRadius = 9;
					
					break;
				}
				default:
				{
					// default DPI_160
					backgroundCornerRadius = 8;
					borderThickness = 1;
					frameThickness = 6;
					arrowWidth = 20;
					arrowHeight = 10;
					contentCornerRadius = 6;
					
					break;
				}
			}
		}
		//--------------------------------------------------------------------------
		//
		//  Overridden methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			borderColor = getStyle ( 'borderColor' );
			
			// create arrow first, super will skip default arrow creation
			arrow = new ThinCalloutArrow (
				borderThickness,
				borderColor
			);
			arrow.id = "arrow";
			arrow.styleName = this;
			
			// call super
			super.createChildren();
			
			// add arrow above all other children
			addChild(arrow);
		}
	}
}