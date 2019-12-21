package com.smartfoxserver.v2.redbox.exceptions
{
	/**
	 * A RedBox exception.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class ClipActionNotAllowedException extends Error
	{
		/**
		 * Thrown when the current user is not allowed to perform an action on a clip.
		 * This exception is raised when the user tries to delete an a/v clip or to update its properties not being its owner.
		 * 
		 * @param	message:	the error message.
		 * 
		 * @example	The following example shows how to handle the "ClipActionNotAllowedException" exception.
		 * 			<code>
		 * 			try
		 * 			{
		 * 				avClipMan.deleteClip(clipId);
		 * 			}
		 * 			catch (err:ClipActionNotAllowedException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#deleteClip
		 * @see		AVClipManager#updateClipProperties
		 */
		public function ClipActionNotAllowedException(message:String)
		{
			super(message);
		}
	}
}