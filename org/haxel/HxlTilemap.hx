package org.haxel;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.haxel.system.HxlTile;
import org.haxel.system.HxlTilemapBuffer;

/**
 * This is a traditional tilemap display and collision class.
 * It takes a string of comma-separated numbers and then associates
 * those values with tiles from the sheet you pass in.
 * It also includes some handy static parsers that can convert
 * arrays or images into strings that can be loaded.
 * 
 * @author	Adam Atomic
 */
class HxlTilemap extends HxlObject
{
/*	[Embed(source="data/autotiles.png")] public static var ImgAuto:Class;
	[Embed(source="data/autotiles_alt.png")] public static var ImgAutoAlt:Class;*/
	
	/**
	 * No auto-tiling.
	 */
	public static inline var OFF:UInt = 0;
	/**
	 * Good for levels with thin walls that don'tile need interior corner art.
	 */
	public static inline var AUTO:UInt = 1;
	/**
	 * Better for levels with thick walls that look better with interior corner art.
	 */
	public static inline var ALT:UInt = 2;

	/**
	 * Set this flag to use one of the 16-tile binary auto-tile algorithms (OFF, AUTO, or ALT).
	 */
	public var auto:UInt;
	
	/**
	 * Read-only variable, do NOT recommend changing after the map is loaded!
	 */
	public var widthInTiles:UInt;
	/**
	 * Read-only variable, do NOT recommend changing after the map is loaded!
	 */
	public var heightInTiles:UInt;
	/**
	 * Read-only variable, do NOT recommend changing after the map is loaded!
	 */
	public var totalTiles:UInt;
	
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _flashPoint:Point;
	/**
	 * Rendering helper, minimize new object instantiation on repetitive methods.
	 */
	private var _flashRect:Rectangle;
	
	/**
	 * Internal reference to the bitmap data object that stores the original tile graphics.
	 */
	private var _tiles:BitmapData;
	/**
	 * Internal list of buffers, one for each camera, used for drawing the tilemaps.
	 */
	private var _buffers:Array<HxlTilemapBuffer>;
	/**
	 * Internal representation of the actual tile data, as a large 1D array of integers.
	 */
	private var _data:Array<UInt>;
	/**
	 * Internal representation of rectangles, one for each tile in the entire tilemap, used to speed up drawing.
	 */
	private var _rects:Array<Rectangle>;
	/**
	 * Internal, the width of a single tile.
	 */
	private var _tileWidth:UInt;
	/**
	 * Internal, the height of a single tile.
	 */
	private var _tileHeight:UInt;
	/**
	 * Internal collection of tile objects, one for each type of tile in the map (NOTE one for every single tile in the whole map).
	 */
	private var _tileObjects:Array<HxlTile>;
	
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTileNotSolid:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTilePartial:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugTileSolid:BitmapData;
	/**
	 * Internal, used for rendering the debug bounding box display.
	 */
	private var _debugRect:Rectangle;
	/**
	 * Internal flag for checking to see if we need to refresh
	 * the tilemap display to show or hide the bounding boxes.
	 */
	private var _lastVisualDebug:Bool;
	/**
	 * Internal, used to sort of insert blank tiles in front of the tiles in the provided graphic.
	 */
	private var _startingIndex:UInt;
	
	/**
	 * The tilemap constructor just initializes some basic variables.
	 */
	public function new()
	{
		super();
		auto = OFF;
		widthInTiles = 0;
		heightInTiles = 0;
		totalTiles = 0;
		_buffers = new Array();
		_flashPoint = new Point();
		_flashRect = null;
		_data = null;
		_tileWidth = 0;
		_tileHeight = 0;
		_rects = null;
		_tiles = null;
		_tileObjects = null;
		immovable = true;
		cameras = null;
		_debugTileNotSolid = null;
		_debugTilePartial = null;
		_debugTileSolid = null;
		_debugRect = null;
		_lastVisualDebug = HxlG.visualDebug;
		_startingIndex = 0;
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		_flashPoint = null;
		_flashRect = null;
		_tiles = null;
		var i:UInt = 0;
		var l:UInt = _tileObjects.length;
		while(i < l)
			cast(_tileObjects[i++], HxlTile).destroy();
		_tileObjects = null;
		i = 0;
		l = _buffers.length;
		while(i < l)
			cast(_buffers[i++], HxlTilemapBuffer).destroy();
		_buffers = null;
		_data = null;
		_rects = null;
		_debugTileNotSolid = null;
		_debugTilePartial = null;
		_debugTileSolid = null;
		_debugRect = null;

		super.destroy();
	}
	
