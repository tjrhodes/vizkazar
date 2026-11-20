package scene;

import Conductor.Pose;
import pattern.Geometry;
import pattern.Tilings.Tiling;
import scene.WallBlocks.WallCut;
import sound.Memory;
import three.Three;

/**
 * The door between two scenes: a wall across the corridor carrying a big
 * rosette of the next pattern, in its own colours, inside a cream frame.
 * Its blocks push out with the equaliser like any wall's. It opens and
 * shuts like a camera's iris: opening, every block slides straight out
 * from the middle and turns a little, vanishing behind the frame; shutting,
 * they slide back in. The frame itself rises out of the walls as the door
 * first closes, so the door grows out of the corridor.
 *
 * Behind each block is a cream plate the full size of its piece, so the
 * shut door shows cream strapwork and no gaps; the plates slide with their
 * blocks. Door units are the corridor's: it fills from -1 to 1 both ways,
 * facing the camera.
 */
class Door {
	/** Four bars make the frame. */
	static inline final creamPieces = 4;

	final blocks = new WallBlocks();
	final shape = new BlockShape();
	final mesh:Mesh;

	public function new(stage:Stage) {
		mesh = new Mesh(shape.geometry, BlockShape.matte());
		mesh.matrixAutoUpdate = false;
		mesh.frustumCulled = false;
		stage.add(mesh);
		show(false);
	}

	public function show(shown:Bool) {
		mesh.visible = shown;
	}

	/** Lays the next tiling across the door, centred on a star, at the same size as on the walls. */
	public function lay(tiling:Tiling) {
		blocks.lay(tiling, -1, 1, creamPieces);
		shape.takeFrom(blocks.writer);
		mesh.geometry = shape.geometry;
	}

	/**
	 * One frame: the door `distance` (corridor units) down the corridor,
	 * its frame risen as far as `closed` and its blocks as `shut` (both from
	 * 0, not there, to 1).
	 */
	public function update(pose:Pose, memory:Memory, now:Float, distance:Float, closed:Float, shut:Float) {
		final inside = blocks.halfWidth * (1 - Settings.doorFrame * closed);
		blocks.startFrame(cutFor(distance, inside, 1 - shut));
		blocks.addPattern(pose, memory, now);
		addFrame(inside);
		shape.refresh(blocks.writer);
		place(distance);
	}

	/**
	 * Cut square inside the frame, each block on its plate; the iris slides
	 * and turns them out as far as `open`. The slide goes as the square of
	 * `open`: blocks only travel far once they are nearly out, so the iris
	 * is seen closing (and opening) over most of the way.
	 */
	function cutFor(distance:Float, inside:Float, open:Float):WallCut {
		return {
			box: {left: -inside, right: inside, bottom: -inside, top: inside},
			corners: false,
			plates: true,
			spread: open * open * Settings.doorOpensWidths * blocks.halfWidth,
			twist: Geometry.radians(open * Settings.doorTwistsDegrees),
			unitsAwayOf: _ -> distance
		};
	}

	/** The frame from the walls in to `inside`: a bar along the top and bottom the full width, and up each side between them. */
	function addFrame(inside:Float) {
		final width = blocks.halfWidth, depth = width * Settings.doorFrame;
		blocks.addCream({left: -width, right: width, bottom: inside, top: width}, depth);
		blocks.addCream({left: -width, right: width, bottom: -width, top: -inside}, depth);
		blocks.addCream({left: -width, right: -inside, bottom: -inside, top: inside}, depth);
		blocks.addCream({left: inside, right: width, bottom: -inside, top: inside}, depth);
	}

	/** Stands the door across the corridor, facing the camera, shrunk from edges to corridor units. */
	function place(distance:Float) {
		final shrink = 1 / blocks.halfWidth;
		mesh.matrix.set(shrink, 0, 0, 0, 0, shrink, 0, 0, 0, 0, shrink, -distance, 0, 0, 0, 1);
		mesh.matrixWorldNeedsUpdate = true;
	}
}
