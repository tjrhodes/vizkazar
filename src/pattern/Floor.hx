package pattern;

import pattern.Geometry.Point;
import pattern.Tile.TileRecipe;
import pattern.Tilings.Tiling;

/**
 * Lays a tiling out over the floor: repeats its tiles in both directions
 * until everything within reach of the middle is covered.
 */
class Floor {
	/** Slanted tilings (the honeycomb ones) need a few more repeats to cover the same ground. */
	static inline final extraRepeatsForSlant = 1.2;

	/** Every tile whose centre lies within `reach` edges of the middle of the picture. */
	public static function laid(tiling:Tiling, reach:Float):Array<Tile> {
		final repeats = repeatsNeeded(tiling, reach);
		final tiles = [];
		for (across in -repeats...repeats + 1)
			for (up in -repeats...repeats + 1)
				for (recipe in tiling.tiles)
					keepIfWithinReach(tiles, tileAt(tiling, recipe, across, up), reach);
		return tiles;
	}

	/**
	 * Every tile touching a long strip: from `fromX` to `toX` along, and
	 * `halfWidth` either side of the middle line across (a corridor wall).
	 */
	public static function laidInStrip(tiling:Tiling, fromX:Float, toX:Float, halfWidth:Float):Array<Tile> {
		final reach = Math.sqrt(Math.max(fromX * fromX, toX * toX) + halfWidth * halfWidth) + 2 * Settings.spareEdgesBeyondScreen;
		return laid(tiling, reach).filter(tile -> touchesStrip(tile, fromX, toX, halfWidth));
	}

	static function touchesStrip(tile:Tile, fromX:Float, toX:Float, halfWidth:Float):Bool {
		final along = tile.centre.x, across = Math.abs(tile.centre.y);
		return along >= fromX - tile.reach && along <= toX + tile.reach && across <= halfWidth + tile.reach;
	}

	static function repeatsNeeded(tiling:Tiling, reach:Float):Int {
		final shortestStep = Math.min(lengthOf(tiling.stepAcross), lengthOf(tiling.stepUp));
		return Math.ceil(reach * extraRepeatsForSlant / shortestStep) + 1;
	}

	static function lengthOf(step:Point):Float {
		return Geometry.distanceBetween({x: 0, y: 0}, step);
	}

	/** The tile from `recipe`, moved `across` and `up` whole repeats of the tiling. */
	static function tileAt(tiling:Tiling, recipe:TileRecipe, across:Int, up:Int):Tile {
		return new Tile({
			x: recipe.placeInRepeat.x + across * tiling.stepAcross.x + up * tiling.stepUp.x,
			y: recipe.placeInRepeat.y + across * tiling.stepAcross.y + up * tiling.stepUp.y
		}, recipe);
	}

	static function keepIfWithinReach(tiles:Array<Tile>, tile:Tile, reach:Float) {
		if (tile.edgesFromMiddle <= reach)
			tiles.push(tile);
	}
}
