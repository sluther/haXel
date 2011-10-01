package org.haxel;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.Stage;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.Sound;

import org.haxel.plugin.DebugPathDisplay;
import org.haxel.plugin.TimerManager;
import org.haxel.system.HxlDebugger;
import org.haxel.system.HxlQuadTree;
import org.haxel.system.input.Input;
import org.haxel.system.input.Keyboard;
import org.haxel.system.input.Mouse;

/**
 * This is a global helper class full of useful functions for audio,
 * input, basic info, and the camera system among other things.
 * Utilities for maths and color and things can be found in <code>HxlU</code>.
 * <code>HxlG</code> is specifically for Haxel-specific properties.
 * 
 * @author	Adam Atomic
 */
class HxlG
{
	/**
	 * If you build and maintain your own version of flixel,
	 * you can give it your own name here.
	 */
	public static var LIBRARY_NAME:String = "haxel";
	/**
	 * Assign a major version to your library.
	 * Appears before the decimal in the console.
	 */
	public static var LIBRARY_MAJOR_VERSION:UInt = 2;
	/**
	 * Assign a minor version to your library.
	 * Appears after the decimal in the console.
	 */
	public static var LIBRARY_MINOR_VERSION:UInt = 55;
	
	/**
	 * Debugger overlay layout preset: Wide but low windows at the bottom of the screen.
	 */
	public static inline var DEBUGGER_STANDARD:UInt = 0;
	/**
	 * Debugger overlay layout preset: Tiny windows in the screen corners.
	 */
	public static inline var DEBUGGER_MICRO:UInt = 1;
	/**
	 * Debugger overlay layout preset: Large windows taking up bottom half of screen.
	 */
	public static inline var DEBUGGER_BIG:UInt = 2;
	/**
	 * Debugger overlay layout preset: Wide but low windows at the top of the screen.
	 */
	public static inline var DEBUGGER_TOP:UInt = 3;
	/**
	 * Debugger overlay layout preset: Large windows taking up left third of screen.
	 */
	public static inline var DEBUGGER_LEFT:UInt = 4;
	/**
	 * Debugger overlay layout preset: Large windows taking up right third of screen.
	 */
	public static inline var DEBUGGER_RIGHT:UInt = 5;
	
	/**
	 * Some handy color presets.  Less glaring than pure RGB full values.
	 * Primarily used in the visual debugger mode for bounding box displays.
	 * Red is used to indicate an active, movable, solid object.
	 */
	public static inline var RED:UInt = 0xffff0012;
	/**
	 * Green is used to indicate solid but immovable objects.
	 */
	public static inline var GREEN:UInt = 0xff00f225;
	/**
	 * Blue is used to indicate non-solid objects.
	 */
	public static inline var BLUE:UInt = 0xff0090e9;
	/**
	 * Pink is used to indicate objects that are only partially solid, like one-way platforms.
	 */
	public static inline var PINK:UInt = 0xfff01eff;
	/**
	 * White... for white stuff.
	 */
	public static inline var WHITE:UInt = 0xffffffff;
	/**
	 * And black too.
	 */
	public static inline var BLACK:UInt = 0xff000000;

	/**
	 * Internal tracker for game object.
	 */
	public static var _game:HxlGame;
	/**
	 * Handy shared variable for implementing your own pause behavior.
	 */
	public static var paused:Bool;
	/**
	 * Whether you are running in Debug or Release mode.
	 * Set automatically by <code>HxlPreloader</code> during startup.
	 */
	public static var debug:Bool;
	
	/**
	 * Represents the amount of time in seconds that passed since last frame.
	 */
	public static var elapsed:Float;
	/**
	 * How fast or slow time should pass in the game; default is 1.0.
	 */
	public static var timeScale:Float;
	/**
	 * The width of the screen in game pixels.
	 */
	public static var width:UInt;
	/**
	 * The height of the screen in game pixels.
	 */
	public static var height:UInt;
	/**
	 * The dimensions of the game world, used by the quad tree for collisions and overlap checks.
	 */
	public static var worldBounds:HxlRect;
	/**
	 * How many times the quad tree should divide the world on each axis.
	 * Generally, sparse collisions can have fewer divisons,
	 * while denser collision activity usually profits from more.
	 * Default value is 6.
	 */
	public static var worldDivisions:UInt;
	/**
	 * Whether to show visual debug displays or not.
	 * Default = false.
	 */
	public static var visualDebug:Bool;
	/**
	 * Setting this to true will disable/skip stuff that isn't necessary for mobile platforms like Android. [BETA]
	 */
	public static var mobile:Bool; 
	/**
	 * The global random number generator seed (for deterministic behavior in recordings and saves).
	 */
	public static var globalSeed:Float;
	/**
	 * <code>HxlG.levels</code> and <code>HxlG.scores</code> are generic
	 * global variables that can be used for various cross-state stuff.
	 */
	public static var levels:Array<Int>;
	public static var level:Int;
	public static var scores:Array<Int>;
	public static var score:Int;
	/**
	 * <code>HxlG.saves</code> is a generic bucket for storing
	 * HxlSaves so you can access them whenever you want.
	 */
	public static var saves:Array<Int>; 
	public static var save:Int;

	/**
	 * A reference to a <code>HxlMouse</code> object.  Important for input!
	 */
	public static var mouse:Mouse;
	/**
	 * A reference to a <code>HxlKeyboard</code> object.  Important for input!
	 */
	public static var keys:Keyboard;
	
