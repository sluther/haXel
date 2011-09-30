package org.haxel.system;
/**
 * Just a helper structure for the HxlSprite animation system.
 * 
 * @author	Adam Atomic
 */
class HxlAnim
{
	/**
	 * String name of the animation (e.g. "walk")
	 */
	public var name:String;
	/**
	 * Seconds between frames (basically the framerate)
	 */
	public var delay:Float;
	/**
	 * A list of frames stored as <code>uint</code> objects
	 */
	public var frames:Array<UInt>;
	/**
	 * Whether or not the animation is looped
	 */
	public var looped:Bool;
	
	/**
	 * Constructor
	 * 
	 * @param	Name		What this animation should be called (e.g. "run")
	 * @param	Frames		An array of numbers indicating what frames to play in what order (e.g. 1, 2, 3)
	 * @param	FrameRate	The speed in frames per second that the animation should play at (e.g. 40)
	 * @param	Looped		Whether or not the animation is looped or just plays once
	 */
	public function new(Name:String, Frames:Array<UInt>, FrameRate:Float=0, Looped:Bool=true)
	{
		name = Name;
		delay = 0;
		if(FrameRate > 0)
			delay = 1.0/FrameRate;
		frames = Frames;
		looped = Looped;
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		frames = null;
	}
}