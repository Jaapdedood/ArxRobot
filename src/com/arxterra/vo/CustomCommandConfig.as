package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import com.arxterra.controllers.SessionManager;
	
	import com.arxterra.interfaces.IPilotMessageSerialize;
	
	import com.arxterra.utils.NonUIComponentBase;
	
	/**
	 * Custom command configuration class.  Uses McuMessage
	 * via composition to store and transmit command byteArray data.
	 */
	public class CustomCommandConfig extends NonUIComponentBase implements IPilotMessageSerialize
	{
		// STATIC CONSTANTS AND PROPERTIES
		
		//   modifier flags
		// SIGNED = 0;
		public static const UNSIGNED:uint = 1;		//				0000 0000 0000 0001
		
		public static const ALT_WIDGET:uint = 2;	//				0000 0000 0000 0010 (1 << 1)
		//															List for SELECT
		//															Stepper for INTEGER
		//															Vertical Slider plus Optional Preset Buttons for SERVO
		
		// public static const ALT_WIDGET_2:uint = 4;	//				0000 0000 0000 0100 (1 << 2)
		//															Buttons for SELECT
		//															Vertical Slider for INTEGER
		
		// public static const ALT_WIDGET_3:uint = ALT_WIDGET | ALT_WIDGET_2;
		//															0000 0000 0000 0110
		//															currently not implemented
		
		//   basic data type flags
		public static const HEADING:uint = 0;
		
		public static const BOOLEAN:uint = 8;	//					0000 0000 0000 1000 (1 << 3)
		
		public static const SELECT:uint = 16;	//					0000 0000 0001 0000 (1 << 4)
		//															Default SELECT widget is Radio Buttons or equivalent
		
		public static const BYTE:uint = 32;		//					0000 0000 0010 0000 (1 << 5)
		//															Default INTEGER widget is Horizontal Slider
		
		public static const SHORT:uint = 64;	//					0000 0000 0100 0000 (1 << 6)
		//															Default INTEGER widget is Horizontal Slider
		
		// public static const BUTTON:uint = 4096;	//					0001 0000 0000 0000 (1 << 12)
		//															Simple button that sends command ID alone upon release
		
		// public static const SERVO:uint = 8192;	//					0010 0000 0000 0000 (1 << 13)
		//															Default widget is Horizontal Slider
		//															plus Optional Preset Buttons
		
		//   op mode compatibility flags
		public static const OP_MODE_RC_COMPATIBLE:uint = 128;	//	0000 0000 1000 0000 (1 << 7)
		public static const OP_MODE_CS_COMPATIBLE:uint = 256;	//	0000 0001 0000 0000 (1 << 8)
		public static const OP_MODE_PP_COMPATIBLE:uint = 512;	//	0000 0010 0000 0000 (1 << 9)
		//   flow protocol flags
		// FLOW_COMMAND = 0;
		public static const FLOW_STATE:uint = 1024;	//				0000 0100 0000 0000 (1 << 10)
		public static const FLOW_STREAM:uint = 2048;	//			0000 1000 0000 0000 (1 << 11)
		//   combinations
		public static const UNSIGNED_BYTE:uint = UNSIGNED | BYTE;	//										0000 0000 0010 0001
		public static const UNSIGNED_SHORT:uint = UNSIGNED | SHORT;	//										0000 0000 0100 0001
		public static const INTEGER:uint = UNSIGNED | BYTE | SHORT /*| SERVO*/;	//								0010 0000 0110 0001
		public static const NON_INTEGER:uint = BOOLEAN | SELECT /*| BUTTON*/;	//								0001 0000 0001 1000
		public static const TYPES:uint = UNSIGNED | BOOLEAN | SELECT | BYTE | SHORT /*| BUTTON | SERVO*/;	//	0011 0000 0111 1001
		
		// array of available types for use by config view
		public static const CONFIG_TYPE_IDS:Array = [
			BOOLEAN,
			SELECT,
			BYTE,
			UNSIGNED_BYTE,
			SHORT,
			UNSIGNED_SHORT,
			// BUTTON,
			// SERVO,
			HEADING
		];
		
		//   events
		public static const COMMAND_UPDATED:String = 'commandUpdated';
		public static const CONFIG_LABEL_UPDATED:String = 'configLabelUpdated';
		public static const FLAGS_UPDATED:String = 'flagsUpdated';
		
		private static const __ALL_FLAGS:uint = UNSIGNED | ALT_WIDGET /*| ALT_WIDGET_2*/ | BOOLEAN | SELECT | BYTE | SHORT /*| BUTTON | SERVO*/ | OP_MODE_RC_COMPATIBLE | OP_MODE_CS_COMPATIBLE | OP_MODE_PP_COMPATIBLE | FLOW_STATE | FLOW_STREAM;
		private static const __HAS_CMD_WIDGET_CHOICE:uint = INTEGER | SELECT /*| SERVO*/;
		private static const __OP_MODE_FLAGS:uint = OP_MODE_RC_COMPATIBLE | OP_MODE_CS_COMPATIBLE | OP_MODE_PP_COMPATIBLE;
		private static const __TELEMETRY_ONLY:uint = FLOW_STATE | FLOW_STREAM;
		
		//   xref compatibility flags by OpModes constants
		private static const __OP_MODE_FLAGS_HASH:Vector.<uint> = new <uint> [
			OP_MODE_RC_COMPATIBLE, OP_MODE_CS_COMPATIBLE, OP_MODE_PP_COMPATIBLE
		];
		private static const __OP_MODE_FLAGS_LEN:uint = __OP_MODE_FLAGS_HASH.length;
		
		private static var __aIntDefLimits:Array;
		public static function get IntegerDefaultLimits ( ) : Array
		{
			if ( !__aIntDefLimits )
			{
				// initialize on first call
				__aIntDefLimits = [];
				// [ max, min, step, step max ]
				__aIntDefLimits [ BYTE ] = [ 127, -128, 1, 127 ];
				__aIntDefLimits [ UNSIGNED_BYTE ] = [ 255, 0, 1, 127 ];
				__aIntDefLimits [ SHORT ] = [ 32767, -32768, 1, 32767 ];
				__aIntDefLimits [ UNSIGNED_SHORT ] = [ 65535, 0, 1, 32767 ];
				// __aIntDefLimits [ SERVO ] = [ 32767, -32768, 1, 32767 ];
			}
			return __aIntDefLimits;
		}
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Transient]
		[Bindable (event="commandUpdated")]
		public function get commandBytes ( ) : ByteArray
		{
			return _mm.messageBytes;
		}
		public function set commandBytes ( val:ByteArray ) : void
		{
			_mm.messageBytes = val;
			_CommandUpdateEventDispatch ( );
			_ConfigLabelUpdateEventDispatch ( );
		}
		
		[Bindable (event="configLabelUpdated")]
		public function get configLabel ( ) : String
		{
			return _mm.messageIdHexDec + ' ' + _sLabel;
		}
		
		/**
		 * also sets value if has not already been set by public setter
		 */		
		[Bindable]
		public function get defaultValue ( ) : *
		{
			return _iDefault;
		}
		public function set defaultValue ( val:* ) : void
		{
			_iDefault = int ( val );
			if ( !_bValueSet )
			{
				value = val;
			}
		}
		
		[Transient]
		[Bindable (event="flagsUpdated")]
		public function get flags ( ) : uint
		{
			return _uFlags;
		}
		public function set flags ( val:uint ) : void
		{
			// validate against all possible flags
			_uFlags = val & __ALL_FLAGS;
			_TypeConfigDefaultsUpdate ( );
			_FlagsUpdateProcess ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get flowIndex ( ) : int
		{
			if ( ( _uFlags & FLOW_STREAM ) > 0 )
				return 2;
			
			if ( ( _uFlags & FLOW_STATE ) > 0 )
				return 1;
			
			return 0;
		}
		public function set flowIndex ( val:int ) : void
		{
			// first clear all flow flags, which is
			// how it will remain if val is 0
			_uFlags &= ~__TELEMETRY_ONLY;
			if ( val == 1 )
			{
				_uFlags |= FLOW_STATE; 
			}
			else if ( val == 2 )
			{
				_uFlags |= FLOW_STREAM;
				_uFlags &= ~OP_MODE_RC_COMPATIBLE; // RC mode not supported by stream flow protocol
			}
			_FlagsUpdateProcess ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get hasWidgetChoice ( ) : Boolean
		{
			if ( ( _uFlags & FLOW_STREAM ) > 0 )
				return false;
			
			if ( ( _uFlags & FLOW_STATE ) > 0 )
				return ( _uFlags & INTEGER ) > 0;
			
			return ( _uFlags & __HAS_CMD_WIDGET_CHOICE ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get hasWidgetChoiceInteger ( ) : Boolean
		{
			if ( ( _uFlags & __TELEMETRY_ONLY ) > 0 )
				return false;
			
			return ( _uFlags & INTEGER ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get hasWidgetChoiceIntegerState ( ) : Boolean
		{
			if ( ( _uFlags & FLOW_STREAM ) > 0 )
				return false;
			
			if ( ( _uFlags & FLOW_STATE ) > 0 )
				return ( _uFlags & INTEGER ) > 0;
			
			return false;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get hasWidgetChoiceSelect ( ) : Boolean
		{
			if ( ( _uFlags & __TELEMETRY_ONLY ) > 0 )
				return false;
			
			return ( _uFlags & SELECT ) > 0;
		}
		
		/**
		 * Unsigned byte Command ID expressed as uint
		 * (stored at the 0 position of messageBytes)
		 */
		[Bindable (event="commandUpdated")]
		public function get id ( ) : uint
		{
			return _mm.messageId
		}
		public function set id ( val:uint ) : void
		{
			// should be validated before this, so not wasting time here
			_mm.messageId = val;
			_CommandUpdateEventDispatch ( );
			_ConfigLabelUpdateEventDispatch ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isBoolean ( ) : Boolean
		{
			return ( _uFlags & BOOLEAN ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isFlowCommand ( ) : Boolean
		{
			return ( _uFlags & __TELEMETRY_ONLY ) == 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isFlowState ( ) : Boolean
		{
			return ( _uFlags & FLOW_STATE ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isFlowStream ( ) : Boolean
		{
			return ( _uFlags & FLOW_STREAM ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isFlowTelemetry ( ) : Boolean
		{
			return ( _uFlags & __TELEMETRY_ONLY ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isHeading ( ) : Boolean
		{
			return ( _uFlags & TYPES ) == 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isInteger ( ) : Boolean
		{
			return ( _uFlags & INTEGER ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isNonHeading ( ) : Boolean
		{
			return ( _uFlags & TYPES ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isNonInteger ( ) : Boolean
		{
			return ( _uFlags & NON_INTEGER ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isSelect ( ) : Boolean
		{
			return ( _uFlags & SELECT ) > 0;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get isShort ( ) : Boolean
		{
			return ( _uFlags & SHORT ) > 0;
		}
		
		[Bindable]
		public function get label ( ) : String
		{
			return _sLabel;
		}
		public function set label ( val:String ) : void
		{
			_sLabel = val;
			_ConfigLabelUpdateEventDispatch ( );
		}
		
		/**
		 * Maximum value for integer control
		 */
		[Bindable]
		public function get max ( ) : int
		{
			return _iMax;
		}
		public function set max ( val:int ) : void
		{
			_iMax = val;
		}
		
		/**
		 * Maximum maximum
		 */
		[Transient]
		[Bindable]
		public function get maxLimit ( ) : int
		{
			return _iMaxLim;
		}
		public function set maxLimit ( val:int ) : void
		{
			_iMaxLim = val;
		}
		
		/**
		 * Maximum safe value for integer entity
		 */
		[Bindable]
		public function get maxSafe():int
		{
			return _iMaxSafe;
		}
		public function set maxSafe(value:int):void
		{
			_iMaxSafe = value;
		}
		
		/**
		 * Minimum value for integer control
		 */
		[Bindable]
		public function get min ( ) : int
		{
			return _iMin;
		}
		public function set min ( val:int ) : void
		{
			_iMin = val;
		}
		
		/**
		 * Minimum minimum
		 */
		[Transient]
		[Bindable]
		public function get minLimit ( ) : int
		{
			return _iMinLim;
		}
		public function set minLimit ( val:int ) : void
		{
			_iMinLim = val;
		}
		
		/**
		 * Minimum safe value for integer entity
		 */
		[Bindable]
		public function get minSafe():int
		{
			return _iMinSafe;
		}
		public function set minSafe(value:int):void
		{
			_iMinSafe = value;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get opModeCompatibilityCS ( ) : Boolean
		{
			return ( _uFlags & OP_MODE_CS_COMPATIBLE ) > 0;
		}
		public function set opModeCompatibilityCS ( value:Boolean ) : void
		{
			if ( value )
				_uFlags |= OP_MODE_CS_COMPATIBLE;
			else
				_uFlags &= ~OP_MODE_CS_COMPATIBLE;
			
			_FlagsUpdateProcess ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get opModeCompatibilityPP ( ) : Boolean
		{
			return ( _uFlags & OP_MODE_PP_COMPATIBLE ) > 0;
		}
		public function set opModeCompatibilityPP ( value:Boolean ) : void
		{
			if ( value )
				_uFlags |= OP_MODE_PP_COMPATIBLE;
			else
				_uFlags &= ~OP_MODE_PP_COMPATIBLE;
			
			_FlagsUpdateProcess ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get opModeCompatibilityRC ( ) : Boolean
		{
			return ( _uFlags & OP_MODE_RC_COMPATIBLE ) > 0;
		}
		public function set opModeCompatibilityRC ( value:Boolean ) : void
		{
			if ( value )
				_uFlags |= OP_MODE_RC_COMPATIBLE;
			else
				_uFlags &= ~OP_MODE_RC_COMPATIBLE;
			
			_FlagsUpdateProcess ( );
		}
		
		[Bindable]
		public function get options ( ) : Vector.<CustomSelectOption>
		{
			if ( !_vOpts )
			{
				_vOpts = new <CustomSelectOption> [];
			}
			return _vOpts;
		}
		public function set options ( val:Vector.<CustomSelectOption> ) : void
		{
			_vOpts = val;
		}
		
		[Bindable]
		/**
		 * Affects display order on Control Panel
		 */
		public function get sortIndex():uint
		{
			return _uSortIdx;
		}
		/**
		 * @private
		 */
		public function set sortIndex ( val:uint ) : void
		{
			_uSortIdx = val;
		}
		
		/**
		 * Step value for integer control
		 */
		[Bindable]
		public function get step ( ) : int
		{
			return _iStep;
		}
		public function set step ( val:int ) : void
		{
			_iStep = val;
		}
		
		/**
		 * Maximum step
		 */
		[Transient]
		[Bindable]
		public function get stepLimit ( ) : int
		{
			return _iStepLim;
		}
		public function set stepLimit ( val:int ) : void
		{
			_iStepLim = val;
		}
		
		[Bindable]
		public var tip:String = '';
		
		[Bindable (event="flagsUpdated")]
		public function get type ( ) : uint
		{
			return _uFlags & TYPES;
		}
		public function set type ( val:uint ) : void
		{
			// clear any previous type flags and
			// validate supplied value against all possible type flags
			_uFlags = ( _uFlags & ~TYPES ) | ( val & TYPES );
			_TypeLimitsDefaultsUpdate ( );
			_FlagsUpdateProcess ( );
		}
		
		[Transient]
		[Bindable (event="flagsUpdated")]
		public function get typeConfig ( ) : uint
		{
			return _uFlags & TYPES;
		}
		public function set typeConfig ( val:uint ) : void
		{
			if ( val < 1 )
			{
				// HEADING
				_uFlags &= ~TYPES;
			}
			else
			{
				// validate against all possible type flags
				_uFlags = ( _uFlags & ~TYPES ) | ( val & TYPES );
			}
			_TypeConfigDefaultsUpdate ( );
			_FlagsUpdateProcess ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get unsigned ( ) : Boolean
		{
			return ( _uFlags & UNSIGNED ) > 0;
		}
		public function set unsigned ( val:Boolean ) : void
		{
			if ( val )
			{
				_uFlags |= UNSIGNED;
			}
			else
			{
				_uFlags &= ~UNSIGNED;
			}
			_FlagsUpdateProcess ( );
		}
		
		/**
		 * Value will be cast to the appropriate type when
		 * read from or written to storage
		 */
		[Transient]
		[Bindable (event="commandUpdated")]
		public function get value ( ) : *
		{
			if ( ( _uFlags & BOOLEAN ) > 0 )
			{
				// BOOLEAN
				return _mm.boolean;
			}
			
			if ( ( _uFlags & SELECT ) > 0 )
			{
				// SELECT
				return _mm.unsignedByte;
			}
			
			if ( ( _uFlags & BYTE ) > 0 )
			{
				if ( ( _uFlags & UNSIGNED ) > 0 )
				{
					// UNSIGNED BYTE
					return _mm.unsignedByte;
				}
				// BYTE
				return _mm.byte;
			}
			
			if ( ( _uFlags & SHORT ) > 0 )
			{
				if ( ( _uFlags & UNSIGNED ) > 0 )
				{
					//  UNSIGNEDSHORT
					return _mm.unsignedShort;
				}
				// SHORT
				return _mm.short;
			}
			
			// HEADING
			return 0; // normally shouldn't get here
		}
		public function set value ( val:* ) : void
		{
			_bValueSet = true;
			if ( ( _uFlags & BOOLEAN ) > 0 )
			{
				// BOOLEAN
				_mm.boolean = val;
			}
			else if ( ( _uFlags & SHORT ) > 0 )
			{
				// SHORT
				_mm.short = val;
			}
			else
			{
				// BYTE or SELECT are only non-heading types left
				// and HEADING value doesn't matter but shouldn't get set anyway
				_mm.byte = val;
			}
			_CommandUpdateEventDispatch ( );
		}
		
		[Bindable (event="flagsUpdated")]
		public function get valueByteCount ( ) : uint
		{
			return _uValByteCount;
		}
		
		[Bindable (event="flagsUpdated")]
		public function get widgetIndex ( ) : int
		{
			return ( ( _uFlags & ALT_WIDGET ) > 0 ) ? 1 : 0;
		}
		public function set widgetIndex ( val:int ) : void
		{
			if ( val == 1 )
			{
				_uFlags |= ALT_WIDGET;
			}
			else
			{
				_uFlags &= ~ALT_WIDGET;
			}
			_FlagsUpdateProcess ( );
		}
		
		// CONSTRUCTOR
		
		public function CustomCommandConfig (
			id:uint = 0,
			defaultValue:* = 0,
			flags:uint = BOOLEAN,
			label:String = '',
			sortIndex:uint = 0
		)
		{
			_sessionMgr = SessionManager.instance;
			_mm = new McuMessage ( new ByteArray ( ) );
			_uSortIdx = sortIndex;
			_sLabel = label;
			_uFlags = flags & __ALL_FLAGS;
			if ( ( _uFlags & TYPES ) == 0 )
			{
				// HEADING
				_mm.messageId = 0;
				_iDefault = 0;
				_mm.byte = 0;
			}
			else
			{
				_mm.messageId = id;
				_iDefault = int ( defaultValue );
				var uIntTypeKey:uint = _uFlags & INTEGER;
				if ( uIntTypeKey > 0 )
				{
					// INTEGER
					var aLims:Array = IntegerDefaultLimits [ uIntTypeKey ];
					_iMax = _iMaxSafe = _iMaxLim = aLims [ 0 ];
					_iMin = _iMinSafe = _iMinLim = aLims [ 1 ];
					_iStep = aLims [ 2 ];
					_iStepLim = aLims [ 3 ];
					if ( ( _uFlags & SHORT ) > 0 )
					{
						// SHORT
						_mm.short = defaultValue;
					}
					else
					{
						// BYTE
						_mm.byte = defaultValue;
					}
				}
				else if ( ( _uFlags & BOOLEAN ) > 0 )
				{
					// BOOLEAN
					_iMax = _iMaxSafe = _iMaxLim = 1;
					_iMin = _iMinSafe = _iMinLim = 0;
					_iStep = _iStepLim = 1;
					_mm.boolean = defaultValue;
				}
				else
				{
					// SELECT
					_iMax = _iMaxSafe = _iMaxLim = 255;
					_iMin = _iMinSafe = _iMinLim = 0;
					_iStep = _iStepLim = 1;
					_mm.byte = defaultValue;
				}
			}
		}
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Checks compatibility flag status for the opMode provided.
		 * @param opMode uint One of the constants of the OpModes class.
		 * @return Boolean <b>true</b> if compatible, <b>false</b> if not.
		 */
		public function opModeCompatibilityGet ( opMode:uint ) : Boolean
		{
			if ( opMode < __OP_MODE_FLAGS_LEN )
				return ( __OP_MODE_FLAGS_HASH [ opMode ] & _uFlags ) > 0;
			
			return false;
		}
		
		/**
		 * Sets or clears compatibility flag for the opMode provided.
		 * @param opMode uint One of the constants of the OpModes class.
		 * @param value Boolean <b>true</b> if compatible, <b>false</b> if not.
		 */
		public function opModeCompatibilitySet ( opMode:uint, value:Boolean ) : void
		{
			if ( opMode < __OP_MODE_FLAGS_LEN )
			{
				if ( value )
				{
					// set the flag
					_uFlags |= __OP_MODE_FLAGS_HASH [ opMode ];
				}
				else
				{
					// clear the flag
					_uFlags &= ~__OP_MODE_FLAGS_HASH [ opMode ];
				}
				_FlagsUpdateProcess ( );
			}
		}
		
		public function setCommandValueFromByteArray ( byteArray:ByteArray ) : Boolean
		{
			_callLater ( _CommandUpdateEventDispatch );
			return _mm.writeValueBytes ( byteArray, _uValByteCount, ( _uFlags & FLOW_STREAM ) > 0 );
		}
		
		public function toSFSObject ( ) : ISFSObject
		{
			var sfso:ISFSObject = _mm.toSFSObject ( );
			if ( ( _uFlags & FLOW_STREAM ) > 0 )
			{
				// streaming, so we accumulate multiple value/timing blocks
				// until toSFSObject method is called to pack up data for relay to Control Panel
				_mm.clearValueBytes ( );
			}
			return sfso;
		}
		
		public function valueTransmit ( ) : void
		{
			_sessionMgr.customRequest ( _mm );
		}
		
		// PROTECTED PROPERTIES AND GET/SET METHOD GROUPS
		
		// PRIVATE PROPERTIES
		
		private var _bValueSet:Boolean = false;
		private var _iDefault:int = 0;
		private var _iMax:int = 255;
		private var _iMaxLim:int = 255;
		private var _iMaxSafe:int = 255;
		private var _iMin:int = 0;
		private var _iMinLim:int = 0;
		private var _iMinSafe:int = 0;
		private var _iStep:int = 1;
		private var _iStepLim:int = 127;
		private var _mm:McuMessage;
		private var _sessionMgr:SessionManager;
		private var _sLabel:String = '';
		private var _uFlags:uint = BOOLEAN | __OP_MODE_FLAGS; // default to Boolean type, compatible with all op modes
		private var _uSortIdx:uint = 0;
		private var _uValByteCount:uint = 0;
		private var _vOpts:Vector.<CustomSelectOption>;
		
		// PRIVATE METHODS
		
		private function _CommandUpdateEventDispatch ( ) : void
		{
			dispatchEvent ( new Event ( COMMAND_UPDATED ) );
		}
		
		private function _ConfigLabelUpdateEventDispatch ( ) : void
		{
			dispatchEvent ( new Event ( CONFIG_LABEL_UPDATED ) );
		}
		
		private function _FlagsUpdateProcess ( ) : void
		{
			_uValByteCount = ( ( _uFlags & FLOW_STREAM ) > 0 ? 4 : 0 ) + ( ( _uFlags & SHORT ) > 0 ? 2 : 1 );
			dispatchEvent ( new Event ( FLAGS_UPDATED ) );
		}
		
		/**
		 * When type flag is changed during configuration, this is called
		 * to set defaults appropriate to the new type.
		 */
		private function _TypeConfigDefaultsUpdate ( ) : void
		{
			_uFlags &= ~ALT_WIDGET;
			if ( ( _uFlags & SELECT ) == 0 )
			{
				// not SELECT
				_vOpts = null;
				
				var uIntTypeKey:uint = _uFlags & INTEGER;
				if ( uIntTypeKey > 0 )
				{
					var aLims:Array = IntegerDefaultLimits [ uIntTypeKey ];
					max = maxSafe = maxLimit = aLims [ 0 ];
					min = minSafe = minLimit = aLims [ 1 ];
					stepLimit = aLims [ 3 ];
					step = aLims [ 2 ];
				}
			}
		}
		
		/**
		 * When type flag is set during restoration, this is
		 * called to set limits appropriate to the type.
		 */
		private function _TypeLimitsDefaultsUpdate ( ) : void
		{
			var uIntTypeKey:uint = _uFlags & INTEGER;
			if ( uIntTypeKey > 0 )
			{
				var aLims:Array = IntegerDefaultLimits [ uIntTypeKey ];
				maxLimit = aLims [ 0 ];
				minLimit = aLims [ 1 ];
				stepLimit = aLims [ 3 ];
			}
		}
	}
}