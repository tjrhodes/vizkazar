package pattern;

/** A place on the flat picture, or an arrow from one place to another. */
typedef Point = {x:Float, y:Float};

/** A box standing square on the picture: from `left` to `right` along, `bottom` to `top` across. */
typedef Box = {left:Float, right:Float, bottom:Float, top:Float};

/**
 * The few bits of school geometry the pattern is built from.
 * Angles are in radians unless a name says degrees.
 */
class Geometry {
	public static inline final fullTurn = 6.283185307179586;

	public static function radians(degrees:Float):Float {
		return degrees * fullTurn / 360;
	}

	/** The point you reach walking `distance` from `start` in the direction `angle`. */
	public static function pointAtAngle(start:Point, distance:Float, angle:Float):Point {
		return {x: start.x + distance * Math.cos(angle), y: start.y + distance * Math.sin(angle)};
	}

	public static function halfwayBetween(a:Point, b:Point):Point {
		return {x: (a.x + b.x) / 2, y: (a.y + b.y) / 2};
	}

	public static function distanceBetween(a:Point, b:Point):Float {
		return Math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
	}

	/** The average of some points: the middle of a kite or a star. */
	public static function middleOf(points:Array<Point>):Point {
		var x = 0.0, y = 0.0;
		for (point in points) {
			x += point.x;
			y += point.y;
		}
		return {x: x / points.length, y: y / points.length};
	}

	/**
	 * The same shape (it must have no dents), every side moved `distance`
	 * in towards the middle. Blocks are shrunk like this so a groove is
	 * left between neighbours, where the cream strapwork shows.
	 */
	public static function inset(outline:Array<Point>, distance:Float):Array<Point> {
		final middle = middleOf(outline), sides = outline.length;
		return [
			for (corner in 0...sides)
				insetCorner(outline[(corner + sides - 1) % sides], outline[corner], outline[(corner + 1) % sides], middle, distance)
		];
	}

	/** Where a corner ends up when both its sides are moved in: where the two moved sides now cross. */
	static function insetCorner(before:Point, corner:Point, after:Point, middle:Point, distance:Float):Point {
		final sideIn = movedTowards(before, corner, middle, distance), sideOut = movedTowards(corner, after, middle, distance);
		return whereRaysCross(sideIn.from, sideIn.along, sideOut.from, sideOut.along);
	}

	/** The side from `a` to `b`, moved `distance` towards `middle`: a starting place and a direction. */
	static function movedTowards(a:Point, b:Point, middle:Point, distance:Float):{from:Point, along:Point} {
		final along = directionFrom(a, b);
		final inwardSign = (middle.x - a.x) * -along.y + (middle.y - a.y) * along.x >= 0 ? 1 : -1;
		return {from: {x: a.x - along.y * distance * inwardSign, y: a.y + along.x * distance * inwardSign}, along: along};
	}

	/**
	 * A band `width` wide running from one place to another, as four
	 * corners. It reaches half its width past each end, so bands meeting
	 * at an angle overlap at the joint and leave no notch.
	 */
	public static function strip(from:Point, to:Point, width:Float):Array<Point> {
		final along = directionFrom(from, to);
		final ahead = {x: along.x * width / 2, y: along.y * width / 2};
		final aside = {x: -ahead.y, y: ahead.x};
		return [
			{x: from.x - ahead.x - aside.x, y: from.y - ahead.y - aside.y},
			{x: to.x + ahead.x - aside.x, y: to.y + ahead.y - aside.y},
			{x: to.x + ahead.x + aside.x, y: to.y + ahead.y + aside.y},
			{x: from.x - ahead.x + aside.x, y: from.y - ahead.y + aside.y}
		];
	}

	/** An arrow of length 1 pointing from one place towards another. */
	public static function directionFrom(from:Point, to:Point):Point {
		final length = distanceBetween(from, to);
		return {x: (to.x - from.x) / length, y: (to.y - from.y) / length};
	}

