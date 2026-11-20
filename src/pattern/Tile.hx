package pattern;

import pattern.Geometry.Point;

/** How to make one kind of tile in a tiling: a regular polygon, placed and turned. */
typedef TileRecipe = {
	/** How many sides (and so corners) the polygon has. */
	sides:Int,
	/** How far each corner is from the tile's centre, in edges. */
	cornerDistance:Float,
	/** The direction of the first corner, in degrees; the rest follow evenly round. */
	firstCornerDegrees:Float,
	/** Where this tile sits inside one repeat of the tiling. */
	placeInRepeat:Point
}

/**
 * One tile laid on the floor: a regular polygon with edges of length 1.
 * These are the plain tiles the stars are later cut out of (see StarCutter).
 */
class Tile {
	static final middleOfPicture:Point = {x: 0, y: 0};

	public final centre:Point;
	public final corners:Array<Point>;

	/** Sound ripples outward from the middle, so each tile knows how far out it is. */
	public final edgesFromMiddle:Float;

	/** How far its corners reach from its own centre. */
	public final reach:Float;

	public var sides(get, never):Int;

	public function new(centre:Point, recipe:TileRecipe) {
		this.centre = centre;
		final firstCorner = Geometry.radians(recipe.firstCornerDegrees);
		final cornerToCorner = Geometry.fullTurn / recipe.sides;
		corners = [
			for (corner in 0...recipe.sides)
				Geometry.pointAtAngle(centre, recipe.cornerDistance, firstCorner + corner * cornerToCorner)
		];
		edgesFromMiddle = Geometry.distanceBetween(middleOfPicture, centre);
		reach = recipe.cornerDistance;
	}

	function get_sides():Int {
		return corners.length;
	}

	/** Corners go round in a circle, so the one after the last is the first again. */
	public function cornerAt(index:Int):Point {
		return corners[(index + sides) % sides];
	}
}
