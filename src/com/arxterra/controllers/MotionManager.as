package com.arxterra.controllers
{
	
	
	import com.arxterra.events.EmergencyEvent;
	import com.arxterra.icons.IconHand0;
	import com.arxterra.icons.IconHand1;
	import com.arxterra.icons.IconHand2;
	import com.arxterra.icons.IconHand3;
	import com.arxterra.icons.IconMotion0;
	import com.arxterra.icons.IconMotion1;
	import com.arxterra.icons.IconMotion2;
	import com.arxterra.utils.NonUIComponentBase;
	import com.arxterra.vo.EmergencyFlags;
	import com.arxterra.vo.Motor;
	import com.arxterra.vo.MoveProps;
	import com.arxterra.vo.UserState;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	[Event(name="control_mode_change", type="flash.events.Event")]
	[Event(name="fraction_left_change", type="flash.events.Event")]
	[Event(name="fraction_right_change", type="flash.events.Event")]
	[Event(name="hand_pref_change", type="flash.events.Event")]
	[Event(name="motion_config_change", type="flash.events.Event")]
	[Event(name="motion_enabled_change", type="flash.events.Event")]
	
	public class MotionManager extends NonUIComponentBase
	{
		// CONSTANTS
		
		//   public
		//     events
		public static const CONTROL_MODE_CHANGE:String = 'control_mode_change';
		public static const FRACTION_LEFT_CHANGE:String = 'fraction_left_change';
		public static const FRACTION_RIGHT_CHANGE:String = 'fraction_right_change';
		public static const HAND_PREF_CHANGE:String = 'hand_pref_change';
		public static const MOTION_CONFIG_CHANGE:String = 'motion_config_change';
		public static const MOTION_ENABLED_CHANGE:String = 'motion_enabled_change';
		
		//     defaults and config constraints
		public static const FULL_STEPS_DEFAULT:int = 6;
		public static const FULL_STEPS_MAX:int = 12;
		public static const FULL_STEPS_MIN:int = 4;
		public static const POLL_MSECS_DEFAULT:int = 250;
		public static const POLL_MSECS_MAX:int = 500;
		public static const POLL_MSECS_MIN:int = 100;
		public static const SMALL_STEPS_PER_FULL_STEP:int = 2;
		
		//     control modes
		public static const CONTROL_MODE_TANK:uint = 0;
		public static const CONTROL_MODE_JOYSTICK:uint = 1;
		public static const CONTROL_MODE_SENSORS:uint = 2;
		
		//     hand pref flags (one-handed = 1, left-handed = 2)
		// 0b00 = 2 Hands, Right Dominant
		// 0b01 = 1 Hand, Right
		// 0b10 = 2 Hands, Left Dominant
		// 0b11 = 1 Hand, Left
		public static const FLAG_ONE_HAND:uint = 1; // 0b01
		public static const FLAG_LEFT_HAND:uint = 2; // 0b10
		
		//   joystick inputs
		private static const INP_NONE:int = 0;
		private static const INP_STOP:int = 1;
		private static const INP_FORWARD:int = 2;
		private static const INP_BACKWARD:int = 3;
		private static const INP_LEFT:int = 4;
		private static const INP_RIGHT:int = 5;
		
		//   joystick motion states
		private static const STOPPED:int = 0;
		private static const TRANSITION:int = 1;
		private static const GOING_FORWARD:int = 2;
		private static const GOING_BACKWARD:int = 3;
		private static const TURNING_RIGHT:int = 4;
		private static const BACKING_RIGHT:int = 5;
		private static const TURNING_LEFT:int = 6;
		private static const BACKING_LEFT:int = 7;
		private static const SPIN_RIGHT:int = 8;
		private static const SPIN_LEFT:int = 9;
		
		private static const _CONTROL_VIEW_STATES:Array = [ 'tank', 'joystick', 'sensors' ];
		
		// CONSTRUCTOR AND INSTANCE
		
		/**
		 * Singleton: use static property <b>instance</b> to get a reference.
		 */
		public function MotionManager ( enforcer:SingletonEnforcer )
		{
			super ( );
			_sessionMgr = SessionManager.instance;
			init ( );
		}
		
		/**
		 * Singleton instance
		 */
		public static function get instance ( ) : MotionManager
		{
			if ( !__instance )
			{
				__instance = new MotionManager ( new SingletonEnforcer ( ) );
			}
			return __instance;
		}
		
		private static var __instance:MotionManager;
		
		
		// PUBLIC PROPERTIES AND GET/SET METHOD GROUPS
		
		[Bindable (event="control_mode_change")]
		public function get controlIcon():Object
		{
			return _aControlIcons [ _uContMode ];
		}
		
		private var _uContMode:uint = CONTROL_MODE_TANK;
		[Bindable (event="control_mode_change")]
		public function get controlMode():uint
		{
			return _uContMode;
		}
		public function set controlMode(value:uint):void
		{
			if( _uContMode !== value)
			{
				_uContMode = value;
				_fUpdateState = _vUpdateStateFuncts [ value ];
				_userState.controlMode = value;
				dispatchEvent ( new Event ( CONTROL_MODE_CHANGE ) );
			}
		}
		
		[Bindable (event="control_mode_change")]
		public function get controlState():String
		{
			return _CONTROL_VIEW_STATES [ _uContMode ];
		}
		
		[Bindable (event="motion_enabled_change")]
		public function get enabled():Boolean
		{
			return _bEnabled;
		}
		public function set enabled(value:Boolean):void
		{
			if ( value !== _bEnabled )
			{
				_bEnabled = value;
				if ( value )
				{
					if ( _tmrPoll )
					{
						_tmrPoll.start ( );
					}
				}
				else
				{
					if ( _tmrPoll )
					{
						_tmrPoll.stop ( );
					}
					_Stop ( false );
				}
				dispatchEvent ( new Event ( MOTION_ENABLED_CHANGE ) );
			}
		}
		
		private var _nFractLeft:Number = 0;
		/**
		 * Requested left motor speed as a float between
		 * 1.0 (flank speed forward) and -1.0 (flank speed backward)
		 */
		[Bindable (event="fraction_left_change")]
		public function get fractionLeft():Number
		{
			return _nFractLeft;
		}
		private function _FractionLeftSet(value:Number):void
		{
			if ( value !== _nFractLeft )
			{
				_nFractLeft = value;
				dispatchEvent ( new Event ( FRACTION_LEFT_CHANGE ) );
			}
		}
		
		private var _nFractRight:Number = 0;
		/**
		 * Requested right motor speed as a float between
		 * 1.0 (flank speed forward) and -1.0 (flank speed backward)
		 */
		[Bindable (event="fraction_right_change")]
		public function get fractionRight():Number
		{
			return _nFractRight;
		}
		private function _FractionRightSet(value:Number):void
		{
			if ( value !== _nFractRight )
			{
				_nFractRight = value;
				dispatchEvent ( new Event ( FRACTION_RIGHT_CHANGE ) );
			}
		}
		
		// fullSteps
		private var _iFullSteps:int;
		/**
		 * The pilot-adjustable number of full steps into which to divide the range of motor speeds.
		 * This is multiplied by the FULL_STEP_DIVISIONS constant to get the total number of
		 * motor speed levels, thus allowing for smoother changes in turns.
		 */
		[Bindable (event="motion_config_change")]
		public function get fullSteps():int
		{
			return _iFullSteps;
		}
		/**
		 * @private
		 */
		public function set fullSteps(value:int):void
		{
			_iFullSteps = value;
			_UpdateProps ( );
		}
		
		[Bindable (event="hand_pref_change")]
		public function get handIcon():Object
		{
			return _aHandIcons [ _uHandPref ];
		}
		
		private var _uHandPref:uint = 0;
		[Bindable (event="hand_pref_change")]
		public function get handPref():uint
		{
			return _uHandPref;
		}
		public function set handPref(value:uint):void
		{
			if( _uHandPref !== value)
			{
				_uHandPref = value;
				_userState.handPref = value;
				dispatchEvent ( new Event ( HAND_PREF_CHANGE ) );
			}
		}
		
		// pollMsecs
		private var _iPollMsecs:int;
		/**
		 * Timer interval for checking control inputs.
		 */
		public function get pollMsecs():int
		{
			return _iPollMsecs;
		}
		/**
		 * @private
		 */
		public function set pollMsecs(value:int):void
		{
			_iPollMsecs = value;
			_tmrPoll.delay = _iPollMsecs;
		}
		
		[Bindable (event="motion_config_change")]
		public function get smallSteps():int
		{
			return _iIdxFlank;
		}
		private function _SmallStepsSet(value:int):void
		{
			if ( value !== _iIdxFlank )
			{
				_iIdxFlank = value;
			}
		}
		
		//		private var _bStopEnabled:Boolean = false;
		//		public function get stopButtonEnabled():Boolean
		//		{
		//			return _bStopEnabled;
		//		}
		//		private function set stopButtonEnabled(value:Boolean):void
		//		{
		//			_bStopEnabled = value;
		//		}
		
		// tipBackward
		//		private var _sTipB:String = '';
		//		/**
		//		 * tip to display when mouse is over the Backward button
		//		 */
		//		public function get tipBackward():String
		//		{
		//			return _sTipB;
		//		}
		//		private function set tipBackward(value:String):void
		//		{
		//			_sTipB = value;
		//		}
		
		// tipForward
		//		private var _sTipF:String = '';
		//		/**
		//		 * tip to display when mouse is over the Forward button
		//		 */
		//		public function get tipForward():String
		//		{
		//			return _sTipF;
		//		}
		//		private function set tipForward(value:String):void
		//		{
		//			_sTipF = value;
		//		}
		
		// tipLeft
		//		private var _sTipL:String = '';
		//		/**
		//		 * tip to display when mouse is over the Left button
		//		 */
		//		public function get tipLeft():String
		//		{
		//			return _sTipL;
		//		}
		//		private function set tipLeft(value:String):void
		//		{
		//			_sTipL = value;
		//		}
		
		// tipRight
		//		private var _sTipR:String = '';
		//		/**
		//		 * tip to display when mouse is over the Right button
		//		 */
		//		public function get tipRight():String
		//		{
		//			return _sTipR;
		//		}
		//		private function set tipRight(value:String):void
		//		{
		//			_sTipR = value;
		//		}
		
		// tipState
		//		private var _sTipState:String = '';
		//		/**
		//		 * text for the motion state display field
		//		 */
		//		public function get tipState():String
		//		{
		//			return _sTipState;
		//		}
		//		private function set tipState(value:String):void
		//		{
		//			_sTipState = value;
		//		}
		
		// tipStop
		//		private var _sTipStop:String = '';
		//		/**
		//		 * tip to display when mouse is over the Stop button
		//		 */
		//		public function get tipStop():String
		//		{
		//			return _sTipStop;
		//		}
		//		private function set tipStop(value:String):void
		//		{
		//			_sTipStop = value;
		//		}
		
		
		// PUBLIC METHODS
		
		public function buttonBackward ( ) : void
		{
			if ( _bBackwardOk )
				_iInput = INP_BACKWARD;
		}
		
		public function buttonForward ( ) : void
		{
			if ( _bForwardOk )
				_iInput = INP_FORWARD;
		}
		
		public function buttonLeft ( ) : void
		{
			if ( _bBackwardOk )
				_iInput = INP_LEFT;
		}
		
		public function buttonRight ( ) : void
		{
			if ( _bBackwardOk )
				_iInput = INP_RIGHT;
		}
		
		public function buttonStop ( ) : void
		{
			_iInput = INP_STOP ;
		}
		
		override public function dismiss ( ) : void
		{
			if ( !_bInited )
				return;
			
			_bInited = false;
			if ( _tmrPoll )
			{
				_tmrPoll.stop ( );
				_tmrPoll.removeEventListener ( TimerEvent.TIMER, _UpdateState );
				_tmrPoll = null;
			}
			_moveProps = null;
			_motorRight = null;
			_motorLeft = null;
			_vUpdateStateFuncts = null;
			_aHandIcons = null;
			_aControlIcons = null;
			super.dismiss ( );
			__instance = null;
		}
		
		/**
		 * Called automatically during instantiation,
		 * but may also be called manually to reactivate
		 * if object was previously dismissed.
		 */
		public function init ( ) : void
		{
			if ( _bInited )
				return;
			
			_bInited = true;
			_vUpdateStateFuncts = new <Function> [
				_UpdateStateTank,
				_UpdateStateJoystick,
				_UpdateStateSensors
			];
			_aControlIcons = [
				IconMotion0,
				IconMotion1,
				IconMotion2
			];
			// right dominant
			// right only
			// left dominant
			// left only
			_aHandIcons = [
				IconHand0,
				IconHand1,
				IconHand2,
				IconHand3
			];
			_motorLeft = new Motor ( );
			_motorRight = new Motor ( );
			_moveProps = MoveProps.NewFromParameters ( );
			_tmrPoll = new Timer ( POLL_MSECS_DEFAULT, 0 );
			_tmrPoll.addEventListener ( TimerEvent.TIMER, _UpdateState );
			setDefaults ( );
			_UpdateDisplay ( );
		}
		
		/**
		 * Set fullSteps and pollMsecs to default values
		 */
		public function setDefaults ( ) : void
		{
			fullSteps = FULL_STEPS_DEFAULT;
			pollMsecs = POLL_MSECS_DEFAULT;
			_UpdateProps ( );
		}
		
		/**
		 * Quick stop
		 */
		public function stop ( ) : void
		{
			_Stop ( );
		}
		
		public function tankBoth ( fract:Number ) : void
		{
			if ( _motorLeft.fractionSpeedSignedSet ( fract ) )
			{
				_bTankChange = true;
			}
			var iIdx:int = _motorLeft.levelIndex;
			var uStat:uint = _motorLeft.state;
			
			if ( _motorRight.levelIndex != iIdx )
			{
				_bTankChange = true;
				_motorRight.levelIndex = iIdx;
			}
			
			if ( _motorRight.state != uStat )
			{
				_bTankChange = true;
				_motorRight.state = uStat;
			}
		}
		
		public function tankLeft ( fract:Number ) : void
		{
			if ( _motorLeft.fractionSpeedSignedSet ( fract ) )
				_bTankChange = true;
		}
		
		public function tankRight ( fract:Number ) : void
		{
			if ( _motorRight.fractionSpeedSignedSet ( fract ) )
				_bTankChange = true;
		}
		
		public function userStateInit ( userState:UserState ) : void
		{
			_userState = userState;
			controlMode = _userState.controlMode;
			handPref = _userState.handPref;
		}
		
		// PRIVATE PROPERTIES
		
		private var _aControlIcons:Array;
		private var _aHandIcons:Array;
		private var _bBackwardOk:Boolean = true;
		private var _bEnabled:Boolean = false;
		private var _bForwardOk:Boolean = true;
		private var _bInited:Boolean = false;
		private var _bTankChange:Boolean = false;
		private var _fUpdateState:Function = _UpdateStateTank;
		private var _iIdxDeadSlow:int = 0;
		private var _iIdxFlank:int; // total number of small steps
		private var _iIdxFull:int; // flank speed minus 1 step
		private var _iIdxSlow:int = SMALL_STEPS_PER_FULL_STEP;
		private var _iInput:int = INP_NONE;
		private var _iInputLast:int = INP_NONE;
		private var _iState:int = STOPPED;
		private var _iStepFull:int = SMALL_STEPS_PER_FULL_STEP;
		private var _iStepSmall:int = 1;
		private var _motorLeft:Motor;
		private var _motorRight:Motor;
		private var _moveProps:MoveProps;
		private var _sessionMgr:SessionManager;
		private var _tmrPoll:Timer;
		private var _uEmFlags:uint = 0;
		private var _userState:UserState;
		private var _vUpdateStateFuncts:Vector.<Function>;
		
		
		// PRIVATE METHODS
		
		private function _EmergencyFlagsUpdated ( event:EmergencyEvent ) : void
		{
			if ( _uEmFlags == event.flags )
				return;
			
			_uEmFlags = event.flags;
			if ( _uEmFlags == 0 )
			{
				// all clear
				_bBackwardOk = true;
				_bForwardOk = true;
			}
			else
			{
				_bForwardOk = false;
				if ( _uEmFlags == EmergencyFlags.OBSTACLE )
				{
					// only flag set is OBSTACLE, so can allow backing and spinning
					_bBackwardOk = true;
					_Stop ( false );
				}
				else
				{
					_bBackwardOk = false;
					_Stop ( false );
				}
			}
		}
		
		private function _Stop ( send:Boolean = true ) : Boolean
		{
			if ( _iState == STOPPED )
				return false;
			
			_iInput = INP_NONE;
			_iInputLast = INP_NONE;
			_iState = STOPPED;
			_motorLeft.release ( );
			_motorRight.release ( );
			_UpdateOutput ( send );
			return true;
		}
		
		private function _UpdateDisplay ( ) : void
		{
			_FractionLeftSet ( _motorLeft.fractionSpeedSigned );
			_FractionRightSet ( _motorRight.fractionSpeedSigned );
			// stopButtonEnabled = ( _iState != STOPPED );
			// _UpdateDisplayTips ( );
		}
		
		/*
		private function _UpdateDisplayTips ( ) : void
		{
			tipStop = _bStopEnabled ? resourceManager.getString ( 'default', 'move_stop_tip' ) : '';
			tipState = resourceManager.getString ( 'default', 'move_state_' + _iState );
			tipBackward = resourceManager.getString ( 'default', 'move_backward_' + _iState );
			tipForward = resourceManager.getString ( 'default', 'move_forward_' + _iState );
			tipLeft = resourceManager.getString ( 'default', 'move_left_' + _iState );
			tipRight = resourceManager.getString ( 'default', 'move_right_' + _iState );
		}
		*/
		
		private function _UpdateOutput ( send:Boolean = true ) : void
		{
			_moveProps.leftRun = _motorLeft.state;
			_moveProps.leftSpeed = _motorLeft.speed;
			_moveProps.rightRun = _motorRight.state;
			_moveProps.rightSpeed = _motorRight.speed;
			_UpdateDisplay ( );
			if ( send )
				_sessionMgr.motionRequest ( _moveProps );
		}
		
		private function _UpdateProps ( ) : void
		{
			_SmallStepsSet ( SMALL_STEPS_PER_FULL_STEP * fullSteps ); // sets _iIdxFlank
			_iIdxFull = _iIdxFlank - SMALL_STEPS_PER_FULL_STEP;
			_motorLeft.levelLimit = _iIdxFlank;
			_motorRight.levelLimit = _iIdxFlank;
			dispatchEvent ( new Event ( MOTION_CONFIG_CHANGE ) );
		}
		
		private function _UpdateState ( event:TimerEvent = null ) : void
		{
			// Triggered by input polling timer
			_fUpdateState ( );
		}
		
		private function _UpdateStateTank ( ) : void
		{
			if ( _bTankChange )
			{
				_bTankChange = false;
				_UpdateOutput ( );
			}
		}
		
		private function _UpdateStateSensors ( ) : void
		{
		}
		
		private function _UpdateStateJoystick ( ) : void
		{
			// If no button is pressed run any pending action(s)
			// otherwise you are done.
			if ( _iInput == INP_NONE )
			{
				if ( _iState == TRANSITION )
				{
					_iInput = _iInputLast;  // delayed input
				}
				else
				{
					return; // no change
				}
			}
			
			// The action to be taken if the stop button
			// is pressed is common to all states
			if ( _iInput == INP_STOP )
			{
				_Stop();
				return;
			}
			
			// Start of Finite State Machine
			var iIdxL:int;
			var iIdxR:int;
			var iStateNext:int = _iState; // assume state will remain the same, unless something changes it
			
			switch ( _iState )
			{
				case TRANSITION:
					// delayed action occurs only when going forward or backward
					// after being in a turn or spin
					switch ( _iInput )
					{
						case INP_FORWARD:
							// start slow
							_motorRight.forward ( _iIdxSlow );
							_motorLeft.forward ( _iIdxSlow );
							iStateNext = GOING_FORWARD;
							break;
						case INP_BACKWARD:
							// start slow
							_motorRight.backward ( _iIdxSlow );
							_motorLeft.backward ( _iIdxSlow );
							iStateNext = GOING_BACKWARD;
							break;
						default:
							break;
					}
					break;
				case STOPPED:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// start slow
							_motorRight.forward ( _iIdxSlow );
							_motorLeft.forward ( _iIdxSlow );
							iStateNext = GOING_FORWARD;
							break;
						case INP_BACKWARD:
							// start slow
							_motorRight.backward ( _iIdxSlow );
							_motorLeft.backward ( _iIdxSlow );
							iStateNext = GOING_BACKWARD;
							break;
						case INP_LEFT:
							// spin
							_motorRight.forward ( _iIdxDeadSlow );
							_motorLeft.backward ( _iIdxDeadSlow );
							iStateNext = SPIN_LEFT;
							break;
						case INP_RIGHT:
							// spin
							_motorRight.backward ( _iIdxDeadSlow );
							_motorLeft.forward ( _iIdxDeadSlow );
							iStateNext = SPIN_RIGHT;
							break;
						default:
							break;
					}
					break;
				case GOING_FORWARD:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// accelerate
							if ( _motorRight.accelerate ( _iStepFull, _iIdxFull ) != _motorLeft.accelerate ( _iStepFull, _iIdxFull ) )
							{
								_Stop();
								return;
							}
							break;
						case INP_BACKWARD:
							// decelerate
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							break;
						case INP_LEFT:
							if ( _motorRight.levelIndex != _motorLeft.levelIndex )
							{
								_Stop();
								return;
							}
							// store current speed to resume when come out of turn
							_motorRight.cruiseStore();
							_motorLeft.cruiseStore();
							// start left turn
							_motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							_motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							iStateNext = TURNING_LEFT;
							break;
						case INP_RIGHT:
							if ( _motorRight.levelIndex != _motorLeft.levelIndex )
							{
								_Stop();
								return;
							}
							// store current speed to resume when come out of turn
							_motorRight.cruiseStore();
							_motorLeft.cruiseStore();
							// start right turn
							_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							iStateNext = TURNING_RIGHT;
							break;
						default:
							break;
					}
					break;
				case GOING_BACKWARD:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// decelerate
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							break;
						case INP_BACKWARD:
							// accelerate
							if ( _motorRight.accelerate ( _iStepFull, _iIdxFull ) != _motorLeft.accelerate ( _iStepFull, _iIdxFull ) )
							{
								_Stop();
								return;
							}
							break;
						case INP_LEFT:
							if ( _motorRight.levelIndex != _motorLeft.levelIndex )
							{
								_Stop();
								return;
							}
							// store current speed to resume when come out of turn
							_motorRight.cruiseStore();
							_motorLeft.cruiseStore();
							// start left turn
							_motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							_motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							iStateNext = BACKING_LEFT;
							break;
						case INP_RIGHT:
							if ( _motorRight.levelIndex != _motorLeft.levelIndex )
							{
								_Stop();
								return;
							}
							// store current speed to resume when come out of turn
							_motorRight.cruiseStore();
							_motorLeft.cruiseStore();
							// start right turn
							_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							iStateNext = BACKING_RIGHT;
							break;
						default:
							break;
					}
					break;
				case TURNING_RIGHT:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// turn completed
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							iStateNext = GOING_FORWARD;
							break;
						case INP_BACKWARD:
							// turn completed and decelerate
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							// if get here, going forward
							iStateNext = GOING_FORWARD;
							break;
						case INP_LEFT:
							// decrease sharpness of turn and
							// if now going straight, just change state
							// if would change turn directions, override to go straight
							iIdxR = _motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							iIdxL = _motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							if ( iIdxR >= iIdxL )
							{
								if ( iIdxR > iIdxL )
								{
									// speeds not equal, so match the slower speed
									_motorRight.levelIndex = iIdxL;
								}
								iStateNext = GOING_FORWARD;
							}
							break;
						case INP_RIGHT:
							// increase sharpness of turn
							_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							break;
						default:
							break;
					}
					break;
				case BACKING_RIGHT:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// turn completed and decelerate
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							// if get here, going backward
							iStateNext = GOING_BACKWARD;
							break;
						case INP_BACKWARD:
							// turn completed
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							iStateNext = GOING_BACKWARD;
							break;
						case INP_LEFT:
							// decrease sharpness of turn and
							// if now going straight, just change state
							// if would change turn directions, override to go straight
							iIdxR = _motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							iIdxL = _motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							if ( iIdxR >= iIdxL )
							{
								if ( iIdxR > iIdxL )
								{
									// speeds not equal, so match the slower speed
									_motorRight.levelIndex = iIdxL;
								}
								iStateNext = GOING_BACKWARD;
							}
							break;
						case INP_RIGHT:
							// increase sharpness of turn
							_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							break;
						default:
							break;
					}
					break;
				case TURNING_LEFT:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// turn completed
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							iStateNext = GOING_FORWARD;
							break;
						case INP_BACKWARD:
							// turn completed and decelerate
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							// if get here, going forward
							iStateNext = GOING_FORWARD;
							break;
						case INP_LEFT:
							// increase sharpness of turn
							_motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							_motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							break;
						case INP_RIGHT:
							// decrease sharpness of turn and
							// if now going straight, just change state
							// if would change turn directions, override to go straight
							iIdxR = _motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							iIdxL = _motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							if ( iIdxR <= iIdxL )
							{
								if ( iIdxR < iIdxL )
								{
									// speeds not equal, so match the slower speed
									_motorLeft.levelIndex = iIdxR;
								}
								iStateNext = GOING_FORWARD;
							}
							break;
						default:
							break;
					}
					break;
				case BACKING_LEFT:
					switch ( _iInput )
					{
						case INP_FORWARD:
							// turn completed and decelerate
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							if ( _motorRight.levelIndex <= _iIdxSlow ||
								_motorRight.decelerate ( _iStepFull, _iIdxSlow ) != _motorLeft.decelerate ( _iStepFull, _iIdxSlow ) )
							{
								_Stop();
								return;
							}
							// if get here, going backward
							iStateNext = GOING_BACKWARD;
							break;
						case INP_BACKWARD:
							// turn completed
							_motorRight.cruiseResume();
							_motorLeft.cruiseResume();
							iStateNext = GOING_BACKWARD;
							break;
						case INP_LEFT:
							// increase sharpness of turn
							_motorRight.accelerate ( _iStepSmall, _iIdxFlank );
							_motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow );
							break;
						case INP_RIGHT:
							// decrease sharpness of turn and
							// if now going straight, just change state
							// if would change turn directions, override to go straight
							iIdxR = _motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow );
							iIdxL = _motorLeft.accelerate ( _iStepSmall, _iIdxFlank );
							if ( iIdxR <= iIdxL )
							{
								if ( iIdxR < iIdxL )
								{
									// speeds not equal, so match the slower speed
									_motorLeft.levelIndex = iIdxR;
								}
								iStateNext = GOING_BACKWARD;
							}
							break;
						default:
							break;
					}
					break;
				case SPIN_RIGHT:
					switch ( _iInput )
					{
						case INP_FORWARD:
						case INP_BACKWARD:
							// stop and TRANSITION
							_motorRight.release();
							_motorLeft.release();
							iStateNext = TRANSITION;
							break;
						case INP_LEFT:
							// decrease spin speed or stop
							if ( _motorRight.levelIndex <= _iIdxDeadSlow ||
								_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow ) != _motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow ) )
							{
								_Stop();
								return;
							}
							break;
						case INP_RIGHT:
							// increase spin speed
							_motorRight.accelerate ( _iStepSmall, _iIdxFull );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFull );
							break;
						default:
							break;
					}
					break;
				case SPIN_LEFT:
					switch ( _iInput )
					{
						case INP_FORWARD:
						case INP_BACKWARD:
							// stop and TRANSITION
							_motorRight.release();
							_motorLeft.release();
							iStateNext = TRANSITION;
							break;
						case INP_LEFT:
							// increase spin speed
							_motorRight.accelerate ( _iStepSmall, _iIdxFull );
							_motorLeft.accelerate ( _iStepSmall, _iIdxFull );
							break;
						case INP_RIGHT:
							// decrease spin speed or stop
							if ( _motorRight.levelIndex <= _iIdxDeadSlow ||
								_motorRight.decelerate ( _iStepSmall, _iIdxDeadSlow ) != _motorLeft.decelerate ( _iStepSmall, _iIdxDeadSlow ) )
							{
								_Stop();
								return;
							}
							break;
						default:
							break;
					}
					break;
				default:
					break;
			}
			
			// Update Finite State Machine
			_iInputLast = _iInput;
			_iInput = INP_NONE;
			_iState = iStateNext;
			
			_UpdateOutput ( );
		}
		
	}
}
class SingletonEnforcer {}