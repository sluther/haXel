package org.haxel.system.debug;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import org.haxel.system.HxlWindow;

	/**
	 * A simple trace output window for use in the debugger overlay.
	 * 
	 * @author Adam Atomic
	 */
	class Log extends HxlWindow
	{
		private static inline var MAX_LOG_LINES:UInt = 200;

		private var _text:TextField;
		private var _lines:Array;
		
		/**
		 * Creates a new window object.  This Flash-based class is mainly (only?) used by <code>HxlDebugger</code>.
		 * 
		 * @param Title			The name of the window, displayed in the header bar.
		 * @param Width			The initial width of the window.
		 * @param Height		The initial height of the window.
		 * @param Resizable		Whether you can change the size of the window with a drag handle.
		 * @param Bounds		A rectangle indicating the valid screen area for the window.
		 * @param BGColor		What color the window background should be, default is gray and transparent.
		 * @param TopColor		What color the window header bar should be, default is black and transparent.
		 */	
		public function new(Title:String, Width:Float, Height:Float, Resizable:Bool=true, Bounds:Rectangle=null, BGColor:UInt=0x7f7f7f7f, TopColor:UInt=0x7f000000)
		{
			super(Title, Width, Height, Resizable, Bounds, BGColor, TopColor);
			
			_text = new TextField();
			_text.x = 2;
			_text.y = 15;
			_text.multiline = true;
			_text.wordWrap = true;
			_text.selectable = true;
			_text.defaultTextFormat = new TextFormat("Courier",12,0xffffff);
			addChild(_text);
			
			_lines = new Array();
		}
		
		/**
		 * Clean up memory.
		 */
		override public function destroy():Void
		{
			removeChild(_text);
			_text = null;
			_lines = null;
			super.destroy();
		}
		
		/**
		 * Adds a new line to the log window.
		 * 
		 * @param Text		The line you want to add to the log window.
		 */
		public function add(Text:String):Void
		{
			if(_lines.length <= 0)
				_text.text = "";
			_lines.push(Text);
			if(_lines.length > MAX_LOG_LINES)
			{
				_lines.shift();
				var newText:String = "";
				for(var i:UInt = 0; i < _lines.length; i++)
					newText += _lines[i]+"\n";
				_text.text = newText;
			}
			else
				_text.appendText(Text+"\n");
			_text.scrollV = _text.height;
		}
		
		/**
		 * Adjusts the width and height of the text field accordingly.
		 */
		override private function updateSize():Void
		{
			super.updateSize();
			
			_text.width = _width-10;
			_text.height = _height-15;
		}
	}
}