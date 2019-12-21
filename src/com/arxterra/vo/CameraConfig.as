package com.arxterra.vo
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.arxterra.interfaces.IPilotMessageSerialize;
	
	[Bindable]
	public class CameraConfig implements IPilotMessageSerialize
	{
		/**
		 * Used for the pilot client to communicate requested camera settings
		 * and for the rover client to report actual settings returned
		 * by the camera class after the requested settings are attempted.
		 * Default values reflect the results of our own experimentation and/or
		 * duplicate those of the AS3 Camera class documentation for the
		 * setMode, setQuality and setKeyFrameInterval methods, which
		 * are used when applying the properties in request mode.
		 * When used for reporting, the properties are populated from the
		 * Camera class properties with the same names, except fps is obtained from currentFPS
		 * and favorArea should already be known from the request or initial configuration
		 * and reported without modification.
		 * @param width default 1280
		 * @param height default 720
		 * @param fps default 15, permitted values 1 to 46
		 * @param favorArea default true, true = keep the size, dropping frames if necessary
		 * @param bandWidth default 0, permitted values = 0 (quality takes precedence) or maximum bandwidth allowed in bytes/second
		 * @param quality default 46, permitted values = 0 (bandwidth takes precedence) or 1 (lowest quality, highest compression) to 100 (no compression)
		 * @param keyFrameInterval default 15, permitted values 1 to 48
		 * 
		 */
		public function CameraConfig (
			width:int = 1280,
			height:int = 720,
			fps:Number = 15,
			favorArea:Boolean = true,
			bandWidth:int = 0,
			quality:int = 46,
			keyFrameInterval:int = 15
		)
		{
			// setMode
			//   if camera cannot deliver the requested width and height, it will
			//   use its closest dimensions that approximate the requested aspect ratio
			this.width = width;
			this.height = height;
			this.fps = fps;
			this.favorArea = favorArea;
			// setQuality
			this.bandWidth = bandWidth;
			this.quality = quality;
			// setKeyFrameInterval
			this.keyFrameInterval = keyFrameInterval;
		}
		
		public function toSFSObject ( ) : ISFSObject
		{
			var sfso:ISFSObject = new SFSObject ( );
			
			sfso.putShort ( 'w', width );
			sfso.putShort ( 'h', height );
			sfso.putFloat ( 'f', fps );
			sfso.putBool ( 'a', favorArea );
			sfso.putInt ( 'b', bandWidth );
			sfso.putByte ( 'q', quality );
			sfso.putByte ( 'k', keyFrameInterval );
			return sfso;
		}
		
		public static function NewFromSFSObject ( sfso:ISFSObject ) : CameraConfig
		{
			return new CameraConfig (
				sfso.getShort ( 'w' ),
				sfso.getShort ( 'h' ),
				sfso.getFloat ( 'f' ),
				sfso.getBool ( 'a' ),
				sfso.getInt ( 'b' ),
				sfso.getByte ( 'q' ),
				sfso.getByte ( 'k' )
			);
		}
		
		private var _iWd:int;
		public function get width():int
		{
			return _iWd;
		}
		public function set width(value:int):void
		{
			if ( value < 1 )
				_iWd = 160;
			else
				_iWd = value;
		}
		
		private var _iHt:int;
		public function get height():int
		{
			return _iHt;
		}
		public function set height(value:int):void
		{
			if ( value < 1 )
				_iHt = 120;
			else
				_iHt = value;
		}
		
		private var _nFps:Number;
		public function get fps():Number
		{
			return _nFps;
		}
		public function set fps(value:Number):void
		{
			if ( value < 1 || value > 46 )
				_nFps = 15;
			else
				_nFps = value;
		}
		
		private var _bFvArea:Boolean;
		public function get favorArea():Boolean
		{
			return _bFvArea;
		}
		public function set favorArea(value:Boolean):void
		{
			_bFvArea = value;
		}
		
		private var _iBandWd:int;
		public function get bandWidth():int
		{
			return _iBandWd;
		}
		public function set bandWidth(value:int):void
		{
			if ( value < 0 )
				_iBandWd = 16384;
			else
				_iBandWd = value;
		}
		
		private var _iQual:int;
		public function get quality():int
		{
			return _iQual;
		}
		public function set quality(value:int):void
		{
			if ( value < 0 || value > 100 )
				_iQual = 0;
			else
				_iQual = value;
		}
		
		private var _iKeyFmInt:int;
		public function get keyFrameInterval():int
		{
			return _iKeyFmInt;
		}
		public function set keyFrameInterval(value:int):void
		{
			if ( value < 1 || value > 48 )
				_iKeyFmInt = 15;
			else
				_iKeyFmInt = value;
		}
		
	}
}