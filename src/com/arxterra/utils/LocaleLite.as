package com.arxterra.utils
{
	import flash.events.Event;

	/**
	 * Base class to handle localization via properties loaded at runtime,
	 * such as from database queries and external configuration files.
	 */	
	public class LocaleLite extends ResourceLite
	{
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @copy LocaleLite
		 */
		public function LocaleLite ( )
		{
			super();
			_resourceManager.addEventListener ( Event.CHANGE, _localeUpdate );
		}
		
		/**
		 * Overrides <b>must</b> call super.dismiss().
		 */
		public function dismiss ( ) : void
		{
			_resourceManager.removeEventListener ( Event.CHANGE, _localeUpdate );
		}
		
		
		// PROTECTED METHODS
		
		/**
		 * Initializes localization data loaded dynamically,
		 * such as from database queries and external configuration files.
		 * @param localeData Object with localization objects keyed to locale names, such as 'en_US'
		 * @param propNames Names of properties to be localized
		 * @param propDefaultValues Optional vector to provide default values
		 * if they are not simply the initial values of propNames properties
		 */
		protected function _dynamicLocalePropsInit (
			localeData:Object,
			propNames:Vector.<String>,
			propDefaultValues:Vector.<String> = null
		) : void
		{
			var i:int;
			if ( localeData != null )
			{
				_oDynLocData = localeData;
				_iDynLocPropsLim = propNames.length;
				if ( _iDynLocPropsLim > 0 )
				{
					_vDynLocPropNames = propNames;
					if ( propDefaultValues != null && propDefaultValues.length >= _iDynLocPropsLim )
					{
						// use supplied defaults
						_vDynLocPropDefVals = propDefaultValues;
					}
					else
					{
						// use current values as defaults
						_vDynLocPropDefVals = new <String> [];
						for ( i=0; i<_iDynLocPropsLim; i++ )
						{
							_vDynLocPropDefVals [ i ] = this [ _vDynLocPropNames [ i ] ];
						}
					}
				}
			}
		}
		
		/**
		 * For any localizable properties initialized via the
		 * _dynamicLocalePropsInit method, looks up values
		 * based upon current locale chain
		 */
		protected function _dynamicLocalePropsUpdate ( ) : void
		{
			if ( _iDynLocPropsLim > 0 )
			{
				var vChain:Vector.<String> = Vector.<String> ( _resourceManager.localeChain );
				var vLocObjs:Vector.<Object> = new <Object> [];
				var i:int;
				var iChainLim:int = vChain.length;
				var iObjsLim:int = 0;
				var i_sLocName:String;
				var i_sPropName:String;
				var j:int;
				var j_oLocData:Object;
				// iterate locale chain to assemble array of available matching
				// locale objects, if any, in current chain order
				for ( i=0; i<iChainLim; i++ )
				{
					i_sLocName = vChain [ i ];
					if ( i_sLocName in _oDynLocData )
					{
						vLocObjs [ iObjsLim++ ] = _oDynLocData [ i_sLocName ] as Object;
					}
				}
				
				if ( iObjsLim < 1 )
				{
					// found nothing that matches current locale chain,
					// so set all to defaults
					for ( i=0; i<_iDynLocPropsLim; i++ )
					{
						this [ _vDynLocPropNames [ i ] ] = _vDynLocPropDefVals [ i ];
					}
				}
				else
				{
					// iterate property names to be localized
					propsLoop: for ( i=0; i<_iDynLocPropsLim; i++ )
					{
						i_sPropName = _vDynLocPropNames [ i ];
						// iterate available locale objects until find localized value, if any
						for ( j=0; j<iObjsLim; j++ )
						{
							j_oLocData = vLocObjs [ j ];
							if ( i_sPropName in j_oLocData )
							{
								this [ i_sPropName ] = j_oLocData [ i_sPropName ] as String;
								continue propsLoop;
							}
						}
						// if get here, found nothing for this property in current locale chain, so use default
						this [ i_sPropName ] = _vDynLocPropDefVals [ i ];
					}
				}
			}
		}
		
		protected function _localeUpdate ( event:Event = null ) : void
		{
			_dynamicLocalePropsUpdate ( );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _iDynLocPropsLim:int = 0;
		private var _oDynLocData:Object;
		private var _vDynLocPropDefVals:Vector.<String>;
		private var _vDynLocPropNames:Vector.<String>;
		
	}
}