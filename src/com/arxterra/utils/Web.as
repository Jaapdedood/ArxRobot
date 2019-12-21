package com.arxterra.utils
{
	import com.arxterra.events.DebugEventEx;
	
	import flash.desktop.NativeApplication;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class Web
	{
		public static function getURL ( url:String, window:String = null ) : void
		{
			var req:URLRequest = new URLRequest ( url );
			try
			{
				navigateToURL ( req, window );
			}
			catch ( err:Error )
			{
				NativeApplication.nativeApplication.dispatchEvent (
					new DebugEventEx (
						DebugEventEx.DEBUG_OUT,
						'URL request failed: ' + err.message
					)
				);
			}
		}
	}
}