package com.smartfoxserver.v2.redbox.exceptions
{
	/**
	 * A RedBox exception.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class BadRequestException extends Error
	{
		/**
		 * Thrown when the wrong request type is passed to the {@link AVChatManager#sendChatRequest} method.
		 * The valid request types are: {@link AVChatManager#REQ_TYPE_SEND}, {@link AVChatManager#REQ_TYPE_RECEIVE} and {@link AVChatManager#REQ_TYPE_SEND_RECEIVE}.
		 * 
		 * @param	message:	the error message.
		 * 
		 * @example	The following example shows how to handle the "BadRequestException" exception.
		 * 			<code>
		 * 			try
		 * 			{
		 * 				avChatMan.sendChatRequest("wrongType", 3, true, true);
		 * 			}
		 * 			catch (err:BadRequestException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVChatManager#sendChatRequest
		 */
		public function BadRequestException(message:String)
		{
			super(message);
		}
	}
}