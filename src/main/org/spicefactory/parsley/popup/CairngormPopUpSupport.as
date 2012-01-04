package org.spicefactory.parsley.popup {

import com.adobe.cairngorm.popup.PopUpWrapper;

import org.spicefactory.lib.logging.LogContext;
import org.spicefactory.lib.logging.Logger;
import org.spicefactory.parsley.core.context.Context;
import org.spicefactory.parsley.view.ParentContext;

import mx.core.IFlexDisplayObject;

import flash.display.DisplayObject;
import flash.events.Event;

/**
 * Support for declarative popups from the Cairngorm 3 library.
 * Since this class is a subclass of the Cairngorm <code>PopUpWrapper</code> class, it supports
 * the same set of attributes. It does not add any additional attributes to the tag.
 * It only adds some additional internal behaviour, mainly to find the nearest Parsley Context
 * in the view hierarchy above the document the PopUp tag was placed upon and adds the
 * popup to the Context for the time it is open.
 * 
 * @author Jens Halm
 */
public class CairngormPopUpSupport extends PopUpWrapper {
	
	
	private static const log:Logger = LogContext.getLogger(CairngormPopUpSupport);
	
	
	private var context:Context;
	
	private var openRequested:Boolean;
	
	
	/**
	 * @private
	 */
	public override function initialized (document:Object, id:String) : void {
		var view:DisplayObject = DisplayObject(document);
		
		if (view.stage != null) {
			findContext(view);
		}
		else {
			view.addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
	}
	
	private function addedToStage (event:Event) : void {
		var view:DisplayObject = DisplayObject(event.target);
		view.removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
		findContext(view);
	}
	
	private function findContext (view:DisplayObject) : void {
		ParentContext.view(view).available(contextFound).execute();
	}
	
	private function contextFound (context:Context) : void {
		if (!context) {
			log.error("No Context found in view hierarchy. PopUp will never open");
			return;
		}
		
		this.context = context;
		
		if (openRequested) {
			openRequested = false;
			super.open = true;
		}
	}
	
	/**
	 * @private
	 */
	public override function set open (value:Boolean) : void {
		if (!context) {
			// if the Context has not been found yet we must defer the opening of the popup
			openRequested = value;	
		}
		else {
			super.open = value;
		}
	}

	/**
	 * @private
	 */
	protected override function getPopUp () : IFlexDisplayObject {
        var popup:IFlexDisplayObject = super.getPopUp();
        context.viewManager.addViewRoot(DisplayObject(popup));
        return popup;
    }

	/**
	 * @private
	 */    
    protected override function popUpClosed () : void {
    	var popup:IFlexDisplayObject = super.getPopUp();
        context.viewManager.removeViewRoot(DisplayObject(popup));
    	super.popUpClosed();
	}
	
	
}
}
