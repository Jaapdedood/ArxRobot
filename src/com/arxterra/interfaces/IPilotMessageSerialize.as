package com.arxterra.interfaces
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;

	public interface IPilotMessageSerialize
	{
		function toSFSObject():ISFSObject;
	}
}