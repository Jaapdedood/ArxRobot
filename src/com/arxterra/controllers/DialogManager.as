package com.arxterra.controllers
{
	import com.arxterra.components.Dialog;
	
	import com.arxterra.events.DialogEvent;
	
	import flash.display.DisplayObjectContainer;
	
	import mx.core.FlexGlobals;
	
	import spark.events.PopUpEvent;
	
	import com.arxterra.utils.NonUIComponentBase;
	
	import com.arxterra.vo.DialogData;

	public class DialogManager extends NonUIComponentBase
	{
		// singleton, so create only one instance
		private static var __instance:DialogManager = new DialogManager();
		
		public static function getInstance ( ) : DialogManager
		{
			return __instance;
		}
		
		/**
		 * Singleton: use getInstance() 
		 */	
		public function DialogManager()
		{
			if ( __instance )
			{
				throw new Error ( 'Cannot create a new instance.\nPlease use DialogManager.getInstance()' );
			}
		}
		
		public function mAlertEventHandler ( e:DialogEvent ) : void
		{
			_AlertShow (
				e.message,
				e.title,
				e.messageParams,
				e.titleParams
			);
		}
		
		public function mDialogEventHandler ( e:DialogEvent ) : void
		{
			_DialogShow (
				e.message,
				e.title,
				e.messageParams,
				e.titleParams,
				e.data,
				e.modal
			);
		}
		
		private var _appTop:DisplayObjectContainer =
			FlexGlobals.topLevelApplication as DisplayObjectContainer;
		
		private var _Dialog:Dialog;
		
		private function _AlertShow (
			a_message:String,
			a_title:String = 'error',
			a_messageParams:Array = null,
			a_titleParams:Array = null
		) : void
		{
			_DialogShow ( a_message, a_title, a_messageParams, a_titleParams );
		}
		
		private function _DialogShow (
			a_message:String,
			a_title:String,
			a_messageParams:Array = null,
			a_titleParams:Array = null,
			a_data:DialogData = null,
			a_modal:Boolean = true
		) : void
		{
			
			if ( _DialogDismiss() )
			{
				_callLater (
					_DialogShow,
					[
						a_message,
						a_title,
						a_messageParams,
						a_titleParams,
						a_data,
						a_modal
					]
				);
			}
			else
			{
				_Dialog = new Dialog ( );
				_Dialog.addEventListener ( PopUpEvent.CLOSE, _DialogClosed );
				_Dialog.open ( _appTop, a_modal );
				_Dialog.mInitialize (
					a_message,
					a_title,
					a_messageParams,
					a_titleParams,
					a_data
				);
			}
		}
		
		private function _DialogClosed ( event:PopUpEvent ) : void
		{
			var respData:DialogData = event.data as DialogData;
			if ( respData.callback != null ) respData.callback ( event.commit, respData );
			_DialogDismiss();
		}
		
		private function _DialogDismiss ( ) : Boolean
		{
			if ( _Dialog == null )
				return false;
			
			_Dialog.removeEventListener ( PopUpEvent.CLOSE, _DialogClosed );
			if ( _Dialog.isOpen ) _Dialog.close();
			_Dialog = null;
			return true;
		}
	}
}