	/**
	 * Load the tilemap with string data and a tile graphic.
	 * 
	 * @param	MapData			A string of comma and line-return delineated indices indicating what order the tiles should go in.
	 * @param	TileGraphic		All the tiles you want to use, arranged in a strip corresponding to the numbers in MapData.
	 * @param	TileWidth		The width of your tiles (e.g. 8) - defaults to height of the tile graphic if unspecified.
	 * @param	TileHeight		The height of your tiles (e.g. 8) - defaults to width if unspecified.
	 * @param	AutoTile		Whether to load the map using an automatic tile placement algorithm.  Setting this to either AUTO or ALT will override any values you put for StartingIndex, DrawIndex, or CollideIndex.
	 * @param	StartingIndex	Used to sort of insert empty tiles in front of the provided graphic.  Default is 0, usually safest ot leave it at that.  Ignored if AutoTile is set.
	 * @param	DrawIndex		Initializes all tile objects equal to and after this index as visible. Default value is 1.  Ignored if AutoTile is set.
	 * @param	CollideIndex	Initializes all tile objects equal to and after this index as allowCollisions = ANY.  Default value is 1.  Ignored if AutoTile is set.  Can override and customize per-tile-type collision behavior using <code>setTileProperties()</code>.	
	 * 
	 * @return	A pointer this instance of HxlTilemap, for chaining as usual :)
	 */
	public function loadMap(MapData:String, TileGraphic:Class<Bitmap>, TileWidth:UInt=0, TileHeight:UInt=0, AutoTile:UInt=OFF, StartingIndex:UInt=0, DrawIndex:UInt=1, CollideIndex:UInt=1):HxlTilemap
	{
		auto = AutoTile;
		_startingIndex = StartingIndex;

		//Figure out the map dimensions based on the data string
		var columns:Array;
		var rows:Array = MapData.split("\n");
		heightInTiles = rows.length;
		_data = new Array();
		var row:UInt = 0;
		var column:UInt;
		while(row < heightInTiles)
		{
			columns = rows[row++].split(",");
			if(columns.length <= 1)
			{
				heightInTiles = heightInTiles - 1;
				continue;
			}
			if(widthInTiles == 0)
				widthInTiles = columns.length;
			column = 0;
			while(column < widthInTiles)
				_data.push(uint(columns[column++]));
		}
		
		//Pre-process the map data if it's auto-tiled
		var i:UInt;
		totalTiles = widthInTiles*heightInTiles;
		if(auto > OFF)
		{
			_startingIndex = 1;
			DrawIndex = 1;
			CollideIndex = 1;
			i = 0;
			while(i < totalTiles)
				autoTile(i++);
		}
		
		//Figure out the size of the tiles
		_tiles = HxlG.addBitmap(TileGraphic);
		_tileWidth = TileWidth;
		if(_tileWidth == 0)
			_tileWidth = _tiles.height;
		_tileHeight = TileHeight;
		if(_tileHeight == 0)
			_tileHeight = _tileWidth;
		
		//create some tile objects that we'll use for overlap checks (one for each tile)
		i = 0;
		var l:UInt = (_tiles.width/_tileWidth) * (_tiles.height/_tileHeight);
		if(auto > OFF)
			l++;
		_tileObjects = new Array(l);
		var ac:UInt;
		while(i < l)
		{
			_tileObjects[i] = new HxlTile(this,i,_tileWidth,_tileHeight,(i >= DrawIndex),(i >= CollideIndex)?allowCollisions:NONE);
			i++;
		}
		
		//create debug tiles for rendering bounding boxes on demand
		_debugTileNotSolid = makeDebugTile(HxlG.BLUE);
		_debugTilePartial = makeDebugTile(HxlG.PINK);
		_debugTileSolid = makeDebugTile(HxlG.GREEN);
		_debugRect = new Rectangle(0,0,_tileWidth,_tileHeight);
		
		//Then go through and create the actual map
		width = widthInTiles*_tileWidth;
		height = heightInTiles*_tileHeight;
		_rects = new Array(totalTiles);
		i = 0;
		while(i < totalTiles)
			updateTile(i++);

		return this;
	}
	
	/**
	 * Internal function to clean up the map loading code.
	 * Just generates a wireframe box the size of a tile with the specified color.
	 */
	private function makeDebugTile(Color:UInt):BitmapData
	{
		var debugTile:BitmapData;
		debugTile = new BitmapData(_tileWidth,_tileHeight,true,0);

		var gfx:Graphics = HxlG.flashGfx;
		gfx.clear();
		gfx.moveTo(0,0);
		gfx.lineStyle(1,Color,0.5);
		gfx.lineTo(_tileWidth-1,0);
		gfx.lineTo(_tileWidth-1,_tileHeight-1);
		gfx.lineTo(0,_tileHeight-1);
		gfx.lineTo(0,0);
		
		debugTile.draw(HxlG.flashGfxSprite);
		return debugTile;
	}
	
	/**
	 * Main logic loop for tilemap is pretty simple,
	 * just checks to see if visual debug got turned on.
	 * If it did, the tilemap is flagged as dirty so it
	 * will be redrawn with debug info on the next draw call.
	 */
	override public function update():Void
	{
		if(_lastVisualDebug != HxlG.visualDebug)
		{
			_lastVisualDebug = HxlG.visualDebug;
			setDirty();
		}
	}

	/**
	 * Internal function that actually renders the tilemap to the tilemap buffer.  Called by draw().
	 * 
	 * @param	Buffer		The <code>HxlTilemapBuffer</code> you are rendering to.
	 * @param	Camera		The related <code>HxlCamera</code>, mainly for scroll values.
	 */
	private function drawTilemap(Buffer:HxlTilemapBuffer,Camera:HxlCamera):Void
	{
		Buffer.fill();
		
		//Copy tile images into the tile buffer
		_point.x = int(Camera.scroll.x*scrollFactor.x) - x; //modified from getScreenXY()
		_point.y = int(Camera.scroll.y*scrollFactor.y) - y;
		var screenXInTiles:Int = (_point.x + ((_point.x > 0)?0.0000001:-0.0000001))/_tileWidth;
		var screenYInTiles:Int = (_point.y + ((_point.y > 0)?0.0000001:-0.0000001))/_tileHeight;
		var screenRows:UInt = Buffer.rows;
		var screenColumns:UInt = Buffer.columns;
		
		//Bound the upper left corner
		if(screenXInTiles < 0)
			screenXInTiles = 0;
		if(screenXInTiles > widthInTiles-screenColumns)
			screenXInTiles = widthInTiles-screenColumns;
		if(screenYInTiles < 0)
			screenYInTiles = 0;
		if(screenYInTiles > heightInTiles-screenRows)
			screenYInTiles = heightInTiles-screenRows;
		
		var rowIndex:Int = screenYInTiles*widthInTiles+screenXInTiles;
		_flashPoint.y = 0;
		var row:UInt = 0;
		var column:UInt;
		var columnIndex:UInt;
		var tile:HxlTile;
		var debugTile:BitmapData;
		while(row < screenRows)
		{
			columnIndex = rowIndex;
			column = 0;
			_flashPoint.x = 0;
			while(column < screenColumns)
			{
				_flashRect = cast(_rects[columnIndex], Rectangle);
				if(_flashRect != null)
				{
					Buffer.pixels.copyPixels(_tiles,_flashRect,_flashPoint,null,null,true);
					if(HxlG.visualDebug && !ignoreDrawDebug)
					{
						tile = _tileObjects[_data[columnIndex]];
						if(tile != null)
						{
							if(tile.allowCollisions <= NONE)
								debugTile = _debugTileNotSolid; //blue
							else if(tile.allowCollisions != ANY)
								debugTile = _debugTilePartial; //pink
							else
								debugTile = _debugTileSolid; //green
							Buffer.pixels.copyPixels(debugTile,_debugRect,_flashPoint,null,null,true);
						}
					}
				}
				_flashPoint.x += _tileWidth;
				column++;
				columnIndex++;
			}
			rowIndex += widthInTiles;
			_flashPoint.y += _tileHeight;
			row++;
		}
		Buffer.x = screenXInTiles*_tileWidth;
		Buffer.y = screenYInTiles*_tileHeight;
	}
	
