package com.arxterra.controllers
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	
	import com.arxterra.interfaces.IPilotMessageSerialize;
	
	import com.arxterra.utils.NonUIComponentBase;
	
	import com.arxterra.vo.CustomCommandConfig;
	import com.arxterra.vo.CustomSelectOption;

	/**
	 * Coordinates user configuration of custom commands,
	 * persistence between sessions, and serialization to update
	 * Control Panel with custom command definitions.
	 */
	public class CustomCommandManager extends NonUIComponentBase implements IPilotMessageSerialize
	{
		// STATIC CONSTANTS AND PROPERTIES
		public static const ID_COUNT:uint = 32;
		public static const ID_MAX:uint = 0x5f; // 95
		public static const ID_MIN:uint = 0x40; // 64
		
		private static var __instance:CustomCommandManager;
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		public function get commandConfigs ( ) : Vector.<CustomCommandConfig>
		{
			return _vCmds;
		}
		
		public function get commandConfigsCount ( ) : uint
		{
			return _vCmds.length;
		}
		
		/**
		 * Flag set while command configuration view is open, so
		 * custom command interpretation is not attempted while
		 * definitions are in flux.
		 */		
		public var suspend:Boolean = false;
		
		// CONSTRUCTOR AND INSTANCE
		
		/**
		 * Singleton instance of CustomCommandManager
		 */
		public static function get instance ( ) : CustomCommandManager
		{
			if ( !__instance )
			{
				__instance = new CustomCommandManager ( new SingletonEnforcer() );
			}
			return __instance;
		}
		
		public function CustomCommandManager ( enforcer:SingletonEnforcer )
		{
			_sessionMgr = SessionManager.instance;
			// prepare for serialization/deserialization
			registerClassAlias ( 'CustomCommandConfig', CustomCommandConfig );
			registerClassAlias ( 'CustomSelectOption', CustomSelectOption );
			// restore or create commands vector
			_callLater ( _Restore );
		}
		
		// OTHER PUBLIC METHODS
		
		/**
		 * @return SFSObject containing custom commands vector
		 * AMF3-serialized into a zlib-compressed byte array.
		 */
		public function toSFSObject ( ) : ISFSObject
		{
			var ba:ByteArray = new ByteArray ( );
			try
			{
				// serialize
				ba.writeObject ( _vCmds );
				// compress
				ba.compress ( );
			}
			catch ( err:Error )
			{
				_debugOut ( err.message );
			}
			
			var sfso:ISFSObject = new SFSObject ( );
			sfso.putByteArray ( 'b', ba );
			return sfso;
		}
		
		/**
		 * @param id command ID
		 * @return CustomCommandConfig instance or null if none exists with the supplied ID
		 */
		public function getCommandConfigById ( id:uint ) : CustomCommandConfig
		{
			var iIdx:int = _vCmdIdHash.indexOf ( id );
			if ( iIdx >= 0 )
				return _vCmds [ iIdx ];
			
			return null;
		}
		
		public function idIsInCustomRange ( uId:uint ) : Boolean
		{
			if ( uId < ID_MIN || uId > ID_MAX )
				return false;
			return true;
		}
		
		public function validate ( store:Boolean = true ) : Boolean
		{
			// check that IDs are unique and command values are legal
			if ( !_IdHashUpdate ( ) )
			{
				// found at least one duplicate ID
				_callLater ( _alert, [ 'error_custom_dup_id', 'error_custom_valid', [ _vCmdIdHash.toString() ] ] );
				return false;
			}
			var i:uint;
			var iLim:uint = _vCmds.length;
			var i_uId:uint;
			var i_ccc:CustomCommandConfig;
			var i_iDef:int;
			var i_iMax:int;
			var i_iMin:int;
			var i_iVal:int;
			var i_uOptsLim:uint;
			var i_vcsOpts:Vector.<CustomSelectOption>;
			var i_vuOptIds:Vector.<uint>;
			var i_uOptIdsLen:uint;
			var j:uint;
			var j_uOptId:uint;
			var j_cso:CustomSelectOption;
			for ( i=0; i<iLim; i++ )
			{
				i_ccc = _vCmds [ i ];
				i_uId = i_ccc.id;
				i_iDef = i_ccc.defaultValue;
				if ( i_ccc.isInteger )
				{
					i_iMax = i_ccc.max;
					i_iMin = i_ccc.min;
					if ( i_iDef > i_iMax || i_iDef < i_iMin || i_iMax > i_ccc.maxLimit || i_iMin < i_ccc.minLimit )
					{
						// default value outside limits
						_callLater ( _alert, [ 'error_custom_int_limits', 'error_custom_valid', [ i_ccc.configLabel ] ] );
						return false;
					}
				}
				else if ( i_ccc.isSelect )
				{
					if ( i_iDef > 255 || i_iDef < 0 )
					{
						// default value outside limits
						_callLater ( _alert, [ 'error_custom_sel_limits', 'error_custom_valid', [ i_ccc.configLabel ] ] );
						return false;
					}
					i_vcsOpts = i_ccc.options;
					i_vuOptIds = new <uint> [];
					i_uOptIdsLen = 0;
					i_uOptsLim = i_vcsOpts.length;
					for ( j=0; j<i_uOptsLim; j++ )
					{
						j_cso = i_vcsOpts [ j ];
						j_uOptId = j_cso.id;
						if ( j_uOptId > 255 )
						{
							_callLater ( _alert, [ 'error_custom_sel_limits', 'error_custom_valid', [ i_ccc.configLabel ] ] );
							return false;
						}
						if ( i_vuOptIds.indexOf ( j_uOptId ) >= 0 )
						{
							// has duplicate option ID
							_callLater ( _alert, [ 'error_custom_sel_dup_opts', 'error_custom_valid', [ i_ccc.configLabel, j_cso.idHexDec ] ] );
							return false;
						}
						i_vuOptIds [ i_uOptIdsLen++ ] = j_uOptId;
					}
					if ( i_vuOptIds.indexOf ( uint ( i_iDef ) ) < 0 )
					{
						// default value does not match one of the options
						_callLater ( _alert, [ 'error_custom_sel_def', 'error_custom_valid', [ i_ccc.configLabel ] ] );
						return false;
					}
				}
			}
			
			// if get here, all is well
			
			if ( store )
				_Persist ( );
			
			suspend = false;
			return true;
		}
		
		// PRIVATE PROPERTIES
		
		private var _sessionMgr:SessionManager;
		private var _vCmdIdHash:Vector.<uint>;
		private var _vCmds:Vector.<CustomCommandConfig>;
		
		// PRIVATE METHODS
		
		private function _IdHashUpdate ( ) : Boolean
		{
			var bValid:Boolean = true;
			_vCmdIdHash = new <uint> [];
			var i:uint;
			var i_ccc:CustomCommandConfig;
			var i_uId:uint;
			var uLen:uint = _vCmds.length;
			for ( i=0; i<uLen; i++ )
			{
				i_uId = _vCmds [ i ].id;
				// Headings all have ID of 0 and may be multiple.
				// Everything else must have unique ID.
				if ( i_uId > 0 && _vCmdIdHash.indexOf ( i_uId ) >= 0 )
				{
					// duplicate ID
					bValid = false;
				}
				_vCmdIdHash [ i ] = i_uId;
			}
			return bValid;
		}
		
		private function _Persist ( ) : void
		{
			var ba:ByteArray = new ByteArray ( );
			var fs:FileStream;
			var f:File = _sessionMgr.settingsDirectory.resolvePath ( 'Custom.dat' );
			var fBkp:File = _sessionMgr.settingsBackupDirectory.resolvePath ( 'Custom.dat' );
			try
			{
				// serialize
				ba.writeObject ( _vCmds );
				
				if ( f.exists ) f.deleteFile ( );
				
				fs = new FileStream();
				// open
				fs.open ( f, FileMode.WRITE );
				// write
				fs.writeBytes ( ba );
				// close
				fs.close();
				// backup copy
				f.copyTo ( fBkp, true );
			}
			catch ( err:Error )
			{
				_debugOut ( err.message );
			}
		}
		
		private function _Restore ( ) : void
		{
			// create new empty vector in case have nothing stored
			_vCmds = new <CustomCommandConfig> [];
			var f:File = _sessionMgr.settingsDirectory.resolvePath ( 'Custom.dat' );
			var fBkp:File = _sessionMgr.settingsBackupDirectory.resolvePath ( 'Custom.dat' );
			var fs:FileStream;
			var ba:ByteArray;
			if ( f.exists )
			{
				// have file
				try
				{
					fs = new FileStream();
					// open
					fs.open ( f, FileMode.READ );
					// read
					ba = new ByteArray();
					fs.readBytes ( ba );
					// close
					fs.close();
					// deserialize
					_vCmds = ba.readObject ( );
					// if no backup copy, create one
					if ( !fBkp.exists )
					{
						f.copyTo ( fBkp, true );
					}
				}
				catch ( err:Error )
				{
					_debugOut ( err.message );
				}
			}
			else if ( fBkp.exists )
			{
				// have backup
				try
				{
					fs = new FileStream();
					// open
					fs.open ( fBkp, FileMode.READ );
					// read
					ba = new ByteArray();
					fs.readBytes ( ba );
					// close
					fs.close();
					// deserialize
					_vCmds = ba.readObject ( );
					// restore main file
					fBkp.copyTo ( f, true );
				}
				catch ( err:Error )
				{
					_debugOut ( err.message );
				}
			}
			_IdHashUpdate ( );
		}
	}
}
class SingletonEnforcer {}