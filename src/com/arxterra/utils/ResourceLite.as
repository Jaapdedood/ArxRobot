package com.arxterra.utils
{
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	public class ResourceLite
	{
		public function ResourceLite()
		{
			_rsrcMgr = ResourceManager.getInstance ( );
		}
		
		
		// PROTECTED METHODS
		
		protected function get _resourceManager ( ) : IResourceManager
		{
			return _rsrcMgr;
		}
		
		
		// PRIVATE PROPERTIES
		
		private var _rsrcMgr:IResourceManager;
	}
}