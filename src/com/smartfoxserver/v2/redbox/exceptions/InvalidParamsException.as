package com.smartfoxserver.v2.redbox.exceptions
{
	/**
	 * A RedBox exception.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class InvalidParamsException extends Error
	{
		/**
		 * Thrown when invalid parameters are passed to specific RedBox classes methods.
		 * This exception is raised when both <i>enableCamera</i> and <i>enableMicrophone</i> parameters are passed as {@code false} to a method involving a camera and/or microphone output stream to be published (live or recorded).
		 * 
		 * @param	message:	the error message.
		 * 
		 * @example	The following example shows how to handle the "InvalidParamsException" exception.
		 * 			<code>
		 * 			try
		 * 			{
		 * 				avClipMan.startClipRecording(false, false);
		 * 			}
		 * 			catch (err:InvalidParamsException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#startClipRecording
		 * @see		AVChatManager#sendChatRequest
		 * @see		AVCastManager#publishLiveCast
		 */
		public function InvalidParamsException(message:String)
		{
			super(message);
		}
	}
}