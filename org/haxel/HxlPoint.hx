package org.haxel;
	import flash.geom.Point;
	
	/**
	 * Stores a 2D floating point coordinate.
	 * 
	 * @author	Adam Atomic
	 */
	class HxlPoint
	{
		/**
		 * @default 0
		 */
		public var x:Float;
		/**
		 * @default 0
		 */
		public var y:Float;
		
		/**
		 * Instantiate a new point object.
		 * 
		 * @param	X		The X-coordinate of the point in space.
		 * @param	Y		The Y-coordinate of the point in space.
		 */
		public function new(X:Float=0, Y:Float=0)
		{
			x = X;
			y = Y;
		}
		
		/**
		 * Instantiate a new point object.
		 * 
		 * @param	X		The X-coordinate of the point in space.
		 * @param	Y		The Y-coordinate of the point in space.
		 */
		public function make(X:Float=0, Y:Float=0):HxlPoint
		{
			x = X;
			y = Y;
			return this;
		}
		
		/**
		 * Helper function, just copies the values from the specified point.
		 * 
		 * @param	Point	Any <code>HxlPoint</code>.
		 * 
		 * @return	A reference to itself.
		 */
		public function copyFrom(Point:HxlPoint):HxlPoint
		{
			x = Point.x;
			y = Point.y;
			return this;
		}
		
		/**
		 * Helper function, just copies the values from this point to the specified point.
		 * 
		 * @param	Point	Any <code>HxlPoint</code>.
		 * 
		 * @return	A reference to the altered point parameter.
		 */
		public function copyTo(Point:HxlPoint):HxlPoint
		{
			Point.x = x;
			Point.y = y;
			return Point;
		}
		
		/**
		 * Helper function, just copies the values from the specified Flash point.
		 * 
		 * @param	Point	Any <code>Point</code>.
		 * 
		 * @return	A reference to itself.
		 */
		public function copyFromFlash(FlashPoint:Point):HxlPoint
		{
			x = FlashPoint.x;
			y = FlashPoint.y;
			return this;
		}
		
		/**
		 * Helper function, just copies the values from this point to the specified Flash point.
		 * 
		 * @param	Point	Any <code>Point</code>.
		 * 
		 * @return	A reference to the altered point parameter.
		 */
		public function copyToFlash(FlashPoint:Point):Point
		{
			FlashPoint.x = x;
			FlashPoint.y = y;
			return FlashPoint;
		}
	}
