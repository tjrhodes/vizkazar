package scene;

import js.lib.Float32Array;
import js.lib.Uint32Array;
import picture.Palette.Colour;
import scene.Stage.Spot;

/**
 * How a block is coloured, the RAI 2 way: no light at all, just three flat
 * tones. Faces pointing up at you take `top`; the sides take `left` or
 * `right`, by which way they face.
 */
typedef Look = {top:Colour, left:Colour, right:Colour};

/**
 * Writes solid blocks into the long lists of numbers the graphics card
 * draws from: where every corner is, what colour it is, and which three
 * corners make each triangle.
 *
 * Every block is a SLAB: a flat outline (the bottom) and the same outline
 * moved somewhere else (the top), joined by side faces. Each face gets its
 * colour from the way it points at that moment, so a block turning over
 * shows its sides and top in the right tones all the way round.
 */
class MeshWriter {
	static inline final brightest = 255;

	public final positions:Float32Array;
	public final colours:Float32Array;
	public final index:Uint32Array;

	var cornersWritten = 0;

	/** How many indices this frame's blocks use: only these are drawn. */
	public var indicesWritten(default, null) = 0;

	/** Corners a block needs: every face has a middle and its own corners (top and bottom the outline's, each side face four). */
	public static function cornersFor(outlineLength:Int):Int {
		return 2 * (1 + outlineLength) + 5 * outlineLength;
	}

	/** Indices a block needs: per side, one triangle on top, one underneath and four in the side face, three corners each. */
	public static function indicesFor(outlineLength:Int):Int {
		return 18 * outlineLength;
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

	/** A block from its `bottom` face to its `top` face (the same corners, moved), joined by side faces. */
	public function addSlab(bottom:Array<Spot>, top:Array<Spot>, look:Look) {
		final inside = Spots.middleOf(bottom.concat(top));
		addFace(top, look, inside);
		addFace(bottom, look, inside);
		for (side in 0...bottom.length) {
			final next = (side + 1) % bottom.length;
			addFace([top[side], bottom[side], bottom[next], top[next]], look, inside);
		}
	}

	/** A flat face, in the tone for the way it points: triangles fanning out from its middle to each side. */
	function addFace(outline:Array<Spot>, look:Look, inside:Spot) {
		final colour = toneFacing(Spots.facing(outline, inside), look), first = cornersWritten;
		addCorner(Spots.middleOf(outline), colour);
		for (spot in outline)
			addCorner(spot, colour);
		for (side in 0...outline.length)
			addTriangle(first, first + 1 + side, first + 1 + (side + 1) % outline.length);
	}

	/**
	 * The tone for a face pointing along `facing`: up towards you is the
	 * top; otherwise a side, lighter facing left and darker facing right,
	 * as if lit from the left (though nothing is lit: the tones are fixed).
	 */
	static function toneFacing(facing:Spot, look:Look):Colour {
		if (facing.z >= Settings.facesCountAsTopsFrom)
			return look.top;
		return facing.x < 0 ? look.left : look.right;
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
