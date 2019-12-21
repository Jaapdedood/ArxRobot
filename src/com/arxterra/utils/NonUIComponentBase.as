package com.arxterra.utils
{
	import com.arxterra.events.DebugByteArrayEvent;
	import com.arxterra.events.DebugEventEx;
	import com.arxterra.events.DialogEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.styles.IStyleManager2;
	import mx.styles.StyleManager;
	
	[Event(name="debugOut", type="com.arxterra.events.DebugEventEx")]
	[Event(name="debug_byte_array", type="com.arxterra.events.DebugByteArrayEvent")]
	
	/**
	 * Extends EventDispatcher with utility methods, such as <code>_callLater</code>,
	 * and access to <code>_resourceManager</code> and <code>_styleManager</code>,
	 * providing a light-weight alternative to UIComponent.
	 */
	public class NonUIComponentBase extends EventDispatcher
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		/**
		 * eventRelay IEventDispatcher reference to top level event dispatcher,
		 * such as the topLevelApplication, to dispatch events on behalf of
		 * objects not in the display list.
		 */
		public static var eventRelay:IEventDispatcher;
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		public function NonUIComponentBase ( )
		{
			super();
			_styleMgr = StyleManager.getStyleManager ( null );
			_rsrcMgr = ResourceManager.getInstance ( );
			_rsrcMgr.addEventListener ( Event.CHANGE, _localeUpdate );
			_CallQueueInit ( );
		}
		
		/**
		 * Overrides <b>must</b> call super.dismiss().
		 */
		public function dismiss ( ) : void
		{
			_CallQueueDismiss ( );
			_rsrcMgr.removeEventListener ( Event.CHANGE, _localeUpdate );
			_rsrcMgr = null;
			_styleMgr = null;
		}
		
		
		// PROTECTED PROPERTIES AND ACCESSORS
		
		protected function get _resourceManager ( ) : IResourceManager
		{
			return _rsrcMgr;
		}
		
		protected function get _styleManager ( ) : IStyleManager2
		{
			return _styleMgr;
		}
		
		
		// PROTECTED METHODS
		
		protected function _alert (
			message:String,
			title:String = 'error',
			messageParams:Array = null,
			titleParams:Array = null
		) : void
		{
			if ( eventRelay )
				eventRelay.dispatchEvent (
					new DialogEvent (
						DialogEvent.ALERT,
						message,
						title,
						messageParams,
						titleParams
					)
				);
		}
		
		/**
		 * Works similarly to the UIComponent's callLater method, except its purpose
		 * is just to avoid blocking code and the timing of execution is not
		 * coordinated with display updates.
		 * @param func
		 * @param args
		 * @param scope
		 */
		protected function _callLater ( func:Function, args:Array = null, scope:Object = null ) : void
		{
			var oScope:Object = scope || this;
			_vCallQueue [ _vCallQueue.length ] = new CallLaterData ( func, args, oScope, setTimeout ( _CallQueueService, _uCallDelay ) );
		}
		
		/**
		 * Sets timer delay for _callLater method
		 * @param msec milliseconds no less than 20,
		 * which is shortest interval considered safe in AS3 docs
		 */		
		protected function _callLaterDelaySet ( msec:uint = 20 ) : void
		{
			if ( msec < 20 )
			{
				_uCallDelay = 20;
			}
			else
			{
				_uCallDelay = msec;
			}
		}
		
		protected function _debugByteArrayOut ( messageResource:String, bytes:ByteArray ) : void
		{
			if ( eventRelay )
			{
				eventRelay.dispatchEvent ( new DebugByteArrayEvent ( DebugByteArrayEvent.DEBUG_BYTE_ARRAY, messageResource, bytes ) );
			}
			dispatchEvent ( new DebugByteArrayEvent ( DebugByteArrayEvent.DEBUG_BYTE_ARRAY, messageResource, bytes ) );
		}
		
		protected function _debugEventRelay ( event:DebugEventEx ) : void
		{
			if ( eventRelay )
			{
				eventRelay.dispatchEvent ( event );
			}
			dispatchEvent ( event );
		}
		
		protected function _debugOut (
			message:String = '',
			isResource:Boolean = false,
			resourceParams:Array = null,
			alertOk:Boolean = false,
			end:String = '\n'
		) : void
		{
			if ( eventRelay )
			{
				eventRelay.dispatchEvent (
					new DebugEventEx (
						DebugEventEx.DEBUG_OUT,
						message,
						isResource,
						resourceParams,
						alertOk,
						end
					)
				);
			}
			
			dispatchEvent (
				new DebugEventEx (
					DebugEventEx.DEBUG_OUT,
					message,
					isResource,
					resourceParams,
					alertOk,
					end
				)
			);
		}
		
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
				var iObjsLim:int;
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
		
		/**
		 * Handles locale change events.
		 * Subclass overrides should call super._localeUpdate()
		 */
		protected function _localeUpdate ( event:Event = null ) : void
		{
			_dynamicLocalePropsUpdate ( );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _iDynLocPropsLim:int = 0;
		private var _oDynLocData:Object;
		private var _rsrcMgr:IResourceManager;
		private var _styleMgr:IStyleManager2;
		private var _uCallDelay:uint = 20;
		private var _vCallQueue:Vector.<CallLaterData>;
		private var _vDynLocPropDefVals:Vector.<String>;
		private var _vDynLocPropNames:Vector.<String>;
		
		
		// PRIVATE METHODS
		
		private function _CallQueueDismiss ( ) : void
		{
			var i:int;
			var iLim:int;
			if ( _vCallQueue )
			{
				iLim = _vCallQueue.length;
				for ( i=0; i<iLim; i++ )
				{
					_vCallQueue [ i ].cancel ( );
				}
				_vCallQueue.length = 0;
				_vCallQueue = null;
			}
		}
		
		private function _CallQueueInit ( ) : void
		{
			_vCallQueue = new <CallLaterData> [];
		}
		
		private function _CallQueueService ( ) : void
		{
			var cld:CallLaterData;
			if ( _vCallQueue.length > 0 )
			{
				cld = _vCallQueue.shift ( );
				cld.call ( );
				cld = null;
			}
		}
	}
}