package com.smartfoxserver.v2.redbox.events
{
	import com.smartfoxserver.v2.core.SFSEvent;

	/**
	 * RedBoxClipEvent is the class representing all events dispatched by the RedBox's {@link AVClipManager} instance, except the connection events (see the {@link RedBoxConnectionEvent} class).
	 * The RedBoxClipEvent extends the SFSEvent class, which provides a public property called {@code params} of type {@code Object} containing event-related parameters.
	 * 
	 * @usage	Please refer to the specific events for usage examples and {@code params} object content.
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class RedBoxClipEvent extends SFSEvent
	{
		/**
		 * Dispatched when clips list is returned, in response to a {@link AVClipManager#getClipList} request.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	clipList:	(<b>Array</b>) a list of {@link Clip} objects for the zone logged in by the user.
		 * 
		 * @example	The following example shows how to request the available clips list.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_LIST, onClipList);
		 * 			
		 * 			avClipMan.getClipList();
		 * 			
		 * 			function onClipList(evt:RedBoxClipEvent):void
		 * 			{
		 * 				for each (var clip:Clip in evt.params.clipList)
		 *				{
		 * 					trace ("Clip id:", clip.id);
		 * 					trace ("Clip submitter:", clip.username);
		 * 					trace ("Clip size:", clip.size + " bytes");
		 * 					trace ("Clip last modified date:", clip.lastModified);
		 * 					trace ("Clip properties:");
		 * 					for (var s:String in clip.properties)
		 * 						trace (s, "-->", clip.properties[s]);
		 * 				}
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#getClipList
		 * @see		#CLIP_ADDED
		 * @see		#CLIP_DELETED
		 * @see		#CLIP_UPDATED
		 * @see		Clip
		 */
		public static const CLIP_LIST:String = "onClipList";
		
		
		/**
		 * Dispatched when the recording af an a/v clip starts, in response to a {@link AVClipManager#startClipRecording} request.
		 * 
		 * No parameters are provided.
		 * 
		 * @example	The following example shows how to handle the "onClipRecordingStarted" event.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_RECORDING_STARTED, onClipRecordingStarted);
		 * 			
		 * 			avClipMan.startClipRecording(true, true);
		 * 			
		 * 			function onClipRecordingStarted(evt:RedBoxClipEvent):void
		 * 			{
		 * 				// Attach camera output to video instance on stage to see what I'm recording
		 * 				video.attachCamera(Camera.getCamera());
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#startClipRecording
		 */
		public static const CLIP_RECORDING_STARTED:String = "onClipRecordingStarted";
		
		
		/**
		 * Dispatched when an error occurs in the RedBox server-side extension after submitting an a/v clip.
		 * This event is used when either a recorded or an uploaded clip is submitted.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	error:	(<b>String</b>) the error message sent by the RedBox extension.
		 * 
		 * @example	The following example shows how to handle a clip submission error.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_SUBMISSION_FAILED, onClipSubmissionFailed);
		 * 			
		 * 			var clipProperties:Object = {};
		 * 			clipProperties.author = "jack";
		 * 			
		 * 			avClipMan.submitRecordedClip(clipProperties);
		 * 			
		 * 			function onClipSubmissionFailed(evt:RedBoxClipEvent):void
		 * 			{
		 * 				trace("An error occurred during clip submission:", evt.params.error);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#submitRecordedClip
		 */
		public static const CLIP_SUBMISSION_FAILED:String = "onClipSubmissionFailed";
		
		
		/**
		 * Dispatched when a new a/v clip has been submitted by one of the users in the current zone.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	clip:	(<b>Clip</b>) the Clip instance representing the added a/v clip.
		 * 
		 * @example	The following example shows how to handle a clip added event.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_ADDED, onClipAdded);
		 * 			
		 * 			function onClipAdded(evt:RedBoxClipEvent):void
		 * 			{
		 * 				var clip:Clip = evt.params.clip;
		 * 				
		 * 				trace("A new clip was submitted");
		 * 				trace ("Clip id:", clip.id);
		 * 				trace ("Clip submitter:", clip.username);
		 * 				trace ("Clip size:", clip.size + " bytes");
		 * 				trace ("Clip last modified date:", clip.lastModified);
		 * 				trace ("Clip properties:");
		 * 				for (var s:String in clip.properties)
		 * 					trace (s, "-->", clip.properties[s]);
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#submitRecordedClip
		 * @see		AVClipManager#submitUploadedClip
		 * @see		Clip
		 */
		public static const CLIP_ADDED:String = "onClipAdded";
		
		
		/**
		 * Dispatched when an a/v clip has been deleted by one of the users in the current zone.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	clip:	(<b>Clip</b>) the Clip instance representing the deleted a/v clip.
		 * 
		 * @example	The following example shows how to handle a clip deletion event.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_DELETED, onClipDeleted);
		 * 			
		 * 			avClipMan.deleteClip(clipId);
		 * 			
		 * 			function onClipDeleted(evt:RedBoxClipEvent):void
		 * 			{
		 * 				trace("The clip " + evt.params.clip.id + " was deleted");
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#deleteClip
		 * @see		Clip
		 */
		public static const CLIP_DELETED:String = "onClipDeleted";
		
		
		/**
		 * Dispatched when the properties of an a/v clip have been updated by one of the users in the current zone.
		 * 
		 * The {@code params} object contains the following parameters.
		 * @param	clip:	(<b>Clip</b>) the Clip instance representing the updated a/v clip.
		 * 
		 * @example	The following example shows how to handle an update in clip properties.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_UPDATED, onClipUpdated);
		 * 			
		 * 			var newClipProperties:Object = {};
		 * 			newClipProperties.title = "Batman - The Dark Knight";
		 * 			newClipProperties.author = "Warner Bros.";
		 * 			
		 * 			avClipMan.updateClipProperties(clipId, newClipProperties);
		 * 			
		 * 			function onClipUpdated(evt:RedBoxClipEvent):void
		 * 			{
		 * 				trace("Clip properties have been updated");
		 * 				var clip:Clip = evt.params.clip;
		 * 				
		 * 				// Update the clip list
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		AVClipManager#updateClipProperties
		 * @see		Clip
		 */
		public static const CLIP_UPDATED:String = "onClipUpdated";
		
		
		//-----------------------------------------------------------------------------------------------------
		
		
		/**
		 *	RedBoxClipEvent class constructor.
		 *
		 *	@param type: the event's type.
		 *	@param params: an object containing the event's parameters.
		 *	
		 *	@exclude
		 */
		public function RedBoxClipEvent(type:String, params:Object = null)
		{
			super(type, params);
		}
	}
}