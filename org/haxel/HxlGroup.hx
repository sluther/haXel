package org.haxel;
/**
 * This is an organizational class that can update and render a bunch of <code>HxlBasic</code>s.
 * NOTE: Although <code>HxlGroup</code> extends <code>HxlBasic</code>, it will not automatically
 * add itself to the global collisions quad tree, it will only add its members.
 * 
 * @author	Adam Atomic
 */
class HxlGroup extends HxlBasic
{
	/**
	 * Use with <code>sort()</code> to sort in ascending order.
	 */
	public static inline var ASCENDING:Int = -1;
	/**
	 * Use with <code>sort()</code> to sort in descending order.
	 */
	public static inline var DESCENDING:Int = 1;
	
	/**
	 * Array of all the <code>HxlBasic</code>s that exist in this group.
	 */
	public var members:Array<HxlBasic>;
	/**
	 * The number of entries in the members array.
	 * For performance and safety you should check this variable
	 * instead of members.length unless you really know what you're doing!
	 */
	public var length:UInt;

	/**
	 * Internal tracker for the maximum capacity of the group.
	 * Default is 0, or no max capacity.
	 */
	private var _maxSize:UInt;
	/**
	 * Internal helper variable for recycling objects a la <code>HxlEmitter</code>.
	 */
	private var _marker:UInt;
	
	/**
	 * Helper for sort.
	 */
	private var _sortIndex:String;
	/**
	 * Helper for sort.
	 */
	private var _sortOrder:Int;

	/**
	 * Constructor
	 */
	public function new(MaxSize:UInt=0)
	{
		super();
		members = new Array();
		length = 0;
		_maxSize = MaxSize;
		_marker = 0;
		_sortIndex = null;
	}
	
	/**
	 * Override this function to handle any deleting or "shutdown" type operations you might need,
	 * such as removing traditional Flash children like Sprite objects.
	 */
	override public function destroy():Void
	{
		if(members != null)
		{
			var basic:HxlBasic;
			var i:UInt = 0;
			while(i < length)
			{
				basic = cast(members[i++], HxlBasic);
				if(basic != null)
					basic.destroy();
			}
			members.length = 0;
			members = null;
		}
		_sortIndex = null;
	}
	
	/**
	 * Just making sure we don't increment the active objects count.
	 */
	override public function preUpdate():Void
	{
	}
	