	/**
	 * A handy container for a background music object.
	 */
	public static var music:HxlSound;
	/**
	 * A list of all the sounds being played in the game.
	 */
	public static var sounds:HxlGroup;
	/**
	 * Whether or not the game sounds are muted.
	 */
	public static var mute:Bool;
	/**
	 * Internal volume level, used for global sound control.
	 */
	private static var _volume:Float;

	/**
	 * An array of <code>HxlCamera</code> objects that are used to draw stuff.
	 * By default flixel creates one camera the size of the screen.
	 */
	public static var cameras:Array<HxlCamera>;
	/**
	 * By default this just refers to the first entry in the cameras array
	 * declared above, but you can do what you like with it.
	 */
	public static var camera:HxlCamera;
	/**
	 * Allows you to possibly slightly optimize the rendering process IF
	 * you are not doing any pre-processing in your game state's <code>draw()</code> call.
	 * @default false
	 */
	public static var useBufferLocking:Bool;
	/**
	 * Internal helper variable for clearing the cameras each frame.
	 */
	private static var _cameraRect:Rectangle;
	
	/**
	 * An array container for plugins.
	 * By default flixel uses a couple of plugins:
	 * DebugPathDisplay, and TimerManager.
	 */
	 public static var plugins:Array<HxlBasic>;
	 
	/**
	 * Set this hook to get a callback whenever the volume changes.
	 * Function should take the form <code>myVolumeHandler(Volume:Float)</code>.
	 */
	public static var volumeHandler:Dynamic;
	
	/**
	 * Useful helper objects for doing Flash-specific rendering.
	 * Primarily used for "debug visuals" like drawing bounding boxes directly to the screen buffer.
	 */
	public static var flashGfxSprite:Sprite;
	public static var flashGfx:Graphics;

	/**
	 * Internal storage system to prevent graphics from being used repeatedly in memory.
	 */
	private static var _cache:Dynamic;

	public static function getLibraryName():String
	{
		return HxlG.LIBRARY_NAME + " v" + HxlG.LIBRARY_MAJOR_VERSION + "." + HxlG.LIBRARY_MINOR_VERSION;
	}
	
	/**
	 * Log data to the debugger.
	 * 
	 * @param	Data		Anything you want to log to the console.
	 */
	public static function log(Data:Dynamic):Void
	{
		if((_game != null) && (_game._debugger != null))
			_game._debugger.log.add((Data == null)?"ERROR: null object":Data.toString());
	}
	
	/**
	 * Add a variable to the watch list in the debugger.
	 * This lets you see the value of the variable all the time.
	 * 
	 * @param	AnyObject		A reference to any object in your game, e.g. Player or Robot or this.
	 * @param	VariableName	The name of the variable you want to watch, in quotes, as a string: e.g. "speed" or "health".
	 * @param	DisplayName		Optional, display your own string instead of the class name + variable name: e.g. "enemy count".
	 */
	public static function watch(AnyObject:Dynamic,VariableName:String,DisplayName:String=null):Void
	{
		if((_game != null) && (_game._debugger != null))
			_game._debugger.watch.add(AnyObject,VariableName,DisplayName);
	}
	
	/**
	 * Remove a variable from the watch list in the debugger.
	 * Don't pass a Variable Name to remove all watched variables for the specified object.
	 * 
	 * @param	AnyObject		A reference to any object in your game, e.g. Player or Robot or this.
	 * @param	VariableName	The name of the variable you want to watch, in quotes, as a string: e.g. "speed" or "health".
	 */
	public static function unwatch(AnyObject:Dynamic,VariableName:String=null):Void
	{
		if((_game != null) && (_game._debugger != null))
			_game._debugger.watch.remove(AnyObject,VariableName);
	}
	
	/**
	 * How many times you want your game to update each second.
	 * More updates usually means better collisions and smoother motion.
	 * NOTE: This is NOT the same thing as the Flash Player framerate!
	 */
	public static var framerate(getFramerate, setFramerate):Float;
	public static function getFramerate():Float
	{
		return 1000/_game._step;
	}
	
	/**
	 * @private
	 */
	public static function setFramerate(Framerate:Float):Float
	{
		_game._step = 1000/Framerate;
		if(_game._maxAccumulation < _game._step)
			_game._maxAccumulation = _game._step;
	}
	
	/**
	 * How many times you want your game to update each second.
	 * More updates usually means better collisions and smoother motion.
	 * NOTE: This is NOT the same thing as the Flash Player framerate!
	 */
	public static var flashFramerate(getFlashFramerate, setFlashFramerate):Float;
	public static function getFlashFramerate():Float
	{
		if(_game.root != null)
			return _game.stage.frameRate;
		else
			return 0;
	}
	
	/**
	 * @private
	 */
	public static function setFlashFramerate(Framerate:Float):Float
	{
		_game._flashFramerate = Framerate;
		if(_game.root != null)
			_game.stage.frameRate = _game._flashFramerate;
		_game._maxAccumulation = 2000/_game._flashFramerate - 1;
		if(_game._maxAccumulation < _game._step)
			_game._maxAccumulation = _game._step;
	}
	
	/**
	 * Generates a random number.  Deterministic, meaning safe
	 * to use if you want to record replays in random environments.
	 * 
	 * @return	A <code>Number</code> between 0 and 1.
	 */
	public static function random():Float
	{
		return globalSeed = HxlU.srand(globalSeed);
	}
	
