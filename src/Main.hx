import js.Browser;
import scene.Corridor;
import Conductor.Pose;
import picture.Palette;
import scene.Door;
import scene.Doorway;
import scene.Stage;
import sound.Memory;
import sound.SoundDesk;

/**
 * The whole piece in one loop. Every frame:
 *   1. the ear listens to the sound (notes, bass, drums, equaliser bands),
 *   2. the memory keeps what it heard (so sound can run down the corridor),
 *   3. the conductor decides the tiling and the shape of the stars,
 *   4. the corridor rebuilds its blocks and the stage draws it.
 * When the conductor changes tiling, a door into the new pattern closes
 * across the corridor ahead, and you travel on through it (see Doorway).
 */
class Main {
	static inline final millisecondsInASecond = 1000;

	final desk:SoundDesk;
	final memory = new Memory();
	final conductor = new Conductor();
	final stage:Stage;
	final doorway = new Doorway();
	final door:Door;

	/** The corridor you are in, and the one waiting behind the door. */
	var corridor:Corridor;

	var nextCorridor:Corridor;

	/** The conductor has asked for a new tiling, to be shown once any doorway under way is through. */
	var changeWaiting = false;

	var lastFrameAt = 0.0;

	static function main() {
		new Main();
	}

	function new() {
		desk = new SoundDesk(cast Browser.document.getElementById("player"));
		stage = new Stage(Browser.document.getElementById("stage"));
		corridor = new Corridor(stage);
		nextCorridor = new Corridor(stage);
		nextCorridor.show(false);
		door = new Door(stage);
		corridor.lay(conductor.tiling);
		stage.tintFor(conductor.tiling);
		new Controls(desk, conductor);
		Browser.window.onresize = stage.fitToWindow;
		Browser.window.requestAnimationFrame(frame);
	}

	/** One frame; `clock` is the browser's milliseconds since the page opened. */
	function frame(clock:Float) {
		final now = clock / millisecondsInASecond;
		final frameSeconds = now - lastFrameAt;
		lastFrameAt = now;
		final moment = desk.ear.hear(frameSeconds);
		memory.remember(moment, now);
		if (conductor.follow(moment, frameSeconds))
			changeWaiting = true;
		openDoorwayIfDue();
		final pose = conductor.pose(moment, now);
		moveOn(pose, now, frameSeconds * (Settings.travelPerSecond + moment.kick * Settings.kickRushesOn));
		stage.show(pose.zoom, now);
		Browser.window.requestAnimationFrame(frame);
	}

	/** Lays the new tiling behind a door down the corridor, unless the conductor has changed its mind back again. */
	function openDoorwayIfDue() {
		if (!changeWaiting || doorway.going)
			return;
		changeWaiting = false;
		if (conductor.tiling == corridor.tiling())
			return;
		nextCorridor.lay(conductor.tiling);
		door.lay(conductor.tiling);
		door.show(true);
		doorway.start(goThrough);
	}

	/**
	 * Travels on. During a doorway: the door, and once it has shut, the old
	 * corridor only up to it and the new one beyond it (before that the old
	 * corridor runs on through the open door).
	 */
	function moveOn(pose:Pose, now:Float, travel:Float) {
		doorway.approach(travel);
		final nextIsBehind = doorway.nextIsBehind(), door = doorway.distance;
		nextCorridor.show(nextIsBehind);
		corridor.update(pose, memory, now, travel, -Settings.corridorBehindCamera, nextIsBehind ? door : Settings.corridorLength);
		if (nextIsBehind)
			nextCorridor.update(pose, memory, now, travel, door, Settings.corridorLength);
		if (doorway.going) {
			this.door.update(pose, memory, now, door, doorway.closed(), doorway.shut());
			stage.tint(Palette.blend(deepOf(corridor), deepOf(nextCorridor), doorway.opening()));
		}
	}

	static function deepOf(shown:Corridor):Colour {
		return Palette.family(shown.tiling().colours).deep;
	}

	/** Through the door: the new corridor is the one you are in, and the old one waits, hidden, for the next doorway. */
	function goThrough() {
		final old = corridor;
		corridor = nextCorridor;
		nextCorridor = old;
		nextCorridor.show(false);
		door.show(false);
		stage.tintFor(corridor.tiling());
	}
}
