package org.haxel;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.media.Sound;
import flash.text.AntiAliasType;
import flash.text.GridFitType;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Mouse;
import flash.utils.Timer;
import flash.Lib;

import org.haxel.plugin.TimerManager;
import org.haxel.system.HxlDebugger;
import org.haxel.system.HxlReplay;

/**
 * HxlGame is the heart of all flixel games, and contains a bunch of basic game loops and things.
 * It is a long and sloppy file that you shouldn't have to worry about too much!
 * It is basically only used to create your game object in the first place,
 * after that HxlG and HxlState have all the useful stuff you actually need.
 * 
 * @author	Adam Atomic
 */
class HxlGame extends Sprite
{
	private var junk:String;
	private var SndBeep:Class<Sound>;
	private var ImgLogo:Class<HxlSprite>;

	/**
	 * Sets 0, -, and + to control the global volume sound volume.
	 * @default true
	 */
	public var useSoundHotKeys:Bool;
	/**
	 * Tells flixel to use the default system mouse cursor instead of custom Haxel mouse cursors.
	 * @default false
	 */
	public var useSystemCursor:Bool;
	/**
	 * Initialize and allow the flixel debugger overlay even in release mode.
	 * Also useful if you don't use HxlPreloader!
	 * @default false
	 */
	public var forceDebugger:Bool;

	/**
	 * Current game state.
	 */
	public var _state:HxlState;
	/**
	 * Mouse cursor.
	 */
	public var _mouse:Sprite;
	
	/**
	 * Class type of the initial/first game state for the game, usually MenuState or something like that.
	 */
	private var _iState:Class<HxlState>;
	/**
	 * Whether the game object's basic initialization has finished yet.
	 */
	private var _created:Bool;
	
	/**
	 * Total number of milliseconds elapsed since game start.
	 */
	private var _total:UInt;
	/**
	 * Total number of milliseconds elapsed since last update loop.
	 * Counts down as we step through the game loop.
	 */
	private var _accumulator:Int;
	/**
	 * Whether the Flash player lost focus.
	 */
	private var _lostFocus:Bool;
	/**
	 * Milliseconds of time per step of the game loop.  FlashEvent.g. 60 fps = 16ms.
	 */
	public var _step:UInt;
	/**
	 * Framerate of the Flash player (NOT the game loop). Default = 30.
	 */
	public var _flashFramerate:UInt;
	/**
	 * Max allowable accumulation (see _accumulator).
	 * Should always (and automatically) be set to roughly 2x the flash player framerate.
	 */
	public var _maxAccumulation:UInt;
	/**
	 * If a state change was requested, the new state object is stored here until we switch to it.
	 */
	public var _requestedState:HxlState;
	/**
	 * A flag for keeping track of whether a game reset was requested or not.
	 */
	public var _requestedReset:Bool;

	/**
	 * The "focus lost" screen (see <code>createFocusScreen()</code>).
	 */
	private var _focus:Sprite;
	/**
	 * The sound tray display container (see <code>createSoundTray()</code>).
	 */
	private var _soundTray:Sprite;
	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	private var _soundTrayTimer:Float;
	/**
	 * Helps display the volume bars on the sound tray.
	 */
	private var _soundTrayBars:Array<HxlSprite>;
	/**
	 * The debugger overlay object.
	 */
	public var _debugger:HxlDebugger;
	/**
	 * A handy boolean that keeps track of whether the debugger exists and is currently visible.
	 */
	public var _debuggerUp:Bool;
	
	/**
	 * Container for a game replay object.
	 */
	public var _replay:HxlReplay;
	/**
	 * Flag for whether a playback of a recording was requested.
	 */
	public var _replayRequested:Bool;
	/**
	 * Flag for whether a new recording was requested.
	 */
	public var _recordingRequested:Bool;
	/**
	 * Flag for whether a replay is currently playing.
	 */
	public var _replaying:Bool;
	/**
	 * Flag for whether a new recording is being made.
	 */
	public var _recording:Bool;
	/**
	 * Array that keeps track of keypresses that can cancel a replay.
	 * Handy for skipping cutscenes or getting out of attract modes!
	 */
	public var _replayCancelKeys:Array<UInt>;
	/**
	 * Helps time out a replay if necessary.
	 */
	public var _replayTimer:Int;
	/**
	 * This function, if set, is triggered when the callback stops playing.
	 */
	public var _replayCallback:Dynamic;

