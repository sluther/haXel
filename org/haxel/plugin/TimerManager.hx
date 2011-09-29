package org.haxel.plugin;
	import org.haxel.HxlBasic;
	import org.haxel.HxlButton;
	import org.haxel.HxlCamera;
	import org.haxel.HxlEmitter;
	import org.haxel.HxlG;
	import org.haxel.HxlGame;
	import org.haxel.HxlGroup;
	import org.haxel.HxlObject;
	import org.haxel.HxlParticle;
	import org.haxel.HxlPath;
	import org.haxel.HxlPoint;
	import org.haxel.HxlRect;
	import org.haxel.HxlSave;
	import org.haxel.HxlSound;
	import org.haxel.HxlSprite;
	import org.haxel.HxlState;
	import org.haxel.HxlText;
	import org.haxel.HxlTileblock;
	import org.haxel.HxlTilemap;
	import org.haxel.HxlTimer;
	import org.haxel.HxlU;
	
	/**
	 * A simple manager for tracking and updating game timer objects.
	 * 
	 * @author	Adam Atomic
	 */
	class TimerManager extends HxlBasic
	{
		private var _timers:Array;
		
		/**
		 * Instantiates a new timer manager.
		 */
		public function new()
		{
			_timers = new Array();
			visible = false; //don't call draw on this plugin
		}
		
		/**
		 * Clean up memory.
		 */
		override public function destroy():Void
		{
			clear();
			_timers = null;
		}
		
		/**
		 * Called by <code>HxlG.updatePlugins()</code> before the game state has been updated.
		 * Cycles through timers and calls <code>update()</code> on each one.
		 */
		override public function update():Void
		{
			var i:Int = _timers.length-1;
			var timer:HxlTimer;
			while(i >= 0)
			{
				timer = _timers[i--] as HxlTimer;
				if((timer != null) && !timer.paused && !timer.finished && (timer.time > 0))
					timer.update();
			}
		}
		
		/**
		 * Add a new timer to the timer manager.
		 * Usually called automatically by <code>HxlTimer</code>'s constructor.
		 * 
		 * @param	Timer	The <code>HxlTimer</code> you want to add to the manager.
		 */
		public function add(Timer:HxlTimer):Void
		{
			_timers.push(Timer);
		}
		
		/**
		 * Remove a timer from the timer manager.
		 * Usually called automatically by <code>HxlTimer</code>'s <code>stop()</code> function.
		 * 
		 * @param	Timer	The <code>HxlTimer</code> you want to remove from the manager.
		 */
		public function remove(Timer:HxlTimer):Void
		{
			var index:Int = _timers.indexOf(Timer);
			if(index >= 0)
				_timers.splice(index,1);
		}
		
		/**
		 * Removes all the timers from the timer manager.
		 */
		public function clear():Void
		{
			var i:Int = _timers.length-1;
			var timer:HxlTimer;
			while(i >= 0)
			{
				timer = _timers[i--] as HxlTimer;
				if(timer != null)
					timer.destroy();
			}
			_timers.length = 0;
		}
	}
}