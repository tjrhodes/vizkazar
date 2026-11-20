package scene;

import Conductor.Pose;
import pattern.Floor;
import pattern.Geometry;
import pattern.Geometry.Box;
import pattern.Geometry.Point;
import pattern.MirrorLines;
import scene.Stage.Spot;
import pattern.StarCutter;
import pattern.Tile;
import pattern.Tilings.Tiling;
import picture.Palette;
import scene.MeshWriter.Look;
import sound.Ear.Moment;
import sound.Memory;
import sound.PitchWheel;

/**
 * How a wall is cut for one frame. Its blocks are cut off straight along
 * `box`, so a wall ends on a clean line (at a corner of the corridor, or
 * at the doorway).
 */
typedef WallCut = {
	box:Box,
	/**
	 * In the corridor, walls meet in corners. The blocks near where two
	 * walls meet become CORNER BLOCKS: a block and its mirror twin on the
	 * next wall, built as one (see addCornerBlock), so blocks on two walls
	 * never run into each other. Each wall builds the corners at its top
	 * edge and leaves its bottom edge to its neighbour.
	 */
	corners:Bool,
	/** Gives every block a cream plate the full size of its piece behind it, which slides with it (the door). */
	plates:Bool,
	/** How far every block has slid out from the middle (edges), and turned (radians): the door opening like an iris. */
	spread:Float,
	twist:Float,
	/** How many corridor widths from the camera a place on the wall is: sound reaches it that much later. */
	unitsAwayOf:Point->Float
}

/**
 * One wall: the pattern built from large solid blocks packed edge to
 * edge, standing out of a cream wall like carved stucco. Every kite is a
 * block, and every star is cut into wedge blocks, one per point. A thin
 * groove between neighbours lets the cream wall show: that is the
 * strapwork.
 *
 * Each block is one bar of a graphic equaliser: it stands out of the wall
 * as far as its band is loud. Round each star, the wedges (inner ring)
 * carry the low half of the bands and the kites (outer ring) the high
 * half, mirrored left to right like the RAI 4 ident. Blocks further down
 * the corridor show the sound from a moment ago, so the music runs away
 * down the walls.
 *
 * Lengths here are in edges (the pattern's own ruler); whoever shows the
 * wall scales it to the screen.
 */
class WallBlocks {
	/**
	 * The most corners and indices one block can need. Its four corners cut
	 * by the four sides of a box make at most eight; cut again at the two
	 * mitre folds, into at most three pieces, at most twelve, and each piece
	 * has its own middle on top and underneath. A corner block has all that
	 * twice (its half on each wall), and so does a door block with its plate.
	 */
	static final cornersPerBlockAtMost = 2 * (MeshWriter.cornersFor(12) + 4);

	static final indicesPerBlockAtMost = 2 * MeshWriter.indicesFor(12);

	static final cream:Look = {top: Palette.band, sides: Palette.band, bottom: Palette.band};

	/** The tiling laid, and how wide half the wall is in its edges. */
	public var tiling(default, null):Tiling;

	public var halfWidth(default, null) = 1.0;

	/** How far along the wall the pattern repeats itself (edges): the wall can slide this far and look the same. */
	public var repeat(default, null) = 1.0;

	public var writer(default, null):MeshWriter;

	var tiles:Array<Tile> = [];
	var family:Family;
	var cut:WallCut;

	public function new() {}

	/**
	 * Lays a tiling from `fromUnits` to `toUnits` along the wall (in half
	 * widths), plus one repeat to slide into, in its colour family, with
	 * room for `creamPieces` plain cream blocks besides the pattern.
	 */
	public function lay(tiling:Tiling, fromUnits:Float, toUnits:Float, creamPieces:Int) {
		this.tiling = tiling;
		halfWidth = MirrorLines.wallHalfWidth(tiling, tiling.edgesAcrossScreen * Settings.wallHalfWidthTimesScreen);
		repeat = tiling.stepAcross.x;
		tiles = Floor.laidInStrip(tiling, fromUnits * halfWidth - repeat, toUnits * halfWidth + repeat, halfWidth);
		family = Palette.family(tiling.colours);
		final blocks = creamPieces + Lambda.fold(tiles, (tile, total) -> total + 2 * tile.sides, 0);
		writer = new MeshWriter(blocks * cornersPerBlockAtMost, blocks * indicesPerBlockAtMost);
	}

	/** Starts this frame's blocks afresh, all cut by `cut`. */
	public function startFrame(cut:WallCut) {
		this.cut = cut;
		writer.rewind();
	}

