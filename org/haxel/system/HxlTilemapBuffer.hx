package org.haxel.system;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;

import org.haxel.HxlCamera;
import org.haxel.HxlG;
import org.haxel.HxlU;

/**
 * A helper object to keep tilemap drawing performance decent across the new multi-camera system.
 * Pretty much don't even have to think about this class unless you are doing some crazy hacking.
 * 
 * @author	Adam Atomic
 */
class HxlTilemapBuffer
{
	/**
	 * The current X position of the buffer.
	 */
	public var x:Float;
	/**
	 * The current Y position of the buffer.
	 */
	public var y:Float;
	/**
	 * The width of the buffer (usually just a few tiles wider than the camera).
	 */
	public var width:Float;
	/**
	 * The height of the buffer (usually just a few tiles taller than the camera).
	 */
	public var height:Float;
	/**
	 * Whether the buffer needs to be redrawn.
	 */
	public var dirty:Bool;
	/**
	 * How many rows of tiles fit in this buffer.
	 */
	public var rows:UInt;
	/**
	 * How many columns of tiles fit in this buffer.
	 */
	public var columns:UInt;

	private var _pixels:BitmapData;	
	private var _flashRect:Rectangle;

	/**
	 * Instantiates a new camera-specific buffer for storing the visual tilemap data.
	 *  
	 * @param TileWidth		The width of the tiles in this tilemap.
	 * @param TileHeight	The height of the tiles in this tilemap.
	 * @param WidthInTiles	How many tiles wide the tilemap is.
	 * @param HeightInTiles	How many tiles tall the tilemap is.
	 * @param Camera		Which camera this buffer relates to.
	 */
	public function new(TileWidth:Float,TileHeight:Float,WidthInTiles:UInt,HeightInTiles:UInt,Camera:HxlCamera=null)
	{
		if(Camera == null)
			Camera = HxlG.camera;

		columns = HxlU.ceil(Camera.width/TileWidth)+1;
		if(columns > WidthInTiles)
			columns = WidthInTiles;
		rows = HxlU.ceil(Camera.height/TileHeight)+1;
		if(rows > HeightInTiles)
			rows = HeightInTiles;
		
		_pixels = new BitmapData(columns*TileWidth,rows*TileHeight,true,0);
		width = _pixels.width;
		height = _pixels.height;			
		_flashRect = new Rectangle(0,0,width,height);
		dirty = true;
	}
	
	/**
	 * Clean up memory.
	 */
	public function destroy():Void
	{
		_pixels = null;
	}
	
	/**
	 * Fill the buffer with the specified color.
	 * Default value is transparent.
	 * 
	 * @param	Color	What color to fill with, in 0xAARRGGBB hex format.
	 */
	public function fill(Color:UInt=0):Void
	{
		_pixels.fillRect(_flashRect,Color);
	}
	
	/**
	 * Read-only, nab the actual buffer <code>BitmapData</code> object.
	 * 
	 * @return	The buffer bitmap data.
	 */
	public var pixels(getPixels, setPixels):BitmapData;
	public function getPixels():BitmapData
	{
		return _pixels;
	}
	
	public function setPixels(holder:BitmapData):BitmapData
	{
		// Placeholder to make haXe compiler happy.
	}


	/**
	 * Just stamps this buffer onto the specified camera at the specified location.
	 * 
	 * @param	Camera		Which camera to draw the buffer onto.
	 * @param	FlashPoint	Where to draw the buffer at in camera coordinates.
	 */
	public function draw(Camera:HxlCamera,FlashPoint:Point):Void
	{
		Camera.buffer.copyPixels(_pixels,_flashRect,FlashPoint,null,null,true);
	}
}