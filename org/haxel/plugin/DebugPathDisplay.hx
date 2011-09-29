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
	 * A simple manager for tracking and drawing HxlPath debug data to the screen.
	 * 
	 * @author	Adam Atomic
	 */
	class DebugPathDisplay extends HxlBasic
	{
		private var _paths:Array;
		
		/**
		 * Instantiates a new debug path display manager.
		 */
		public function new()
		{
			_paths = new Array();
			active = false; //don't call update on this plugin
		}
		
		/**
		 * Clean up memory.
		 */
		override public function destroy():Void
		{
			super.destroy();
			clear();
			_paths = null;
		}
		
		/**
		 * Called by <code>HxlG.drawPlugins()</code> after the game state has been drawn.
		 * Cycles through cameras and calls <code>drawDebug()</code> on each one.
		 */
		override public function draw():Void
		{
			if(!HxlG.visualDebug || ignoreDrawDebug)
				return;	
			
			if(cameras == null)
				cameras = HxlG.cameras;
			var i:UInt = 0;
			var l:UInt = cameras.length;
			while(i < l)
				drawDebug(cameras[i++]);
		}
		
		/**
		 * Similar to <code>HxlObject</code>'s <code>drawDebug()</code> functionality,
		 * this function calls <code>drawDebug()</code> on each <code>HxlPath</code> for the specified camera.
		 * Very helpful for debugging!
		 * 
		 * @param	Camera	Which <code>HxlCamera</code> object to draw the debug data to.
		 */
		override public function drawDebug(Camera:HxlCamera=null):Void
		{
			if(Camera == null)
				Camera = HxlG.camera;
			
			var i:Int = _paths.length-1;
			var path:HxlPath;
			while(i >= 0)
			{
				path = _paths[i--] as HxlPath;
				if((path != null) && !path.ignoreDrawDebug)
					path.drawDebug(Camera);
			}
		}
		
		/**
		 * Add a path to the path debug display manager.
		 * Usually called automatically by <code>HxlPath</code>'s constructor.
		 * 
		 * @param	Path	The <code>HxlPath</code> you want to add to the manager.
		 */
		public function add(Path:HxlPath):Void
		{
			_paths.push(Path);
		}
		
		/**
		 * Remove a path from the path debug display manager.
		 * Usually called automatically by <code>HxlPath</code>'s <code>destroy()</code> function.
		 * 
		 * @param	Path	The <code>HxlPath</code> you want to remove from the manager.
		 */
		public function remove(Path:HxlPath):Void
		{
			var index:Int = _paths.indexOf(Path);
			if(index >= 0)
				_paths.splice(index,1);
		}
		
		/**
		 * Removes all the paths from the path debug display manager.
		 */
		public function clear():Void
		{
			var i:Int = _paths.length-1;
			var path:HxlPath;
			while(i >= 0)
			{
				path = _paths[i--] as HxlPath;
				if(path != null)
					path.destroy();
			}
			_paths.length = 0;
		}
	}
}