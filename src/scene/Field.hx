package scene;

import Conductor.Pose;
import pattern.Floor;
import pattern.Geometry;
import pattern.Geometry.Point;
import pattern.StarCutter;
import pattern.Tile;
import pattern.Tilings.Tiling;
import picture.Palette;
import scene.MeshWriter.Look;
import scene.Stage.Spot;
import sound.Ear.Moment;
import sound.Memory;
import sound.PitchWheel;
import three.Three;

/**
 * A field of solid columns, drawn the RAI 2 way: the pattern laid out
 * flat, every kite and every star wedge a column standing up out of the
 * ground, its top in a clean colour and its sides in two darker tones. A
 * thin groove between neighbours lets the ground show: that is the
 * strapwork.
 *
 * Each column is one bar of a graphic equaliser: it stands as tall as its
 * band is loud. Round each star, the wedges (inner ring) carry the low
 * half of the bands and the kites (outer ring) the high half, mirrored
 * left to right. Columns further from the middle show the sound from a
 * moment ago, so the music ripples outwards.
 *
 * Lengths are in edges (the pattern's own ruler).
 */
class Field {
	/** Kites and wedges have four corners, and the groove cut round them keeps four. */
	static final cornersPerBlock = MeshWriter.cornersFor(4);

	static final indicesPerBlock = MeshWriter.indicesFor(4);

	/** A block turned this far is on its edge: it is not drawn. */
	static final onItsEdge = Math.PI / 2 - 0.001;

	static final middleOfField:Point = {x: 0, y: 0};

	public var tiling(default, null):Tiling;

	/** How many edges of this tiling fill the screen across. */
	public var width(default, null) = 1.0;

	final shape = new BlockShape();
	final mesh:Mesh;
	var writer:MeshWriter;
	var tiles:Array<Tile> = [];
	var family:Family;

	/** This frame's groove width (edges), and how far each block has turned, by how far it is from the middle. */
	var groove = 0.0;

	var turnOf:Float->Float = _ -> 0;

	public function new(stage:Stage) {
		mesh = new Mesh(shape.geometry, BlockShape.flat());
		mesh.frustumCulled = false;
		stage.add(mesh);
	}

	/** How many edges of a tiling fill the screen across: its pieces show at much the same size whatever the tiling. */
	public static function widthFor(tiling:Tiling):Float {
		return tiling.edgesAcrossScreen * Settings.fieldShownTimesScreen;
	}

	/** How many edges fill the screen across when the view has closed in on the star in the middle (the tiling's biggest tile sits there). */
	public function closeUpWidth():Float {
		return 2 * tiling.tiles[0].cornerDistance * Settings.closeUpTimesStar;
	}

	/** How far out from the middle the field is laid (edges): past the screen's corners, whatever its shape. */
	public function reach():Float {
		return width * Settings.fieldLaidOutToWidths;
	}

	public function show(shown:Bool) {
		mesh.visible = shown;
	}

	/** Lays a tiling out over the field, in its colour family. */
	public function lay(tiling:Tiling) {
		this.tiling = tiling;
		width = widthFor(tiling);
		tiles = Floor.laid(tiling, reach());
		family = Palette.family(tiling.colours);
		final blocks = Lambda.fold(tiles, (tile, total) -> total + 2 * tile.sides, 0);
		writer = new MeshWriter(blocks * cornersPerBlock, blocks * indicesPerBlock);
		shape.takeFrom(writer);
		mesh.geometry = shape.geometry;
	}

	/**
	 * Builds this frame's blocks, as tall as the music says, each turned by
	 * `turnOf` its distance from the middle (radians; 0 standing up, on its
	 * edge and so not drawn at a quarter turn either way).
	 */
	public function build(pose:Pose, memory:Memory, now:Float, turnOf:Float->Float) {
		writer.rewind();
		groove = pose.bandWidth / 2;
		this.turnOf = turnOf;
		final contactAngle = pose.contactAngleFor(tiling);
		for (tile in tiles) {
			final moment = memory.momentFrom(tile.edgesFromMiddle / width * Settings.echoSecondsAcrossScreen, now);
			addTile(tile, StarCutter.cut(tile, contactAngle), moment);
		}
		shape.refresh(writer);
	}

