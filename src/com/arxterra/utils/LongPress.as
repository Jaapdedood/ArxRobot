package com.arxterra.utils
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class LongPress
	{
		/**
		 * Singleton: Use <b>instance</b> property
		 */
		public function LongPress ( enforcer:SingletonEnforcer )
		{
		}
		
		private static var __instance:LongPress;
		/**
		 * Singleton instance of LongPress
		 */
		public static function get instance ( ) : LongPress
		{
			if ( !__instance )
			{
				__instance = new LongPress ( new SingletonEnforcer ( ) );
			}
			return __instance;
		}
		
		/**
		 * Static wrapper for <b>instance.begin</b>,
		 * which starts the long press timer.
		 * @param callback Function to call if press qualifies as long
		 */		
		public static function Begin ( callback:Function ) : void
		{
			instance.begin ( callback );
		}
		
		/**
		 * Static wrapper for <b>instance.end</b>,
		 * which stops the long press timer.
		 */		
		public static function End ( ) : void
		{
			instance.end ( );
		}
		
		/**
		 * Static wrapper for <b>instance.wasLong</b>
		 * @return Boolean true if latest candidate qualifed as a long press
		 */		
		public static function WasLong ( ) : Boolean
		{
			return instance.wasLong ( );
		}
		
		/**
		 * Starts the long press timer
		 * @param callback Function to call if press qualifies as long
		 */
		public function begin ( callback:Function ) : void
		{
			_bLong = false;
			_TimerClear ( );
			_fCallback = callback;
			_tmr = new Timer ( 800, 1 );
			_tmr.addEventListener ( TimerEvent.TIMER, _Fire );
			_tmr.start ( );
		}
		
		/**
		 * Stops the long press timer
		 */
		public function end ( ) : void
		{
			_TimerClear ( );
		}
		
		/**
		 * @return Boolean true if latest candidate qualifed as a long press
		 */
		public function wasLong ( ) : Boolean
		{
			return _bLong;
		}
		
		private var _bLong:Boolean = false;
		private var _fCallback:Function;
		private var _tmr:Timer;
		
		private function _Fire ( event:TimerEvent ) : void
		{
			_bLong = true;
			_fCallback ( );
			_TimerClear ( );
		}
		
		private function _TimerClear ( ) : void
		{
			if ( _tmr )
			{
				_tmr.stop();
				_tmr.removeEventListener ( TimerEvent.TIMER, _Fire );
				_tmr = null;
			}
			_fCallback = null;
		}
	}
}
class SingletonEnforcer {}