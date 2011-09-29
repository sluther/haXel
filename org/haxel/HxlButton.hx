package org.haxel;
	import flash.events.MouseEvent;
	
	/**
	 * A simple button class that calls a function when clicked by the mouse.
	 * 
	 * @author	Adam Atomic
	 */
	class HxlButton extends HxlSprite
	{
		/*[Embed(source="data/button.png")] private var ImgDefaultButton:Class;
		[Embed(source="data/beep.mp3")] private var SndBeep:Class;*/
		
		/**
		 * Used with public variable <code>status</code>, means not highlighted or pressed.
		 */
		public static var NORMAL:UInt = 0;
		/**
		 * Used with public variable <code>status</code>, means highlighted (usually from mouse over).
		 */
		public static var HIGHLIGHT:UInt = 1;
		/**
		 * Used with public variable <code>status</code>, means pressed (usually from mouse click).
		 */
		public static var PRESSED:UInt = 2;
		
		/**
		 * The text that appears on the button.
		 */
		public var label:HxlText;
		/**
		 * Controls the offset (from top left) of the text from the button.
		 */
		public var labelOffset:HxlPoint;
		/**
		 * This function is called when the button is released.
		 * We recommend assigning your main button behavior to this function
		 * via the <code>HxlButton</code> constructor.
		 */
		public var onUp:Function;
		/**
		 * This function is called when the button is pressed down.
		 */
		public var onDown:Function;
		/**
		 * This function is called when the mouse goes over the button.
		 */
		public var onOver:Function;
		/**
		 * This function is called when the mouse leaves the button area.
		 */
		public var onOut:Function;
		/**
		 * Shows the current state of the button.
		 */
		public var status:UInt;
		/**
		 * Set this to play a sound when the mouse goes over the button.
		 * We recommend using the helper function setSounds()!
		 */
		public var soundOver:HxlSound;
		/**
		 * Set this to play a sound when the mouse leaves the button.
		 * We recommend using the helper function setSounds()!
		 */
		public var soundOut:HxlSound;
		/**
		 * Set this to play a sound when the button is pressed down.
		 * We recommend using the helper function setSounds()!
		 */
		public var soundDown:HxlSound;
		/**
		 * Set this to play a sound when the button is released.
		 * We recommend using the helper function setSounds()!
		 */
		public var soundUp:HxlSound;

		/**
		 * Used for checkbox-style behavior.
		 */
		private var _onToggle:Bool;
		
		/**
		 * Tracks whether or not the button is currently pressed.
		 */
		private var _pressed:Bool;
		/**
		 * Whether or not the button has initialized itself yet.
		 */
		private var _initialized:Bool;
		
		/**
		 * Creates a new <code>HxlButton</code> object with a gray background
		 * and a callback function on the UI thread.
		 * 
		 * @param	X			The X position of the button.
		 * @param	Y			The Y position of the button.
		 * @param	Label		The text that you want to appear on the button.
		 * @param	OnClick		The function to call whenever the button is clicked.
		 */
		public function new(X:Float=0,Y:Float=0,Label:String=null,OnClick:Function=null)
		{
			super(X,Y);
			if(Label != null)
			{
				label = new HxlText(0,0,80,Label);
				label.setFormat(null,8,0x333333,"center");
				labelOffset = new HxlPoint(-1,3);
			}
			loadGraphic(ImgDefaultButton,true,false,80,20);
			
			onUp = OnClick;
			onDown = null;
			onOut = null;
			onOver = null;
			
			soundOver = null;
			soundOut = null;
			soundDown = null;
			soundUp = null;

			status = NORMAL;
			_onToggle = false;
			_pressed = false;
			_initialized = false;
		}
		
		/**
		 * Called by the game state when state is changed (if this object belongs to the state)
		 */
		override public function destroy():Void
		{
			if(HxlG.stage != null)
				HxlG.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(label != null)
			{
				label.destroy();
				label = null;
			}
			onUp = null;
			onDown = null;
			onOut = null;
			onOver = null;
			if(soundOver != null)
				soundOver.destroy();
			if(soundOut != null)
				soundOut.destroy();
			if(soundDown != null)
				soundDown.destroy();
			if(soundUp != null)
				soundUp.destroy();
			super.destroy();
		}
		
		/**
		 * Since button uses its own mouse handler for thread reasons,
		 * we run a little pre-check here to make sure that we only add
		 * the mouse handler when it is actually safe to do so.
		 */
		override public function preUpdate():Void
		{
			super.preUpdate();
			
			if(!_initialized)
			{
				if(HxlG.stage != null)
				{
					HxlG.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					_initialized = true;
				}
			}
		}
		
		/**
		 * Called by the game loop automatically, handles mouseover and click detection.
		 */
		override public function update():Void
		{
			updateButton(); //Basic button logic

			//Default button appearance is to simply update
			// the label appearance based on animation frame.
			if(label == null)
				return;
			switch(frame)
			{
				case HIGHLIGHT:	//Extra behavior to accomodate checkbox logic.
					label.alpha = 1.0;
					break;
				case PRESSED:
					label.alpha = 0.5;
					label.y++;
					break;
				case NORMAL:
				default:
					label.alpha = 0.8;
					break;
			}
		}
		
		/**
		 * Basic button update logic
		 */
		private function updateButton():Void
		{
			//Figure out if the button is highlighted or pressed or what
			// (ignore checkbox behavior for now).
			if(HxlG.mouse.visible)
			{
				if(cameras == null)
					cameras = HxlG.cameras;
				var camera:HxlCamera;
				var i:UInt = 0;
				var l:UInt = cameras.length;
				var offAll:Bool = true;
				while(i < l)
				{
					camera = HxlCamera<cameras[i++]> cast HxlCamera;
					HxlG.mouse.getWorldPosition(camera,_point);
					if(overlapsPoint(_point,true,camera))
					{
						offAll = false;
						if(HxlG.mouse.justPressed())
						{
							status = PRESSED;
							if(onDown != null)
								onDown();
							if(soundDown != null)
								soundDown.play(true);
						}
						if(status == NORMAL)
						{
							status = HIGHLIGHT;
							if(onOver != null)
								onOver();
							if(soundOver != null)
								soundOver.play(true);
						}
					}
				}
				if(offAll)
				{
					if(status != NORMAL)
					{
						if(onOut != null)
							onOut();
						if(soundOut != null)
							soundOut.play(true);
					}
					status = NORMAL;
				}
			}
		
			//Then if the label and/or the label offset exist,
			// position them to match the button.
			if(label != null)
			{
				label.x = x;
				label.y = y;
			}
			if(labelOffset != null)
			{
				label.x += labelOffset.x;
				label.y += labelOffset.y;
			}
			
			//Then pick the appropriate frame of animation
			if((status == HIGHLIGHT) && _onToggle)
				frame = NORMAL;
			else
				frame = status;
		}
		
		/**
		 * Just draws the button graphic and text label to the screen.
		 */
		override public function draw():Void
		{
			super.draw();
			if(label != null)
			{
				label.scrollFactor = scrollFactor;
				label.cameras = cameras;
				label.draw();
			}
		}
		
		/**
		 * Updates the size of the text field to match the button.
		 */
		override private function resetHelpers():Void
		{
			super.resetHelpers();
			if(label != null)
				label.width = width;
		}
		
		/**
		 * Set sounds to play during mouse-button interactions.
		 * These operations can be done manually as well, and the public
		 * sound variables can be used after this for more fine-tuning,
		 * such as positional audio, etc.
		 * 
		 * @param SoundOver			What embedded sound effect to play when the mouse goes over the button. Default is null, or no sound.
		 * @param SoundOverVolume	How load the that sound should be.
		 * @param SoundOut			What embedded sound effect to play when the mouse leaves the button area. Default is null, or no sound.
		 * @param SoundOutVolume	How load the that sound should be.
		 * @param SoundDown			What embedded sound effect to play when the mouse presses the button down. Default is null, or no sound.
		 * @param SoundDownVolume	How load the that sound should be.
		 * @param SoundUp			What embedded sound effect to play when the mouse releases the button. Default is null, or no sound.
		 * @param SoundUpVolume		How load the that sound should be.
		 */
		public function setSounds(SoundOver:Class=null, SoundOverVolume:Float=1.0, SoundOut:Class=null, SoundOutVolume:Float=1.0, SoundDown:Class=null, SoundDownVolume:Float=1.0, SoundUp:Class=null, SoundUpVolume:Float=1.0):Void
		{
			if(SoundOver != null)
				soundOver = HxlG.loadSound(SoundOver, SoundOverVolume);
			if(SoundOut != null)
				soundOut = HxlG.loadSound(SoundOut, SoundOutVolume);
			if(SoundDown != null)
				soundDown = HxlG.loadSound(SoundDown, SoundDownVolume);
			if(SoundUp != null)
				soundUp = HxlG.loadSound(SoundUp, SoundUpVolume);
		}
		
		/**
		 * Use this to toggle checkbox-style behavior.
		 */
		public var on(getOn, setOn):Bool;
		public function getOn():Bool
		{
			return _onToggle;
		}
		
		/**
		 * @private
		 */
		public function setOn(On:Bool):Void
		{
			_onToggle = On;
		}
		
		/**
		 * Internal function for handling the actual callback call (for UI thread dependent calls like <code>HxlU.openURL()</code>).
		 */
		private function onMouseUp(event:MouseEvent):Void
		{
			if(!exists || !visible || !active || (status != PRESSED))
				return;
			if(onUp != null)
				onUp();
			if(soundUp != null)
				soundUp.play(true);
		}
	}