	/**
	 * Instantiate a new game object.
	 * 
	 * @param	GameSizeX		The width of your game in game pixels, not necessarily final display pixels (see Zoom).
	 * @param	GameSizeY		The height of your game in game pixels, not necessarily final display pixels (see Zoom).
	 * @param	InitialState	The class name of the state you want to create and switch to first (e.g. MenuState).
	 * @param	Zoom			The default level of zoom for the game's cameras (e.g. 2 = all pixels are now drawn at 2x).  Default = 1.
	 * @param	GameFramerate	How frequently the game should update (default is 60 times per second).
	 * @param	FlashFramerate	Sets the actual display framerate for Flash player (default is 30 times per second).
	 * @param	UseSystemCursor	Whether to use the default OS mouse pointer, or to use custom flixel ones.
	 */
	public function new(GameSizeX:UInt,GameSizeY:UInt,InitialState:Class<HxlState>,Zoom:Float=1,GameFramerate:UInt=60,FlashFramerate:UInt=30,UseSystemCursor:Bool=false)
	{
		//super high priority init stuff (focus, mouse, etc)
		_lostFocus = false;
		_focus = new Sprite();
		_focus.visible = false;
		_soundTray = new Sprite();
		_mouse = new Sprite();
		
		//basic display and update setup stuff
		HxlG.init(this,GameSizeX,GameSizeY,Zoom);
		HxlG.framerate = GameFramerate;
		HxlG.flashFramerate = FlashFramerate;
		_accumulator = _step;
		_total = 0;
		_state = null;
		useSoundHotKeys = true;
		useSystemCursor = UseSystemCursor;
		if(!useSystemCursor)
			flash.ui.Mouse.hide();
		forceDebugger = false;
		_debuggerUp = false;
		
		//replay data
		_replay = new HxlReplay();
		_replayRequested = false;
		_recordingRequested = false;
		_replaying = false;
		_recording = false;
		
		//then get ready to create the game object for real
		_iState = InitialState;
		_requestedState = null;
		_requestedReset = true;
		_created = false;
		addEventListener(Event.ENTER_FRAME, create);
	}
	
