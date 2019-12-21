package com.arxterra.utils
{
	import com.arxterra.controllers.MotionManager;
	import com.arxterra.icons.IconModeSmRC;

	/**
	 * Pilot connector for the Remote Control operational mode.
	 */
	[Bindable]
	public class PilotConnectorRC extends PilotConnector
	{
		/**
		 * @copy PilotConnectorRC
		 */
		public function PilotConnectorRC ( )
		{
			super ( );
		}
		
		override public function dismiss ( ) : void
		{
			_motMgr.enabled = false;
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
			_motMgr = MotionManager.instance;
			_motMgr.enabled = true;
		}
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="icon_changed")]
		override public function get icon ( ) : Object
		{
			return IconModeSmRC;
		}
		
		
		// OTHER PUBLIC METHODS
		
		override public function sleep ( ) : void
		{
			super.sleep ( );
			_motMgr.enabled = false;
		}
		
		override public function wake ( ) : void
		{
			super.wake ( );
			_motMgr.enabled = true;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _motMgr:MotionManager;
		
	}
}