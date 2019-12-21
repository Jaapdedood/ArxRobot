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
	
	[Event(name="media_audio_partner_change", type="flash.events.Event")]
	[Event(name="media_audio_public_change", type="flash.events.Event")]
	[Event(name="media_camera_flip_horizontal_change", type="flash.events.Event")]
	[Event(name="media_camera_flip_vertical_change", type="flash.events.Event")]
	[Event(name="media_camera_needed_change", type="flash.events.Event")]
	[Event(name="media_camera_rotation_change", type="flash.events.Event")]
	[Event(name="media_microphone_needed_change", type="flash.events.Event")]
	[Event(name="media_config_change", type="flash.events.Event")]
	[Event(name="media_visual_mode_change", type="flash.events.Event")]
	[Event(name="media_visual_needed_change", type="flash.events.Event")]
	[Event(name="media_visual_partner_change", type="flash.events.Event")]
	[Event(name="media_visual_public_change", type="flash.events.Event")]
	[Event(name="media_visual_source_change", type="flash.events.Event")]
	
	public class MediaConfig extends EventDispatcher implements IExternalizable, IPilotMessageSerialize
	{
		// CONSTANTS
		
		//   event names
		public static const MEDIA_AUDIO_PARTNER_CHANGE:String = 'media_audio_partner_change';
		public static const MEDIA_AUDIO_PUBLIC_CHANGE:String = 'media_audio_public_change';
		public static const MEDIA_CAMERA_FLIP_HORIZONTAL_CHANGE:String = 'media_camera_flip_horizontal_change';
		public static const MEDIA_CAMERA_FLIP_VERTICAL_CHANGE:String = 'media_camera_flip_vertical_change';
		public static const MEDIA_CAMERA_NEEDED_CHANGE:String = 'media_camera_needed_change';
		public static const MEDIA_CAMERA_ROTATION_CHANGE:String = 'media_camera_rotation_change';
		public static const MEDIA_CONFIG_CHANGE:String = 'media_config_change';
		public static const MEDIA_MICROPHONE_NEEDED_CHANGE:String = 'media_microphone_needed_change';
		public static const MEDIA_VISUAL_MODE_CHANGE:String = 'media_visual_mode_change';
		public static const MEDIA_VISUAL_NEEDED_CHANGE:String = 'media_visual_needed_change';
		public static const MEDIA_VISUAL_PARTNER_CHANGE:String = 'media_visual_partner_change';
		public static const MEDIA_VISUAL_PUBLIC_CHANGE:String = 'media_visual_public_change';
		public static const MEDIA_VISUAL_SOURCE_CHANGE:String = 'media_visual_source_change';
		
		//   individual flags
		private static const _AUDIO_PARTNER:uint =	1; // same as 1 << 0
		private static const _AUDIO_PUBLIC:uint =	1 << 1; // 2
		private static const _VISUAL_PARTNER:uint =	1 << 2; // 4
		private static const _VISUAL_PUBLIC:uint =	1 << 3; // 8
		private static const _VISUAL_STATIC:uint =	1 << 4; // 16
		private static const _CAM_FLIP_H:uint =		1 << 5; // 32
		private static const _CAM_FLIP_V:uint =		1 << 6; // 64
		
		//   combinations
		private static const _MIC_NEEDED:uint = _AUDIO_PARTNER | _AUDIO_PUBLIC;
		private static const _VISUAL_NEEDED:uint = _VISUAL_PARTNER | _VISUAL_PUBLIC;
		
		private static const _FLAG_COUNT:uint = 7;
		private static const _ALL_FLAGS:uint = ( 1 << _FLAG_COUNT ) - 1;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="media_audio_partner_change")]
		/**
		 * Allow partner to hear audio
		 */
		public function get audioToPartner():Boolean
		{
			return ( _uFlags & _AUDIO_PARTNER ) > 0;
		}
		public function set audioToPartner(value:Boolean):void
		{
			var bMic:Boolean = ( ( _uFlags & _MIC_NEEDED ) > 0 );
			if ( _FlagUpdate ( _AUDIO_PARTNER, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_AUDIO_PARTNER_CHANGE );
				if ( bMic != ( ( _uFlags & _MIC_NEEDED ) > 0 ) )
				{
					_ChangeEventDispatch ( MEDIA_MICROPHONE_NEEDED_CHANGE );
				}
			}
		}
		
		[Bindable (event="media_audio_public_change")]
		/**
		 * Allow guests to hear audio
		 */
		public function get audioToPublic():Boolean
		{
			return ( _uFlags & _AUDIO_PUBLIC ) > 0;
		}
		public function set audioToPublic(value:Boolean):void
		{
			var bMic:Boolean = ( ( _uFlags & _MIC_NEEDED ) > 0 );
			if ( _FlagUpdate ( _AUDIO_PUBLIC, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_AUDIO_PUBLIC_CHANGE );
				if ( bMic != ( ( _uFlags & _MIC_NEEDED ) > 0 ) )
				{
					_ChangeEventDispatch ( MEDIA_MICROPHONE_NEEDED_CHANGE );
				}
			}
		}
		
		[Bindable (event="media_camera_flip_horizontal_change")]
		public function get cameraFlipHorizontal():Boolean
		{
			return ( _uFlags & _CAM_FLIP_H ) > 0;
		}
		public function set cameraFlipHorizontal(value:Boolean):void
		{
			if ( _FlagUpdate ( _CAM_FLIP_H, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_CAMERA_FLIP_HORIZONTAL_CHANGE );
			}
		}
		
		[Bindable (event="media_camera_flip_vertical_change")]
		public function get cameraFlipVertical():Boolean
		{
			return ( _uFlags & _CAM_FLIP_V ) > 0;
		}
		public function set cameraFlipVertical(value:Boolean):void
		{
			if ( _FlagUpdate ( _CAM_FLIP_V, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_CAMERA_FLIP_VERTICAL_CHANGE );
			}
		}
		
		[Bindable (event="media_camera_needed_change")]
		public function get cameraNeeded():Boolean
		{
			return ( ( _uFlags & _VISUAL_STATIC ) < 1 ) && ( ( _uFlags & _VISUAL_NEEDED ) > 0 );
		}
		
		[Bindable (event="media_camera_rotation_change")]
		/**
		 * Rotation (in degrees) override manually set by user. Set values are 0, 90, 180, 270.
		 * Any value over 270 indicates value has not been set. If value is unset
		 * or displayOrientation is not locked, this value is ignored, and the
		 * rotation default for the current display orientation is used.
		 * Otherwise this value is used to force rotation to that set by user.
		 */
		public function get cameraRotation():uint
		{
			return 90 * _uRotPos;
		}
		public function set cameraRotation(value:uint):void
		{
			var uNew:uint = uint ( Math.round ( value / 90.0 ) );
			if ( uNew != _uRotPos )
			{
				// changed
				_uRotPos = uNew;
				_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			}
		}
		
		[Bindable (event="media_microphone_needed_change")]
		public function get microphoneNeeded():Boolean
		{
			return ( _uFlags & _MIC_NEEDED ) > 0;
		}
		
		[Bindable (event="media_visual_mode_change")]
		/**
		 * Use static image for visual, rather than camera feed, which is default
		 */
		public function get visualModeStatic():Boolean
		{
			return ( _uFlags & _VISUAL_STATIC ) > 0;
		}
		public function set visualModeStatic(value:Boolean):void
		{
			if ( _FlagUpdate ( _VISUAL_STATIC, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_VISUAL_MODE_CHANGE );
				if ( ( _uFlags & _VISUAL_NEEDED ) > 0 )
				{
					// camera needed has changed
					_ChangeEventDispatch ( MEDIA_CAMERA_NEEDED_CHANGE );
				}
			}
		}
		
		[Bindable (event="media_visual_needed_change")]
		public function get visualNeeded():Boolean
		{
			return ( _uFlags & _VISUAL_NEEDED ) > 0;
		}
		
		[Bindable (event="media_visual_source_change")]
		/**
		 * Source for static image.  May be either a fully qualified URL or the name of a locally stored image file.
		 */
		public function get visualStaticSource():String
		{
			return _sImgSrc;
		}
		public function set visualStaticSource(value:String):void
		{
			if ( value != _sImgSrc )
			{
				_sImgSrc = value;
				_ChangeEventDispatch ( MEDIA_VISUAL_SOURCE_CHANGE );
			}
		}
		
		[Bindable (event="media_visual_partner_change")]
		/**
		 * Allow partner to see visual
		 */
		public function get visualToPartner():Boolean
		{
			return ( _uFlags & _VISUAL_PARTNER ) > 0;
		}
		public function set visualToPartner(value:Boolean):void
		{
			var bDyn:Boolean = ( ( _uFlags & _VISUAL_STATIC ) < 1 );
			var bVis:Boolean = ( ( _uFlags & _VISUAL_NEEDED ) > 0 );
			var bCam:Boolean = ( bDyn && bVis );
			if ( _FlagUpdate ( _VISUAL_PARTNER, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_VISUAL_PARTNER_CHANGE );
				if ( bVis != ( ( _uFlags & _VISUAL_NEEDED ) > 0 ) )
				{
					// visual needed has changed
					bVis = !bVis;
					_ChangeEventDispatch ( MEDIA_VISUAL_NEEDED_CHANGE );
					if ( bCam != ( bDyn && bVis ) )
					{
						// camera needed has changed
						_ChangeEventDispatch ( MEDIA_CAMERA_NEEDED_CHANGE );
					}
				}
			}
		}
		
		[Bindable (event="media_visual_public_change")]
		/**
		 * Allow guests to see visual
		 */
		public function get visualToPublic():Boolean
		{
			return ( _uFlags & _VISUAL_PUBLIC ) > 0;
		}
		public function set visualToPublic(value:Boolean):void
		{
			var bDyn:Boolean = ( ( _uFlags & _VISUAL_STATIC ) < 1 );
			var bVis:Boolean = ( ( _uFlags & _VISUAL_NEEDED ) > 0 );
			var bCam:Boolean = ( bDyn && bVis );
			if ( _FlagUpdate ( _VISUAL_PUBLIC, value ) )
			{
				// changed
				_ChangeEventDispatch ( MEDIA_VISUAL_PUBLIC_CHANGE );
				if ( bVis != ( ( _uFlags & _VISUAL_NEEDED ) > 0 ) )
				{
					// visual needed has changed
					bVis = !bVis;
					_ChangeEventDispatch ( MEDIA_VISUAL_NEEDED_CHANGE );
					if ( bCam != ( bDyn && bVis ) )
					{
						// camera needed has changed
						_ChangeEventDispatch ( MEDIA_CAMERA_NEEDED_CHANGE );
					}
				}
			}
		}
		
		// CONSTRUCTOR AND SERIALIZATION / DESERIALIZATION
		
		public function MediaConfig ( bytes:ByteArray = null )
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
		public function writeExternal ( output:IDataOutput ) : void
		{
			output.writeObject ( _BaOut ( ) );
		}
		
		// implements IPilotMessageSerialize
		public function toSFSObject ( ) : ISFSObject
		{
			var sfso:ISFSObject = new SFSObject ( );
			sfso.putByteArray ( 'b', _BaOut ( ) );
			return sfso;
		}
		
		public function updateFromSFSObject ( sfso:ISFSObject ) : void
		{
			_BaInNotify ( sfso.getByteArray ( 'b' ) );
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : MediaConfig
		{
			return new MediaConfig ( sfso.getByteArray ( 'b' ) );
		}
		
		
		// OTHER PUBLIC METHODS
		
		/**
		 * Manually rotate 90 degrees clockwise from current value.
		 * @return uint New value in degrees
		 */
		public function cameraRotate090 ( ) : uint
		{
			if ( _uRotPos > 3 )
			{
				_uRotPos = 0;
			}
			if ( ++_uRotPos > 3 )
			{
				_uRotPos = 0;
			}
			_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			return 90 * _uRotPos;
		}
		
		/**
		 * Manually rotate 180 degrees from current value.
		 * @return uint New value in degrees
		 */
		public function cameraRotate180 ( ) : uint
		{
			if ( _uRotPos > 3 )
			{
				_uRotPos = 0;
			}
			_uRotPos += 2;
			if ( _uRotPos > 3 )
			{
				_uRotPos -= 4;
			}
			_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			return 90 * _uRotPos;
		}
		
		/**
		 * Manually rotate 90 degrees counterclockwise from current value.
		 * @return uint New value in degrees
		 */
		public function cameraRotate270 ( ) : uint
		{
			if ( _uRotPos > 3 )
			{
				_uRotPos = 0;
			}
			_uRotPos += 3;
			if ( _uRotPos > 3 )
			{
				_uRotPos -= 4;
			}
			_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			return 90 * _uRotPos;
		}
		
		/**
		 * Releases manual rotation override and allows use of the
		 * rotation default for the current display orientation.
		 */
		public function cameraRotateAuto ( ) : void
		{
			if ( _uRotPos != 4 )
			{
				// changing
				_uRotPos = 4;
				_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _sImgSrc:String = '';
		private var _tmrMstr:Timer;
		private var _uFlags:uint = 0;
		private var _uRotPos:uint = 4;
		
		
		// PRIVATE METHODS
		
		private function _BaIn ( ba:ByteArray ) : void
		{
			ba.position = 0;
			_uFlags = _ALL_FLAGS & ba.readUnsignedByte ( );
			_uRotPos = ba.readUnsignedByte ( );
			if ( ba.bytesAvailable > 2 )
			{
				_sImgSrc = ba.readUTF ( );
			}
			else
			{
				_sImgSrc = '';
			}
		}
		
		private function _BaInNotify ( ba:ByteArray ) : void
		{
			var bCam:Boolean;
			var bChgRot:Boolean;
			var bChgSrc:Boolean;
			var bDyn:Boolean;
			var bMic:Boolean;
			var bVis:Boolean;
			var sSrc:String;
			var uChgFlgs:uint;
			var uFlgs:uint;
			var uRt:uint;
			ba.position = 0;
			uFlgs = _ALL_FLAGS & ba.readUnsignedByte ( );
			uRt = ba.readUnsignedByte ( );
			if ( ba.bytesAvailable > 2 )
			{
				sSrc = ba.readUTF ( );
			}
			else
			{
				sSrc = '';
			}
			// detect which things are changing
			bMic = ( ( _uFlags & _MIC_NEEDED ) > 0 );
			bDyn = ( ( _uFlags & _VISUAL_STATIC ) < 1 );
			bVis = ( ( _uFlags & _VISUAL_NEEDED ) > 0 );
			bCam = ( bDyn && bVis );
			uChgFlgs = _uFlags ^ uFlgs;
			bChgRot = ( uRt != _uRotPos );
			bChgSrc = ( sSrc != _sImgSrc );
			_uFlags = uFlgs;
			_uRotPos = uRt;
			_sImgSrc = sSrc;
			// dispatch events for changes
			if ( bChgRot )
			{
				// cam rotation changed
				_ChangeEventDispatch ( MEDIA_CAMERA_ROTATION_CHANGE );
			}
			if ( bChgSrc )
			{
				// static image source changed
				_ChangeEventDispatch ( MEDIA_VISUAL_SOURCE_CHANGE );
			}
			if ( uChgFlgs > 0 )
			{
				// at least one flag has changed
				if ( ( uChgFlgs & _AUDIO_PARTNER ) > 0 )
				{
					// audio partner flag changed
					_ChangeEventDispatch ( MEDIA_AUDIO_PARTNER_CHANGE );
				}
				if ( ( uChgFlgs & _AUDIO_PUBLIC ) > 0 )
				{
					// audio public flag changed
					_ChangeEventDispatch ( MEDIA_AUDIO_PUBLIC_CHANGE );
				}
				if ( bMic != ( ( _uFlags & _MIC_NEEDED ) > 0 ) )
				{
					// need for mic changed
					_ChangeEventDispatch ( MEDIA_MICROPHONE_NEEDED_CHANGE );
				}
				if ( ( uChgFlgs & _VISUAL_PARTNER ) > 0 )
				{
					// visual to partner flag changed
					_ChangeEventDispatch ( MEDIA_VISUAL_PARTNER_CHANGE );
				}
				if ( ( uChgFlgs & _VISUAL_PUBLIC ) > 0 )
				{
					// visual to public flag changed
					_ChangeEventDispatch ( MEDIA_VISUAL_PUBLIC_CHANGE );
				}
				if ( ( uChgFlgs & _VISUAL_STATIC ) > 0 )
				{
					// visual mode changed
					bDyn = !bDyn;
					_ChangeEventDispatch ( MEDIA_VISUAL_MODE_CHANGE );
				}
				if ( bVis != ( ( _uFlags & _VISUAL_NEEDED ) > 0 ) )
				{
					// visual needed flag changed
					bVis = !bVis;
					_ChangeEventDispatch ( MEDIA_VISUAL_NEEDED_CHANGE );
				}
				if ( bCam != ( bDyn && bVis ) )
				{
					// need for camera changed
					_ChangeEventDispatch ( MEDIA_CAMERA_NEEDED_CHANGE );
				}
				if ( ( uChgFlgs & _CAM_FLIP_H ) > 0 )
				{
					// cam horizontal flip flag changed
					_ChangeEventDispatch ( MEDIA_CAMERA_FLIP_HORIZONTAL_CHANGE );
				}
				if ( ( uChgFlgs & _CAM_FLIP_V ) > 0 )
				{
					// cam vertical flip flag changed
					_ChangeEventDispatch ( MEDIA_CAMERA_FLIP_VERTICAL_CHANGE );
				}
			}
		}
		
		private function _BaOut ( ) : ByteArray
		{
			var ba:ByteArray = new ByteArray ( );
			ba.writeByte ( _uFlags );
			ba.writeByte ( _uRotPos );
			if ( _sImgSrc.length > 0 )
			{
				ba.writeUTF ( _sImgSrc );
			}
			return ba;
		}
		
		private function _ChangeEventDispatch ( eventName:String ) : void
		{
			dispatchEvent ( new Event ( eventName ) );
			_MasterChangeEventQueue ( );
		}
		
		private function _FlagUpdate ( flagPattern:uint, value:Boolean ) : Boolean
		{
			var uNew:uint;
			if ( value )
			{
				uNew = _uFlags | flagPattern;
			}
			else
			{
				uNew = _uFlags & ~flagPattern;
			}
			if ( uNew != _uFlags )
			{
				_uFlags = uNew;
				return true; // return
			}
			return false;
		}
		
		private function _MasterChangeEvent ( event:TimerEvent ) : void
		{
			_tmrMstr.stop ( );
			_tmrMstr.removeEventListener ( TimerEvent.TIMER, _MasterChangeEvent );
			_tmrMstr = null;
			dispatchEvent ( new Event ( MEDIA_CONFIG_CHANGE ) );
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