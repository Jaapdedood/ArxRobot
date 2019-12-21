package com.smartfoxserver.v2.redbox.events
{
	import com.smartfoxserver.v2.core.SFSEvent;

	/**
	 * RedBoxCastEvent is the class representing all events dispatched by the RedBox's {@link AVCastManager} instance, except the connection events (see the {@link RedBoxConnectionEvent} class).
	 * The RedBoxCastEvent extends the SFSEvent class, which provides a public property called {@code params} of type {@code Object} containing event-related parameters.
	 * 
	 * @usage	Please refer to the specific events for usage examples and {@code params} object content.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class RedBoxCastEvent extends SFSEvent
	{
		/**
		 * Dispatched when a user in the current room published his own live stream.
		 * This event is fired only if the {@link AVCastManager#getAvailableCasts} method has already been called.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	liveCast:	(<b>LiveCast</b>) the LiveCast instance representing the live stream published.
		 * 
		 * @example	The following example shows how to handle a live cast published event.
		 * 			<code>
		 * 			avCastMan.addEventListener(RedBoxCastEvent.LIVE_CAST_PUBLISHED, onLiveCastPublished);
		 * 			
		 * 			// A user publishes his own live cast...
		 * 			
		 * 			function onLiveCastPublished(evt:RedBoxCastEvent):void
		 * 			{
		 * 				var liveCast:LiveCast = evt.params.liveCast;
		 * 				
		 * 				// Subscribe live cast
		 * 				var stream:NetStream = avCastMan.subscribeLiveCast(liveCast.id);
		 * 				
		 * 				// Display a/v stream on stage
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVCastManager#subscribeLiveCast
		 * @see		LiveCast
		 */
		 public static const LIVE_CAST_PUBLISHED:String = "onLiveCastPublished";
		
		
		/**
		 * Dispatched when a user in the current room stops his own live stream.
		 * This event is fired only if the {@link AVCastManager#getAvailableCasts} method has already been called.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	liveCast:	(<b>LiveCast</b>) the LiveCast instance representing the stopped live stream.
		 * 
		 * @example	The following example shows how to handle a live cast stopped event.
		 * 			<code>
		 * 			avCastMan.addEventListener(RedBoxCastEvent.LIVE_CAST_UNPUBLISHED, onLiveCastUnpublished);
		 * 			
		 * 			// A user stops streaming...
		 * 			
		 * 			function onLiveCastUnpublished(evt:RedBoxCastEvent):void
		 * 			{
		 * 				var liveCast:LiveCast = evt.params.liveCast;
		 * 				
		 * 				// Remove Video object from stage
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVCastManager#subscribeLiveCast
		 * @see		LiveCast
		 */
		 public static const LIVE_CAST_UNPUBLISHED:String = "onLiveCastUnpublished";
		
		
		//-----------------------------------------------------------------------------------------------------
		
		
		/**
		 *	RedBoxCastEvent class constructor.
		 *
		 *	@param type: the event's type.
		 *	@param params: an object containing the event's parameters.
		 *	
		 *	@exclude
		 */
		public function RedBoxCastEvent(type:String, params:Object = null)
		{
			super(type, params);
		}
	}
}