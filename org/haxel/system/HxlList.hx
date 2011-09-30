package org.haxel.system;
import org.haxel.HxlObject;

/**
 * A miniature linked list class.
 * Useful for optimizing time-critical or highly repetitive tasks!
 * See <code>HxlQuadTree</code> for how to use it, IF YOU DARE.
 */
class HxlList
{
	/**
	 * Stores a reference to a <code>HxlObject</code>.
	 */
	public var object:HxlObject;
	/**
	 * Stores a reference to the next link in the list.
	 */
	public var next:HxlList;
	
	/**
	 * Creates a new link, and sets <code>object</code> and <code>next</code> to <code>null</code>.
	 */
	public function new()
	{
		object = null;
		next = null;
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		object = null;
		if(next != null)
			next.destroy();
		next = null;
	}
}
