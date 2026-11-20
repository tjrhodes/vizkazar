package scene;

import js.lib.Float32Array;
import js.lib.Uint32Array;
import pattern.Geometry.Point;
import picture.Palette.Colour;
import scene.Stage.Spot;

/** How a block is coloured: its top, its sides, and its underneath. */
typedef Look = {top:Colour, sides:Colour, bottom:Colour};

/**
 * Writes solid blocks into the long lists of numbers the graphics card
 * draws from: where every corner is, what colour it is, and which three
 * corners make each triangle.
 *
 * Every block is a SLAB: a flat outline (the bottom) and the same outline
 * moved somewhere else (the top), joined by walls. Usually the top is
 * straight above the bottom, a prism; but it can be pushed out at a slant
 * (a corner block moving out at 45°), as long as both faces stay flat. Top, walls and
 * bottom each have their own corners, so each has its own colour. Faces
 * are cut into triangles fanning out from the middle, which works for
 * every shape used here.
 */
class MeshWriter {
	static inline final brightest = 255;

	public final positions:Float32Array;
	public final colours:Float32Array;
	public final index:Uint32Array;

	var cornersWritten = 0;

	/** How many indices this frame's blocks use: only these are drawn. */
	public var indicesWritten(default, null) = 0;

	/** Corners a block needs: top and bottom (a middle and the outline each), and two per wall corner. */
	public static function cornersFor(outlineLength:Int):Int {
		return 2 * (1 + outlineLength) + 2 * outlineLength;
	}

	/** Indices a block needs: per side, one triangle on top, one underneath and two in the wall, three corners each. */
	public static function indicesFor(outlineLength:Int):Int {
		return 12 * outlineLength;
	}

	public function new(corners:Int, indices:Int) {
		positions = new Float32Array(corners * 3);
		colours = new Float32Array(corners * 3);
		index = new Uint32Array(indices);
	}

	/** Starts writing from the beginning again (the blocks are rewritten every frame). */
	public function rewind() {
		cornersWritten = 0;
		indicesWritten = 0;
	}

	/** A block standing on the flat wall: `outline` raised to `heightAt` each point. */
	public function addPrism(outline:Array<Point>, heightAt:Point->Float, look:Look) {
		final bottom = [for (point in outline) {x: point.x, y: point.y, z: 0.0}];
		final top = [for (point in outline) {x: point.x, y: point.y, z: heightAt(point)}];
		addSlab(bottom, top, look);
	}

	/** A block from its `bottom` face to its `top` face (the same corners, moved), joined by walls. */
	public function addSlab(bottom:Array<Spot>, top:Array<Spot>, look:Look) {
		addFace(top, look.top);
		addFace(bottom, look.bottom);
		addWalls(bottom, top, look.sides);
	}

	/** A flat face: triangles fanning out from its middle to each side. */
	function addFace(outline:Array<Spot>, colour:Colour) {
		final first = cornersWritten;
		addCorner(middleOf(outline), colour);
		for (spot in outline)
			addCorner(spot, colour);
		for (side in 0...outline.length)
			addTriangle(first, first + 1 + side, first + 1 + (side + 1) % outline.length);
	}

	/** The walls: each side of the outline, from the bottom up to the top, as two triangles. */
	function addWalls(bottom:Array<Spot>, top:Array<Spot>, colour:Colour) {
		final first = cornersWritten, sides = bottom.length;
		for (corner in 0...sides) {
			addCorner(top[corner], colour);
			addCorner(bottom[corner], colour);
		}
		for (side in 0...sides) {
			final upper = first + 2 * side, nextUpper = first + 2 * ((side + 1) % sides);
			addTriangle(upper, upper + 1, nextUpper + 1);
			addTriangle(upper, nextUpper + 1, nextUpper);
		}
	}

	static function middleOf(outline:Array<Spot>):Spot {
		var x = 0.0, y = 0.0, z = 0.0;
		for (spot in outline) {
			x += spot.x;
			y += spot.y;
			z += spot.z;
		}
		return {x: x / outline.length, y: y / outline.length, z: z / outline.length};
	}

	function addCorner(spot:Spot, colour:Colour) {
		final at = cornersWritten * 3;
		positions[at] = spot.x;
		positions[at + 1] = spot.y;
		positions[at + 2] = spot.z;
		colours[at] = colour.red / brightest;
		colours[at + 1] = colour.green / brightest;
		colours[at + 2] = colour.blue / brightest;
		cornersWritten++;
	}

	function addTriangle(a:Int, b:Int, c:Int) {
		index[indicesWritten] = a;
		index[indicesWritten + 1] = b;
		index[indicesWritten + 2] = c;
		indicesWritten += 3;
	}
}
