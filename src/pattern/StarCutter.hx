package pattern;

import pattern.Geometry.Point;

/**
 * The four-sided piece cut off at one corner of a tile. It is a kite: its
 * left and right halves mirror each other across the line from `corner` to
 * `innerPoint`, which is what will let it flip over in the 3D version.
 */
typedef Kite = {
	middleBefore:Point,
	corner:Point,
	middleAfter:Point,
	innerPoint:Point
}

/** A tile after cutting: a star in the middle and one kite at every corner. */
typedef CutTile = {
	star:Array<Point>,
	kites:Array<Kite>
}

/**
 * Cuts a star out of a plain tile, the way the craftsmen's patterns can be
 * drawn (the method is known as "polygons in contact").
 *
 * From the middle of every edge, two lines set off into the tile, one
 * leaning towards each end of the edge. Both leave the edge at the same
 * angle: the CONTACT ANGLE. Where the lines from neighbouring edges cross,
 * a point of the star appears.
 *
 * The tile next door does the same from the same edge-middle at the same
 * angle, so every line carries straight on across the edge. That is why
 * the stars of separate tiles join up into one unbroken woven pattern.
 *
 * The whole look hangs on that one angle: small and the stars are fat with
 * tiny kites; near a quarter turn they shrink to thin needles.
 */
class StarCutter {
	public static function cut(tile:Tile, contactAngle:Float):CutTile {
		final kites = [for (corner in 0...tile.sides) kiteAtCorner(tile, corner, contactAngle)];
		return {star: starBetween(kites), kites: kites};
	}

	/** The kite at one corner: the corner, the middles of its two edges, and where their lines cross. */
	static function kiteAtCorner(tile:Tile, index:Int, contactAngle:Float):Kite {
		final corner = tile.cornerAt(index);
		final middleBefore = Geometry.halfwayBetween(tile.cornerAt(index - 1), corner);
		final middleAfter = Geometry.halfwayBetween(corner, tile.cornerAt(index + 1));
		final lineBefore = lineLeaningTowards(corner, middleBefore, tile.centre, contactAngle);
		final lineAfter = lineLeaningTowards(corner, middleAfter, tile.centre, contactAngle);
		return {
			middleBefore: middleBefore,
			corner: corner,
			middleAfter: middleAfter,
			innerPoint: Geometry.whereRaysCross(middleBefore, lineBefore, middleAfter, lineAfter)
		};
	}

	/**
	 * The direction of the line leaving an edge's middle towards one of its
	 * corners: along the edge at angle 0, straight in to the tile's centre
	 * at a quarter turn, and leaning in between for anything between.
	 */
	static function lineLeaningTowards(corner:Point, edgeMiddle:Point, tileCentre:Point, contactAngle:Float):Point {
		final alongEdge = Geometry.directionFrom(edgeMiddle, corner);
		final intoTile = Geometry.directionFrom(edgeMiddle, tileCentre);
		return Geometry.leaning(alongEdge, intoTile, contactAngle);
	}

	/** The star is what is left in the middle: round it goes, an inner point then an edge-middle, in turn. */
	static function starBetween(kites:Array<Kite>):Array<Point> {
		final outline = [];
		for (kite in kites) {
			outline.push(kite.innerPoint);
			outline.push(kite.middleAfter);
		}
		return outline;
	}
}