	/** Every kite and wedge of the pattern, standing out as far as the music says. */
	public function addPattern(pose:Pose, memory:Memory, now:Float) {
		final contactAngle = pose.contactAngleFor(tiling);
		for (tile in tiles) {
			if (!mayReachBox(tile))
				continue;
			final moment = memory.momentFrom(cut.unitsAwayOf(tile.centre) * Settings.echoSecondsPerCorridorWidth, now);
			addTile(tile, StarCutter.cut(tile, contactAngle), moment, pose.bandWidth / 2);
		}
	}

	/** A tile wholly before or beyond the stretch shown needn't be built (the door's tiles all may: they slide). */
	function mayReachBox(tile:Tile):Bool {
		final reach = tile.reach + cut.spread;
		return tile.centre.x + reach >= cut.box.left && tile.centre.x - reach <= cut.box.right;
	}

	/** A plain cream block filling `area`, standing `depth` out of the wall (the wall itself, the door frame). */
	public function addCream(area:Box, depth:Float) {
		writer.addPrism(Geometry.cornersOf(area), _ -> depth, cream);
	}

	function addTile(tile:Tile, star:CutTile, moment:Moment, groove:Float) {
		for (corner in 0...tile.sides) {
			final kite = star.kites[corner], nextKite = star.kites[(corner + 1) % tile.sides];
			final kitePlace = corner / tile.sides, wedgePlace = (corner + 0.5) / tile.sides;
			final kiteOutline = [kite.middleBefore, kite.corner, kite.middleAfter, kite.innerPoint];
			final wedgeOutline = [tile.centre, kite.innerPoint, kite.middleAfter, nextKite.innerPoint];
			final kiteLevel = moment.bands[bandFor(kitePlace, true)], wedgeLevel = moment.bands[bandFor(wedgePlace, false)];
			addBlock(kiteOutline, groove, depthFor(kiteLevel, moment), kiteLook(kitePlace, kiteLevel, moment));
			addBlock(wedgeOutline, groove, depthFor(wedgeLevel, moment), wedgeLook(wedgePlace, wedgeLevel, moment));
		}
	}

	/**
	 * A block of the pattern: shrunk to leave its groove, slid out with the
	 * iris, cut to the box. In the corridor, a block near the top corner
	 * becomes a corner block, and one near the bottom corner is left out
	 * (the neighbouring wall's corner block, folded round, fills its place).
	 */
	function addBlock(outline:Array<Point>, groove:Float, depth:Float, look:Look) {
		final shape = slidOutFromMiddle(Geometry.inset(outline, groove));
		if (cut.plates)
			addPlate(slidOutFromMiddle(outline));
		final kept = Geometry.clippedToBox(shape, cut.box);
		if (kept.length < 3)
			return;
		if (cut.corners && isNearCorner(shape, 1))
			addCornerBlock(kept, depth, look);
		else if (!cut.corners || !isNearCorner(shape, -1))
			writer.addPrism(kept, _ -> depth, look);
	}

	/**
	 * Whether a block belongs to the corner at the top edge (`side` 1) or
	 * the bottom edge (`side` -1): it lies on that half of the wall and
	 * comes so near the edge that, pushed out as far as blocks ever go, it
	 * would reach the mitre. Such a block and its mirror twin on the next
	 * wall would meet on the diagonal, so they are built as one.
	 */
	function isNearCorner(shape:Array<Point>, side:Int):Bool {
		final mitreReaches = cut.box.top - depthOf(1, 1);
		return side * Geometry.middleOf(shape).y > 0 && Lambda.exists(shape, point -> side * point.y > mitreReaches);
	}

	/** The cream behind a door block, as big as its whole piece, so the door shows no gaps until it opens. */
	function addPlate(outline:Array<Point>) {
		final kept = Geometry.clippedToBox(outline, cut.box);
		if (kept.length >= 3)
			writer.addPrism(kept, _ -> Settings.creamWallDepth * halfWidth, cream);
	}

	/**
	 * A CORNER BLOCK: one block folded round the corner where this wall's
	 * top edge meets the next wall, half on each. The wall is as wide as a
	 * line the pattern is mirrored along (see MirrorLines), so the half on
	 * the next wall is this half's mirror image, and a block crossing the
	 * corner is whole again once folded.
	 *
	 * Pushed out `height`, each half stands that far off its own wall, and
	 * across the inside of the fold a 45° face joins them, so it is one
	 * solid block, not two. As the block grows, that face moves out along
	 * the diagonal. Across the wall the block's top is three flat faces
	 * (level, the 45° face, and the hidden mitre where the halves meet), so
	 * it is built in those three slices.
	 */
	function addCornerBlock(outline:Array<Point>, height:Float, look:Look) {
		final corner = cut.box.top, bevel = height * Settings.cornerBevelTimesHeight;
		final slices = [corner - (bevel - height), corner - bevel / 2];
		for (piece in Geometry.slicedAtHeights(outline, slices)) {
			final bottom = [for (point in piece) {x: point.x, y: point.y, z: 0.0}];
			final top = [for (point in piece) {x: point.x, y: point.y, z: cornerTopAt(corner - point.y, height, bevel)}];
			writer.addSlab(bottom, top, look);
			writer.addSlab(mirroredRoundCorner(bottom), mirroredRoundCorner(top), look);
		}
	}