	/**
	 * Shuffles the entries in an array into a new random order.
	 * <code>HxlG.shuffle()</code> is deterministic and safe for use with replays/recordings.
	 * HOWEVER, <code>HxlU.shuffle()</code> is NOT deterministic and unsafe for use with replays/recordings.
	 * 
	 * @param	A				A Flash <code>Array</code> object containing...stuff.
	 * @param	HowManyTimes	How many swaps to perform during the shuffle operation.  Good rule of thumb is 2-4 times as many objects are in the list.
	 * 
	 * @return	The same Flash <code>Array</code> object that you passed in in the first place.
	 */
	public static function shuffle(Objects:Array<Dynamic>,HowManyTimes:UInt):Array<Dynamic>
	{
		var i:UInt = 0;
		var index1:UInt;
		var index2:UInt;
		var object:{};
		while(i < HowManyTimes)
		{
			index1 = HxlG.random()*Objects.length;
			index2 = HxlG.random()*Objects.length;
			object = Objects[index2];
			Objects[index2] = Objects[index1];
			Objects[index1] = object;
			i++;
		}
		return Objects;
	}
	
	/**
	 * Fetch a random entry from the given array.
	 * Will return null if random selection is missing, or array has no entries.
	 * <code>HxlG.getRandom()</code> is deterministic and safe for use with replays/recordings.
	 * HOWEVER, <code>HxlU.getRandom()</code> is NOT deterministic and unsafe for use with replays/recordings.
	 * 
	 * @param	Objects		A Flash array of objects.
	 * @param	StartIndex	Optional offset off the front of the array. Default value is 0, or the beginning of the array.
	 * @param	Length		Optional restriction on the number of values you want to randomly select from.
	 * 
	 * @return	The random object that was selected.
	 */
	public static function getRandom(Objects:Array<Dynamic>,StartIndex:UInt=0,Length:UInt=0):Dynamic
	{
		if(Objects != null)
		{
			var l:UInt = Length;
			if((l == 0) || (l > Objects.length - StartIndex))
				l = Objects.length - StartIndex;
			if(l > 0)
				return Objects[StartIndex + uint(HxlG.random()*l)];
		}
		return null;
	}
	
	/**
	 * Load replay data from a string and play it back.
	 * 
	 * @param	Data		The replay that you want to load.
	 * @param	State		Optional parameter: if you recorded a state-specific demo or cutscene, pass a new instance of that state here.
	 * @param	CancelKeys	Optional parameter: an array of string names of keys (see HxlKeyboard) that can be pressed to cancel the playback, e.g. ["ESCAPE","ENTER"].  Also accepts 2 custom key names: "ANY" and "MOUSE" (fairly self-explanatory I hope!).
	 * @param	Timeout		Optional parameter: set a time limit for the replay.  CancelKeys will override this if pressed.
	 * @param	Callback	Optional parameter: if set, called when the replay finishes.  Running to the end, CancelKeys, and Timeout will all trigger Callback(), but only once, and CancelKeys and Timeout will NOT call HxlG.stopReplay() if Callback is set!
	 */
	public static function loadReplay(Data:String,State:HxlState=null,CancelKeys:Array<UInt>=null,Timeout:Int=0,Callback:Dynamic=null):Void
	{
		_game._replay.load(Data);
		if(State == null)
			HxlG.resetGame();
		else
			HxlG.switchState(State);
		_game._replayCancelKeys = CancelKeys;
		_game._replayTimer = Timeout*1000;
		_game._replayCallback = Callback;
		_game._replayRequested = true;
	}
	
	/**
	 * Resets the game or state and replay requested flag.
	 * 
	 * @param	StandardMode	If true, reload entire game, else just reload current game state.
	 */
	public static function reloadReplay(StandardMode:Bool=true):Void
	{
		if(StandardMode)
			HxlG.resetGame();
		else
			HxlG.resetState();
		if(_game._replay.frameCount > 0)
			_game._replayRequested = true;
	}
	
	/**
	 * Stops the current replay.
	 */
	public static function stopReplay():Void
	{
		_game._replaying = false;
		if(_game._debugger != null)
			_game._debugger.vcr.stopped();
		resetInput();
	}
	
	/**
	 * Resets the game or state and requests a new recording.
	 * 
	 * @param	StandardMode	If true, reset the entire game, else just reset the current state.
	 */
	public static function recordReplay(StandardMode:Bool=true):Void
	{
		if(StandardMode)
			HxlG.resetGame();
		else
			HxlG.resetState();
		_game._recordingRequested = true;
	}
	
	/**
	 * Stop recording the current replay and return the replay data.
	 * 
	 * @return	The replay data in simple ASCII format (see <code>HxlReplay.save()</code>).
	 */
	public static function stopRecording():String
	{
		_game._recording = false;
		if(_game._debugger != null)
			_game._debugger.vcr.stopped();
		return _game._replay.save();
	}
	
	/**
	 * Request a reset of the current game state.
	 */
	public static function resetState():Void
	{
		_game._requestedState = Type.createInstance(HxlU.getClass(HxlU.getClassName(_game._state,false)), []);
	}
	
	/**
	 * Like hitting the reset button on a game console, this will re-launch the game as if it just started.
	 */
	public static function resetGame():Void
	{
		_game._requestedReset = true;
	}
	
	/**
	 * Reset the input helper objects (useful when changing screens or states)
	 */
	public static function resetInput():Void
	{
		keys.reset();
		mouse.reset();
	}
	