	/**
	 * Automatically goes through and calls update on everything you added.
	 */
	override public function update():Void
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && basic.exists && basic.active)
			{
				basic.preUpdate();
				basic.update();
				basic.postUpdate();
			}
		}
	}
	
	/**
	 * Automatically goes through and calls render on everything you added.
	 */
	override public function draw():Void
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && basic.exists && basic.visible)
				basic.draw();
		}
	}
	
	/**
	 * The maximum capacity of this group.  Default is 0, meaning no max capacity, and the group can just grow.
	 */
	public var maxSize(getMaxSize, setMaxSize):UInt;
	public function getMaxSize():UInt
	{
		return _maxSize;
	}
	
	/**
	 * @private
	 */
	public function setMaxSize(Size:UInt):UInt
	{
		_maxSize = Size;
		if(_marker >= _maxSize)
			_marker = 0;
		if((_maxSize == 0) || (members == null) || (_maxSize >= members.length))
			return;
		
		//If the max size has shrunk, we need to get rid of some objects
		var basic:HxlBasic;
		var i:UInt = _maxSize;
		var l:UInt = members.length;
		while(i < l)
		{
			basic = cast(members[i++], HxlBasic);
			if(basic != null)
				basic.destroy();
		}
		length = members.length = _maxSize;
	}
	
	/**
	 * Adds a new <code>HxlBasic</code> subclass (HxlBasic, HxlSprite, Enemy, etc) to the group.
	 * HxlGroup will try to replace a null member of the array first.
	 * Failing that, HxlGroup will add it to the end of the member array,
	 * assuming there is room for it, and doubling the size of the array if necessary.
	 *
	 * <p>WARNING: If the group has a maxSize that has already been met,
	 * the object will NOT be added to the group!</p>
	 *
	 * @param	Object		The object you want to add to the group.
	 *
	 * @return	The same <code>HxlBasic</code> object that was passed in.
	 */
	public function add(Object:HxlBasic):HxlBasic
	{
		var i:UInt = 0;
		var l:UInt = members.length;
		
		//Don't bother adding an object twice.
		for(i in 0 ... l) {
			if(members[i] == Object) {
				return Object;
			}
		}
/*		if(members.indexOf(Object) >= 0)
			return Object;*/
		
		//First, look for a null entry where we can add the object.
		for(i in 0 ... l)
		{
			if(members[i] == null)
			{
				members[i] = Object;
				if(i >= length)
					length = i+1;
				return Object;
			}
		}
		
		//Failing that, expand the array (if we can) and add the object.
/*		if(_maxSize > 0)
		{
			if(members.length >= _maxSize)
				return Object;
			else if(members.length * 2 <= _maxSize)
				members.length *= 2;
			else
				members.length = _maxSize;
		}
		else
			members.length *= 2;*/
		
		//If we made it this far, then we successfully grew the group,
		//and we can go ahead and add the object at the first open slot.
		var newIndex:UInt = i + 1;
		members[newIndex] = Object;
		length = newIndex;
		return Object;
	}
	
	/**
	 * Recycling is designed to help you reuse game objects without always re-allocating or "newing" them.
	 * 
	 * <p>If you specified a maximum size for this group (like in HxlEmitter),
	 * then recycle will employ what we're calling "rotating" recycling.
	 * Recycle() will first check to see if the group is at capacity yet.
	 * If group is not yet at capacity, recycle() returns a new object.
	 * If the group IS at capacity, then recycle() just returns the next object in line.</p>
	 * 
	 * <p>If you did NOT specify a maximum size for this group,
	 * then recycle() will employ what we're calling "grow-style" recycling.
	 * Recycle() will return either the first object with exists == false,
	 * or, finding none, add a new object to the array,
	 * doubling the size of the array if necessary.</p>
	 * 
	 * <p>WARNING: If this function needs to create a new object,
	 * and no object class was provided, it will return null
	 * instead of a valid object!</p>
	 * 
	 * @param	ObjectClass		The class type you want to recycle (e.g. HxlSprite, EvilRobot, etc). Do NOT "new" the class in the parameter!
	 * 
	 * @return	A reference to the object that was created.  Don't forget to cast it back to the Class you want cast(myObjectClass;, ).
	 */
	public function recycle(ObjectClass:Class<HxlBasic>=null):HxlBasic
	{
		var basic:HxlBasic;
		if(_maxSize > 0)
		{
			if(length < _maxSize)
			{
				if(ObjectClass == null)
					return null;
				return add(cast(Type.createInstance(ObjectClass, []), HxlBasic));
			}
			else
			{
				basic = members[_marker++];
				if(_marker >= _maxSize)
					_marker = 0;
				return basic;
			}
		}
		else
		{
			basic = getFirstAvailable(ObjectClass);
			if(basic != null)
				return basic;
			if(ObjectClass == null)
				return null;
			return add(cast(Type.createInstance(ObjectClass, []), HxlBasic));
		}
	}
	
	/**
	 * Removes an object from the group.
	 * 
	 * @param	Object	The <code>HxlBasic</code> you want to remove.
	 * @param	Splice	Whether the object should be cut from the array entirely or not.
	 * 
	 * @return	The removed object.
	 */
	public function remove(Object:HxlBasic,Splice:Bool=false):HxlBasic
	{
		
		var i:UInt = 0;
		var l:UInt = members.length;
		var index:UInt = 0;
		
		//Don't bother adding an object twice.
		for(i in 0 ... l) {
			if(members[i] == Object) {
				index = i;
			}
		}
		if((index  == 0))
			return null;
		if(Splice)
		{
			members.splice(index,1);
			length--;
		}
		else
			members[index] = null;
		return Object;
	}
	
	/**
	 * Replaces an existing <code>HxlBasic</code> with a new one.
	 * 
	 * @param	OldObject	The object you want to replace.
	 * @param	NewObject	The new object you want to use instead.
	 * 
	 * @return	The new object.
	 */
	public function replace(OldObject:HxlBasic,NewObject:HxlBasic):HxlBasic
	{
		var index:Int = members.indexOf(OldObject);
		if((index < 0) || (index >= members.length))
			return null;
		members[index] = NewObject;
		return NewObject;
	}
	
	/**
	 * Call this function to sort the group according to a particular value and order.
	 * For example, to sort game objects for Zelda-style overlaps you might call
	 * <code>myGroup.sort("y",ASCENDING)</code> at the bottom of your
	 * <code>HxlState.update()</code> override.  To sort all existing objects after
	 * a big explosion or bomb attack, you might call <code>myGroup.sort("exists",DESCENDING)</code>.
	 * 
	 * @param	Index	The <code>String</code> name of the member variable you want to sort on.  Default value is "y".
	 * @param	Order	A <code>HxlGroup</code> constant that defines the sort order.  Possible values are <code>ASCENDING</code> and <code>DESCENDING</code>.  Default value is <code>ASCENDING</code>.  
	 */
	public function sort(Index:String="y",Order:Int=ASCENDING):Void
	{
		_sortIndex = Index;
		_sortOrder = Order;
		members.sort(sortHandler);
	}

	/**
	 * Go through and set the specified variable to the specified value on all members of the group.
	 * 
	 * @param	VariableName	The string representation of the variable name you want to modify, for example "visible" or "scrollFactor".
	 * @param	Value			The value you want to assign to that variable.
	 * @param	Recurse			Default value is true, meaning if <code>setAll()</code> encounters a member that is a group, it will call <code>setAll()</code> on that group rather than modifying its variable.
	 */
	public function setAll(VariableName:String,Value:Class<HxlBasic>,Recurse:Bool=true):Void
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if(basic != null)
			{
				if(Recurse && Std.is(basic, HxlGroup))
					cast(Basic, HxlGroup).setAll(VariableName,Value,Recurse);
				else
					basic[VariableName] = Value;
			}
		}
	}
	
	/**
	 * Go through and call the specified function on all members of the group.
	 * Currently only works on functions that have no required parameters.
	 * 
	 * @param	FunctionName	The string representation of the function you want to call on each object, for example "kill()" or "init()".
	 * @param	Recurse			Default value is true, meaning if <code>callAll()</code> encounters a member that is a group, it will call <code>callAll()</code> on that group rather than calling the group's function.
	 */ 
	public function callAll(FunctionName:String,Recurse:Bool=true):Void
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if(basic != null)
			{
				if(Recurse && Std.is(basic, HxlGroup))
					cast(basic, HxlGroup).callAll(FunctionName,Recurse);
				else
					basic[FunctionName]();
			}
		}
	}
	
	/**
	 * Call this function to retrieve the first object with exists == false in the group.
	 * This is handy for recycling in general, e.g. respawning enemies.
	 * 
	 * @param	ObjectClass		An optional parameter that lets you narrow the results to instances of this particular class.
	 * 
	 * @return	A <code>HxlBasic</code> currently flagged as not existing.
	 */
	public function getFirstAvailable(ObjectClass:Class<HxlBasic>=null):HxlBasic
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && !basic.exists && ((ObjectClass == null) || Std.is(basic, ObjectClass)))
				return basic;
		}
		return null;
	}
	
	/**
	 * Call this function to retrieve the first index set to 'null'.
	 * Returns -1 if no index stores a null object.
	 * 
	 * @return	An <code>int</code> indicating the first null slot in the group.
	 */
	public function getFirstNull():Int
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		var l:UInt = members.length;
		while(i < l)
		{
			if(members[i] == null)
				return i;
			else
				i++;
		}
		return -1;
	}
	
	/**
	 * Call this function to retrieve the first object with exists == true in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 * 
	 * @return	A <code>HxlBasic</code> currently flagged as existing.
	 */
	public function getFirstExtant():HxlBasic
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && basic.exists)
				return basic;
		}
		return null;
	}
	
	/**
	 * Call this function to retrieve the first object with dead == false in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 * 
	 * @return	A <code>HxlBasic</code> currently flagged as not dead.
	 */
	public function getFirstAlive():HxlBasic
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && basic.exists && basic.alive)
				return basic;
		}
		return null;
	}
	
	/**
	 * Call this function to retrieve the first object with dead == true in the group.
	 * This is handy for checking if everything's wiped out, or choosing a squad leader, etc.
	 * 
	 * @return	A <code>HxlBasic</code> currently flagged as dead.
	 */
	public function getFirstDead():HxlBasic
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && !basic.alive)
				return basic;
		}
		return null;
	}
	
	/**
	 * Call this function to find out how many members of the group are not dead.
	 * 
	 * @return	The number of <code>HxlBasic</code>s flagged as not dead.  Returns -1 if group is empty.
	 */
	public function countLiving():Int
	{
		var count:Int = -1;
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if(basic != null)
			{
				if(count < 0)
					count = 0;
				if(basic.exists && basic.alive)
					count++;
			}
		}
		return count;
	}
	
	/**
	 * Call this function to find out how many members of the group are dead.
	 * 
	 * @return	The number of <code>HxlBasic</code>s flagged as dead.  Returns -1 if group is empty.
	 */
	public function countDead():Int
	{
		var count:Int = -1;
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if(basic != null)
			{
				if(count < 0)
					count = 0;
				if(!basic.alive)
					count++;
			}
		}
		return count;
	}
	
	/**
	 * Returns a member at random from the group.
	 * 
	 * @param	StartIndex	Optional offset off the front of the array. Default value is 0, or the beginning of the array.
	 * @param	Length		Optional restriction on the number of values you want to randomly select from.
	 * 
	 * @return	A <code>HxlBasic</code> from the members list.
	 */
	public function getRandom(StartIndex:UInt=0,Length:UInt=0):HxlBasic
	{
		if(Length == 0)
			Length = length;
		return cast(HxlG.getRandom(members,StartIndex,Length), HxlBasic);
	}
	
	/**
	 * Remove all instances of <code>HxlBasic</code> subclass (HxlSprite, HxlBlock, etc) from the list.
	 * WARNING: does not destroy() or kill() any of these objects!
	 */
	public function clear():Void
	{
		length = members.length = 0;
	}
	
	/**
	 * Calls kill on the group's members and then on the group itself.
	 */
	override public function kill():Void
	{
		var basic:HxlBasic;
		var i:UInt = 0;
		while(i < length)
		{
			basic = cast(members[i++], HxlBasic);
			if((basic != null) && basic.exists)
				basic.kill();
		}
		super.kill();
	}
	
	/**
	 * Helper function for the sort process.
	 * 
	 * @param 	Obj1	The first object being sorted.
	 * @param	Obj2	The second object being sorted.
	 * 
	 * @return	An integer value: -1 (Obj1 before Obj2), 0 (same), or 1 (Obj1 after Obj2).
	 */
	private function sortHandler(Obj1:HxlBasic,Obj2:HxlBasic):Int
	{
		if(Obj1[_sortIndex] < Obj2[_sortIndex])
			return _sortOrder;
		else if(Obj1[_sortIndex] > Obj2[_sortIndex])
			return -_sortOrder;
		return 0;
	}
}