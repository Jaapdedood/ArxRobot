package com.arxterra.utils
{
	import com.arxterra.controllers.CameraManager;
	
	import com.arxterra.icons.IconModeSmRobotPP;
	
	/**
	 * Pilot connector for the Peer to Peer operational mode.
	 */
	[Bindable]
	public class PilotConnectorPP extends PilotConnector
	{
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="icon_changed")]
		override public function get icon ( ) : Object
		{
			return IconModeSmRobotPP;
		}
		
		
		// CONSTRUCTOR / DESTRUCTOR
		
		/**
		 * @copy PilotConnectorPP
		 */
		public function PilotConnectorPP ( )
		{
			super ( );
		}
		
		override public function dismiss ( ) : void
		{
			if ( _camMgr )
			{
				// _camMgr.removeEventListener ( CameraManager.CAMERA_CONFIG_CHANGED, _AvOutConfigUpdate );
				_camMgr.enabled = false;
				_camMgr = null;
			}
			
			super.dismiss ( );
		}
		
		/**
		 * Called automatically by superclass during instantiation,
		 * but may also be called manually to reactivate
		 * if object was previously dismissed.
		 * Subclass overrides must call super.init().
		 */
		override public function init ( ) : void
		{
			super.init ( );
			
			_camMgr = CameraManager.instance;
			// _camMgr.addEventListener ( CameraManager.CAMERA_CONFIG_CHANGED, _AvOutConfigUpdate );
			_camMgr.enabled = true;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _camMgr:CameraManager;
	}
}