	/**
	 * Set up and play a looping background soundtrack.
	 * 
	 * @param	Music		The sound file you want to loop in the background.
	 * @param	Volume		How loud the sound should be, from 0 to 1.
	 */
	public static function playMusic(Music:Class<Sound>,Volume:Float=1.0):Void
	{
		if(music == null)
			music = new HxlSound();
		else if(music.active)
			music.stop();
		music.loadEmbedded(Music,true);
		music.volume = Volume;
		music.survive = true;
		music.play();
	}
	
	/**
	 * Creates a new sound object.
	 * 
	 * @param	EmbeddedSound	The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
	 * @param	Volume			How loud to play it (0 to 1).
	 * @param	Looped			Whether to loop this sound.
	 * @param	AutoDestroy		Whether to destroy this sound when it finishes playing.  Leave this value set to "false" if you want to re-use this <code>HxlSound</code> instance.
	 * @param	AutoPlay		Whether to play the sound.
	 * @param	URL				Load a sound from an external web resource instead.  Only used if EmbeddedSound = null.
	 * 
	 * @return	A <code>HxlSound</code> object.
	 */
	public static function loadSound(EmbeddedSound:Class<Sound>=null,Volume:Float=1.0,Looped:Bool=false,AutoDestroy:Bool=false,AutoPlay:Bool=false,URL:String=null):HxlSound
	{
		if((EmbeddedSound == null) && (URL == null))
		{
			HxlG.log("WARNING: HxlG.loadSound() requires either\nan embedded sound or a URL to work.");
			return null;
		}
		var sound:HxlSound = cast(sounds.recycle(HxlSound), HxlSound);
		if(EmbeddedSound != null)
			sound.loadEmbedded(EmbeddedSound,Looped,AutoDestroy);
		else
			sound.loadStream(URL,Looped,AutoDestroy);
		sound.volume = Volume;
		if(AutoPlay)
			sound.play();
		return sound;
	}
	
	/**
	 * Creates a new sound object from an embedded <code>Class</code> object.
	 * NOTE: Just calls HxlG.loadSound() with AutoPlay == true.
	 * 
	 * @param	EmbeddedSound	The sound you want to play.
	 * @param	Volume			How loud to play it (0 to 1).
	 * @param	Looped			Whether to loop this sound.
	 * @param	AutoDestroy		Whether to destroy this sound when it finishes playing.  Leave this value set to "false" if you want to re-use this <code>HxlSound</code> instance.
	 * 
	 * @return	A <code>HxlSound</code> object.
	 */
	public static function play(EmbeddedSound:Class<Sound>,Volume:Float=1.0,Looped:Bool=false,AutoDestroy:Bool=true):HxlSound
	{
		return HxlG.loadSound(EmbeddedSound,Volume,Looped,AutoDestroy,true);
	}
	
	/**
	 * Creates a new sound object from a URL.
	 * NOTE: Just calls HxlG.loadSound() with AutoPlay == true.
	 * 
	 * @param	URL		The URL of the sound you want to play.
	 * @param	Volume	How loud to play it (0 to 1).
	 * @param	Looped	Whether or not to loop this sound.
	 * @param	AutoDestroy		Whether to destroy this sound when it finishes playing.  Leave this value set to "false" if you want to re-use this <code>HxlSound</code> instance.
	 * 
	 * @return	A HxlSound object.
	 */
	public static function stream(URL:String,Volume:Float=1.0,Looped:Bool=false,AutoDestroy:Bool=true):HxlSound
	{
		return HxlG.loadSound(null,Volume,Looped,AutoDestroy,true,URL);
	}
	
	/**
	 * Set <code>volume</code> to a number between 0 and 1 to change the global volume.
	 * 
	 * @default 0.5
	 */
	 public static var volume(getVolume, setVolume):Float;
	 public static function getVolume():Float
	 {
		 return _volume;
	 }
	 
	/**
	 * @private
	 */
	public static function setVolume(Volume:Float):Float
	{
		_volume = Volume;
		if(_volume < 0)
			_volume = 0;
		else if(_volume > 1)
			_volume = 1;
		if(volumeHandler != null)
			volumeHandler(HxlG.mute?0:_volume);
	}

	/**
	 * Called by HxlGame on state changes to stop and destroy sounds.
	 * 
	 * @param	ForceDestroy		Kill sounds even if they're flagged <code>survive</code>.
	 */
	public static function destroySounds(ForceDestroy:Bool=false):Void
	{
		if((music != null) && (ForceDestroy || !music.survive))
		{
			music.destroy();
			music = null;
		}
		var i:UInt = 0;
		var sound:HxlSound;
		var l:UInt = sounds.members.length;
		while(i < l)
		{
			sound = HxlSound<sounds.members[i++]> cast HxlSound;
			if((sound != null) && (ForceDestroy || !sound.survive))
				sound.destroy();
		}
	}
	
	/**
	 * Called by the game loop to make sure the sounds get updated each frame.
	 */
	public static function updateSounds():Void
	{
		if((music != null) && music.active)
			music.update();
		if((sounds != null) && sounds.active)
			sounds.update();
	}
	
	/**
	 * Pause all sounds currently playing.
	 */
	public static function pauseSounds():Void
	{
		if((music != null) && music.exists && music.active)
			music.pause();
		var i:UInt = 0;
		var sound:HxlSound;
		var l:UInt = sounds.length;
		while(i < l)
		{
			sound = cast(sounds.members[i++], HxlSound);
			if((sound != null) && sound.exists && sound.active)
				sound.pause();
		}
	}
	