	/**
	 * Draws the tilemap buffers to the cameras and handles flickering.
	 */
	override public function draw():Void
	{
		if(_flickerTimer != 0)
		{
			_flicker = !_flicker;
			if(_flicker)
				return;
		}
		
		if(cameras == null)
			cameras = HxlG.cameras;
		var camera:HxlCamera;
		var buffer:HxlTilemapBuffer;
		var i:UInt = 0;
		var l:UInt = cameras.length;
		while(i < l)
		{
			camera = cameras[i];
			if(_buffers[i] == null)
				_buffers[i] = new HxlTilemapBuffer(_tileWidth,_tileHeight,widthInTiles,heightInTiles,camera);
			buffer = cast(_buffers[i++], HxlTilemapBuffer);
			if(!buffer.dirty)
			{
				_point.x = x - int(camera.scroll.x*scrollFactor.x) + buffer.x; //copied from getScreenXY()
				_point.y = y - int(camera.scroll.y*scrollFactor.y) + buffer.y;
				buffer.dirty = (_point.x > 0) || (_point.y > 0) || (_point.x + buffer.width < camera.width) || (_point.y + buffer.height < camera.height);
			}
			if(buffer.dirty)
			{
				drawTilemap(buffer,camera);
				buffer.dirty = false;
			}
			_flashPoint.x = x - int(camera.scroll.x*scrollFactor.x) + buffer.x; //copied from getScreenXY()
			_flashPoint.y = y - int(camera.scroll.y*scrollFactor.y) + buffer.y;
			_flashPoint.x += (_flashPoint.x > 0)?0.0000001:-0.0000001;
			_flashPoint.y += (_flashPoint.y > 0)?0.0000001:-0.0000001;
			buffer.draw(camera,_flashPoint);
			_VISIBLECOUNT++;
		}
	}
	
	/**
	 * Fetches the tilemap data array.
	 * 
	 * @param	Simple		If true, returns the data as copy, as a series of 1s and 0s (useful for auto-tiling stuff). Default value is false, meaning it will return the actual data array (NOT a copy).
	 * 
	 * @return	An array the size of the tilemap full of integers indicating tile placement.
	 */
	public function getData(Simple:Bool=false):Array<Bool>
	{
		if(!Simple)
			return _data;
		
		var i:UInt = 0;
		var l:UInt = _data.length;
		var data:Array = new Array(l);
		while(i < l)
		{
			data[i] = (cast(_tileObjects[_data[i]], HxlTile).allowCollisions > 0)?1:0;
			i++;
		}
		return data;
	}
	
	/**
	 * Set the dirty flag on all the tilemap buffers.
	 * Basically forces a reset of the drawn tilemaps, even if it wasn'tile necessary.
	 * 
	 * @param	Dirty		Whether to flag the tilemap buffers as dirty or not.
	 */
	public function setDirty(Dirty:Bool=true):Void
	{
		var i:UInt = 0;
		var l:UInt = _buffers.length;
		while(i < l)
			cast(_buffers[i++], HxlTilemapBuffer).dirty = Dirty;
	}
	
	/**
	 * Find a path through the tilemap.  Any tile with any collision flags set is treated as impassable.
	 * If no path is discovered then a null reference is returned.
	 * 
	 * @param	Start		The start point in world coordinates.
	 * @param	End			The end point in world coordinates.
	 * @param	Simplify	Whether to run a basic simplification algorithm over the path data, removing extra points that are on the same line.  Default value is true.
	 * @param	RaySimplify	Whether to run an extra raycasting simplification algorithm over the remaining path data.  This can result in some close corners being cut, and should be used with care if at all (yet).  Default value is false.
	 * 
	 * @return	A <code>HxlPath</code> from the start to the end.  If no path could be found, then a null reference is returned.
	 */
	public function findPath(Start:HxlPoint,End:HxlPoint,Simplify:Bool=true,RaySimplify:Bool=false):HxlPath
	{
		//figure out what tile we are starting and ending on.
		var startIndex:UInt = int((Start.y-y)/_tileHeight) * widthInTiles + int((Start.x-x)/_tileWidth);
		var endIndex:UInt = int((End.y-y)/_tileHeight) * widthInTiles + int((End.x-x)/_tileWidth);

		//check that the start and end are clear.
		if((cast(_tileObjects[_data[startIndex]], HxlTile).allowCollisions > 0) ||
			(cast(_tileObjects[_data[startIndex]], HxlTile).allowCollisions > 0) )
			return null;
		
		//figure out how far each of the tiles is from the starting tile
		var distances:Array = computePathDistance(startIndex,endIndex);
		if(distances == null)
			return null;

		//then count backward to find the shortest path.
		var points:Array = new Array();
		walkPath(distances,endIndex,points);
		
		//reset the start and end points to be exact
		var node:HxlPoint;
		node = cast(points[points.length-1], HxlPoint);
		node.x = Start.x;
		node.y = Start.y;
		node = cast(points[0], HxlPoint);
		node.x = End.x;
		node.y = End.y;

		//some simple path cleanup options
		if(Simplify)
			simplifyPath(points);
		if(RaySimplify)
			raySimplifyPath(points);
		
		//finally load the remaining points into a new path object and return it
		var path:HxlPath = new HxlPath();
		var i:Int = points.length - 1;
		while(i >= 0)
		{
			node = cast(points[i--], HxlPoint);
			if(node != null)
				path.addPoint(node,true);
		}
		return path;
	}
	
	/**
	 * Pathfinding helper function, strips out extra points on the same line.
	 *
	 * @param	Points		An array of <code>HxlPoint</code> nodes.
	 */
	private function simplifyPath(Points:Array<HxlPoint>):Void
	{
		var deltaPrevious:Float;
		var deltaNext:Float;
		var last:HxlPoint = Points[0];
		var node:HxlPoint;
		var i:UInt = 1;
		var l:UInt = Points.length-1;
		while(i < l)
		{
			node = Points[i];
			deltaPrevious = (node.x - last.x)/(node.y - last.y);
			deltaNext = (node.x - Points[i+1].x)/(node.y - Points[i+1].y);
			if((last.x == Points[i+1].x) || (last.y == Points[i+1].y) || (deltaPrevious == deltaNext))
				Points[i] = null;
			else
				last = node;
			i++;
		}
	}
	
