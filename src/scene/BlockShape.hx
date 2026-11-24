package scene;

import three.Three;

/**
 * The shape the graphics card draws for a set of blocks, made from a
 * MeshWriter's lists of numbers. The blocks are rewritten every frame and
 * how many there are changes (blocks on their edge are left out), so each
 * frame only the part written is drawn.
 */
class BlockShape {
	public var geometry(default, null) = new BufferGeometry();

	var positions:BufferAttribute;
	var colours:BufferAttribute;
	var index:BufferAttribute;

	public function new() {}

	/** The look every block shares: flat colours, coloured corner by corner, with no light at all. */
	public static function flat():MeshBasicMaterial {
		return new MeshBasicMaterial({vertexColors: true, side: Three.DoubleSide});
	}

	/** Starts drawing from a new writer's lists (a new tiling was laid); the old shape is let go. */
	public function takeFrom(writer:MeshWriter) {
		final old = geometry;
		geometry = new BufferGeometry();
		positions = new BufferAttribute(writer.positions, 3);
		colours = new BufferAttribute(writer.colours, 3);
		index = new BufferAttribute(writer.index, 1);
		geometry.setAttribute("position", positions);
		geometry.setAttribute("color", colours);
		geometry.setIndex(index);
		old.dispose();
	}

	/** Sends this frame's blocks to the graphics card, and draws only as many as were written. */
	public function refresh(writer:MeshWriter) {
		positions.needsUpdate = true;
		colours.needsUpdate = true;
		index.needsUpdate = true;
		geometry.setDrawRange(0, writer.indicesWritten);
	}
}