	/**
	 * Resume playing existing sounds.
	 */
	public static function resumeSounds():Void
	{
		if((music != null) && music.exists)
			music.play();
		var i:UInt = 0;
		var sound:HxlSound;
		var l:UInt = sounds.length;
		while(i < l)
		{
			sound = cast(sounds.members[i++], HxlSound);
			if((sound != null) && sound.exists)
				sound.resume();
		}
	}
	
	/**
	 * Check the local bitmap cache to see if a bitmap with this key has been loaded already.
	 *
	 * @param	Key		The string key identifying the bitmap.
	 * 
	 * @return	Whether or not this file can be found in the cache.
	 */
	public static function checkBitmapCache(Key:String):Bool
	{
		return (_cache[Key] != undefined) && (_cache[Key] != null);
	}
	
	/**
	 * Generates a new <code>BitmapData</code> object (a colored square) and caches it.
	 * 
	 * @param	Width	How wide the square should be.
	 * @param	Height	How high the square should be.
	 * @param	Color	What color the square should be (0xAARRGGBB)
	 * @param	Unique	Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key		Force the cache to use a specific Key to index the bitmap.
	 * 
	 * @return	The <code>BitmapData</code> we just created.
	 */
	public static function createBitmap(Width:UInt, Height:UInt, Color:UInt, Unique:Bool=false, Key:String=null):BitmapData
	{
		if(Key == null)
		{
			Key = Width+"x"+Height+":"+Color;
			if(Unique && checkBitmapCache(Key))
			{
				var inc:UInt = 0;
				var ukey:String;
				do
				{
					ukey = Key + inc++;
				} while(checkBitmapCache(ukey));
				Key = ukey;
			}
		}
		if(!checkBitmapCache(Key))
			_cache[Key] = new BitmapData(Width,Height,true,Color);
		return _cache[Key];
	}
	
	/**
	 * Loads a bitmap from a file, caches it, and generates a horizontally flipped version if necessary.
	 * 
	 * @param	Graphic		The image file that you want to load.
	 * @param	Reverse		Whether to generate a flipped version.
	 * @param	Unique		Ensures that the bitmap data uses a new slot in the cache.
	 * @param	Key			Force the cache to use a specific Key to index the bitmap.
	 * 
	 * @return	The <code>BitmapData</code> we just created.
	 */
	public static function addBitmap(Graphic:Class<Bitmap>, Reverse:Bool=false, Unique:Bool=false, Key:String=null):BitmapData
	{
		var needReverse:Bool = false;
		if(Key == null)
		{
			Key = String(Graphic)+(Reverse?"_REVERSE_":"");
			if(Unique && checkBitmapCache(Key))
			{
				var inc:UInt = 0;
				var ukey:String;
				do
				{
					ukey = Key + inc++;
				} while(checkBitmapCache(ukey));
				Key = ukey;
			}
		}
		
		//If there is no data for this key, generate the requested graphic
		if(!checkBitmapCache(Key))
		{
			_cache[Key] = (Type.createInstance(Graphic, [])).bitmapData;
			if(Reverse)
				needReverse = true;
		}
		var pixels:BitmapData = _cache[Key];
		if(!needReverse && Reverse && (pixels.width == (Type.createInstance(Graphic, [])).bitmapData.width))
			needReverse = true;
		if(needReverse)
		{
			var newPixels:BitmapData = new BitmapData(pixels.width<<1,pixels.height,true,0x00000000);
			newPixels.draw(pixels);
			var mtx:Matrix = new Matrix();
			mtx.scale(-1,1);
			mtx.translate(newPixels.width,0);
			newPixels.draw(pixels,mtx);
			pixels = newPixels;
			_cache[Key] = pixels;
		}
		return pixels;
	}
	
	/**
	 * Dumps the cache's image references.
	 */
	public static function clearBitmapCache():Void
	{
		_cache = {};
	}
	
	/**
	 * Read-only: retrieves the Flash stage object (required for event listeners)
	 * Will be null if it's not safe/useful yet.
	 */
	public var stage(getStage, setStage):Stage;
	public static function getStage():Stage
	{
		if(_game.root != null)
			return _game.stage;
		return null;
	}
	
	public static function setStage(stage:Stage):Stage {
		// This method is only here to please the haXe compiler,
		// as a setter is needed for every property that has a getter
	}
	
	/**
	 * Read-only: access the current game state from anywhere.
	 */
	public var state(getState, setState):HxlState;
	public static function getState():HxlState
	{
		return _game._state;
	}
	
	public static function setState(state:HxlState):HxlState {
		// This method is only here to please the haXe compiler,
		// as a setter is needed for every property that has a getter
	}
	
	/**
	 * Switch from the current game state to the one specified here.
	 */
	public static function switchState(State:HxlState):Void
	{
		_game._requestedState = State;
	}
	
	/**
	 * Change the way the debugger's windows are laid out.
	 * 
	 * @param	Layout		See the presets above (e.g. <code>DEBUGGER_MICRO</code>, etc).
	 */
	public static function setDebuggerLayout(Layout:UInt):Void
	{
		if(_game._debugger != null)
			_game._debugger.setLayout(Layout);
	}
	
	/**
	 * Just resets the debugger windows to whatever the last selected layout was (<code>DEBUGGER_STANDARD</code> by default).
	 */
	public static function resetDebuggerLayout():Void
	{
		if(_game._debugger != null)
			_game._debugger.resetLayout();
	}
	
