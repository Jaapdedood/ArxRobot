package com.arxterra.vo
{
	import com.arxterra.interfaces.IPilotMessageSerialize;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.Timer;
	
	[Event(name="inset_config_change", type="flash.events.Event")]
	[Event(name="inset_horizontal_change", type="flash.events.Event")]
	[Event(name="inset_size_change", type="flash.events.Event")]
	[Event(name="inset_vertical_change", type="flash.events.Event")]
	
	public class InsetConfig extends EventDispatcher implements IExternalizable, IPilotMessageSerialize
	{
		// CONSTANTS
		
		//   event names
		public static const INSET_CONFIG_CHANGE:String = 'inset_config_change';
		public static const INSET_HORIZONTAL_CHANGE:String = 'inset_horizontal_change';
		public static const INSET_SIZE_CHANGE:String = 'inset_size_change';
		public static const INSET_VERTICAL_CHANGE:String = 'inset_vertical_change';
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="inset_horizontal_change")]
		public function get horizontalPosition():Number
		{
			return _nPosH;
		}
		public function set horizontalPosition(value:Number):void
		{
			if ( value != _nPosH )
			{
				_nPosH = value;
				_ChangeEventDispatch ( INSET_HORIZONTAL_CHANGE );
			}
		}
		
		[Bindable (event="inset_size_change")]
		public function get size():Number
		{
			return _nSize;
		}
		public function set size(value:Number):void
		{
			if ( value != _nSize )
			{
				_nSize = value;
				_ChangeEventDispatch ( INSET_SIZE_CHANGE );
			}
		}
		
		[Bindable (event="inset_vertical_change")]
		public function get verticalPosition():Number
		{
			return _nPosH;
		}
		public function set verticalPosition(value:Number):void
		{
			if ( value != _nPosH )
			{
				_nPosH = value;
				_ChangeEventDispatch ( INSET_VERTICAL_CHANGE );
			}
		}
		
		
		// CONSTRUCTOR AND SERIALIZATION / DESERIALIZATION
		
		public function InsetConfig ( bytes:ByteArray = null )
		{
			if ( bytes )
			{
				_BaIn ( bytes );
			}
		}
		
		// implements IExternalizable
		public function readExternal ( input:IDataInput ) : void
		{
			_BaIn ( input.readObject ( ) );
		}
		
		// implements IExternalizable
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject ( _BaOut ( ) );
		}
		
		// implements IPilotMessageSerialize
		public function toSFSObject():ISFSObject
		{
			var sfso:ISFSObject = new SFSObject ( );
			sfso.putByteArray ( 'b', _BaOut ( ) );
			return sfso;
		}
		
		public function updateFromSFSObject ( sfso:ISFSObject ) : void
		{
			_BaInNotify ( sfso.getByteArray ( 'b' ) );
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : InsetConfig
		{
			return new InsetConfig ( sfso.getByteArray ( 'b' ) );
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _nPosH:Number = 1; // 0 (left) to 1 (right), fraction of position within available width
		private var _nPosV:Number = 1; // 0 (top) to 1 (bottom), fraction of position within available height
		private var _nSize:Number = 0.5; // 0 to 1 fraction of available space, as constrained by min and max constants
		private var _tmrMstr:Timer;
		private var _uBytes:uint = 1;
		
		
		// PRIVATE METHODS
		
		private function _BaIn ( ba:ByteArray ) : void
		{
			var uLen:uint = ba.length;
			if ( uLen < 3 )
			{
				return; // return
			}
			
			ba.position = 0;
			if ( uLen > 5 )
			{
				_uBytes = 2;
				_nPosH = ba.readUnsignedShort ( ) / 65535.0;
				_nPosV = ba.readUnsignedShort ( ) / 65535.0;
				_nSize = ba.readUnsignedShort ( ) / 65535.0;
			}
			else
			{
				_uBytes = 1;
				_nPosH = ba.readUnsignedByte ( ) / 255.0;
				_nPosV = ba.readUnsignedByte ( ) / 255.0;
				_nSize = ba.readUnsignedByte ( ) / 255.0;
			}
		}
		
		private function _BaInNotify ( ba:ByteArray ) : void
		{
			var uLen:uint = ba.length;
			if ( uLen < 3 )
			{
				return; // return
			}
			
			ba.position = 0;
			if ( ba.length > 5 )
			{
				_uBytes = 2;
				_nPosH = ba.readUnsignedShort ( ) / 65535.0;
				_nPosV = ba.readUnsignedShort ( ) / 65535.0;
				_nSize = ba.readUnsignedShort ( ) / 65535.0;
			}
			else
			{
				_uBytes = 1;
				_nPosH = ba.readUnsignedByte ( ) / 255.0;
				_nPosV = ba.readUnsignedByte ( ) / 255.0;
				_nSize = ba.readUnsignedByte ( ) / 255.0;
			}
		}
		
		private function _BaOut ( ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			if ( _uBytes < 2 )
			{
				ba.writeByte ( Math.round ( 255.0 * _nPosH ) );
				ba.writeByte ( Math.round ( 255.0 * _nPosV ) );
				ba.writeByte ( Math.round ( 255.0 * _nSize ) );
			}
			else
			{
				ba.writeShort ( Math.round ( 65535.0 * _nPosH ) );
				ba.writeShort ( Math.round ( 65535.0 * _nPosV ) );
				ba.writeShort ( Math.round ( 65535.0 * _nSize ) );
			}
			return ba;
		}
		
		private function _ChangeEventDispatch ( eventName:String ) : void
		{
			dispatchEvent ( new Event ( eventName ) );
			_MasterChangeEventQueue ( );
		}
		
		private function _MasterChangeEvent ( event:TimerEvent ) : void
		{
			_tmrMstr.stop ( );
			_tmrMstr.removeEventListener ( TimerEvent.TIMER, _MasterChangeEvent );
			_tmrMstr = null;
			dispatchEvent ( new Event ( INSET_CONFIG_CHANGE ) );
		}
		
		private function _MasterChangeEventQueue ( ) : void
		{
			if ( !_tmrMstr )
			{
				_tmrMstr = new Timer ( 20, 0 );
				_tmrMstr.addEventListener ( TimerEvent.TIMER, _MasterChangeEvent );
				_tmrMstr.start ( );
			}
		}
	}
}