	/**
	 * Makes the little volume tray slide out.
	 * 
	 * @param	Silent	Whether or not it should beep.
	 */
	public function showSoundTray(Silent:Bool=false):Void
	{
		if(!Silent)
			HxlG.play(SndBeep);
		_soundTrayTimer = 1;
		_soundTray.y = 0;
		_soundTray.visible = true;
		var globalVolume:UInt = Math.round(HxlG.volume*10);
		if(HxlG.mute)
			globalVolume = 0;
		for (i in 0..._soundTrayBars.length)
		{
			if(i < globalVolume) _soundTrayBars[i].alpha = 1;
			else _soundTrayBars[i].alpha = 0.5;
		}
	}

	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash keyboard event.
	 */
	private function onKeyUp(FlashEvent:KeyboardEvent):Void
	{
		if(_debuggerUp && _debugger.watch.editing)
			return;
		if(!HxlG.mobile)
		{
			if((_debugger != null) && ((FlashEvent.keyCode == 192) || (FlashEvent.keyCode == 220)))
			{
				_debugger.visible = !_debugger.visible;
				_debuggerUp = _debugger.visible;
				if(_debugger.visible)
					flash.ui.Mouse.show();
				else if(!useSystemCursor)
					flash.ui.Mouse.hide();
				//_console.toggle();
				return;
			}
			if(useSoundHotKeys)
			{
				var c:Int = FlashEvent.keyCode;
				var code:String = String.fromCharCode(FlashEvent.charCode);
				switch(c)
				{
					case 48:
					case 96:
						HxlG.mute = !HxlG.mute;
						if(HxlG.volumeHandler != null)
							HxlG.volumeHandler(HxlG.mute?0:HxlG.volume);
						showSoundTray();
						return;
					case 109:
					case 189:
						HxlG.mute = false;
			    		HxlG.volume = HxlG.volume - 0.1;
			    		showSoundTray();
						return;
					case 107:
					case 187:
						HxlG.mute = false;
			    		HxlG.volume = HxlG.volume + 0.1;
			    		showSoundTray();
						return;
					default:
						return;
				}
			}
		}
		if(_replaying)
			return;
		HxlG.keys.handleKeyUp(FlashEvent);
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash keyboard event.
	 */
	private function onKeyDown(FlashEvent:KeyboardEvent):Void
	{
		if(_debuggerUp && _debugger.watch.editing)
			return;
		if(_replaying && (_replayCancelKeys != null) && (_debugger == null) && (FlashEvent.keyCode != 192) && (FlashEvent.keyCode != 220))
		{
			var cancel:Bool = false;
			var replayCancelKey:String;
			var i:UInt = 0;
			var l:UInt = _replayCancelKeys.length;
			while(i < l)
			{
				replayCancelKey = cast(_replayCancelKeys[i++], String);
				if((replayCancelKey == "ANY") || (HxlG.keys.getKeyCode(replayCancelKey) == FlashEvent.keyCode))
				{
					if(_replayCallback != null)
					{
						_replayCallback();
						_replayCallback = null;
					}
					else
						HxlG.stopReplay();
					break;
				}
			}
			return;
		}
		HxlG.keys.handleKeyDown(FlashEvent);
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash mouse event.
	 */
	private function onMouseDown(FlashEvent:MouseEvent):Void
	{
		if(_debuggerUp)
		{
			if(_debugger.hasMouse)
				return;
			if(_debugger.watch.editing)
				_debugger.watch.submit();
		}
		if(_replaying && (_replayCancelKeys != null))
		{
			var replayCancelKey:String;
			var i:UInt = 0;
			var l:UInt = _replayCancelKeys.length;
			while(i < l)
			{
				replayCancelKey = cast(_replayCancelKeys[i++], String);
				if((replayCancelKey == "MOUSE") || (replayCancelKey == "ANY"))
				{
					if(_replayCallback != null)
					{
						_replayCallback();
						_replayCallback = null;
					}
					else
						HxlG.stopReplay();
					break;
				}
			}
			return;
		}
		HxlG.mouse.handleMouseDown(FlashEvent);
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash mouse event.
	 */
	private function onMouseUp(FlashEvent:MouseEvent):Void
	{
		if((_debuggerUp && _debugger.hasMouse) || _replaying)
			return;
		HxlG.mouse.handleMouseUp(FlashEvent);
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash mouse event.
	 */
	private function onMouseWheel(FlashEvent:MouseEvent):Void
	{
		if((_debuggerUp && _debugger.hasMouse) || _replaying)
			return;
		HxlG.mouse.handleMouseWheel(FlashEvent);
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash event.
	 */
	private function onFocus(FlashEvent:Event=null):Void
	{
		if(!_debuggerUp && !useSystemCursor)
			flash.ui.Mouse.hide();
		HxlG.resetInput();
		_lostFocus = _focus.visible = false;
		stage.frameRate = _flashFramerate;
		HxlG.resumeSounds();
	}
	
	/**
	 * Internal event handler for input and focus.
	 * 
	 * @param	FlashEvent	Flash event.
	 */
	private function onFocusLost(FlashEvent:Event=null):Void
	{
		if((x != 0) || (y != 0))
		{
			x = 0;
			y = 0;
		}
		flash.ui.Mouse.show();
		_lostFocus = _focus.visible = true;
		stage.frameRate = 10;
		HxlG.pauseSounds();
	}
	
	/**
	 * Handles the onEnterFrame call and figures out how many updates and draw calls to do.
	 * 
	 * @param	FlashEvent	Flash event.
	 */
	private function onEnterFrame(FlashEvent:Event=null):Void
	{			
		var mark:UInt = Lib.getTimer();
		var elapsedMS:UInt = mark-_total;
		_total = mark;
		updateSoundTray(elapsedMS);
		if(!_lostFocus)
		{
			if((_debugger != null) && _debugger.vcr.paused)
			{
				if(_debugger.vcr.stepRequested)
				{
					_debugger.vcr.stepRequested = false;
					step();
				}
			}
			else
			{
				_accumulator += elapsedMS;
				if(_accumulator > _maxAccumulation)
					_accumulator = _maxAccumulation;
				while(_accumulator >= _step)
				{
					step();
					_accumulator = _accumulator - _step; 
				}
			}
			
			HxlBasic._VISIBLECOUNT = 0;
			draw();
			
			if(_debuggerUp)
			{
				_debugger.perf.flash(elapsedMS);
				_debugger.perf.visibleObjects(HxlBasic._VISIBLECOUNT);
				_debugger.perf.update();
				_debugger.watch.update();
			}
		}
	}

	/**
	 * If there is a state change requested during the update loop,
	 * this function handles actual destroying the old state and related processes,
	 * and calls creates on the new state and plugs it into the game object.
	 */
	private function switchState():Void
	{ 
		//Basic reset stuff
		HxlG.resetCameras();
		HxlG.resetInput();
		HxlG.destroySounds();
		HxlG.clearBitmapCache();
		
		//Clear the debugger overlay's Watch window
		if(_debugger != null)
			_debugger.watch.removeAll();
		
		//Clear any timers left in the timer manager
		var timerManager:TimerManager = HxlTimer.manager;
		if(timerManager != null)
			timerManager.clear();
		
		//Destroy the old state (if there is an old state)
		if(_state != null)
			_state.destroy();
		
		//Finally assign and create the new state
		_state = _requestedState;
		_state.create();
	}
	
	/**
	 * This is the main game update logic section.
	 * The onEnterFrame() handler is in charge of calling this
	 * the appropriate number of times each frame.
	 * This block handles state changes, replays, all that good stuff.
	 */
	private function step():Void
	{
		//handle game reset request
		if(_requestedReset)
		{
			_requestedReset = false;
			_requestedState = Type.createInstance(_iState, []);
			_replayTimer = 0;
			_replayCancelKeys = null;
			HxlG.reset();
		}
		
		//handle replay-related requests
		if(_recordingRequested)
		{
			_recordingRequested = false;
			_replay.create(HxlG.globalSeed);
			_recording = true;
			if(_debugger != null)
			{
				_debugger.vcr.recording();
				HxlG.log("FLIXEL: starting new flixel gameplay record.");
			}
		}
		else if(_replayRequested)
		{
			_replayRequested = false;
			_replay.rewind();
			HxlG.globalSeed = _replay.seed;
			if(_debugger != null)
				_debugger.vcr.playing();
			_replaying = true;
		}
		
		//handle state switching requests
		if(_state != _requestedState)
			switchState();
		
		//finally actually step through the game physics
		HxlBasic._ACTIVECOUNT = 0;
		if(_replaying)
		{
			_replay.playNextFrame();
			if(_replayTimer > 0)
			{
				_replayTimer -= _step;
				if(_replayTimer <= 0)
				{
					if(_replayCallback != null)
					{
						_replayCallback();
						_replayCallback = null;
					}
					else
						HxlG.stopReplay();
				}
			}
			if(_replaying && _replay.finished)
			{
				HxlG.stopReplay();
				if(_replayCallback != null)
				{
					_replayCallback();
					_replayCallback = null;
				}
			}
			if(_debugger != null)
				_debugger.vcr.updateRuntime(_step);
		}
		else
			HxlG.updateInput();
		if(_recording)
		{
			_replay.recordFrame();
			if(_debugger != null)
				_debugger.vcr.updateRuntime(_step);
		}
		update();
		HxlG.mouse.wheel = 0;
		if(_debuggerUp)
			_debugger.perf.activeObjects(HxlBasic._ACTIVECOUNT);
	}

	/**
	 * This function just updates the soundtray object.
	 */
	private function updateSoundTray(MS:Float):Void
	{
		//animate stupid sound tray thing
		
		if(_soundTray != null)
		{
			if(_soundTrayTimer > 0)
				_soundTrayTimer -= MS/1000;
			else if(_soundTray.y > -_soundTray.height)
			{
				_soundTray.y -= (MS/1000)*HxlG.height*2;
				if(_soundTray.y <= -_soundTray.height)
				{
					_soundTray.visible = false;
					
					//Save sound preferences
					var soundPrefs:HxlSave = new HxlSave();
					if(soundPrefs.bind("flixel"))
					{
						if(soundPrefs.data.sound == null)
							soundPrefs.data.sound = {};
						soundPrefs.data.sound.mute = HxlG.mute;
						soundPrefs.data.sound.volume = HxlG.volume;
						soundPrefs.close();
					}
				}
			}
		}
	}
	
	/**
	 * This function is called by step() and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	private function update():Void
	{			
		var mark:UInt = Lib.getTimer();
		
		HxlG.elapsed = HxlG.timeScale*(_step/1000);
		HxlG.updateSounds();
		HxlG.updatePlugins();
		_state.update();
		HxlG.updateCameras();
		
		if(_debuggerUp)
			_debugger.perf.flixelUpdate(Lib.getTimer()-mark);
	}
	
	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	private function draw():Void
	{
		var mark:UInt = Lib.getTimer();
		HxlG.lockCameras();
		_state.draw();
		HxlG.drawPlugins();
		HxlG.unlockCameras();
		if(_debuggerUp)
			_debugger.perf.flixelDraw(Lib.getTimer()-mark);
	}
	
	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 * 
	 * @param	FlashEvent	Just a Flash system event, not too important for our purposes.
	 */
	private function create(FlashEvent:Event):Void
	{
		if(root == null)
			return;
		removeEventListener(Event.ENTER_FRAME, create);
		_total = Lib.getTimer();
		
		//Set up the view window and double buffering
		stage.scaleMode = StageScaleMode.NO_SCALE;
           stage.align = StageAlign.TOP_LEFT;
           stage.frameRate = _flashFramerate;
		
		//Add basic input event listeners and mouse container
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		addChild(_mouse);
		
		//Let mobile devs opt out of unnecessary overlays.
		if(!HxlG.mobile)
		{
			//Debugger overlay
			if(HxlG.debug || forceDebugger)
			{
				_debugger = new HxlDebugger(HxlG.width*HxlCamera.defaultZoom,HxlG.height*HxlCamera.defaultZoom);
				addChild(_debugger);
			}
			
			//Volume display tab
			createSoundTray();
			
			//Focus gained/lost monitoring
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			createFocusScreen();
		}
		
		//Finally, set up an event for the actual game loop stuff.
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	private function createSoundTray():Void
	{
		_soundTray.visible = false;
		_soundTray.scaleX = 2;
		_soundTray.scaleY = 2;
		var tmp:Bitmap = new Bitmap(new BitmapData(80,30,true,0x7F000000));
		_soundTray.x = (HxlG.width/2)*HxlCamera.defaultZoom-(tmp.width/2)*_soundTray.scaleX;
		_soundTray.addChild(tmp);
		
		var text:TextField = new TextField();
		text.width = tmp.width;
		text.height = tmp.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		text.defaultTextFormat = new TextFormat("system",8,0xffffff,false,false,false,"","","center", 0, 0, 0, 0);
		_soundTray.addChild(text);
		text.text = "VOLUME";
		text.y = 16;
		
		var bx:UInt = 10;
		var by:UInt = 14;
		_soundTrayBars = new Array();
		var i:UInt = 0;
		while(i < 10)
		{
			tmp = new Bitmap(new BitmapData(4,++i,false,0xffffff));
			tmp.x = bx;
			tmp.y = by;
			_soundTrayBars.push(_soundTray.addChild(tmp));
			bx += 6;
			by--;
		}
		
		_soundTray.y = -_soundTray.height;
		_soundTray.visible = false;
		addChild(_soundTray);
		
		//load saved sound preferences for this game if they exist
		var soundPrefs:HxlSave = new HxlSave();
		if(soundPrefs.bind("flixel") && (soundPrefs.data.sound != null))
		{
			if(soundPrefs.data.sound.volume != null)
				HxlG.volume = soundPrefs.data.sound.volume;
			if(soundPrefs.data.sound.mute != null)
				HxlG.mute = soundPrefs.data.sound.mute;
			soundPrefs.destroy();
		}
	}
	
	/**
	 * Sets up the darkened overlay with the big white "play" button that appears when a flixel game loses focus.
	 */
	private function createFocusScreen():Void
	{
		var gfx:Graphics = _focus.graphics;
		var screenWidth:Float = HxlG.width*HxlCamera.defaultZoom;
		var screenHeight:Float = HxlG.height*HxlCamera.defaultZoom;
		
		//draw transparent black backdrop
		gfx.moveTo(0,0);
		gfx.beginFill(0,0.5);
		gfx.lineTo(screenWidth,0);
		gfx.lineTo(screenWidth,screenHeight);
		gfx.lineTo(0,screenHeight);
		gfx.lineTo(0,0);
		gfx.endFill();
		
		//draw white arrow
		var halfWidth:Float = screenWidth/2;
		var halfHeight:Float = screenHeight/2;
		var helper:Float = HxlU.min(halfWidth,halfHeight)/3;
		gfx.moveTo(halfWidth-helper,halfHeight-helper);
		gfx.beginFill(0xffffff,0.65);
		gfx.lineTo(halfWidth+helper,halfHeight);
		gfx.lineTo(halfWidth-helper,halfHeight+helper);
		gfx.lineTo(halfWidth-helper,halfHeight-helper);
		gfx.endFill();
		
		var logo:Bitmap = new ImgLogo();
		logo.scaleX = Std.parseInt(helper/10);
		if(logo.scaleX < 1)
			logo.scaleX = 1;
		logo.scaleY = logo.scaleX;
		logo.x -= logo.scaleX;
		logo.alpha = 0.35;
		_focus.addChild(logo);

		addChild(_focus);
	}
}