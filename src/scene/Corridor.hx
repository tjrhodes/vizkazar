package scene;

import Conductor.Pose;
import pattern.Tilings.Tiling;
import scene.Stage.Spot;
import scene.WallBlocks.WallCut;
import sound.Memory;
import three.Three;

/** How one wall sits: which way across it runs, which way its blocks stand out, and where it is (in corridor units). */
typedef WallPlace = {
	across:Spot,
	out:Spot,
	at:Spot
}

/**
 * The corridor the camera travels down, like the room in the RAI 4
 * ident: floor, ceiling and both side walls carry the same wall of
 * blocks, mirrored, so wherever you look there is a lit solid surface.
 * The walls slide towards the camera (sliding by exactly one repeat of
 * the pattern looks the same, so they can slide for ever), faster for a
 * moment on each kick.
 *
 * Where two walls meet, the blocks on both sides of the corner are one
 * corner block, folded round it and pushing out at 45° (see WallCut). For
 * that, each wall is the floor turned round the corridor's middle line by
 * a quarter turn more than the last, so every corner has one wall's top
 * edge on one side and the next wall's bottom edge on the other. Each frame shows only a stretch of the corridor: during
 * a doorway, the old corridor ends at the door and the new one starts there.
 *
 * The four walls share one set of blocks, built once a frame, and each
 * places it with its own matrix. Corridor units: half the corridor's
 * width is 1; the camera is in the middle, looking down -z.
 */
class Corridor {
	static final walls:Array<WallPlace> = [
		{across: {x: 1, y: 0, z: 0}, out: {x: 0, y: 1, z: 0}, at: {x: 0, y: -1, z: 0}}, // floor
		{across: {x: 0, y: 1, z: 0}, out: {x: -1, y: 0, z: 0}, at: {x: 1, y: 0, z: 0}}, // right
		{across: {x: -1, y: 0, z: 0}, out: {x: 0, y: -1, z: 0}, at: {x: 0, y: 1, z: 0}}, // ceiling
		{across: {x: 0, y: -1, z: 0}, out: {x: 1, y: 0, z: 0}, at: {x: -1, y: 0, z: 0}} // left
	];

	/** Besides the pattern, each wall has its cream backing. */
	static inline final creamPieces = 1;

	final blocks = new WallBlocks();
	final shape = new BlockShape();
	final meshes:Array<Mesh>;

	/** How far the walls have slid so far, in edges of the tiling laid. */
	var slid = 0.0;

	public function new(stage:Stage) {
		final matte = BlockShape.matte();
		meshes = [for (_ in walls) new Mesh(shape.geometry, matte)];
		for (mesh in meshes)
			placeable(mesh, stage);
	}

	/** Each wall's place is set by hand every frame, and its shape changes every frame. */
	static function placeable(mesh:Mesh, stage:Stage) {
		mesh.matrixAutoUpdate = false;
		mesh.frustumCulled = false;
		stage.add(mesh);
	}

	public function tiling():Tiling {
		return blocks.tiling;
	}

	public function show(shown:Bool) {
		for (mesh in meshes)
			mesh.visible = shown;
	}

	/** Lays a new tiling on every wall, from behind the camera to the far end. */
	public function lay(tiling:Tiling) {
		blocks.lay(tiling, -Settings.corridorBehindCamera, Settings.corridorLength, creamPieces);
		slid = slid % blocks.repeat;
		shape.takeFrom(blocks.writer);
		for (mesh in meshes)
			mesh.geometry = shape.geometry;
	}

	/**
	 * One frame: slides the walls on `travel` (corridor units), rebuilds
	 * the stretch from `nearest` to `furthest` (corridor units from the
	 * camera) and puts every wall in its place.
	 */
	public function update(pose:Pose, memory:Memory, now:Float, travel:Float, nearest:Float, furthest:Float) {
		final width = blocks.halfWidth;
		slid = (slid + travel * width) % blocks.repeat;
		final from = slid + nearest * width, to = slid + furthest * width;
		blocks.startFrame(cutFrom(from, to));
		blocks.addPattern(pose, memory, now);
		addCream(from, to);
		shape.refresh(blocks.writer);
		for (wall in 0...walls.length)
			place(meshes[wall], walls[wall]);
	}

	/** The pattern runs from `from` to `to` along (edges) and right across, with corner blocks where the walls meet. */
	function cutFrom(from:Float, to:Float):WallCut {
		final width = blocks.halfWidth;
		return {
			box: {left: from, right: to, bottom: -width, top: width},
			corners: true,
			plates: false,
			spread: 0,
			twist: 0,
			unitsAwayOf: place -> Math.max(0, place.x - slid) / width
		};
	}

	/** The cream wall behind the blocks: a little wider than the wall, running on behind its neighbours, so no crack shows in the corners. */
	function addCream(from:Float, to:Float) {
		final width = blocks.halfWidth * Settings.creamWallWiderTimes;
		blocks.addCream({left: from, right: to, bottom: -width, top: width}, Settings.creamWallDepth * blocks.halfWidth);
	}

	/**
	 * Puts a wall in its place. The wall is built flat: along it (x, the
	 * corridor's length, which runs away from the camera down -z), across
	 * it (y) and out of it (z). The matrix turns those three into the
	 * wall's own directions, shrinks edges to corridor units, and moves it
	 * to its side, slid towards the camera.
	 */
	function place(mesh:Mesh, wall:WallPlace) {
		final shrink = 1 / blocks.halfWidth;
		final a = wall.across, o = wall.out, at = wall.at;
		mesh.matrix.set(0, a.x * shrink, o.x * shrink, at.x, 0, a.y * shrink, o.y * shrink, at.y, -shrink, a.z * shrink, o.z * shrink,
			at.z + slid * shrink, 0, 0, 0, 1);
		mesh.matrixWorldNeedsUpdate = true;
	}
}
