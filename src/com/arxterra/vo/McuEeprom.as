package com.arxterra.vo
{
	import com.arxterra.components.EepromItemRendererBoolean;
	import com.arxterra.components.EepromItemRendererGroup;
	import com.arxterra.components.EepromItemRendererNumeric;
	import com.arxterra.components.EepromItemRendererReadOnly;
	
	import flash.utils.ByteArray;
	
	import mx.core.ClassFactory;
	
	[Bindable]
	/**
	 * Represents an Mcu EEPROM item.
	 */
	public class McuEeprom
	{
		// CONSTANTS
		
		private static const __RESOURCE_ROOT:String = 'eeprom_';
		private static const __TYPES:Vector.<String> = new <String> [ 'bool', 'byte', 'double', 'group', 'short', 'ubyte', 'ushort' ];
		private static const __NUMERICS:Vector.<String> = new <String> [ 'byte', 'double', 'short', 'ubyte', 'ushort' ];
		// [ max, min, step ]
		private static const __NUM_DEF_PROPS:Object = {
			'byte': [ 127, -128, 1 ],
			'double': [ 99.99, 0, 0.01 ],
			'short': [ 32767, -32768, 1 ],
			'ubyte': [ 255, 0, 1 ],
			'ushort': [ 65535, 0, 1 ]
		};
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		/**
		 * EEPROM address, as a uint representing an unsigned short
		 */
		[Bindable (event="eeprom_changed")]
		public function get address ( ) : uint
		{
			_ba.position = 0;
			return _ba.readUnsignedShort ( );
		}
		
		/**
		 * EEPROM address, as a hex string representing an unsigned short
		 */
		[Bindable (event="eeprom_changed")]
		public function get addressHex ( ) : String
		{
			var s:String = address.toString ( 16 ).toUpperCase ( );
			while ( s.length < 3 )
			{
				s = '0' + s;
			}
			return '0x' + s;
		}
		
		/**
		 * Number of bytes required to store the data, as a uint representing an unsigned byte
		 */
		[Bindable (event="eeprom_changed")]
		public function get byteCount ( ) : uint
		{
			return _ba [ 2 ];
		}
		
		/**
		 * True if value has been changed by user after initialization
		 */
		[Bindable (event="eeprom_changed")]
		public function get changed ( ) : Boolean
		{
			return _bChanged;
		}
		
		/**
		 * ByteArray to send to Mcu to read this EEPROM item
		 */
		public function get messageBytesForRead ( ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( 0x6 );
			ba.writeBytes ( _ba, 0, 3 );
			return ba;
		}
		
		/**
		 * ByteArray to send to Mcu to write this EEPROM item
		 */
		public function get messageBytesForWrite ( ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( 0x7 );
			ba.writeBytes ( _ba );
			return ba;
		}
		
		/**
		 * True if value is editable by user
		 */
		public function get editable ( ) : Boolean
		{
			return _bEditable;
		}
		
		public function get groupId ( ) : String
		{
			return _sGroupId;
		}
		
		/**
		 * Somewhat human-readable unique ID used for lookup, SmartFox variables, locale resource names, and documentation
		 */
		public function get id ( ) : String
		{
			return _sId;
		}
		
		public function get isNumeric ( ) : Boolean
		{
			return _bNumeric;
		}
		
		/**
		 * Item renderer for DataGroup view
		 */
		public function get itemRenderer ( ) : ClassFactory
		{
			if ( !_cfValueRenderer )
			{
				if ( _sType == 'group' )
				{
					_cfValueRenderer = new ClassFactory ( com.arxterra.components.EepromItemRendererGroup );
				}
				else if ( !_bEditable )
				{
					_cfValueRenderer = new ClassFactory ( com.arxterra.components.EepromItemRendererReadOnly );
				}
				else if ( _sType == 'bool' )
				{
					_cfValueRenderer = new ClassFactory ( com.arxterra.components.EepromItemRendererBoolean );
				}
				else
				{
					// numeric
					_cfValueRenderer = new ClassFactory ( com.arxterra.components.EepromItemRendererNumeric );
				}
			}
			return _cfValueRenderer;
		}
		
		/**
		 * Maximum value for numeric editor
		 */
		public function get maximum ( ) : Number
		{
			return _nMax;
		}
		public function set maximum ( val:Number ) : void
		{
			_nMax = val;
		}
		
		/**
		 * Minimum value for numeric editor
		 */
		public function get minimum ( ) : Number
		{
			return _nMin;
		}
		public function set minimum ( val:Number ) : void
		{
			_nMin = val;
		}
		
		/**
		 * Flag for item that should be reported to SmartFox Server as user variable
		 */
		public function get reportable ( ) : Boolean
		{
			return _bReportable;
		}
		
		/**
		 * Name passed to resourceManager.getString() to read localized label string from locale properties.  Derived from ID string.
		 */
		[Bindable (event="eeprom_changed")]
		public function get resource ( ) : String
		{
			return __RESOURCE_ROOT + _sId;
		}
		
		/**
		 * Step value for numeric editor
		 */
		public function get step ( ) : Number
		{
			return _nStep;
		}
		public function set step ( val:Number ) : void
		{
			_nStep = val;
		}
		
		/**
		 * Returns one of the abbreviations stored in __TYPES,
		 * which (with the exception of 'group') are used
		 * in the json config files to represent data types
		 * written into ByteArray form and stored in EEPROM
		 */
		[Bindable (event="eeprom_changed")]
		public function get type ( ) : String
		{
			return _sType;
		}
		
		/**
		 * Value will be cast to the appropriate type when stored
		 */
		public function get value ( ) : *
		{
			return this [ _sType ];
		}
		public function set value ( val:* ) : void
		{
			if ( this [ _sType ] != val )
			{
				_bChanged = true;
				this [ _sType ] = val;
			}
		}
		
		
		// CONSTRUCTOR
		
		/**
		 * @param address uint - EEPROM address, as a uint representing an unsigned short
		 * @param byteCount uint - Number of bytes required to store the data, as a uint representing an unsigned byte
		 * @param id String - Somewhat human-readable unique ID used in SmartFox variables, locale resource names, and documentation
		 * @param type String - One of the abbreviations [ 'bool', 'byte', 'double', 'short', 'ubyte', 'ushort' ]
		 * used in eeprom.json config file to represent data types written into ByteArray form stored in EEPROM
		 * @param val * - Data stored in this EEPROM item
		 * @param reportable Boolean - True if this item should be reported to SmartFox Server as user variable
		 * #param groupId String - ID used for grouping in configuration view
		 */
		public function McuEeprom ( address:uint, byteCount:uint, id:String, type:String, val:*, reportable:Boolean, groupId:String )
		{
			_sId = id;
			_sGroupId = groupId;
			// create byte array
			_ba = new ByteArray ( );
			// store address
			_ba.writeShort ( address );
			// validate type and store it
			if ( __TYPES.indexOf ( type ) < 0 )
			{
				// default to read-only ubyte, and flag error
				_bEditable = false;
				_bError = true;
				_sType = 'ubyte';
				_ba.writeByte ( 1 );
			}
			else
			{
				_sType = type;
				_ba.writeByte ( byteCount );
			}
			// check for read-only metadata group items
			if ( _sGroupId == 'g0mt' )
			{
				_bEditable = false;
			}
			if ( _bEditable && __NUMERICS.indexOf ( _sType ) >= 0 )
			{
				_bNumeric = true;
				var aDefs:Array = __NUM_DEF_PROPS [ _sType ];
				_nMax = aDefs [ 0 ];
				_nMin = aDefs [ 1 ];
				_nStep = aDefs [ 2 ];
			}
			_bReportable = reportable;
			// store value
			this [ _sType ] = val;
			// any updates to value via the value setter will set the changed flag
		}
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Sets value (without setting <strong>changed</strong> flag).
		 * @param val value deserialized from storage
		 */
		public function restoreValue ( val:* ) : void
		{
			this [ _sType ] = val;
		}
		
		/**
		 * Sets value (without setting <strong>changed</strong> flag) from the
		 * next available bytes in the supplied byte array.
		 * @param byteArray reference to incoming byte array
		 * @return <strong>true</strong> if there were sufficient bytes available, <strong>false</strong> if not
		 */
		public function restoreValueFromByteArray ( byteArray:ByteArray ) : Boolean
		{
			if ( byteArray.bytesAvailable < byteCount )
				return false;
			
			byteArray.readBytes ( _ba, 3, byteCount );
			return true;
		}
		
		// PUBLIC STATIC METHODS
		
		public static function NewFromJson ( id:String, props:Object ) : McuEeprom
		{
			var ae:McuEeprom = new McuEeprom ( props.addr, props.bytes, id, props.type, props.def, props.rep, props.grpid );
			if ( ae.isNumeric )
			{
				if ( 'max' in props )
				{
					ae.maximum = props.max;
				}
				if ( 'min' in props )
				{
					ae.minimum = props.min;
				}
				if ( 'step' in props )
				{
					ae.step = props.step;
				}
			}
			return ae;
		}
		
		// PROTECTED PROPERTIES AND GET/SET METHOD GROUPS
		
		protected function get bool ( ) : Boolean
		{
			if ( !_ReadyToReadValue ( ) )
				return false;
			return _ba.readBoolean ( );
		}
		protected function set bool ( val:Boolean ) : void
		{
			_ba.position = 3;
			_ba.writeBoolean ( val );
		}
		
		protected function get byte ( ) : int
		{
			if ( !_ReadyToReadValue ( ) )
				return 0;
			return _ba.readByte ( );
		}
		protected function set byte ( val:int ) : void
		{
			_ba.position = 3;
			_ba.writeByte ( val );
		}
		
		protected function get short ( ) : int
		{
			if ( !_ReadyToReadValue ( ) )
				return 0;
			return _ba.readShort ( );
		}
		protected function set short ( val:int ) : void
		{
			_ba.position = 3;
			_ba.writeShort ( val );
		}
		
		protected function get double ( ) : Number
		{
			if ( !_ReadyToReadValue ( ) )
				return NaN;
			return _ba.readDouble ( );
		}
		protected function set double ( value:Number ) : void
		{
			_ba.position = 3;
			_ba.writeDouble ( value );
		}
		
		protected function get group ( ) : *
		{
			return null;
		}
		protected function set group ( val:* ) : void
		{
		}
		
		protected function get ubyte ( ) : uint
		{
			if ( !_ReadyToReadValue ( ) )
				return 0;
			return _ba.readUnsignedByte ( );
		}
		protected function set ubyte ( val:uint ) : void
		{
			_ba.position = 3;
			_ba.writeByte ( val );
		}
		
		protected function get ushort ( ) : uint
		{
			if ( !_ReadyToReadValue ( ) )
				return 0;
			return _ba.readUnsignedShort ( );
		}
		protected function set ushort ( val:uint ) : void
		{
			_ba.position = 3;
			_ba.writeShort ( val );
		}
		
		// PRIVATE PROPERTIES
		
		private var _ba:ByteArray;
		private var _bChanged:Boolean = false;
		private var _bEditable:Boolean = true;
		private var _bError:Boolean = false;
		private var _bNumeric:Boolean = false;
		private var _bReportable:Boolean;
		private var _cfValueRenderer:ClassFactory;
		private var _nMax:Number = 255;
		private var _nMin:Number = 0;
		private var _nStep:Number = 1;
		private var _sGroupId:String;
		private var _sId:String;
		private var _sType:String;
		
		// PRIVATE METHODS
		
		// validates whether enough bytes are available, and sets position
		private function _ReadyToReadValue ( ) : Boolean
		{
			if ( _ba.length < 3 )
				return false;
			_ba.position = 3;
			if ( _ba.bytesAvailable <  _ba [ 2 ] )
				return false;
			return true;
		}
		
	}
}