package pattern;

import pattern.Tilings.Tiling;

/**
 * Where a tiling is its own mirror image, across a line running along it
 * (y = some height), and where the corridor's corners should fall.
 *
 * Every tiling here is mirrored across y = 0. It repeats itself going up
 * every `verticalRepeat`, so it is mirrored across every half repeat as
 * well. A corridor wall reaching from one such line to the other (y = -W
 * to W) folds round its corners like paper: a block crossing a corner
 * line is cut exactly down its own middle, and its other half is the
 * neighbouring wall's mirror image, so folded round the corner it is the
 * whole block again.
 *
 * Best of all is a mirror line no tile crosses, running along a white gap
 * of the strapwork: then no block is cut at the corner at all.
 */
class MirrorLines {
	/** A half width this far from the one asked for still looks right. */
	static inline final mayStrayBy = 0.4;

	/** Tiles this far round the middle are enough to find the white gaps. */
	static inline final tilesLookedAt = 12.0;

	static inline final nearlyZero = 1e-6;

	/**
	 * Half the corridor's width (edges) for a tiling, close to `wanted`:
	 * the nearest mirror line along a white gap if there is one near
	 * enough, otherwise the nearest mirror line.
	 */
	public static function wallHalfWidth(tiling:Tiling, wanted:Float):Float {
		final lines = linesUpTo(tiling, wanted * (1 + mayStrayBy));
		final nearEnough = lines.filter(line -> Math.abs(line - wanted) <= wanted * mayStrayBy);
		final gaps = nearEnough.filter(line -> runsAlongAGap(tiling, line));
		return closestTo(wanted, gaps.length > 0 ? gaps : lines);
	}

	/** Every mirror line above the middle, up to `highest`. */
	static function linesUpTo(tiling:Tiling, highest:Float):Array<Float> {
		final apart = verticalRepeat(tiling) / 2;
		return [for (step in 1...Math.ceil(highest / apart) + 1) step * apart];
	}

	/**
	 * How far up the tiling goes before it repeats exactly above itself:
	 * one step up, or a few if each step up also shifts it sideways (the
	 * honeycomb tilings), until the sideways shift is whole repeats.
	 */
	static function verticalRepeat(tiling:Tiling):Float {
		var steps = 1;
		while (!isWholeRepeatsAcross(steps * tiling.stepUp.x, tiling.stepAcross.x))
			steps++;
		return steps * tiling.stepUp.y;
	}

	static function isWholeRepeatsAcross(shift:Float, repeat:Float):Bool {
		final repeats = shift / repeat;
		return Math.abs(repeats - Math.round(repeats)) < nearlyZero;
	}

	/** Whether no tile crosses the line y = `height`: it runs along a white gap between tiles. */
	static function runsAlongAGap(tiling:Tiling, height:Float):Bool {
		return !Lambda.exists(Floor.laid(tiling, height + tilesLookedAt), tile -> crosses(tile, height));
	}

	static function crosses(tile:Tile, height:Float):Bool {
		final below = Lambda.exists(tile.corners, corner -> corner.y < height - nearlyZero);
		final above = Lambda.exists(tile.corners, corner -> corner.y > height + nearlyZero);
		return below && above;
	}

	static function closestTo(wanted:Float, lines:Array<Float>):Float {
		var closest = lines[0];
		for (line in lines)
			if (Math.abs(line - wanted) < Math.abs(closest - wanted))
				closest = line;
		return closest;
	}
}