	/**
	 * How high a corner block's half stands at `fromCorner` (edges from the
	 * corner): level at its height, rising up the 45° face near the corner,
	 * and never past the mitre (the diagonal), where its other half begins.
	 */
	static function cornerTopAt(fromCorner:Float, height:Float, bevel:Float):Float {
		return Math.min(fromCorner, Math.max(height, bevel - fromCorner));
	}

	/**
	 * Spots mirrored across the 45° slope through the top edge: what was on
	 * this wall lands on the neighbouring wall, which stands at the top edge
	 * rising out of the picture.
	 */
	function mirroredRoundCorner(spots:Array<Spot>):Array<Spot> {
		final edge = cut.box.top;
		return [for (spot in spots) {x: spot.x, y: edge - spot.z, z: edge - spot.y}];
	}

	/** The block moved straight out from the middle of the wall by the spread, and turned with the twist. */
	function slidOutFromMiddle(outline:Array<Point>):Array<Point> {
		if (cut.spread == 0)
			return outline;
		final middle = Geometry.middleOf(outline);
		final distance = Geometry.distanceBetween({x: 0, y: 0}, middle);
		final share = distance > 0 ? cut.spread / distance : 0;
		return [
			for (point in outline)
				Geometry.turnedAboutMiddle({x: point.x + middle.x * share, y: point.y + middle.y * share}, cut.twist)
		];
	}

	/**
	 * Which band a block shows. Round each star, places are folded in half
	 * (a place and its mirror image share a band), so the pattern stays
	 * symmetric; the outer ring takes the upper half of the bands.
	 */
	static function bandFor(place:Float, outerRing:Bool):Int {
		final half = Std.int(Settings.equaliserBands / 2);
		final folded = place <= 0.5 ? place * 2 : (1 - place) * 2;
		return Std.int(Math.min(half - 1, Math.floor(folded * half))) + (outerRing ? half : 0);
	}

	/** How far a block stands out of the wall (edges): a little at rest, more with its band and with a kick. */
	function depthFor(level:Float, moment:Moment):Float {
		return depthOf(level, moment.kick);
	}

	/** How far out a block stands (edges) with its band at `level` and a kick of `kick`, each from 0 to 1. */
	function depthOf(level:Float, kick:Float):Float {
		final push = level * Settings.bandPushesOut + kick * Settings.kickPushesOut;
		return (Settings.creamWallDepth + Settings.blockRestsOut + push) * halfWidth;
	}

	/**
	 * A kite's face takes its family's shade for its place on the pitch
	 * wheel, half lit at rest and brighter the louder its notes are; its
	 * sides brighten with its band, so a block standing far out glows along
	 * its length.
	 */
	function kiteLook(place:Float, level:Float, moment:Moment):Look {
		final shade = Palette.inFamily(family, place);
		final strength = PitchWheel.strengthAround(moment.noteStrengths, place, 1 / Settings.equaliserBands);
		return lookOf(Palette.blend(family.deep, shade, Settings.faceAtRest + (1 - Settings.faceAtRest) * strength), shade, level, moment);
	}

	/** A wedge's face wakes in the shade of the bass's note, as bright as the bass is strong. */
	function wedgeLook(place:Float, level:Float, moment:Moment):Look {
		final bassShade = Palette.inFamily(family, PitchWheel.placeOfNote(moment.bassNote));
		final face = Palette.blend(Palette.starAsleep, bassShade, moment.bassStrength * Settings.starGlowAtFullBass);
		return lookOf(face, Palette.inFamily(family, place), level, moment);
	}

	/** Face lightened by a snare; sides from deep to the block's shade as its band rises. */
	function lookOf(face:Colour, shade:Colour, level:Float, moment:Moment):Look {
		final top = Palette.blend(face, Palette.band, moment.snare * Settings.snareLightensTowardsCream);
		return {top: top, sides: Palette.blend(family.deep, shade, Settings.sidesAtRest + (1 - Settings.sidesAtRest) * level), bottom: family.deep};
	}
}