	/**
	 * Add a new camera object to the game.
	 * Handy for PiP, split-screen, etc.
	 * 
	 * @param	NewCamera	The camera you want to add.
	 * 
	 * @return	This <code>HxlCamera</code> instance.
	 */
	public static function addCamera(NewCamera:HxlCamera):HxlCamera
	{
		HxlG._game.addChildAt(NewCamera._flashSprite,HxlG._game.getChildIndex(HxlG._game._mouse));
		HxlG.cameras.push(NewCamera);
		return NewCamera;
	}
	
	/**
	 * Remove a camera from the game.
	 * 
	 * @param	Camera	The camera you want to remove.
	 * @param	Destroy	Whether to call destroy() on the camera, default value is true.
	 */
	public static function removeCamera(Camera:HxlCamera,Destroy:Bool=true):Void
	{
		try
		{
			HxlG._game.removeChild(Camera._flashSprite);
		}
		catch(E:Error)
		{
			HxlG.log("Error removing camera, not part of game.");
		}
		if(Destroy)
			Camera.destroy();
	}
	
	/**
	 * Dumps all the current cameras and resets to just one camera.
	 * Handy for doing split-screen especially.
	 * 
	 * @param	NewCamera	Optional; specify a specific camera object to be the new main camera.
	 */
	public static function resetCameras(NewCamera:HxlCamera=null):Void
	{
		var cam:HxlCamera;
		var i:UInt = 0;
		var l:UInt = cameras.length;
		while(i < l)
		{
			cam = HxlCamera<HxlG.cameras[i++]> cast HxlCamera;
			HxlG._game.removeChild(cam._flashSprite);
			cam.destroy();
		}
		HxlG.cameras.length = 0;
		
		if(NewCamera == null)
			NewCamera = new HxlCamera(0,0,HxlG.width,HxlG.height);
		HxlG.camera = HxlG.addCamera(NewCamera);
	}
	
	/**
	 * All screens are filled with this color and gradually return to normal.
	 * 
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the flash to fade.
	 * @param	OnComplete	A function you want to run when the flash finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public static function flash(Color:UInt=0xffffffff, Duration:Float=1, OnComplete:Dynamic=null, Force:Bool=false):Void
	{
		var i:UInt = 0;
		var l:UInt = HxlG.cameras.length;
		while(i < l)
			cast(HxlG.cameras[i++], HxlCamera).flash(Color,Duration,OnComplete,Force);
	}
	
	/**
	 * The screen is gradually filled with this color.
	 * 
	 * @param	Color		The color you want to use.
	 * @param	Duration	How long it takes for the fade to finish.
	 * @param	OnComplete	A function you want to run when the fade finishes.
	 * @param	Force		Force the effect to reset.
	 */
	public static function fade(Color:UInt=0xff000000, Duration:Float=1, OnComplete:Dynamic=null, Force:Bool=false):Void
	{
		var i:UInt = 0;
		var l:UInt = HxlG.cameras.length;
		while(i < l)
			cast(HxlG.cameras[i++], HxlCamera).fade(Color,Duration,OnComplete,Force);
	}
	
	/**
	 * A simple screen-shake effect.
	 * 
	 * @param	Intensity	Percentage of screen size representing the maximum distance that the screen can move while shaking.
	 * @param	Duration	The length in seconds that the shaking effect should last.
	 * @param	OnComplete	A function you want to run when the shake effect finishes.
	 * @param	Force		Force the effect to reset (default = true, unlike flash() and fade()!).
	 * @param	Direction	Whether to shake on both axes, just up and down, or just side to side (use class constants SHAKE_BOTH_AXES, SHAKE_VERTICAL_ONLY, or SHAKE_HORIZONTAL_ONLY).  Default value is SHAKE_BOTH_AXES (0).
	 */
	public static function shake(Intensity:Float=0.05, Duration:Float=0.5, OnComplete:Dynamic=null, Force:Bool=true, Direction:UInt=0):Void
	{
		var i:UInt = 0;
		var l:UInt = HxlG.cameras.length;
		while(i < l)
			cast(HxlG.cameras[i++], HxlCamera).shake(Intensity,Duration,OnComplete,Force,Direction);
	}
	
	/**
	 * Get and set the background color of the game.
	 * Get functionality is equivalent to HxlG.camera.bgColor.
	 * Set functionality sets the background color of all the current cameras.
	 */
	public var bgColor(getBgColor, setBgColor):UInt;
	public static function getBgColor():UInt
	{
		if(HxlG.camera == null)
			return 0xff000000;
		else
			return HxlG.camera.bgColor;
	}
	
	public static function setBgColor(Color:UInt):Void
	{
		var i:UInt = 0;
		var l:UInt = HxlG.cameras.length;
		while(i < l)
			cast(HxlG.cameras[i++], HxlCamera).bgColor = Color;
	}

