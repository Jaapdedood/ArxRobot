package com.arxterra.controllers
{
	import flash.events.TimerEvent;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import com.arxterra.utils.HexStringUtil;
	import com.arxterra.utils.NonUIComponentBase;
	
	import com.arxterra.vo.McuMessage;
	import com.arxterra.vo.MessageByteArray;
	import com.arxterra.vo.MessageData;
	import com.arxterra.vo.WaypointCoordinates;
	import com.arxterra.vo.WaypointsList;
	
	public class WaypointsManager extends NonUIComponentBase
	{
		// CONSTRUCTOR AND INSTANCE
		
		/**
		 * Singleton: use static property <b>instance</b> to get a reference.
		 */
		public function WaypointsManager(enforcer:SingletonEnforcer)
		{
			super();
			_sessionMgr = SessionManager.instance;
			registerClassAlias ( 'WPC', WaypointCoordinates as Class );
			_bActive = false;
			_bEnabled = false;
			_iBufferIdx = -1;
			_vWps = new <WaypointCoordinates> [];
		}
		
		/**
		 * Singleton instance
		 */
		public static function get instance ( ) : WaypointsManager
		{
			if ( !__instance )
			{
				__instance = new WaypointsManager ( new SingletonEnforcer ( ) );
			}
			return __instance;
		}
		
		private static var __instance:WaypointsManager;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		/**
		 * True if Waypoint Navigation (autopilot) is currently engaged
		 */
		public function get active():Boolean
		{
			return _bActive;
		}
		/**
		 * @private
		 */
		public function set active(value:Boolean):void
		{
			if ( _bActive == value )
				return;
			
			if ( !_bEnabled )
			{
				if ( !_bActive )
				{
					return;
				}
				_bActive = false;
			}
			else
			{
				_bActive = value;
			}
			if ( _bActive )
			{
				_sessionMgr.mcuSendCommandId ( McuMessage.WAYPOINTS_ON );
			}
			else
			{
				_sessionMgr.mcuSendCommandId ( McuMessage.WAYPOINTS_OFF );
			}
			_UserVarsWpActiveUpdate ( );
		}
		
		/**
		 * True if capabilities settings indicate the robot
		 * supports Waypoint Navigation
		 */
		public function get enabled():Boolean
		{
			return _bEnabled;
		}
		/**
		 * @private
		 */
		public function set enabled(value:Boolean):void
		{
			if ( _bEnabled == value )
				return;
			
			_bEnabled = value;
			if ( !_bEnabled )
			{
				active = false;
				_BufferClear ( );
				if ( _vWps.length > 0 )
				{
					_vWps = new <WaypointCoordinates> [];
					_UserVarsWpListUpdate ( );
				}
			}
			_UserVarsWpEnabledUpdate ( );
		}
		
		
		// OTHER PUBLIC METHODS
		
		public function getActiveMessage ( ) : MessageData
		{
			return new MessageData ( 'wpn', _bActive );
		}
		
		public function getEnabledMessage ( ) : MessageData
		{
			return new MessageData ( 'wpe', _bEnabled );
		}
		
		public function getList ( ) : Vector.<WaypointCoordinates>
		{
			return _vWps;
		}
		
		public function getListMessage ( ) : MessageData
		{
			return new MessageData ( 'wpl', new WaypointsList ( _vWps ), true );
		}
		
		/**
		 * Control Panel appended an imported route to the list
		 */
		public function listAppend ( wpsMsg:WaypointsList ) : void
		{
			if ( !_bEnabled )
				return;
			
			var vWpsNew:Vector.<WaypointCoordinates> = wpsMsg.waypointsVector;
			
			var iAppend:int = vWpsNew.length;
			if ( iAppend > 0 )
			{
				var iLenOld:int = _vWps.length;
				if ( iLenOld < 1 )
				{
					_vWps = vWpsNew;
				}
				else
				{
					_vWps = _vWps.concat ( vWpsNew );
				}
				
				// set up timer if not already running
				if ( _iBufferIdx < 0 )
				{
					// position at first of the new batch
					_iBufferIdx = iLenOld;
					_tmrBuffer = new Timer ( 1000, 0 );
					_tmrBuffer.addEventListener ( TimerEvent.TIMER, _BufferService );
					_tmrBuffer.start ( );
				}
			}
			
			_UserVarsWpListUpdate ( );
		}
		
		/**
		 * Empty the waypoints vector
		 * @param report Boolean false if calling from another function
		 * that will take care of updating the user vars itself
		 */
		public function listClear ( report:Boolean = true ) : void
		{
			if ( !_bEnabled )
				return;
			
			if ( _vWps.length < 1 )
				return; // nothing to do here
			
			// update list
			_vWps = new <WaypointCoordinates> [];
			
			// relay to Mcu
			_sessionMgr.mcuSendCommandId ( McuMessage.WAYPOINTS_CLEAR );
			
			if ( report )
				_UserVarsWpListUpdate ( );
		}
		
		/**
		 * Control Panel replaced list with an imported route
		 */
		public function listReplace ( wpsMsg:WaypointsList ) : void
		{
			listClear ( false );
			listAppend ( wpsMsg );
		}
		
		/**
		 * Control Panel added a new waypoint
		 */
		public function waypointAdd ( wpNew:WaypointCoordinates ) : void
		{
			if ( !_bEnabled )
				return;
			
			// if there is one already in the list with the same admin ID, remove it?
			// _WaypointGetById ( wpNew.adminId, true );
			
			// add new waypoint to list
			_vWps [ _vWps.length ] = wpNew;
			
			// update control panel
			_UserVarsWpListUpdate ( );
			
			// relay to Mcu if not buffering
			if ( _iBufferIdx < 0 )
			{
				var baSend:ByteArray = wpNew.messageBytesForMcu;
				if ( _sessionMgr.debugOn )
				{
					_debugOut ( 'Waypoint data as received: ' + wpNew.messageString + '\n      as sent to MCU: ' + HexStringUtil.HexStringFromByteArray ( baSend ) );
				}
				_sessionMgr.mcuSendCommandByteArray ( baSend );
			}
		}
		
		/**
		 * Mcu reported that a waypoint has been reached
		 */
		public function waypointArrived ( adminId:uint ) : void
		{
			if ( !_bEnabled )
				return;
			
			// remove from list
			var wp:WaypointCoordinates = _WaypointGetById ( adminId, true ); // passing true triggers removal
			if ( wp != null )
			{
				_UserVarsWpListUpdate ( );
			}
		}
		
		/**
		 * Control Panel deleted a waypoint
		 */
		public function waypointDelete ( mba:MessageByteArray ) : void
		{
			if ( !_bEnabled )
				return;
			
			// remove from list and return object if was not just in buffer
			var wp:WaypointCoordinates = _WaypointGetById ( mba.unsignedByte, true ); // passing true triggers removal
			if ( wp != null )
			{
				_UserVarsWpListUpdate ( );
				
				if ( _sessionMgr.debugOn )
				{
					_debugOut ( 'Waypoint delete: ' + mba.messageString );
				}
				// relay to Mcu
				_sessionMgr.mcuSendCommandByteArray ( mba.messageBytes );
			}
		}
		
		
		/**
		 * Control Panel moved an existing waypoint
		 */
		public function waypointMove ( wpMove:WaypointCoordinates ) : void
		{
			if ( !_bEnabled )
				return;
			
			// find in list
			var wpOrig:WaypointCoordinates = _WaypointGetById ( wpMove.adminId );
			if ( wpOrig != null )
			{
				var baMove:ByteArray = wpMove.messageBytes;
				baMove.position = 1;
				
				wpOrig.writeValueBytes ( baMove, 16 );
				_UserVarsWpListUpdate ( );
				
				// relay to Mcu if it has already received this waypoint
				if ( _iBufferIdx < 0 || _iBufferIdx > _iFoundIdx )
				{
					var baSend:ByteArray = wpMove.messageBytesForMcu;
					if ( _sessionMgr.debugOn )
					{
						_debugOut ( 'Waypoint move as received: ' + wpMove.messageString + '\n      as sent to MCU: ' + HexStringUtil.HexStringFromByteArray ( baSend ) );
					}
					_sessionMgr.mcuSendCommandByteArray ( baSend );
				}
			}
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _bActive:Boolean;
		private var _bEnabled:Boolean;
		private var _iBufferIdx:int = -1;
		private var _iFoundIdx:int = -1;
		private var _sessionMgr:SessionManager;
		private var _tmrBuffer:Timer;
		private var _vWps:Vector.<WaypointCoordinates>;
		
		
		// PRIVATE METHODS
		
		private function _BufferClear ( ) : void
		{
			_iBufferIdx = -1; // indicates not currently running
			if ( _tmrBuffer )
			{
				_tmrBuffer.stop ( );
				_tmrBuffer.removeEventListener ( TimerEvent.TIMER, _BufferService );
				_tmrBuffer = null;
			}
		}
		
		private function _BufferService ( event:TimerEvent = null ) : void
		{
			if ( _iBufferIdx >= _vWps.length )
			{
				_BufferClear ( );
				return;
			}
			// deal with the current one, and increment index
			var wpCur:WaypointCoordinates = _vWps [ _iBufferIdx++ ];
			var baSend:ByteArray = wpCur.messageBytesForMcu;
			if ( _sessionMgr.debugOn )
			{
				_debugOut ( 'Waypoint data as received: ' + wpCur.messageString + '\n      as sent to MCU: ' + HexStringUtil.HexStringFromByteArray ( baSend ) );
			}
			_sessionMgr.mcuSendCommandByteArray ( baSend );
		}
		
		private function _UserVarsWpActiveUpdate ( ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [ getActiveMessage() ] );
		}
		
		private function _UserVarsWpEnabledUpdate ( ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [ getEnabledMessage() ] );
		}
		
		private function _UserVarsWpListUpdate ( ) : void
		{
			_sessionMgr.pilotConnector.userVarsQueue ( new <MessageData> [ getListMessage() ] );
		}
		
		private function _WaypointGetById ( adminId:uint, removeFromList:Boolean = false ) : WaypointCoordinates
		{
			var i:int;
			var wp:WaypointCoordinates;
			var i_wp:WaypointCoordinates;
			var iLim:int = _vWps.length;
			for ( i=0; i<iLim; i++ )
			{
				i_wp = _vWps [ i ];
				if ( i_wp.adminId == adminId )
				{
					_iFoundIdx = i;
					wp = i_wp;
					if ( removeFromList )
					{
						_vWps.removeAt ( i );
						if ( i < _iBufferIdx )
						{
							// removal moves next item to be processed forward
							_iBufferIdx--;
						}
						else if ( _iBufferIdx >= 0 )
						{
							// Buffering a batch append and Mcu didn't know about it yet anyway,
							// so return null, as indication not to relay deletion to Mcu
							wp = null;
						}
					}
					break;
				}
			}
			return wp;
		}
	}
}
class SingletonEnforcer {}