	/** Mixes two directions: all `along` at angle 0, all `across` at a quarter turn. */
	public static function leaning(along:Point, across:Point, angle:Float):Point {
		final a = Math.cos(angle), b = Math.sin(angle);
		return {x: along.x * a + across.x * b, y: along.y * a + across.y * b};
	}

	/**
	 * Where two rays cross. Each ray is a starting place and a direction.
	 * (If they run parallel they never cross: we answer halfway between the
	 * starts, which is where they would have met had they leaned a hair inward.)
	 */
	public static function whereRaysCross(startA:Point, directionA:Point, startB:Point, directionB:Point):Point {
		final spread = directionA.x * directionB.y - directionA.y * directionB.x;
		if (Math.abs(spread) < 1e-9)
			return halfwayBetween(startA, startB);
		final alongA = ((startB.x - startA.x) * directionB.y - (startB.y - startA.y) * directionB.x) / spread;
		return {x: startA.x + directionA.x * alongA, y: startA.y + directionA.y * alongA};
	}

	/** The four corners of a box, going round. */
	public static function cornersOf(box:Box):Array<Point> {
		return [{x: box.left, y: box.bottom}, {x: box.right, y: box.bottom}, {x: box.right, y: box.top}, {x: box.left, y: box.top}];
	}

	/**
	 * The part of a shape (no dents) inside a box: cut off straight along
	 * each side of the box, like trimming a tile to fit against a wall.
	 * Answers fewer than three points if nothing is left.
	 */
	public static function clippedToBox(outline:Array<Point>, box:Box):Array<Point> {
		if (Lambda.foreach(outline, point -> isInside(point, box)))
			return outline;
		final leftKept = keptBefore(outline, point -> box.left - point.x);
		final rightKept = keptBefore(leftKept, point -> point.x - box.right);
		final bottomKept = keptBefore(rightKept, point -> box.bottom - point.y);
		return keptBefore(bottomKept, point -> point.y - box.top);
	}

	static function isInside(point:Point, box:Box):Bool {
		return point.x >= box.left && point.x <= box.right && point.y >= box.bottom && point.y <= box.top;
	}

	/**
	 * A shape (no dents) cut by straight lines running along it, at the
	 * `heights` given (y values, lowest first), into the pieces between
	 * them. Empty pieces are left out.
	 */
	public static function slicedAtHeights(outline:Array<Point>, heights:Array<Float>):Array<Array<Point>> {
		final bounds = [Math.NEGATIVE_INFINITY].concat(heights).concat([Math.POSITIVE_INFINITY]);
		final pieces = [
			for (piece in 0...bounds.length - 1)
				keptBefore(keptBefore(outline, point -> point.y - bounds[piece + 1]), point -> bounds[piece] - point.y)
		];
		return pieces.filter(piece -> piece.length >= 3);
	}

	/**
	 * The part of a shape (no dents) on this side of a straight line.
	 * `beyond` says how far past the line a point is: points with 0 or less
	 * are kept, and where a side crosses the line a new corner is made.
	 */
	static function keptBefore(outline:Array<Point>, beyond:Point->Float):Array<Point> {
		final kept = [];
		for (corner in 0...outline.length) {
			final here = outline[corner], next = outline[(corner + 1) % outline.length];
			final pastHere = beyond(here), pastNext = beyond(next);
			if (pastHere <= 0)
				kept.push(here);
			if ((pastHere <= 0) != (pastNext <= 0))
				kept.push(partWay(here, next, pastHere / (pastHere - pastNext)));
		}
		return kept;
	}

	/** The point `share` of the way from `a` to `b`. */
	public static function partWay(a:Point, b:Point, share:Float):Point {
		return {x: a.x + (b.x - a.x) * share, y: a.y + (b.y - a.y) * share};
	}

	/** A point turned `angle` about the middle of the picture. */
	public static function turnedAboutMiddle(point:Point, angle:Float):Point {
		final cos = Math.cos(angle), sin = Math.sin(angle);
		return {x: point.x * cos - point.y * sin, y: point.x * sin + point.y * cos};
	}
}
