import js.Browser;
import Conductor.Pose;
import picture.Palette;
import scene.Field;
import scene.Stage;
import scene.TurnWave;
import sound.BarClock;
import sound.Ear.Moment;
import sound.Memory;
import sound.SoundDesk;

/**
 * The whole piece in one loop. Every frame:
 *   1. the ear listens to the sound (notes, bass, drums, equaliser bands),
 *   2. the memory keeps what it heard (so sound can ripple outwards),
 *   3. the conductor decides the tiling and the shape of the stars,
 *   4. the field rebuilds its columns and the stage draws it.
 * When the conductor changes tiling, the change waits for the first beat
 * of the next phrase (see Changeover): the view closes in on the middle
 * star during the bar before, then a wave of turning blocks runs out from
 * the middle, turning the old pattern over into the new one (see
 * TurnWave), while the view pulls back out.
 */
class Main {
	static inline final millisecondsInASecond = 1000;

	final desk:SoundDesk;
	final memory = new Memory();
	final conductor = new Conductor();
	final stage:Stage;
	final wave = new TurnWave();
	final clock = new BarClock();
	final changeover = new Changeover();

	/** The field on show, and the one the wave is turning over into. */
	var field:Field;

	var nextField:Field;

	/** The conductor has asked for a new tiling, to be planned once any change under way has finished. */
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
		desk.whenJumped = clock.trackJumped;
		desk.whenNewSound = clock.forget;
		new Controls(desk, conductor);
		Browser.window.onresize = stage.fitToWindow;
		Browser.window.requestAnimationFrame(frame);
	}

	/**
	 * One frame; `millisecondsOpen` is how long the page has been open.
	 * The ear hears the sound before it comes out of the speakers, so the
	 * pictures show the moment you are hearing (`seen`), a little behind
	 * what the ear has just heard (see SoundDesk.picturesWait). Changes are
	 * still planned from what the ear hears, and land when you hear the beat.
	 */
	function frame(millisecondsOpen:Float) {
		final now = millisecondsOpen / millisecondsInASecond;
		final frameSeconds = now - lastFrameAt;
		lastFrameAt = now;
		final trackNow = desk.trackTime(now);
		final heard = listen(frameSeconds, now, trackNow);
		if (conductor.follow(heard, frameSeconds))
			changeWaiting = true;
		planChangeIfDue(now, trackNow);
		final seen = now - desk.picturesWait();
		startWaveIfDue(seen);
		wave.advance(frameSeconds);
		final pose = conductor.pose(memory.momentFrom(0, seen), seen);
		build(pose, seen);
		stage.show(widthShown(seen), pose.zoom);
		Browser.window.requestAnimationFrame(frame);
	}

	/** This frame's sound: remembered (so it can ripple outwards), and its kick, if any, kept time by in the track's time. */
	function listen(frameSeconds:Float, now:Float, trackNow:Float):Moment {
		final moment = desk.ear.hear(frameSeconds);
		memory.remember(moment, now);
		if (moment.kickLandedSecondsAgo != null)
			clock.hearKick(trackNow - moment.kickLandedSecondsAgo);
		return moment;
	}

	/**
	 * Plans the change the conductor asked for, unless one is under way or
	 * it has changed its mind back again: the new tiling is laid now, out
	 * of sight. A change picked from the menu comes on the next bar.
	 */
	function planChangeIfDue(now:Float, trackNow:Float) {
		if (!changeWaiting || changeover.isPlanned() || wave.going)
			return;
		changeWaiting = false;
		if (conductor.tiling == field.tiling)
			return;
		nextField.lay(conductor.tiling);
		changeover.plan(clock, now, trackNow, conductor.pinnedTiling != null);
	}

	/** On the planned beat, the new field comes into sight, on its edge, and the wave sets off. */
	function startWaveIfDue(now:Float) {
		if (!changeover.isDue(now))
			return;
		nextField.show(true);
		wave.start(Math.max(field.reach(), nextField.reach()), changeover.turnSeconds, turnedOver);
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

	/**
	 * How much of the field shows across the screen (edges): closing in on
	 * the middle star before a change, and pulling back out from it onto the
	 * new tiling as the blocks turn.
	 */
	function widthShown(now:Float):Float {
		if (wave.going)
			return between(field.closeUpWidth(), nextField.width, Ease.gentlyBetween(0, wave.progress(), 1));
		return between(field.width, field.closeUpWidth(), changeover.closedIn(now));
	}

	static function between(from:Float, to:Float, share:Float):Float {
		return from + (to - from) * share;
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
