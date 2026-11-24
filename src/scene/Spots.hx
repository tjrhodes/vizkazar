package scene;

import scene.Stage.Spot;

/** Sums with places and directions in 3D (see Stage.Spot). */
class Spots {
	public static function minus(a:Spot, b:Spot):Spot {
		return {x: a.x - b.x, y: a.y - b.y, z: a.z - b.z};
	}

	public static function plus(a:Spot, b:Spot):Spot {
		return {x: a.x + b.x, y: a.y + b.y, z: a.z + b.z};
	}

	public static function scaled(a:Spot, by:Float):Spot {
		return {x: a.x * by, y: a.y * by, z: a.z * by};
	}

	public static function dot(a:Spot, b:Spot):Float {
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}

	public static function cross(a:Spot, b:Spot):Spot {
		return {x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x};
	}

	/** The same direction, one long (or no direction at all, left as it is). */
	public static function normalised(a:Spot):Spot {
		final length = Math.sqrt(dot(a, a));
		return length > 0 ? scaled(a, 1 / length) : a;
	}

	/** The middle of some places: their average. */
	public static function middleOf(spots:Array<Spot>):Spot {
		var sum:Spot = {x: 0, y: 0, z: 0};
		for (spot in spots)
			sum = plus(sum, spot);
		return scaled(sum, 1 / spots.length);
	}

	/**
	 * The direction a flat face points, away from `inside` (the middle of
	 * its block). Worked out from every corner of the face at once, so it
	 * holds for any flat shape whichever way round its corners go.
	 */
	public static function facing(face:Array<Spot>, inside:Spot):Spot {
		var sum:Spot = {x: 0, y: 0, z: 0};
		for (corner in 0...face.length)
			sum = plus(sum, cross(face[corner], face[(corner + 1) % face.length]));
		final outward = dot(sum, minus(middleOf(face), inside)) < 0 ? scaled(sum, -1) : sum;
		return normalised(outward);
	}

	/**
	 * A place turned `angle` (radians) about a line through `pivot` running
	 * along `axis` (one long), the way a right-hand screw turns.
	 */
	public static function turnedAbout(spot:Spot, pivot:Spot, axis:Spot, angle:Float):Spot {
		final from = minus(spot, pivot), cos = Math.cos(angle), sin = Math.sin(angle);
		final along = scaled(axis, dot(axis, from) * (1 - cos));
		return plus(pivot, plus(plus(scaled(from, cos), scaled(cross(axis, from), sin)), along));
	}
}