	/**
	 * Pathfinding helper function, strips out even more points by raycasting from one point to the next and dropping unnecessary points.
	 * 
	 * @param	Points		An array of <code>HxlPoint</code> nodes.
	 */
	private function raySimplifyPath(Points:Array<HxlPoint>):Void
	{
		var source:HxlPoint = Points[0];
		var lastIndex:Int = -1;
		var node:HxlPoint;
		var i:UInt = 1;
		var l:UInt = Points.length;
		while(i < l)
		{
			node = Points[i++];
			if(node == null)
				continue;
			if(ray(source,node,_point))	
			{
				if(lastIndex >= 0)
					Points[lastIndex] = null;
			}
			else
				source = Points[lastIndex];
			lastIndex = i-1;
		}
	}
	
	/**
	 * Pathfinding helper function, floods a grid with distance information until it finds the end point.
	 * NOTE: Currently this process does NOT use any kind of fancy heuristic!  It's pretty brute.
	 * 
	 * @param	StartIndex	The starting tile's map index.
	 * @param	EndIndex	The ending tile's map index.
	 * 
	 * @return	A Flash <code>Array</code> of <code>HxlPoint</code> nodes.  If the end tile could not be found, then a null <code>Array</code> is returned instead.
	 */
	private function computePathDistance(StartIndex:UInt, EndIndex:UInt):Array<HxlPoint>
	{
		//Create a distance-based representation of the tilemap.
		//All walls are flagged as -2, all open areas as -1.
		var mapSize:UInt = widthInTiles*heightInTiles;
		var distances:Array = new Array(mapSize);
		var i:Int = 0;
		while(i < mapSize)
		{
			if(cast(mapSize[i++], HxlTile).allowCollisions)
				distances[i] = -2;
			else
				distances[i] = -1;
			i++;
		}
		distances[StartIndex] = 0;
		var distance:UInt = 1;
		var neighbors:Array = [StartIndex];
		var current:Array;
		var currentIndex:UInt;
		var left:Bool;
		var right:Bool;
		var up:Bool;
		var down:Bool;
		var currentLength:UInt;
		var foundEnd:Bool = false;
		while(neighbors.length > 0)
		{
			current = neighbors;
			neighbors = new Array();
			
			i = 0;
			currentLength = current.length;
			while(i < currentLength)
			{
				currentIndex = current[i++];
				if(currentIndex == EndIndex)
				{
					foundEnd = true;
					neighbors.length = 0;
					break;
				}
				
				//basic map bounds
				left = currentIndex%widthInTiles > 0;
				right = currentIndex%widthInTiles < widthInTiles-1;
				up = currentIndex/widthInTiles > 0;
				down = currentIndex/widthInTiles < heightInTiles-1;
				
				var index:UInt;
				if(up)
				{
					index = currentIndex - widthInTiles;
					if(distances[index] == -1)
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(right)
				{
					index = currentIndex + 1;
					if(distances[index] == -1)
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(down)
				{
					index = currentIndex + widthInTiles;
					if(distances[index] == -1)
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(left)
				{
					index = currentIndex - 1;
					if(distances[index] == -1)
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(up && right)
				{
					index = currentIndex - widthInTiles + 1;
					if((distances[index] == -1) && (distances[currentIndex-widthInTiles] >= -1) && (distances[currentIndex+1] >= -1))
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(right && down)
				{
					index = currentIndex + widthInTiles + 1;
					if((distances[index] == -1) && (distances[currentIndex+widthInTiles] >= -1) && (distances[currentIndex+1] >= -1))
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(left && down)
				{
					index = currentIndex + widthInTiles - 1;
					if((distances[index] == -1) && (distances[currentIndex+widthInTiles] >= -1) && (distances[currentIndex-1] >= -1))
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
				if(up && left)
				{
					index = currentIndex - widthInTiles - 1;
					if((distances[index] == -1) && (distances[currentIndex-widthInTiles] >= -1) && (distances[currentIndex-1] >= -1))
					{
						distances[index] = distance;
						neighbors.push(index);
					}
				}
			}
			distance++;
		}
		if(!foundEnd)
			distances = null;
		return distances;
	}
	
	/**
	 * Pathfinding helper function, recursively walks the grid and finds a shortest path back to the start.
	 * 
	 * @param	Data	A Flash <code>Array</code> of distance information.
	 * @param	Start	The tile we're on in our walk backward.
	 * @param	Points	A Flash <code>Array</code> of <code>HxlPoint</code> nodes composing the path from the start to the end, compiled in reverse order.
	 */
	private function walkPath(Data:Array<UInt>,Start:UInt,Points:Array<HxlPoint>):Void
	{
		Points.push(new HxlPoint(x + uint(Start%widthInTiles)*_tileWidth + _tileWidth*0.5, y + uint(Start/widthInTiles)*_tileHeight + _tileHeight*0.5));
		if(Data[Start] == 0)
			return;
		
		//basic map bounds
		var left:Bool = Start%widthInTiles > 0;
		var right:Bool = Start%widthInTiles < widthInTiles-1;
		var up:Bool = Start/widthInTiles > 0;
		var down:Bool = Start/widthInTiles < heightInTiles-1;
		
		var current:UInt = Data[Start];
		var i:UInt;
		if(up)
		{
			i = Start - widthInTiles;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(right)
		{
			i = Start + 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(down)
		{
			i = Start + widthInTiles;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(left)
		{
			i = Start - 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(up && right)
		{
			i = Start - widthInTiles + 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(right && down)
		{
			i = Start + widthInTiles + 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(left && down)
		{
			i = Start + widthInTiles - 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
		if(up && left)
		{
			i = Start - widthInTiles - 1;
			if((Data[i] >= 0) && (Data[i] < current))
			{
				walkPath(Data,i,Points);
				return;
			}
		}
	}
	
	/**
	 * Checks to see if some <code>HxlObject</code> overlaps this <code>HxlObject</code> object in world space.
	 * If the group has a LOT of things in it, it might be faster to use <code>HxlG.overlaps()</code>.
	 * WARNING: Currently tilemaps do NOT support screen space overlap checks!
	 * 
	 * @param	Object			The object being tested.
	 * @param	InScreenSpace	Whether to take scroll factors into account when checking for overlap.
	 * @param	Camera			Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * 
	 * @return	Whether or not the two objects overlap.
	 */
	override public function overlaps(ObjectOrGroup:HxlBasic,InScreenSpace:Bool=false,Camera:HxlCamera=null):Bool
	{
		if(Std.is(ObjectOrGroup, HxlGroup))
		{
			var results:Bool = false;
			var basic:HxlBasic;
			var i:UInt = 0;
			var members:Array = cast(ObjectOrGroup, HxlGroup).members;
			while(i < length)
			{
				basic = cast(members[i++], HxlBasic);
				if(Std.is(basic, HxlObject))
				{
					if(overlapsWithCallback(cast(basic, HxlObject)))
						results = true;
				}
				else
				{
					if(overlaps(basic,InScreenSpace,Camera))
						results = true;
				}
			}
			return results;
		}
		else if(Std.is(ObjectOrGroup, HxlObject))
			return overlapsWithCallbackcast(ObjectOrGroup, HxlObject);
		return false;
	}
	
	/**
	 * Checks to see if this <code>HxlObject</code> were located at the given position, would it overlap the <code>HxlObject</code> or <code>HxlGroup</code>?
	 * This is distinct from overlapsPoint(), which just checks that point, rather than taking the object's size into account.
	 * WARNING: Currently tilemaps do NOT support screen space overlap checks!
	 * 
	 * @param	X				The X position you want to check.  Pretends this object (the caller, not the parameter) is located here.
	 * @param	Y				The Y position you want to check.  Pretends this object (the caller, not the parameter) is located here.
	 * @param	ObjectOrGroup	The object or group being tested.
	 * @param	InScreenSpace	Whether to take scroll factors into account when checking for overlap.  Default is false, or "only compare in world space."
	 * @param	Camera			Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * 
	 * @return	Whether or not the two objects overlap.
	 */
	override public function overlapsAt(X:Float,Y:Float,ObjectOrGroup:HxlBasic,InScreenSpace:Bool=false,Camera:HxlCamera=null):Bool
	{
		if(Std.is(ObjectOrGroup, HxlGroup))
		{
			var results:Bool = false;
			var basic:HxlBasic;
			var i:UInt = 0;
			var members:Array = (cast(ObjectOrGroup, HxlGroup)).members;
			while(i < length)
			{
				basic = cast(members[i++], HxlBasic);
				if(Std.is(basic, HxlObject))
				{
					_point.x = X;
					_point.y = Y;
					if(overlapsWithCallback(cast(basic, HxlObject),null,false,_point))
						results = true;
				}
				else
				{
					if(overlapsAt(X,Y,basic,InScreenSpace,Camera))
						results = true;
				}
			}
			return results;
		}
		else if(Std.is(ObjectOrGroup, HxlObject))
		{
			_point.x = X;
			_point.y = Y;
			return overlapsWithCallback(cast(ObjectOrGroup, HxlObject),null,false,_point);
		}
		return false;
	}
	
	/**
	 * Checks if the Object overlaps any tiles with any collision flags set,
	 * and calls the specified callback function (if there is one).
	 * Also calls the tile's registered callback if the filter matches.
	 * 
	 * @param	Object				The <code>HxlObject</code> you are checking for overlaps against.
	 * @param	Callback			An optional function that takes the form "myCallback(Object1:HxlObject,Object2:HxlObject)", where Object1 is a HxlTile object, and Object2 is the object passed in in the first parameter of this method.
	 * @param	FlipCallbackParams	Used to preserve A-B list ordering from HxlObject.separate() - returns the HxlTile object as the second parameter instead.
	 * @param	Position			Optional, specify a custom position for the tilemap (useful for overlapsAt()-type funcitonality).
	 * 
	 * @return	Whether there were overlaps, or if a callback was specified, whatever the return value of the callback was.
	 */
	public function overlapsWithCallback(Object:HxlObject,Callback:Dynamic=null,FlipCallbackParams:Bool=false,Position:HxlPoint=null):Bool
	{
		var results:Bool = false;
		
		var X:Float = x;
		var Y:Float = y;
		if(Position != null)
		{
			X = Position.x;
			Y = Position.y;
		}
		
		//Figure out what tiles we need to check against
		var selectionX:Int = HxlU.floor((Object.x - X)/_tileWidth);
		var selectionY:Int = HxlU.floor((Object.y - Y)/_tileHeight);
		var selectionWidth:UInt = selectionX + (HxlU.ceil(Object.width/_tileWidth)) + 1;
		var selectionHeight:UInt = selectionY + HxlU.ceil(Object.height/_tileHeight) + 1;
		
		//Then bound these coordinates by the map edges
		if(selectionX < 0)
			selectionX = 0;
		if(selectionY < 0)
			selectionY = 0;
		if(selectionWidth > widthInTiles)
			selectionWidth = widthInTiles;
		if(selectionHeight > heightInTiles)
			selectionHeight = heightInTiles;
		
		//Then loop through this selection of tiles and call HxlObject.separate() accordingly
		var rowStart:UInt = selectionY*widthInTiles;
		var row:UInt = selectionY;
		var column:UInt;
		var tile:HxlTile;
		var overlapFound:Bool;
		var deltaX:Float = X - last.x;
		var deltaY:Float = Y - last.y;
		while(row < selectionHeight)
		{
			column = selectionX;
			while(column < selectionWidth)
			{
				overlapFound = false;
				tile = cast(_tileObjects[_data[rowStart+column]], HxlTile);
				if(tile.allowCollisions)
				{
					tile.x = X+column*_tileWidth;
					tile.y = Y+row*_tileHeight;
					tile.last.x = tile.x - deltaX;
					tile.last.y = tile.y - deltaY;
					if(Callback != null)
					{
						if(FlipCallbackParams)
							overlapFound = Callback(Object,tile);
						else
							overlapFound = Callback(tile,Object);
					}
					else
						overlapFound = (Object.x + Object.width > tile.x) && (Object.x < tile.x + tile.width) && (Object.y + Object.height > tile.y) && (Object.y < tile.y + tile.height);
					if(overlapFound)
					{
						if((tile.callbackFunc != null) && ((tile.filter == null) || (Std.is(Object, tile.filter))))
						{
							tile.mapIndex = rowStart+column;
							tile.callbackFunc(tile, Object);
						}
						results = true;
					}
				}
				else if((tile.callbackFunc != null) && ((tile.filter == null) || (Std.is(Object, tile.filter))))
				{
					tile.mapIndex = rowStart+column;
					tile.callbackFunc(tile,Object);
				}
				column++;
			}
			rowStart += widthInTiles;
			row++;
		}
		return results;
	}
	
	/**
	 * Checks to see if a point in 2D world space overlaps this <code>HxlObject</code> object.
	 * 
	 * @param	Point			The point in world space you want to check.
	 * @param	InScreenSpace	Whether to take scroll factors into account when checking for overlap.
	 * @param	Camera			Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * 
	 * @return	Whether or not the point overlaps this object.
	 */
	override public function overlapsPoint(Point:HxlPoint,InScreenSpace:Bool=false,Camera:HxlCamera=null):Bool
	{
		if(!InScreenSpace)
			return cast(_tileObjects[_data[uint(uint((Point.y-y)/_tileHeight)*widthInTiles + (Point.x-x)/_tileWidth)]], HxlTile).allowCollisions > 0;
		
		if(Camera == null)
			Camera = HxlG.camera;
		Point.x = Point.x - Camera.scroll.x;
		Point.y = Point.y - Camera.scroll.y;
		getScreenXY(_point,Camera);
		return cast(_tileObjects[_data[uint(uint((Point.y-y)/_tileHeight)*widthInTiles + (Point.x-x)/_tileWidth)]], HxlTile).allowCollisions > 0;
	}
	
	/**
	 * Check the value of a particular tile.
	 * 
	 * @param	X		The X coordinate of the tile (in tiles, not pixels).
	 * @param	Y		The Y coordinate of the tile (in tiles, not pixels).
	 * 
	 * @return	A uint containing the value of the tile at this spot in the array.
	 */
	public function getTile(X:UInt,Y:UInt):UInt
	{
		return cast(_data[Y * widthInTiles + X], UInt);
	}
	
	/**
	 * Get the value of a tile in the tilemap by index.
	 * 
	 * @param	Index	The slot in the data array (Y * widthInTiles + X) where this tile is stored.
	 * 
	 * @return	A uint containing the value of the tile at this spot in the array.
	 */
	public function getTileByIndex(Index:UInt):UInt
	{
		return cast(_data[Index], UInt);
	}
	
	/**
	 * Returns a new Flash <code>Array</code> full of every map index of the requested tile type.
	 *
	 * @param	Index	The requested tile type.
	 * 
	 * @return	An <code>Array</code> with a list of all map indices of that tile type.
	 */
	public function getTileInstances(Index:UInt):Array<UInt>
	{
		var array:Array = null;
		var i:UInt = 0;
		var l:UInt = widthInTiles * heightInTiles;
		while(i < l)
		{
			if(_data[i] == Index)
			{
				if(array == null)
					array = new Array();
				array.push(i);
			}
			i++;
		}
		
		return array;
	}
	
	/**
	 * Returns a new Flash <code>Array</code> full of every coordinate of the requested tile type.
	 * 
	 * @param	Index		The requested tile type.
	 * @param	Midpoint	Whether to return the coordinates of the tile midpoint, or upper left corner. Default is true, return midpoint.
	 * 
	 * @return	An <code>Array</code> with a list of all the coordinates of that tile type.
	 */
	public function getTileCoords(Index:UInt,Midpoint:Bool=true):Array<HxlPoint>
	{
		var array:Array = null;
		
		var point:HxlPoint;
		var i:UInt = 0;
		var l:UInt = widthInTiles * heightInTiles;
		while(i < l)
		{
			if(_data[i] == Index)
			{
				point = new HxlPoint(x + uint(i%widthInTiles)*_tileWidth,y + uint(i/widthInTiles)*_tileHeight);
				if(Midpoint)
				{
					point.x += _tileWidth*0.5;
					point.y += _tileHeight*0.5;
				}
				if(array == null)
					array = new Array();
				array.push(point);
			}
			i++;
		}
		
		return array;
	}
	
	/**
	 * Change the data and graphic of a tile in the tilemap.
	 * 
	 * @param	X				The X coordinate of the tile (in tiles, not pixels).
	 * @param	Y				The Y coordinate of the tile (in tiles, not pixels).
	 * @param	Tile			The new integer data you wish to inject.
	 * @param	UpdateGraphics	Whether the graphical representation of this tile should change.
	 * 
	 * @return	Whether or not the tile was actually changed.
	 */ 
	public function setTile(X:UInt,Y:UInt,Tile:UInt,UpdateGraphics:Bool=true):Bool
	{
		if((X >= widthInTiles) || (Y >= heightInTiles))
			return false;
		return setTileByIndex(Y * widthInTiles + X,Tile,UpdateGraphics);
	}
	
	/**
	 * Change the data and graphic of a tile in the tilemap.
	 * 
	 * @param	Index			The slot in the data array (Y * widthInTiles + X) where this tile is stored.
	 * @param	Tile			The new integer data you wish to inject.
	 * @param	UpdateGraphics	Whether the graphical representation of this tile should change.
	 * 
	 * @return	Whether or not the tile was actually changed.
	 */
	public function setTileByIndex(Index:UInt,Tile:UInt,UpdateGraphics:Bool=true):Bool
	{
		if(Index >= _data.length)
			return false;
		
		var ok:Bool = true;
		_data[Index] = Tile;
		
		if(!UpdateGraphics)
			return ok;
		
		setDirty();
		
		if(auto == OFF)
		{
			updateTile(Index);
			return ok;
		}
		
		//If this map is autotiled and it changes, locally update the arrangement
		var i:UInt;
		var row:Int = int(Index/widthInTiles) - 1;
		var rowLength:Int = row + 3;
		var column:Int = Index%widthInTiles - 1;
		var columnHeight:Int = column + 3;
		while(row < rowLength)
		{
			column = columnHeight - 3;
			while(column < columnHeight)
			{
				if((row >= 0) && (row < heightInTiles) && (column >= 0) && (column < widthInTiles))
				{
					i = row*widthInTiles+column;
					autoTile(i);
					updateTile(i);
				}
				column++;
			}
			row++;
		}
		
		return ok;
	}
	
	/**
	 * Adjust collision settings and/or bind a callback function to a range of tiles.
	 * This callback function, if present, is triggered by calls to overlap() or overlapsWithCallback().
	 * 
	 * @param	Tile			The tile or tiles you want to adjust.
	 * @param	AllowCollisions	Modify the tile or tiles to only allow collisions from certain directions, use HxlObject constants NONE, ANY, LEFT, RIGHT, etc.  Default is "ANY".
	 * @param	Callback		The function to trigger, e.g. <code>lavaCallback(Tile:HxlTile, Object:HxlObject)</code>.
	 * @param	CallbackFilter	If you only want the callback to go off for certain classes or objects based on a certain class, set that class here.
	 * @param	Range			If you want this callback to work for a bunch of different tiles, input the range here.  Default value is 1.
	 */
	public function setTileProperties(Tile:UInt,AllowCollisions:UInt=0x1111,Callback:Dynamic=null,CallbackFilter:Class<Dynamic>=null,Range:UInt=1):Void
	{
		if(Range <= 0)
			Range = 1;
		var tile:HxlTile;
		var i:UInt = Tile;
		var l:UInt = Tile+Range;
		while(i < l)
		{
			tile = cast(_tileObjects[i++], HxlTile);
			tile.allowCollisions = AllowCollisions;
			tile.callbackFunc = Callback;
			tile.filter = CallbackFilter;
		}
	}
	
	/**
	 * Call this function to lock the automatic camera to the map's edges.
	 * 
	 * @param	Camera			Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * @param	Border			Adjusts the camera follow boundary by whatever number of tiles you specify here.  Handy for blocking off deadends that are offscreen, etc.  Use a negative number to add padding instead of hiding the edges.
	 * @param	UpdateWorld		Whether to update the collision system's world size, default value is true.
	 */
	public function follow(Camera:HxlCamera=null,Border:Int=0,UpdateWorld:Bool=true):Void
	{
		if(Camera == null)
			Camera = HxlG.camera;
		Camera.setBounds(x+Border*_tileWidth,y+Border*_tileHeight,width-Border*_tileWidth*2,height-Border*_tileHeight*2,UpdateWorld);
	}
	
	/**
	 * Get the world coordinates and size of the entire tilemap as a <code>HxlRect</code>.
	 * 
	 * @param	Bounds		Optional, pass in a pre-existing <code>HxlRect</code> to prevent instantiation of a new object.
	 * 
	 * @return	A <code>HxlRect</code> containing the world coordinates and size of the entire tilemap.
	 */
	public function getBounds(Bounds:HxlRect=null):HxlRect
	{
		if(Bounds == null)
			Bounds = new HxlRect();
		return Bounds.make(x,y,width,height);
	}
	
	/**
	 * Shoots a ray from the start point to the end point.
	 * If/when it passes through a tile, it stores that point and returns false.
	 * 
	 * @param	Start		The world coordinates of the start of the ray.
	 * @param	End			The world coordinates of the end of the ray.
	 * @param	Result		A <code>Point</code> object containing the first wall impact.
	 * @param	Resolution	Defaults to 1, meaning check every tile or so.  Higher means more checks!
	 * @return	Returns true if the ray made it from Start to End without hitting anything.  Returns false and fills Result if a tile was hit.
	 */
	public function ray(Start:HxlPoint, End:HxlPoint, Result:HxlPoint=null, Resolution:Float=1):Bool
	{
		var step:Float = _tileWidth;
		if(_tileHeight < _tileWidth)
			step = _tileHeight;
		step /= Resolution;
		var deltaX:Float = End.x - Start.x;
		var deltaY:Float = End.y - Start.y;
		var distance:Float = Math.sqrt(deltaX*deltaX + deltaY*deltaY);
		var steps:UInt = Math.ceil(distance/step);
		var stepX:Float = deltaX/steps;
		var stepY:Float = deltaY/steps;
		var curX:Float = Start.x - stepX - x;
		var curY:Float = Start.y - stepY - y;
		var tileX:UInt;
		var tileY:UInt;
		var i:UInt = 0;
		while(i < steps)
		{
			curX += stepX;
			curY += stepY;
			
			if((curX < 0) || (curX > width) || (curY < 0) || (curY > height))
			{
				i++;
				continue;
			}
			
			tileX = curX/_tileWidth;
			tileY = curY/_tileHeight;
			if(cast(_tileObjects[_data[tileY*widthInTiles+tileX]], HxlTile).allowCollisions)
			{
				//Some basic helper stuff
				tileX *= _tileWidth;
				tileY *= _tileHeight;
				var rx:Float = 0;
				var ry:Float = 0;
				var q:Float;
				var lx:Float = curX-stepX;
				var ly:Float = curY-stepY;
				
				//Figure out if it crosses the X boundary
				q = tileX;
				if(deltaX < 0)
					q += _tileWidth;
				rx = q;
				ry = ly + stepY*((q-lx)/stepX);
				if((ry > tileY) && (ry < tileY + _tileHeight))
				{
					if(Result == null)
						Result = new HxlPoint();
					Result.x = rx;
					Result.y = ry;
					return false;
				}
				
				//Else, figure out if it crosses the Y boundary
				q = tileY;
				if(deltaY < 0)
					q += _tileHeight;
				rx = lx + stepX*((q-ly)/stepY);
				ry = q;
				if((rx > tileX) && (rx < tileX + _tileWidth))
				{
					if(Result == null)
						Result = new HxlPoint();
					Result.x = rx;
					Result.y = ry;
					return false;
				}
				return true;
			}
			i++;
		}
		return true;
	}
	
	/**
	 * Converts a one-dimensional array of tile data to a comma-separated string.
	 * 
	 * @param	Data		An array full of integer tile references.
	 * @param	Width		The number of tiles in each row.
	 * @param	Invert		Recommended only for 1-bit arrays - changes 0s to 1s and vice versa.
	 * 
	 * @return	A comma-separated string containing the level data in a <code>HxlTilemap</code>-friendly format.
	 */
	public static function arrayToCSV(Data:Array<UInt>,Width:Int,Invert:Bool=false):String
	{
		var row:UInt = 0;
		var column:UInt;
		var csv:String;
		var Height:Int = Data.length / Width;
		var index:Int;
		while(row < Height)
		{
			column = 0;
			while(column < Width)
			{
				index = Data[row*Width+column];
				if(Invert)
				{
					if(index == 0)
						index = 1;
					else if(index == 1)
						index = 0;
				}
				
				if(column == 0)
				{
					if(row == 0)
						csv += index;
					else
						csv += "\n"+index;
				}
				else
					csv += ", "+index;
				column++;
			}
			row++;
		}
		return csv;
	}
	
	/**
	 * Converts a <code>BitmapData</code> object to a comma-separated string.
	 * Black pixels are flagged as 'solid' by default,
	 * non-black pixels are set as non-colliding.
	 * Black pixels must be PURE BLACK.
	 * 
	 * @param	bitmapData	A Flash <code>BitmapData</code> object, preferably black and white.
	 * @param	Invert		Load white pixels as solid instead.
	 * @param	Scale		Default is 1.  Scale of 2 means each pixel forms a 2x2 block of tiles, and so on.
	 * @param	ColorMap	An array of color values (uint 0xAARRGGBB) in the order they're intended to be assigned as indices
	 * 
	 * @return	A comma-separated string containing the level data in a <code>HxlTilemap</code>-friendly format.
	 */
	public static function bitmapToCSV(bitmapData:BitmapData,Invert:Bool=false,Scale:UInt=1,ColorMap:Array<UInt>=null):String
	{
		//Import and scale image if necessary
		if(Scale > 1)
		{
			var bd:BitmapData = bitmapData;
			bitmapData = new BitmapData(bitmapData.width*Scale,bitmapData.height*Scale);
			var mtx:Matrix = new Matrix();
			mtx.scale(Scale,Scale);
			bitmapData.draw(bd,mtx);
		}
		
		//Walk image and export pixel values
		var row:UInt = 0;
		var column:UInt;
		var pixel:UInt;
		var csv:String = "";
		var bitmapWidth:UInt = bitmapData.width;
		var bitmapHeight:UInt = bitmapData.height;
		while(row < bitmapHeight)
		{
			column = 0;
			while(column < bitmapWidth)
			{
				//Decide if this pixel/tile is solid (1) or not (0)
				pixel = bitmapData.getPixel(column,row);
				if(ColorMap != null)
					pixel = ColorMap.indexOf(pixel);
				else if((Invert && (pixel > 0)) || (!Invert && (pixel == 0)))
					pixel = 1;
				else
					pixel = 0;
				
				//Write the result to the string
				if(column == 0)
				{
					if(row == 0)
						csv += pixel;
					else
						csv += "\n"+pixel;
				}
				else
					csv += ", "+pixel;
				column++;
			}
			row++;
		}
		return csv;
	}
	
	/**
	 * Converts a resource image file to a comma-separated string.
	 * Black pixels are flagged as 'solid' by default,
	 * non-black pixels are set as non-colliding.
	 * Black pixels must be PURE BLACK.
	 * 
	 * @param	ImageFile	An embedded graphic, preferably black and white.
	 * @param	Invert		Load white pixels as solid instead.
	 * @param	Scale		Default is 1.  Scale of 2 means each pixel forms a 2x2 block of tiles, and so on.
	 * 
	 * @return	A comma-separated string containing the level data in a <code>HxlTilemap</code>-friendly format.
	 */
	public static function imageToCSV(ImageFile:Class<Bitmap>,Invert:Bool=false,Scale:UInt=1):String
	{
		return bitmapToCSV(Type.createInstance(ImageFile, []).bitmapData,Invert,Scale);
	}
	
	/**
	 * An public function used by the binary auto-tilers.
	 * 
	 * @param	Index		The index of the tile you want to analyze.
	 */
	private function autoTile(Index:UInt):Void
	{
		if(_data[Index] == 0)
			return;
		
		_data[Index] = 0;
		if((Index-widthInTiles < 0) || (_data[Index-widthInTiles] > 0)) 		//UP
			_data[Index] += 1;
		if((Index%widthInTiles >= widthInTiles-1) || (_data[Index+1] > 0)) 		//RIGHT
			_data[Index] += 2;
		if((Index+widthInTiles >= totalTiles) || (_data[Index+widthInTiles] > 0)) //DOWN
			_data[Index] += 4;
		if((Index%widthInTiles <= 0) || (_data[Index-1] > 0)) 					//LEFT
			_data[Index] += 8;
		if((auto == ALT) && (_data[Index] == 15))	//The alternate algo checks for interior corners
		{
			if((Index%widthInTiles > 0) && (Index+widthInTiles < totalTiles) && (_data[Index+widthInTiles-1] <= 0))
				_data[Index] = 1;		//BOTTOM LEFT OPEN
			if((Index%widthInTiles > 0) && (Index-widthInTiles >= 0) && (_data[Index-widthInTiles-1] <= 0))
				_data[Index] = 2;		//TOP LEFT OPEN
			if((Index%widthInTiles < widthInTiles-1) && (Index-widthInTiles >= 0) && (_data[Index-widthInTiles+1] <= 0))
				_data[Index] = 4;		//TOP RIGHT OPEN
			if((Index%widthInTiles < widthInTiles-1) && (Index+widthInTiles < totalTiles) && (_data[Index+widthInTiles+1] <= 0))
				_data[Index] = 8; 		//BOTTOM RIGHT OPEN
		}
		_data[Index] += 1;
	}
	
	/**
	 * Internal function used in setTileByIndex() and the constructor to update the map.
	 * 
	 * @param	Index		The index of the tile you want to update.
	 */
	private function updateTile(Index:UInt):Void
	{
		var tile:HxlTile = cast(_tileObjects[_data[Index]], HxlTile);
		if((tile == null) || !tile.visible)
		{
			_rects[Index] = null;
			return;
		}
		var rx:UInt = (_data[Index]-_startingIndex)*_tileWidth;
		var ry:UInt = 0;
		if(rx >= _tiles.width)
		{
			ry = uint(rx/_tiles.width)*_tileHeight;
			rx %= _tiles.width;
		}
		_rects[Index] = (new Rectangle(rx,ry,_tileWidth,_tileHeight));
	}
}