	function addTile(tile:Tile, star:CutTile, moment:Moment) {
		for (corner in 0...tile.sides) {
			final kite = star.kites[corner], nextKite = star.kites[(corner + 1) % tile.sides];
			final kitePlace = corner / tile.sides, wedgePlace = (corner + 0.5) / tile.sides;
			final kiteOutline = [kite.middleBefore, kite.corner, kite.middleAfter, kite.innerPoint];
			final wedgeOutline = [tile.centre, kite.innerPoint, kite.middleAfter, nextKite.innerPoint];
			final kiteLevel = moment.bands[bandFor(kitePlace, true)], wedgeLevel = moment.bands[bandFor(wedgePlace, false)];
			addBlock(kiteOutline, heightFor(kiteLevel, moment), kiteLook(kitePlace, moment));
			addBlock(wedgeOutline, heightFor(wedgeLevel, moment), wedgeLook(wedgePlace, moment));
		}
	}

	/** A column: the piece shrunk to leave its groove, raised to `height`, turned as far as the wave has got. */
	function addBlock(outline:Array<Point>, height:Float, look:Look) {
		final piece = Geometry.inset(outline, groove);
		final middle = Geometry.middleOf(piece);
		final turn = turnOf(Geometry.distanceBetween(middleOfField, middle));
		if (Math.abs(turn) >= onItsEdge)
			return;
		final bottom = [for (point in piece) {x: point.x, y: point.y, z: 0.0}];
		final top = [for (point in piece) {x: point.x, y: point.y, z: height}];
		if (turn == 0)
			writer.addSlab(bottom, top, look);
		else
			writer.addSlab(turned(bottom, middle, height, turn), turned(top, middle, height, turn), look);
	}

	/**
	 * A column's corners turned over like a card, about a line through its
	 * own middle (half way up) running round the field, so its top rolls
	 * outwards, away from the middle of the field.
	 */
	static function turned(spots:Array<Spot>, middle:Point, height:Float, turn:Float):Array<Spot> {
		final outwards = Spots.normalised({x: middle.x, y: middle.y, z: 0});
		final roundTheField:Spot = outwards.x == 0 && outwards.y == 0 ? {x: 0, y: 1, z: 0} : {x: -outwards.y, y: outwards.x, z: 0};
		final pivot:Spot = {x: middle.x, y: middle.y, z: height / 2};
		return [for (spot in spots) Spots.turnedAbout(spot, pivot, roundTheField, turn)];
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

	/** How tall a column stands (edges): a little at rest, more with its band and with a kick. */
	static function heightFor(level:Float, moment:Moment):Float {
		return Settings.columnRests + level * Settings.columnRisesWithBand + moment.kick * Settings.columnRisesWithKick;
	}

	/** A kite's top is white, taking on its shade of the family as its notes sound. */
	function kiteLook(place:Float, moment:Moment):Look {
		final shade = Palette.inFamily(family, place);
		final strength = PitchWheel.strengthAround(moment.noteStrengths, place, 1 / Settings.equaliserBands);
		return lookOf(Palette.blend(Palette.white, shade, strength * Settings.kiteTopTakesNoteShade), shade);
	}

	/** A wedge's top is its shade of the family, turning to the bass note's shade as the bass grows, and lit white by a snare. */
	function wedgeLook(place:Float, moment:Moment):Look {
		final shade = Palette.inFamily(family, place);
		final bassShade = Palette.inFamily(family, PitchWheel.placeOfNote(moment.bassNote));
		final top = Palette.blend(shade, bassShade, moment.bassStrength);
		return lookOf(Palette.blend(top, Palette.white, moment.snare * Settings.snareWhitensWedges), shade);
	}

	/** A top, with sides in two darker tones of the block's shade. */
	function lookOf(top:Colour, shade:Colour):Look {
		return {
			top: top,
			left: Palette.blend(shade, family.deep, Settings.leftSidesDarken),
			right: Palette.blend(shade, family.deep, Settings.rightSidesDarken)
		};
	}
}
