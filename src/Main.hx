import js.Browser;
import Conductor.Pose;
import picture.Palette;
import scene.Field;
import scene.Stage;
import scene.TurnWave;
import sound.Memory;
import sound.SoundDesk;

/**
 * The whole piece in one loop. Every frame:
 *   1. the ear listens to the sound (notes, bass, drums, equaliser bands),
 *   2. the memory keeps what it heard (so sound can ripple outwards),
 *   3. the conductor decides the tiling and the shape of the stars,
 *   4. the field rebuilds its columns and the stage draws it.
 * When the conductor changes tiling, a wave of turning blocks runs out
 * from the middle, turning the old pattern over into the new one (see
 * TurnWave).
 */
class Main {
	static inline final millisecondsInASecond = 1000;

	final desk:SoundDesk;
	final memory = new Memory();
	final conductor = new Conductor();
	final stage:Stage;
	final wave = new TurnWave();

	/** The field on show, and the one the wave is turning over into. */
	var field:Field;

	var nextField:Field;

	/** The conductor has asked for a new tiling, to be shown once any wave under way has finished. */
	var changeWaiting = false;

	var lastFrameAt = 0.0;

	static function main() {
		new Main();
	}

	function new() {
		desk = new SoundDesk(cast Browser.document.getElementById("player"));
		stage = new Stage(Browser.document.getElementById("stage"));
		field = new Field(stage);
		nextField = new Field(stage);
		nextField.show(false);
		field.lay(conductor.tiling);
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
		startWaveIfDue();
		wave.advance(frameSeconds);
		final pose = conductor.pose(moment, now);
		build(pose, now);
		stage.show(widthShown(), pose.zoom);
		Browser.window.requestAnimationFrame(frame);
	}

	/** Lays the new tiling and sets the wave running, unless the conductor has changed its mind back again. */
	function startWaveIfDue() {
		if (!changeWaiting || wave.going)
			return;
		changeWaiting = false;
		if (conductor.tiling == field.tiling)
			return;
		nextField.lay(conductor.tiling);
		nextField.show(true);
		wave.start(Math.max(field.reach(), nextField.reach()), turnedOver);
	}

	/** This frame's columns: during a wave, the old ones turning up onto their edges and the new ones turning down. */
	function build(pose:Pose, now:Float) {
		if (!wave.going) {
			field.build(pose, memory, now, _ -> 0);
			stage.tint(deepOf(field));
			return;
		}
		field.build(pose, memory, now, wave.oldBlockTurn);
		nextField.build(pose, memory, now, wave.newBlockTurn);
		stage.tint(Palette.blend(deepOf(field), deepOf(nextField), wave.progress()));
	}

	/** How much of the field shows across the screen: during a wave, moving from the old tiling's scale to the new one's. */
	function widthShown():Float {
		if (!wave.going)
			return field.width;
		return field.width + (nextField.width - field.width) * Ease.gentlyBetween(0, wave.progress(), 1);
	}

	static function deepOf(shown:Field):Colour {
		return Palette.family(shown.tiling.colours).deep;
	}

	/** Every block has turned: the new field is the one on show, and the old one waits, hidden, for the next change. */
	function turnedOver() {
		final old = field;
		field = nextField;
		nextField = old;
		nextField.show(false);
	}
}