	/**
	 * Call this function to see if one <code>HxlObject</code> overlaps another.
	 * Can be called with one object and one group, or two groups, or two objects,
	 * whatever floats your boat! For maximum performance try bundling a lot of objects
	 * together using a <code>HxlGroup</code> (or even bundling groups together!).
	 * 
	 * <p>NOTE: does NOT take objects' scrollfactor into account, all overlaps are checked in world space.</p>
	 * 
	 * @param	ObjectOrGroup1	The first object or group you want to check.
	 * @param	ObjectOrGroup2	The second object or group you want to check.  If it is the same as the first, flixel knows to just do a comparison within that group.
	 * @param	NotifyCallback	A function with two <code>HxlObject</code> parameters - e.g. <code>myOverlapFunction(Object1:HxlObject,Object2:HxlObject)</code> - that is called if those two objects overlap.
	 * @param	ProcessCallback	A function with two <code>HxlObject</code> parameters - e.g. <code>myOverlapFunction(Object1:HxlObject,Object2:HxlObject)</code> - that is called if those two objects overlap.  If a ProcessCallback is provided, then NotifyCallback will only be called if ProcessCallback returns true for those objects!
	 * 
	 * @return	Whether any oevrlaps were detected.
	 */
	public static function overlap(ObjectOrGroup1:HxlBasic=null,ObjectOrGroup2:HxlBasic=null,NotifyCallback:Dynamic=null,ProcessCallback:Dynamic=null):Bool
	{
		if(ObjectOrGroup1 == null)
			ObjectOrGroup1 = HxlG.state;
		if(Std.is(ObjectOrGroup2, Type.getClass(ObjectOrGroup1)))
			ObjectOrGroup2 = null;
		HxlQuadTree.divisions = HxlG.worldDivisions;
		var quadTree:HxlQuadTree = new HxlQuadTree(HxlG.worldBounds.x,HxlG.worldBounds.y,HxlG.worldBounds.width,HxlG.worldBounds.height);
		quadTree.load(ObjectOrGroup1,ObjectOrGroup2,NotifyCallback,ProcessCallback);
		var result:Bool = quadTree.execute();
		quadTree.destroy();
		return result;
	}
	
	/**
	 * Call this function to see if one <code>HxlObject</code> collides with another.
	 * Can be called with one object and one group, or two groups, or two objects,
	 * whatever floats your boat! For maximum performance try bundling a lot of objects
	 * together using a <code>HxlGroup</code> (or even bundling groups together!).
	 * 
	 * <p>This function just calls HxlG.overlap and presets the ProcessCallback parameter to HxlObject.separate.
	 * To create your own collision logic, write your own ProcessCallback and use HxlG.overlap to set it up.</p>
	 * 
	 * <p>NOTE: does NOT take objects' scrollfactor into account, all overlaps are checked in world space.</p>
	 * 
	 * @param	ObjectOrGroup1	The first object or group you want to check.
	 * @param	ObjectOrGroup2	The second object or group you want to check.  If it is the same as the first, flixel knows to just do a comparison within that group.
	 * @param	NotifyCallback	A function with two <code>HxlObject</code> parameters - e.g. <code>myOverlapFunction(Object1:HxlObject,Object2:HxlObject)</code> - that is called if those two objects overlap.
	 * 
	 * @return	Whether any objects were successfully collided/separated.
	 */
	public static function collide(ObjectOrGroup1:HxlBasic=null, ObjectOrGroup2:HxlBasic=null, NotifyCallback:Dynamic=null):Bool
	{
		return overlap(ObjectOrGroup1,ObjectOrGroup2,NotifyCallback,HxlObject.separate);
	}
	
	/**
	 * Adds a new plugin to the global plugin array.
	 * 
	 * @param	Plugin	Any object that extends HxlBasic. Useful for managers and other things.  See org.haxel.plugin for some examples!
	 * 
	 * @return	The same <code>HxlBasic</code>-based plugin you passed in.
	 */
	public static function addPlugin(Plugin:HxlBasic):HxlBasic
	{
		//Don't add repeats
		var pluginList:Array<HxlBasic> = HxlG.plugins;
		var i:UInt = 0;
		var l:UInt = pluginList.length;
		while(i < l)
		{
			if(pluginList[i++].toString() == Plugin.toString())
				return Plugin;
		}
		
		//no repeats! safe to add a new instance of this plugin
		pluginList.push(Plugin);
		return Plugin;
	}
	
	/**
	 * Retrieves a plugin based on its class name from the global plugin array.
	 * 
	 * @param	ClassType	The class name of the plugin you want to retrieve. See the <code>HxlPath</code> or <code>HxlTimer</code> constructors for example usage.
	 * 
	 * @return	The plugin object, or null if no matching plugin was found.
	 */
	public static function getPlugin(ClassType:Class<HxlBasic>):HxlBasic
	{
		var pluginList:Array = HxlG.plugins;
		var i:UInt = 0;
		var l:UInt = pluginList.length;
		while(i < l)
		{
			if(Std.is(pluginList[i], ClassType))
				return plugins[i];
			i++;
		}
		return null;
	}
	
	/**
	 * Removes an instance of a plugin from the global plugin array.
	 * 
	 * @param	Plugin	The plugin instance you want to remove.
	 * 
	 * @return	The same <code>HxlBasic</code>-based plugin you passed in.
	 */
	public static function removePlugin(Plugin:HxlBasic):HxlBasic
	{
		//Don't add repeats
		var pluginList:Array<HxlBasic> = HxlG.plugins;
		var i:Int = pluginList.length-1;
		while(i >= 0)
		{
			if(pluginList[i] == Plugin)
				pluginList.splice(i,1);
			i--;
		}
		return Plugin;
	}
	
	/**
	 * Removes an instance of a plugin from the global plugin array.
	 * 
	 * @param	ClassType	The class name of the plugin type you want removed from the array.
	 * 
	 * @return	Whether or not at least one instance of this plugin type was removed.
	 */
	public static function removePluginType(ClassType:Class<Dynamic>):Bool
	{
		//Don't add repeats
		var results:Bool = false;
		var pluginList:Array<HxlBasic> = HxlG.plugins;
		var i:Int = pluginList.length-1;
		while(i >= 0)
		{
			if(Std.is(pluginList[i], ClassType))
			{
				pluginList.splice(i,1);
				results = true;
			}
			i--;
		}
		return results;
	}
	
