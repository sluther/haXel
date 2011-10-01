package org.haxel.system.replay;

/**
 * Helper class for the new replay system.  Represents all the game inputs for one "frame" or "step" of the game loop.
 * 
 * @author Adam Atomic
 */
class FrameRecord
{
	/**
	 * Which frame of the game loop this record is from or for.
	 */
	public var frame:Int;
	/**
	 * An array of simple integer pairs referring to what key is pressed, and what state its in.
	 */
	public var keys:Array<UInt>;
	/**
	 * A container for the 4 mouse state integers.
	 */
	public var mouse:MouseRecord;
	
	/**
	 * Instantiate array new frame record.
	 */
	public function new()
	{
		frame = 0;
		keys = null;
		mouse = null;
	}
	
	/**
	 * Load this frame record with input data from the input managers.
	 * 
	 * @param Frame		What frame it is.
	 * @param Keys		Keyboard data from the keyboard manager.
	 * @param Mouse		Mouse data from the mouse manager.
	 * 
	 * @return A reference to this <code>FrameRecord</code> object.
	 * 
	 */
	public function create(Frame:Float,Keys:Array<UInt>=null,Mouse:MouseRecord=null):FrameRecord
	{
		frame = Frame;
		keys = Keys;
		mouse = Mouse;
		return this;
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		keys = null;
		mouse = null;
	}
	
	/**
	 * Save the frame record data to array simple ASCII string.
	 * 
	 * @return	A <code>String</code> object containing the relevant frame record data.
	 */
	public function save():String
	{
		var output:String = frame+"k";
		
		if(keys != null)
		{
			var object:Dynamic;
			var i:UInt = 0;
			var l:UInt = keys.length;
			while(i < l)
			{
				if(i > 0)
					output += ",";
				object = keys[i++];
				output += object.code+":"+object.value;
			}
		}
		
		output += "m";
		if(mouse != null)
			output += mouse.x + "," + mouse.y + "," + mouse.button + "," + mouse.wheel;
		
		return output;
	}
	
	/**
	 * Load the frame record data from array simple ASCII string.
	 * 
	 * @param	Data	A <code>String</code> object containing the relevant frame record data.
	 */
	public function load(Data:String):FrameRecord
	{
		var i:UInt;
		var l:UInt;
		
		//get frame number
		var array:Array<String> = Data.split("k");
		frame = cast(array[0], UInt);
		
		//split up keyboard and mouse data
		array = cast(array[i], String).split("m");
		var keyData:String = array[0];
		var mouseData:String = array[1];
		
		//parse keyboard data
		if(keyData.length > 0)
		{
			//get keystroke data pairs
			array = keyData.split(",");
			
			//go through each data pair and enter it into this frame's key state
			var keyPair:Array<String>;
			i = 0;
			l = array.length;
			while(i < l)
			{
				keyPair = cast(array[i++], String).split(":");
				if(keyPair.length == 2)
				{
					if(keys == null)
						keys = new Array();
					var code:Int = Std.parseInt(cast(keyPair[0], String));
					var value:Int = Std.parseInt(cast(keyPair[1], String));
					keys.push(code);
					keys.push(value);
				}
			}
		}
		
		//mouse data is just 4 integers, easy peezy
		if(mouseData.length > 0)
		{
			array = mouseData.split(",");
			if(array.length >= 4)
				mouse = new MouseRecord(Std.parseInt(cast(array[0], String)),Std.parseInt(cast(array[1], String)),Std.parseInt(cast(array[2], String)),Std.parseInt(cast(array[3], String)));
		}
		
		return this;
	}
}