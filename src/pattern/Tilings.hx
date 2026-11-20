package pattern;

import pattern.Geometry.Point;
import picture.Palette.FamilyInHex;
import pattern.Tile.TileRecipe;

/** One way of covering the floor with regular polygons, repeated in two directions. */
typedef Tiling = {
	/** The name shown in the complexity menu. */
	name:String,
	/** One repeat of the tiling to the right, and one repeat up-and-across. */
	stepAcross:Point,
	stepUp:Point,
	/** The tiles inside one repeat. */
	tiles:Array<TileRecipe>,
	/** How many edges fit across the longest side of the screen: bigger means finer. */
	edgesAcrossScreen:Float,
	/** The contact angle (see StarCutter) the stars rest at, in degrees. */
	restingContactDegrees:Float,
	/** How full the music's level must be (0 to 1) before this tiling appears. */
	wakesAtFullness:Float,
	/** The colour family it is drawn in. */
	colours:FamilyInHex
}

/**
 * The tilings the piece moves through as the music fills out, simplest first.
 * Each is one of the classic grids under Islamic star patterns: the number
 * in its name is the number of points on its biggest stars.
 *
 * The square roots below are just where the tiles must sit for edges of
 * length 1 to meet exactly; nothing about them is tuned by eye.
 */
class Tilings {
	static final root2 = Math.sqrt(2);
	static final root3 = Math.sqrt(3);

	/** Corner distance of a regular polygon whose edges are 1 long. */
	static function cornerDistanceFor(sides:Int):Float {
		return 0.5 / Math.sin(Geometry.fullTurn / 2 / sides);
	}

	static function tile(sides:Int, firstCornerDegrees:Float, x:Float, y:Float):TileRecipe {
		return {
			sides: sides,
			cornerDistance: cornerDistanceFor(sides),
			firstCornerDegrees: firstCornerDegrees,
			placeInRepeat: {x: x, y: y}
		};
	}

	/** Squares, like graph paper: four-pointed stars. */
	static final fourFold:Tiling = {
		name: "4-fold",
		stepAcross: {x: 1, y: 0},
		stepUp: {x: 0, y: 1},
		tiles: [tile(4, 45, 0, 0)],
		edgesAcrossScreen: 9,
		restingContactDegrees: 62,
		wakesAtFullness: 0,
		colours: Settings.cobaltFamily
	};

	/** Hexagons, like honeycomb: the six-pointed stars of the carved wooden panel. */
	static final sixFold:Tiling = {
		name: "6-fold",
		stepAcross: {x: root3, y: 0},
		stepUp: {x: root3 / 2, y: 1.5},
		tiles: [tile(6, 30, 0, 0)],
		edgesAcrossScreen: 15,
		restingContactDegrees: 58,
		wakesAtFullness: 0.4,
		colours: Settings.greenFamily
	};

	/** Octagons with a small square in each gap: eight-pointed stars. */
	static final eightFold:Tiling = {
		name: "8-fold",
		stepAcross: {x: 1 + root2, y: 0},
		stepUp: {x: 0, y: 1 + root2},
		tiles: [tile(8, 22.5, 0, 0), tile(4, 0, (1 + root2) / 2, (1 + root2) / 2)],
		edgesAcrossScreen: 19,
		restingContactDegrees: 66,
		wakesAtFullness: 0.62,
		colours: Settings.purpleFamily
	};

	/** Twelve-sided tiles with a small triangle in each gap: the twelve-petalled rosettes of the zellige. */
	static final twelveFold:Tiling = {
		name: "12-fold",
		stepAcross: {x: 2 + root3, y: 0},
		stepUp: {x: (2 + root3) / 2, y: (2 + root3) * root3 / 2},
		tiles: [
			tile(12, 15, 0, 0),
			tile(3, 30, (2 + root3) / 2, (2 + root3) * root3 / 6),
			tile(3, 90, 0, (2 + root3) * root3 / 3)
		],
		edgesAcrossScreen: 26,
		restingContactDegrees: 64,
		wakesAtFullness: 0.82,
		colours: Settings.ochreFamily
	};

	public static final simplestFirst:Array<Tiling> = [fourFold, sixFold, eightFold, twelveFold];

	/** The tiling to wait underneath this one: the next more complex, or for the most complex, the one before it. */
	public static function neighbourOf(tiling:Tiling):Tiling {
		final at = simplestFirst.indexOf(tiling);
		return at + 1 < simplestFirst.length ? simplestFirst[at + 1] : simplestFirst[at - 1];
	}
}
