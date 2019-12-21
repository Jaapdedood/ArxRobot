package com.smartfoxserver.v2.redbox.exceptions
{
	/**
	 * A RedBox exception.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class InvalidChatSessionIdException extends Error
	{
		/**
		 * Thrown when an invalid chat session id is passed to an {@link AVChatManager} method.
		 * This exception is raised if the passed session id is unknown or if the chat session' status doesn't match the expected one.
		 * 
		 * @param	message:	the error message.
		 * 
		 * @example	The following example shows how to handle the "InvalidChatSessionIdException" exception.
		 * 			<code>
		 * 			try
		 * 			{
		 * 				avChatMan.refuseChatRequest(wrongSessionId);
		 * 			}
		 * 			catch (err:InvalidChatSessionIdException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVChatManager#refuseChatRequest
		 * @see		AVChatManager#acceptChatRequest
		 */
		public function InvalidChatSessionIdException(message:String)
		{
			super(message);
		}
	}
}