	/**
	 * Called by <code>HxlGame</code> to set up <code>HxlG</code> during <code>HxlGame</code>'s constructor.
	 */
	public static function init(Game:HxlGame,Width:UInt,Height:UInt,Zoom:Float):Void
	{
		HxlG._game = Game;
		HxlG.width = Width;
		HxlG.height = Height;
		
		HxlG.mute = false;
		HxlG._volume = 0.5;
		HxlG.sounds = new HxlGroup();
		HxlG.volumeHandler = null;
		
		HxlG.clearBitmapCache();
		
		if(flashGfxSprite == null)
		{
			flashGfxSprite = new Sprite();
			flashGfx = flashGfxSprite.graphics;
		}

		HxlCamera.defaultZoom = Zoom;
		HxlG._cameraRect = new Rectangle();
		HxlG.cameras = new Array();
		useBufferLocking = false;
		
		plugins = new Array();
		addPlugin(new DebugPathDisplay());
		addPlugin(new TimerManager());
		
		HxlG.mouse = new Mouse(HxlG._game._mouse);
		HxlG.keys = new Keyboard();
		HxlG.mobile = false;

		HxlG.levels = new Array();
		HxlG.scores = new Array();
		HxlG.visualDebug = false;
	}
	
	/**
	 * Called whenever the game is reset, doesn't have to do quite as much work as the basic initialization stuff.
	 */
	public static function reset():Void
	{
		HxlG.clearBitmapCache();
		HxlG.resetInput();
		HxlG.destroySounds(true);
		HxlG.levels.length = 0;
		HxlG.scores.length = 0;
		HxlG.level = 0;
		HxlG.score = 0;
		HxlG.paused = false;
		HxlG.timeScale = 1.0;
		HxlG.elapsed = 0;
		HxlG.globalSeed = Math.random();
		HxlG.worldBounds = new HxlRect(-10,-10,HxlG.width+20,HxlG.height+20);
		HxlG.worldDivisions = 6;
		var debugPathDisplay:DebugPathDisplay = DebugPathDisplay<HxlG.getPlugin(DebugPathDisplay)> cast DebugPathDisplay;
		if(debugPathDisplay != null)
			debugPathDisplay.clear();
	}
	
	/**
	 * Called by the game object to update the keyboard and mouse input tracking objects.
	 */
	public static function updateInput():Void
	{
		HxlG.keys.update();
		if(!_game._debuggerUp || !_game._debugger.hasMouse)
			HxlG.mouse.update(HxlG._game.mouseX,HxlG._game.mouseY);
	}
	
	/**
	 * Called by the game object to lock all the camera buffers and clear them for the next draw pass.
	 */
	public static function lockCameras():Void
	{
		var cam:HxlCamera;
		var cams:Array = HxlG.cameras;
		var i:UInt = 0;
		var l:UInt = cams.length;
		while(i < l)
		{
			cam = HxlCamera<cams[i++]> cast HxlCamera;
			if((cam == null) || !cam.exists || !cam.visible)
				continue;
			if(useBufferLocking)
				cam.buffer.lock();
			cam.fill(cam.bgColor);
			cam.screen.dirty = true;
		}
	}
	
	/**
	 * Called by the game object to draw the special FX and unlock all the camera buffers.
	 */
	public static function unlockCameras():Void
	{
		var cam:HxlCamera;
		var cams:Array = HxlG.cameras;
		var i:UInt = 0;
		var l:UInt = cams.length;
		while(i < l)
		{
			cam = HxlCamera<cams[i++]> cast HxlCamera;
			if((cam == null) || !cam.exists || !cam.visible)
				continue;
			cam.drawFX();
			if(useBufferLocking)
				cam.buffer.unlock();
		}
	}
	
	/**
	 * Called by the game object to update the cameras and their tracking/special effects logic.
	 */
	public static function updateCameras():Void
	{
		var cam:HxlCamera;
		var cams:Array = HxlG.cameras;
		var i:UInt = 0;
		var l:UInt = cams.length;
		while(i < l)
		{
			cam = HxlCamera<cams[i++]> cast HxlCamera;
			if((cam != null) && cam.exists)
			{
				if(cam.active)
					cam.update();
				cam._flashSprite.x = cam.x + cam._flashOffsetX;
				cam._flashSprite.y = cam.y + cam._flashOffsetY;
				cam._flashSprite.visible = cam.visible;
			}
		}
	}
	
	/**
	 * Used by the game object to call <code>update()</code> on all the plugins.
	 */
	public static function updatePlugins():Void
	{
		var plugin:HxlBasic;
		var pluginList:Array = HxlG.plugins;
		var i:UInt = 0;
		var l:UInt = pluginList.length;
		while(i < l)
		{
			plugin = HxlBasic<pluginList[i++]> cast HxlBasic;
			if(plugin.exists && plugin.active)
				plugin.update();
		}
	}
	
	/**
	 * Used by the game object to call <code>draw()</code> on all the plugins.
	 */
	public static function drawPlugins():Void
	{
		var plugin:HxlBasic;
		var pluginList:Array = HxlG.plugins;
		var i:UInt = 0;
		var l:UInt = pluginList.length;
		while(i < l)
		{
			plugin = HxlBasic<pluginList[i++]> cast HxlBasic;
			if(plugin.exists && plugin.visible)
				plugin.draw();
		}
	}
}