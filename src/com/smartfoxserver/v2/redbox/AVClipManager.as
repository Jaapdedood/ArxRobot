package com.smartfoxserver.v2.redbox
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.redbox.data.Clip;
	import com.smartfoxserver.v2.redbox.events.RedBoxClipEvent;
	import com.smartfoxserver.v2.redbox.exceptions.ClipActionNotAllowedException;
	import com.smartfoxserver.v2.redbox.exceptions.InvalidParamsException;
	import com.smartfoxserver.v2.redbox.exceptions.NoAVConnectionException;
	import com.smartfoxserver.v2.redbox.utils.Constants;
	import com.smartfoxserver.v2.redbox.utils.Logger;
	
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.NetStream;
	
	/**
	 * SmartFoxServer 2X RedBox Audio/Video Clip Manager.
	 * This class is responsible for audio/video clip recording & playback through the connection to the Red5 server.
	 * The AVClipManager handles the list of available a/v clips, their custom additional properties and the streaming to/from the Red5 server.
	 * 
	 * <b>NOTE</b>: in the provided examples, {@code avClipMan} always indicates an AVClipManager instance.
	 * 
	 * @usage	The <b>AVClipManager</b> class allows the playback of audio/video clips hosted on the server (for example movie trailers, video interviews, lessons, video messages, etc.) and the recording of live broadcasts.
	 * 			Each clip can be described by a number of custom parameters that are saved on the file system together with the clip's flv file.
	 * 			
	 * 			<i>Videoclip player</i>
	 * 			In this kind of application, the list of available clips is retrieved and displayed on the stage. When the user clicks on an item, a video player handles the incoming stream. The following workflow is suggested.
	 * 			<ol>
	 * 				<li>The current user logs in and joins a Room (usually a lobby); the list of available clips is requested using the {@link #getClipList} method.
	 * 				Calling this method also enables the reception of the {@link RedBoxClipEvent#CLIP_ADDED}, {@link RedBoxClipEvent#CLIP_DELETED} and {@link RedBoxClipEvent#CLIP_UPDATED} events which notify that a new clip has been added or removed from the clips list, or that the properties of a clip have been updated.</li>
	 * 				<li>The clips list is received by means of the {@link RedBoxClipEvent#CLIP_LIST} event: the clips, together with their properties (for example title, author, description, etc.) are listed in a specific component on the stage (for example a datagrid).</li>
	 * 				<li>When the user selects a clip, a NetStream object is requested to the AVClipManager by means of the {@link #getStream} method and the playback is started using the clip's id with the NetStream's <i>play</i> method (a simple Video object or a more complex UI component with advanced seek/volume controls can be used to display the streaming clip).</li>
	 * 			</ol>
	 * 			<hr />
	 * 			<i>Video message recorder</i>
	 * 			In this kind of application, a video message is recorded, previewed and finally submitted together with a number of additional properties. The following workflow is suggested.
	 * 			<ol>
	 * 				<li>The current user logs in and joins a Room (usually a lobby); the user interface displays the required controls to start/stop recording, preview a recorded clip, submit it or cancel the process; also, a form to collect the clip properties (for example the message title) is available.</i>
	 * 				<li>The user clicks on the "start recording" button: the {@link #startClipRecording} method is invoked and a unique clip id is requested to the server-side extension.</li>
	 * 				<li>When the {@link RedBoxClipEvent#CLIP_RECORDING_STARTED} event is fired in response, the camera/microphone output is attached to an outgoing stream which is recorded on the file system by the Red5 server. A Video object is added to the stage to display the user's own camera output.</i>
	 * 				<li>The user clicks on the "stop recording" button: the {@link #stopClipRecording} method is called and the outgoing stream is closed. The flv file on the server is now just temporary: if the user disconnects from SmartFoxServer or the {@link #cancelClipRecording} method is called, the file is removed from the file system.</li>
	 * 				<li>The user clicks on the "preview clip" button: the {@link #previewRecordedClip} method is called and a playing NetStream object is returned. The stream is attached to a Video object on the stage to display it.</li>
	 * 				<li>The user clicks on the "submit clip" button: the collected clip properties are passed to the {@link #submitRecordedClip} method and saved on the server's file system together with the clip's flv file. On the server side the clip is added to the list of available clips.</li>
	 * 			</ol>
	 * 
	 * @version	1.0.0 for SmartFoxServer 2X
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 */
	public class AVClipManager extends BaseAVManager
	{
		//--------------------------------------
		// CLASS CONSTANTS
		//--------------------------------------
		
		// Outgoing extension commands
		private const CMD_LIST:String = "list";			// Request the list of available clips
		private const CMD_REMOVE:String = "rmv";		// Remove user from notification queue
		private const CMD_NEW_ID:String = "newId";		// Request a unique clip id
		private const CMD_CANCEL:String = "cancel";		// Remove temporary clip
		private const CMD_SUBMIT_REC:String = "sbtRec";	// Submit recorded clip
		private const CMD_SUBMIT_UPL:String = "sbtUpl";	// Submit uploaded clip
		private const CMD_DELETE:String = "del";		// Delete a clip
		private const CMD_UPDATE:String = "upd";		// Update clip properties
		
		// Incoming extension responses
		private const RES_LIST:String = "list";			// List of available clips received
		private const RES_NEW_ID:String = "newId";		// Unique clip id received
		private const RES_ADD:String = "add";			// Clip added to clips list
		private const RES_DELETE:String = "del";		// Clip removed from clips list
		private const RES_UPDATE:String = "upd";		// Clip properties updated
		
		// Incoming extension errors
		private const ERR_SUBMIT:String = "err_submit";
		
		//--------------------------------------
		//  PRIVATE VARIABLES
		//--------------------------------------
		
		// Clip playback related params
		private var clipList:Array;
		private var playStream:NetStream;
		
		// Clip recording related params
		private var recStream:NetStream;
		private var recClipId:String;
		private var useCamOnRec:Boolean;
		private var useMicOnRec:Boolean;
		
		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
		
		/**
		 * AVClipManager contructor.
		 * 
		 * @param	sfs:		the SmartFox API main class instance.
		 * @param	red5Ip:		the Red5 server IP address (include the port number if the default one is not used).
		 * @param	useRTMPT:	connect to Red5 server using the HTTP-tunnelled RTMP protocol (optional, default is {@code false}); Red5 must be configured accordingly.
		 * @param	debug:		turn on the debug messages (optional, default is {@code false}).
		 *
		 * @example	The following example shows how to instantiate the AVClipManager class.
		 * 			<code>
		 * 			var smartFox:SmartFox = new SmartFox();
		 * 			var red5IpAddress:String = "127.0.0.1";
		 * 			
		 * 			var avClipMan:AVClipManager = new AVClipManager(smartFox, red5IpAddress);
		 * 			</code>
		 */
		function AVClipManager(sfs:SmartFox, red5Ip:String, useRTMPT:Boolean = false, debug:Boolean = false)
		{
			super(sfs, red5Ip, useRTMPT, debug);
			
			// Add SmartFoxServer event listeners
			smartFox.addEventListener(SFSEvent.EXTENSION_RESPONSE, onRedBoxExtensionResponse);
		}
		
		// -------------------------------------------------------
		// PUBLIC METHODS
		// -------------------------------------------------------
		
		/**
		 * Destroy the AVChatManager instance.
		 * Calling this method causes the interruption of all chat sessions currently in progress (if any) and the disconnection from Red5.
		 * This method should always be called before deleting the AVChatManager instance.
		 * 
		 * @example	The following example shows how to destroy the AVChatManager instance.
		 * 			<code>
		 * 			avChatMan.destroy();
		 * 			avChatMan = null;
		 * 			</code>
		 */
		override public function destroy():void
		{
			super.destroy();
			
			// Remove SmartFoxServer event listeners
			smartFox.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onRedBoxExtensionResponse);
			
			// Tell RedBox extension to remove user from clips list update notification queue
			if (clipList != null)
			{
				if (smartFox.isConnected)
					sendCommand(Constants.CLIP_MANAGER_KEY, CMD_REMOVE);
				
				// Clear clips list
				clipList = null;
			}
			
			// Close current streams
			if (playStream != null)
				playStream.close();
			
			recClipId = null
			if (recStream != null)
				recStream.close();
			
			// Disconnect from Red5 server
			if (netConn.connected)
				netConn.close();
			
			Logger.log("AVClipManager instance destroyed");
		}
		
		/**
		 * Retrieve the list of available a/v clips for the current zone.
		 * The clip list is requested to the RedBox server-side extension only the first time that this method is called, then only updates are notified.
		 * The list is an array of {@link Clip} objects returned by means of the {@link RedBoxClipEvent#CLIP_LIST} event.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_LIST
		 * 
		 * @example	The following example shows how to request the clips list to the AVClipManager instance.
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
		 * @see		Clip
		 * @see		RedBoxClipEvent#CLIP_LIST
		 * @see		RedBoxClipEvent#CLIP_ADDED
		 * @see		RedBoxClipEvent#CLIP_DELETED
		 * @see		RedBoxClipEvent#CLIP_UPDATED
		 */
		public function getClipList():void
		{
			// If the clip list is null, retrieve it from the server-side extension;
			// otherwise we already received it before, so we can dispatch the "onClipList" event immediately
			if (clipList == null)
				sendCommand(Constants.CLIP_MANAGER_KEY, CMD_LIST);
			else
			{
				var params:Object = {};
				params.clipList = clipList;
				
				dispatchAVClipEvent(RedBoxClipEvent.CLIP_LIST, params);
			}
		}
		
		/**
		 * Retrieve a {@link Clip} object instance from the clips list.
		 * 
		 * @param	clipId:	(<b>String</b>) the id of the {@link Clip} object to be retrieved.
		 * 
		 * @return	The {@link Clip} object.
		 * 
		 * @example	The following example shows how to get a clip from the clips list.
		 * 			<code>
		 * 			var clip:Clip = avClipMan.getClip(clipId);
		 * 			
		 * 			if (clip != null)
		 * 			{
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
		 * @see		Clip
		 */
		public function getClip(clipId:String):Clip
		{
			return (clipList != null ? clipList[clipId] : null);
		}
		
		/**
		 * Get a NetStream object which makes use of the AVClipManager connection to Red5.
		 * This method can be used to retrieve a valid NetStream object and play an a/v clip from the clips list by means of its id.
		 * 
		 * @return	A flash.net.NetStream object.
		 * 
		 * @throws	NoAVConnectionException if the connection to Red5 is not available.
		 * 
		 * @example	The following example shows how to get a stream and play a clip; the "onMetaData" handler is also set to trace the clip's flv metadata.
		 * 			<code>
		 * 			var stream:NetStream = avClipMan.getStream();
		 * 			stream.client = this; // This is required in order to handle the onMetaData, onCuePoint and onPlayStatus events.
		 * 			                      // Check the flash.net.NetStream class documentation for more details.
		 * 			
		 * 			video.attachNetStream(stream); // Attach stream to a Video object instance on the stage
		 * 			stream.play(clipId, 0);
		 * 			
		 * 			function onMetaData(info:Object):void
		 * 			{
		 * 				trace ("Duration: " + info.duration);
		 * 				trace ("Framerate: " + info.framerate);
		 * 				trace ("Width: " + info.width);
		 * 				trace ("Height: " + info.height);
		 * 			}
		 * 			</code>
		 * 
		 * @see		NoAVConnectionException
		 * @see		flash.net.NetStream
		 */
		public function getStream():NetStream
		{
			// Check Red5 connection availability
			if (!netConn.connected)
				throw new NoAVConnectionException(Constants.ERROR_NO_CONNECTION + " [getStream method]");
			
			//------------------------------
			
			// Close current stream
			if (playStream != null)
				playStream.close();
			
			// Create new stream if not yet availabla
			playStream = new NetStream(netConn);
			
			return playStream;
		}
		
		/**
		 * Start recording a new a/v clip.
		 * When this method is called, a unique clip id is requested to the RedBox server-side extension (unless a previous one is already available).
		 * On extension response, the recording is started and the {@link RedBoxClipEvent#CLIP_RECORDING_STARTED} event is fired.
		 * Audio and video recording mode/quality should be set before calling this method. In order to alter these settings, please refer to the flash.media.Microphone and flash.media.Camera classes documentation.
		 * 
		 * @param	enableCamera:		enable video recording; default value is {@code true}.
		 * @param	enableMicrophone:	enable audio recording; default value is {@code true}.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_RECORDING_STARTED
		 * 
		 * @throws	NoAVConnectionException if the connection to Red5 is not available.
		 * @throws	InvalidParamsException if both <i>enableCamera</i> and <i>enableMicrophone</i> parameters are set to {@code false}.
		 * 
		 * @example	The following example shows how to start recording a new clip; camera mode is set before starting the recording.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_RECORDING_STARTED, onClipRecordingStarted);
		 * 			
		 * 			try
		 * 			{
		 * 				var camera:Camera = Camera.getCamera();
		 * 				camera.setMode(320, 240, 15);
		 * 				
		 * 				avClipMan.startClipRecording(true, true);
		 * 			}
		 * 			catch (err:NoAVConnectionException)
		 * 			{
		 * 				trace (err.message);
		 * 			}
		 * 			
		 * 			function onClipRecordingStarted(evt:RedBoxClipEvent):void
		 * 			{
		 * 				// Attach camera output to video instance on stage to see what I'm recording
		 * 				video.attachCamera(Camera.getCamera());
		 * 			}
		 * 			</code>
		 * 
		 * @see		#stopClipRecording
		 * @see		#cancelClipRecording
		 * @see		#previewRecordedClip
		 * @see		#submitRecordedClip
		 * @see		RedBoxClipEvent#CLIP_RECORDING_STARTED
		 * @see		NoAVConnectionException
		 * @see		InvalidParamsException
		 * @see		flash.media.Camera
		 * @see		flash.media.Microphone
		 */
		public function startClipRecording(enableCamera:Boolean = true, enableMicrophone:Boolean = true):void
		{
			// If cam & mic are both null, why sending this type of request?
			if (!enableCamera && !enableMicrophone)
				throw new InvalidParamsException(Constants.ERROR_INVALID_PARAMS);
			
			// Check Red5 connection availability
			if (!netConn.connected)
				throw new NoAVConnectionException(Constants.ERROR_NO_CONNECTION + " [getStream method]");
			
			//------------------------------
			
			// Save recording options
			useCamOnRec = enableCamera;
			useMicOnRec = enableMicrophone;
			
			// Check if clip id is available
			if (recClipId == null)
			{
				// Request unique clip id to RedBox extension
				// On server response, recording will be started
				sendCommand(Constants.CLIP_MANAGER_KEY, CMD_NEW_ID);
			}
			else
			{
				// Start clip recording
				recordClip();
			}
		}
		
		/**
		 * Stop current recording of an a/v clip.
		 * This method stops the current a/v clip recording started with the {@link #startClipRecording} method.
		 * When a recording is stopped, the resulting clip is still temporary and must be saved by calling the {@link #submitRecordedClip} method.
		 * If a clip is not submitted, the temporary file on the server is deleted when the {@link #cancelClipRecording} method is called or when the user disconnects from SmartFoxServer.
		 * 
		 * @example	The following example shows how to stop clip recording.
		 * 			<code>
		 * 			avClipMan.stopClipRecording();
		 * 			
		 * 			// Detach camera output from video instance on the stage
		 * 			video.attachCamera(null);
		 * 			</code>
		 * 
		 * @see		#startClipRecording
		 * @see		#cancelClipRecording
		 * @see		#previewRecordedClip
		 * @see		#submitRecordedClip
		 */
		public function stopClipRecording():void
		{
			// Close stream
			if (recStream != null)
			{
				recStream.close();
				recStream.attachCamera(null);
				recStream.attachAudio(null);
			}
		}
		
		/**
		 * Cancel current recording of an a/v clip.
		 * This method stops the current a/v clip recording (if not already stopped by means of the {@link #stopClipRecording} method) and forces the temporary clip created on the server to be deleted immediately.
		 * 
		 * @example	The following example shows how to cancel a clip recording.
		 * 			<code>
		 * 			avClipMan.cancelClipRecording();
		 * 			
		 * 			// Detach camera output from video instance on the stage
		 * 			video.attachCamera(null);
		 * 			</code>
		 * 
		 * @see		#startClipRecording
		 * @see		#stopClipRecording
		 * @see		#previewRecordedClip
		 * @see		#submitRecordedClip
		 */
		public function cancelClipRecording():void
		{
			// Stop recording
			stopClipRecording();
			
			if (recClipId != null)
			{
				// Request temporary file deletion
				sendCommand(Constants.CLIP_MANAGER_KEY, CMD_CANCEL);
				
				recClipId = null;
			}
		}
		
		/**
		 * Preview the recorded a/v clip.
		 * This method stops the current a/v clip recording (if not already stopped by means of the {@link #stopClipRecording} method) and plays it back for preview purposes.
		 * The returned flash.net.NetStream object is already playing and clip events can't be catched. For a more advanced control over the clip preview, check the {@link #getRecordedClipId} method.
		 * 
		 * @return	A flash.net.NetStream object already playing the previously recorded clip.
		 * 
		 * @throws	NoAVConnectionException if the connection to Red5 is not available.
		 * 
		 * @example	The following example shows how to preview a recorded clip.
		 * 			<code>
		 * 			var stream:NetStream = avClipMan.previewRecordedClip();
		 * 			
		 * 			// Attach stream to a Video object instance on the stage to display the preview
		 * 			video.attachNetStream(stream);
		 * 			</code>
		 * 
		 * @see		#startClipRecording
		 * @see		#stopClipRecording
		 * @see		#cancelClipRecording
		 * @see		#submitRecordedClip
		 * @see		#getRecordedClipId
		 * @see		NoAVConnectionException
		 */
		public function previewRecordedClip():NetStream
		{
			// Stop recording
			stopClipRecording();
			
			if (recClipId != null)
			{
				// Check Red5 connection availability
				if (!netConn.connected)
					throw new NoAVConnectionException(Constants.ERROR_NO_CONNECTION + " [getStream method]");
				
				//------------------------------
				
				// Play recorded clip
				recStream.play(recClipId, 0);
				
				// Return NetStream object
				return recStream;
			}
			
			return null;
		}
		
		/**
		 * Submit the recorded a/v clip to the server.
		 * This method stops the current a/v clip recording (if not already stopped by means of the {@link #stopClipRecording} method) and makes the RedBox server-side extension save the clip properties and add it to the clips list.
		 * If the submission is successful, the {@link RedBoxClipEvent#CLIP_ADDED} event is fired, otherwise the {@link RedBoxClipEvent#CLIP_SUBMISSION_FAILED} event is fired.
		 * 
		 * @param	properties:	an object containing the clip properties (see the {@link Clip#properties} attribute) to be saved. Only properties of type {@code String}, {@code Number} and {@code Boolean} are accepted; also, {@code Number} and {@code Boolean} are converted to {@code String}.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_ADDED
		 * @sends	RedBoxClipEvent#CLIP_SUBMISSION_FAILED
		 * 
		 * @example	The following example shows how to submit a recorded clip.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_ADDED, onClipAdded);
		 * 			
		 * 			var clipProperties:Object = {};
		 * 			clipProperties.title = "My first video message";
		 * 			clipProperties.author = "jack";
		 * 			
		 * 			avClipMan.submitRecordedClip(clipProperties);
		 * 			
		 * 			function onClipAdded(evt:RedBoxClipEvent):void
		 * 			{
		 * 				trace("A new clip was added");
		 * 				var clip:Clip = evt.params.clip;
		 * 				
		 * 				// Update the clip list
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		#startClipRecording
		 * @see		#stopClipRecording
		 * @see		#cancelClipRecording
		 * @see		#previewRecordedClip
		 * @see		RedBoxClipEvent#CLIP_ADDED
		 * @see		RedBoxClipEvent#CLIP_SUBMISSION_FAILED
		 * @see		Clip#properties
		 */
		public function submitRecordedClip(properties:Object = null):void
		{
			// Stop recording
			stopClipRecording();
			
			if (recClipId != null)
			{
				// Validate properties
				var props:Object = validateClipProperties(properties);
				
				// Send submit command to extension
				var params:ISFSObject = new SFSObject();
				params.putSFSObject("properties", SFSObject.newFromObject(props));
				
				sendCommand(Constants.CLIP_MANAGER_KEY, CMD_SUBMIT_REC, params);
				
				recClipId = null;
			}
		}
		
		/**
		 * Get the id of the currently recorded clip.
		 * This id is {@code null} until the {@link RedBoxClipEvent#CLIP_RECORDING_STARTED} event is received, and it's set back to {@code null} when the {@link #submitRecordedClip} or {@link #cancelClipRecording} methods are called.
		 * The recorded clip id is usually not necessary, unless a more advanced control over the clip preview is required with respect to what the {@link #previewRecordedClip} method offers.
		 * In this case the {@link #getStream} method can be used and the clip stream played by means of its id.
		 * 
		 * @return	The id of the recorded clip.
		 * 
		 * @example	The following example shows how to use the id to preview a recorded a/v clip.
		 * 			<code>
		 * 			var recordedClipId:String = avClipman.getRecordedClipId();
		 * 			var stream:NetStream = avClipMan.getStream();
		 * 			stream.client = this; // This is required in order to handle the onPlayStatus event.
		 * 			
		 * 			video.attachNetStream(stream); // Attach stream to a Video object instance on the stage to preview the recorded clip
		 * 			stream.play(recordedClipId, 0);
		 * 			
		 * 			function onPlayStatus(info:Object):void
		 * 			{
		 * 				// Reset video upon completion
		 * 				if (info.code == "NetStream.Play.Complete")
		 * 					video.attachNetStream(null);
		 * 			}
		 * 			</code>
		 * 
		 * @see		#previewRecordedClip
		 */
		public function getRecordedClipId():String
		{
			return recClipId;
		}
		
		/**
		 * Submit a previously uploaded a/v clip to the server.
		 * This method should be used when a new clip has been uploaded to the Red5 streams folder directly, for example via FTP (instead of being recorded using the {@link #startClipRecording} method).
		 * By submitting the clip, the RedBox server-side extension saves the passed properties and causes the {@link RedBoxClipEvent#CLIP_ADDED} event to be triggered to notify the clips list update to all users.
		 * If the submission fails, the {@link RedBoxClipEvent#CLIP_SUBMISSION_FAILED} event is fired.
		 * <b>NOTE</b>: the file extension of the uploaded clip must be lowercase!
		 * 
		 * @param	clipId:		the id of the uploaded clip. The id must match the flv file name, extension excluded; also, the clip id must begin with the zone name followed by an underscore character.
		 * @param	properties:	an object containing the clip properties (see the {@link Clip#properties} attribute) to be saved. Only properties of type {@code String}, {@code Number} and {@code Boolean} are accepted; also, {@code Number} and {@code Boolean} are converted to {@code String}.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_ADDED
		 * @sends	RedBoxClipEvent#CLIP_SUBMISSION_FAILED
		 * 
		 * @example	The following example shows how to submit "VideoClipPlayer_TheDarkKnight.flv" videoclip, previously uploaded to the Red5 streams folder.
		 * 			<code>
		 * 			avClipMan.addEventListener(RedBoxClipEvent.CLIP_ADDED, onClipAdded);
		 * 			
		 * 			var clipProperties:Object = {};
		 * 			clipProperties.title = "The Dark Knight";
		 * 			clipProperties.author = "Warner Bros.";
		 * 			
		 * 			avClipMan.submitUploadedClip("VideoClipPlayer_TheDarkKnight", clipProperties);
		 * 			
		 * 			function onClipAdded(evt:RedBoxClipEvent):void
		 * 			{
		 * 				trace("A new movie trailer was added!");
		 * 				var clip:Clip = evt.params.clip;
		 * 				
		 * 				// Update the clip list
		 * 				...
		 * 			}
		 * 			</code>
		 * 
		 * @see		RedBoxClipEvent#CLIP_ADDED
		 * @see		RedBoxClipEvent#CLIP_SUBMISSION_FAILED
		 * @see		Clip#properties
		 */
		public function submitUploadedClip(clipId:String, properties:Object = null):void
		{
			// Validate properties
			var props:Object = validateClipProperties(properties);
			
			// Send submit command to extension
			var params:ISFSObject = new SFSObject();
			params.putUtfString("id", clipId);
			params.putSFSObject("properties", SFSObject.newFromObject(props));
			
			sendCommand(Constants.CLIP_MANAGER_KEY, CMD_SUBMIT_UPL, params);
		}
		
		/**
		 * Remove a clip from the Red5 streams folder.
		 * In order to delete a clip, the user must be the its owner (see the {@link Clip#username} property).
		 * If the clip is deleted successfully, the AVClipManager's internal clips list is updated and the {@link RedBoxClipEvent#CLIP_DELETED} event is fired.
		 * 
		 * @param	clipId:	the id of the clip to be deleted.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_DELETED
		 * 
		 * @throws	ClipActionNotAllowedException if the user is not the clip's owner.
		 * 
		 * @example	The following example shows how to delete a clip.
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
		 * @see		RedBoxClipEvent#CLIP_DELETED
		 * @see		ClipActionNotAllowedException
		 */
		public function deleteClip(clipId:String):void
		{
			// Check if user is the clip owner
			if (smartFox.mySelf.name != clipList[clipId].username)
				throw new ClipActionNotAllowedException(Constants.ERROR_DELETE_NOT_ALLOWED);
			
			//------------------------------
			
			// Send delete command to extension
			var params:ISFSObject = new SFSObject();
			params.putUtfString("id", clipId);
			
			sendCommand(Constants.CLIP_MANAGER_KEY, CMD_DELETE, params);
		}
		
		/**
		 * Update the clip properties.
		 * In order to update the clip properties, the user must be the clip's owner (see the {@link Clip#username} property).
		 * If the clip properties are updated successfully, the AVClipManager's internal clips list is updated and the {@link RedBoxClipEvent#CLIP_UPDATED} event is fired.
		 * <b>NOTE</b>: it's not possible to update a subset of properties, leaving the remaining ones unaltered: when this method is called, the whole clip's properties file is overwritten.
		 * 
		 * @param	clipId:		the id of the clip to update.
		 * @param	properties:	an object containing the clip properties (see the {@link Clip#properties} attribute) to be saved. Only properties of type {@code String}, {@code Number} and {@code Boolean} are accepted; also, {@code Number} and {@code Boolean} are converted to {@code String}.
		 * 
		 * @sends	RedBoxClipEvent#CLIP_UPDATED
		 * 
		 * @throws	ClipActionNotAllowedException if the user is not the clip's owner.
		 * 
		 * @example	The following example shows how to update the properties of a clip.
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
		 * @see		RedBoxClipEvent#CLIP_UPDATED
		 * @see		ClipActionNotAllowedException
		 */
		public function updateClipProperties(clipId:String, properties:Object):void
		{
			// Check if user is the clip owner
			if (smartFox.mySelf.name != clipList[clipId].username)
				throw new ClipActionNotAllowedException(Constants.ERROR_UPDATE_NOT_ALLOWED);
			
			//------------------------------
			
			// Validate properties
			var props:Object = validateClipProperties(properties);
			
			// Send update command to extension
			var params:ISFSObject = new SFSObject();
			params.putUtfString("id", clipId);
			params.putSFSObject("properties", SFSObject.newFromObject(props));
			
			sendCommand(Constants.CLIP_MANAGER_KEY, CMD_UPDATE, params);
		}
		
		// -------------------------------------------------------
		// SMARTFOXSERVER & RED5 EVENT HANDLERS
		// -------------------------------------------------------
		
		/**
		 * Handle incoming server responses.
		 * 
		 * @exclude
		 */
		public function onRedBoxExtensionResponse(evt:SFSEvent):void
		{
			var dataObj:Object = evt.params;
			var cmdArray:Array = dataObj.cmd.split(".");
			
			// Retrieve manager key from the command string to filter responses addressed to the AVChatManager only
			var managerKey:String = cmdArray[0];
			var responseKey:String = cmdArray[1];
			
			if (managerKey == Constants.CLIP_MANAGER_KEY)
			{
				Logger.log("Extension response received:", responseKey);
					
				var params:ISFSObject = evt.params.params as ISFSObject;
				
				// Available clips list received
				if (responseKey == RES_LIST)
					handleClipList(params);
					
					// New clip id received
				else if (responseKey == RES_NEW_ID)
					handleNewClipId(params);
					
					// New clip added to clips list
				else if (responseKey == RES_ADD)
					handleNewClipAdded(params);
					
					// Clip submission error received
				else if (responseKey == ERR_SUBMIT)
					handleClipSubmitError(params);
					
					// Clip removed from clips list
				else if (responseKey == RES_DELETE)
					handleClipDeleted(params);
					
					// Clip properties updated
				else if (responseKey == RES_UPDATE)
					handleClipUpdated(params);
			}
		}
		
		// -------------------------------------------------------
		// PRIVATE METHODS
		// -------------------------------------------------------
		
		override protected function handleRed5ConnectionError(errorCode:String):void
		{
			// Close streams
			if (playStream != null)
			{
				playStream.close();
				playStream = null;
			}
			
			if (recStream != null)
			{
				recStream.close();
				recStream = null;
				recClipId = null;
			}
		}
		
		/**
		 * Dispatch AVClipManager events.
		 */
		private function dispatchAVClipEvent(type:String, params:Object = null):void
		{
			var event:RedBoxClipEvent = new RedBoxClipEvent(type, params);
			dispatchEvent(event);
		}
		
		/**
		 * Handle the server response after the clips list has been requested.
		 */
		private function handleClipList(data:ISFSObject):void
		{
			// Populate the client-side clips list
			clipList = [];
			var clipListData:ISFSObject = data.getSFSObject("clipList");
			
			for each (var c:String in clipListData.getKeys())
			{
				// Add new clip to list
				clipList[c] = createClip(c, clipListData.getSFSObject(c));
			}
			
			Logger.log("Clip list created");
			
			// Dispatch the "onClipList" event
			var params:Object = {};
			params.clipList = clipList;
			
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_LIST, params);
		}
		
		/**
		 * Create a Clip instance
		 */
		private function createClip(clipId:String, clipData:ISFSObject):Clip
		{
			var properties:ISFSObject = clipData.getSFSObject("properties");
			
			var clipParams:Object = {};
			clipParams.id = clipId;
			clipParams.username = (properties.containsKey("username") ? properties.getUtfString("username") : null);
			clipParams.size = clipData.getLong("size");
			clipParams.lastModified = clipData.getUtfString("lastModified");
			clipParams.rtmpURL = red5AppURL + "/" + clipId + ".flv";
			clipParams.properties = {};
			
			for each (var m:String in properties.getKeys())
			{
				if (m != "username")
					clipParams.properties[m] = properties.getUtfString(m);
			}
			
			return new Clip(clipParams);
		}
		
		/**
		 * Handle the server response after a new clip id has been requested.
		 */
		private function handleNewClipId(data:ISFSObject):void
		{
			// Save clip id
			recClipId = data.getUtfString("id");
			
			// Start clip recording
			recordClip();
		}
		
		/**
		 * Start clip recording.
		 */
		private function recordClip():void
		{
			// Create stream
			if (recStream == null)
			{
				recStream = new NetStream(netConn);
				
				// Add event handlers to prevent asyncError event to be dispatched during preview
				var client:Object = {};
				client.onMetaData = function():void {};
				client.onCuePoint = function():void {};
				client.onPlayStatus = function():void {};
				client.onLastSecond = function():void {};
				
				recStream.client = client;
			}
			
			recStream.close();
			
			// Attach camera and microphone to the stream
			if (useCamOnRec)
				recStream.attachCamera(Camera.getCamera());
			
			if (useMicOnRec)
				recStream.attachAudio(Microphone.getMicrophone());
			
			// Publish stream
			recStream.publish(recClipId, Constants.BROADCAST_TYPE_RECORD);
			
			// Dispatch event
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_RECORDING_STARTED);
		}
		
		/**
		 * Handle the server error due to problems in saving submitted clip.
		 */
		private function handleClipSubmitError(data:ISFSObject):void
		{
			Logger.log("Clip submission error, dispatching event");
			
			// Dispatch event
			var params:Object = {};
			params.error = data.getUtfString("err");
			
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_SUBMISSION_FAILED, params);
		}
		
		/**
		 * Handle the server response after a new clip has been submitted by a user.
		 */
		private function handleNewClipAdded(data:ISFSObject):void
		{
			var clipId:String = data.getUtfString("id");
			
			// Update clips list
			var clip:Clip = createClip(clipId, data.getSFSObject("data"));
			clipList[clipId] = clip;
			
			// Dispatch event
			var params:Object = {};
			params.clip = clip;
			
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_ADDED, params);
		}
		
		/**
		 * Check if clip properties are valid (during submission).
		 */
		private function validateClipProperties(properties:Object):Object
		{
			var props:Object = {};
			
			if (properties != null)
			{
				// Cycle through properties: discard everything which is not a String, Number or Boolean
				for (var p:String in properties)
				{
					var type:String = typeof(properties[p]);
					
					if (type == "boolean" || type == "number" || type == "string")
					{
						props[p] = properties[p].toString();
					}
				}
			}
			
			return props;
		}
		
		/**
		 * Handle the server response after a clip has been deleted by a user.
		 */
		private function handleClipDeleted(data:ISFSObject):void
		{
			var clipId:String = data.getUtfString("id");
			
			// Dispatch event
			var params:Object = {};
			params.clip = clipList[clipId];
			
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_DELETED, params);
			
			// Update clips list
			delete clipList[clipId];
		}
		
		/**
		 * Handle the server response after a clip's properties have been updated by a user.
		 */
		private function handleClipUpdated(data:ISFSObject):void
		{
			// Update clips list
			var clip:Clip = clipList[data.getUtfString("id")];
			var clipData:ISFSObject = data.getSFSObject("data");
			var clipProperties:ISFSObject = clipData.getSFSObject("properties");
			
			var properties:Object = {};
			
			for each (var m:String in clipProperties.getKeys())
			{
				if (m != "username")
					properties[m] = clipProperties.getUtfString(m);
			}
			
			clip.setProperties(properties);
			
			// Dispatch event
			var params:Object = {};
			params.clip = clip;
			
			dispatchAVClipEvent(RedBoxClipEvent.CLIP_UPDATED, params);
		}
	}
}