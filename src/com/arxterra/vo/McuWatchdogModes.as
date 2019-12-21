package com.arxterra.vo
{
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import org.apache.flex.collections.VectorList;

	public class McuWatchdogModes
	{
		// CONSTANTS
		public static const OFF:uint = 0x00;
		public static const INT_1:uint = 0x46;
		public static const INT_2:uint = 0x47;
		public static const INT_4:uint = 0x60;
		public static const INT_8:uint = 0x61;
		public static const INT_RST_1:uint = 0x4e;
		public static const INT_RST_2:uint = 0x4f;
		public static const INT_RST_4:uint = 0x68;
		public static const INT_RST_8:uint = 0x69;
		public static const DEFAULT:uint = INT_4;
		
		private static const _DEF_IDX:int = 3;
		private static const _DEF_MSEC:int = 4000;
		private static const _IDS:Vector.<uint> = new <uint> [ OFF, INT_1, INT_2, INT_4, INT_8, INT_RST_1, INT_RST_2, INT_RST_4, INT_RST_8 ];
		private static const _MSECS:Vector.<int> = new <int> [ _DEF_MSEC, 1000, 2000, 4000, 8000, 1000, 2000, 4000, 8000 ];
		private static const _RSRCS:Vector.<String> = new <String> [
			'mcu_wd_mode_OFF',
			'mcu_wd_mode_INT_1',
			'mcu_wd_mode_INT_2',
			'mcu_wd_mode_INT_4',
			'mcu_wd_mode_INT_8',
			'mcu_wd_mode_INT_RST_1',
			'mcu_wd_mode_INT_RST_2',
			'mcu_wd_mode_INT_RST_4',
			'mcu_wd_mode_INT_RST_8'
		];
		
		
		// CONSTRUCTOR/DESTRUCTOR
		
		public function McuWatchdogModes ( )
		{
		}
		
		
		// PUBLIC STATIC METHODS
		
		public static function GetModeIdByIndex ( index:uint ) : uint
		{
			if ( index < _IDS.length )
			{
				return _IDS [ index ]; // return
			}
			return DEFAULT;
		}
		
		public static function GetModeIndexById ( modeId:uint ) : int
		{
			var iIdx:int = _IDS.indexOf ( modeId );
			if ( iIdx < 0 )
			{
				return _DEF_IDX; // return
			}
			return iIdx;
		}
		
		public static function GetModeMsecsById ( modeId:uint ) : int
		{
			var iIdx:int = _IDS.indexOf ( modeId );
			if ( iIdx < 0 )
			{
				return _DEF_MSEC; // return
			}
			return _MSECS [ iIdx ];
		}
		
		public static function get ModesList():VectorList
		{
			if ( !__vModeList )
			{
				__ModesListCreate ( );
			}
			return new VectorList ( __vModeList );
		}
		
		public static function get ModesListTypicalItem():ListDataItem
		{
			if ( !__vModeList )
			{
				__ModesListCreate ( );
			}
			return __ldiTypical;
		}
		
		
		// PRIVATE STATIC METHODS
		
		private static function __ModesListCreate ( ) : void
		{
			var u:uint;
			var u_sLabel:String;
			var u_uLen:uint;
			var uMaxLen:uint = 0;
			var uMaxLenIdx:uint = 0;
			var uLim:uint = _IDS.length;
			var rsrcMgr:IResourceManager = ResourceManager.getInstance ( );
			__vModeList = new <ListDataItem> [];
			for ( u=0; u<uLim; u++ )
			{
				u_sLabel = rsrcMgr.getString ( 'default', _RSRCS [ u ] );
				u_uLen = u_sLabel.length;
				if ( u_uLen > uMaxLen )
				{
					uMaxLen = u_uLen;
					uMaxLenIdx = u;
				}
				__vModeList [ u ] = new ListDataItem ( _IDS [ u ], u_sLabel );
			}
			__ldiTypical = __vModeList [ uMaxLenIdx ];
		}
		
		// PRIVATE STATIC PROPERTIES
		
		private static var __ldiTypical:ListDataItem;
		private static var __vModeList:Vector.<ListDataItem>;
		
	}
}