package com.smartfoxserver.v2.redbox.exceptions
{
	/**
	 * A RedBox exception.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class NoAVConnectionException extends Error
	{
		/**
		 * Thrown when the connection to Red5 is not available.
		 * This exception is raised when a RedBox method is called which requires a connection to Red5, but this is not currently available.
		 * 
		 * @param	message:	the error message.
		 * 
		 * @example	The following example shows how to handle the "NoAVConnectionException" exception.
		 * 			<code>
		 * 			try
		 * 			{
		 * 				avClipMan.getStream();
		 * 			}
		 * 			catch (err:NoAVConnectionException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#getStream
		 * @see		AVClipManager#startClipRecording
		 * @see		AVClipManager#previewRecordedClip
		 * @see		AVChatManager#sendChatRequest
		 * @see		AVChatManager#acceptChatRequest
		 * @see		AVCastManager#publishLiveCast
		 * @see		AVCastManager#subscribeLiveCast
		 */
		public function NoAVConnectionException(message:String)
		{
			super(message);
		}
	}
}