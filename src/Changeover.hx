import sound.BarClock;

/**
 * When the next change of tiling happens, in time with the music. It
 * lands on beat one of the first bar of a phrase (see Settings.phraseBars),
 * and during the bar before, the view closes in on the star in the middle;
 * as the blocks turn over, it pulls back out onto the new pattern.
 *
 * With no beat to keep time by (an intro, a breakdown), it goes soon,
 * after a short close-in.
 */
class Changeover {
	/** When the blocks start turning, and how long before that the close-in starts (null: no change planned). */
	public var turnsAt(default, null):Null<Float> = null;

	var closesInFor = 1.0;

	/** How long the blocks take to turn over, in seconds. */
	public var turnSeconds(default, null) = 1.0;

	public function new() {}

	public function isPlanned():Bool {
		return turnsAt != null;
	}

	/** Plans a change for the next phrase (or the next bar, if `soon`), or a short while off with no beat. */
	public function plan(clock:BarClock, now:Float, soon:Bool) {
		final bar = clock.barLength(now);
		closesInFor = bar != null ? bar * Settings.closeUpBars : Settings.closeUpSecondsWithoutBeat;
		turnSeconds = bar != null ? bar * Settings.turnWaveBars : Settings.turnWaveSecondsWithoutBeat;
		final phrase = clock.nextPhraseStart(now + closesInFor, soon ? 1 : Settings.phraseBars, now);
		turnsAt = phrase != null && phrase >= now ? phrase : now + closesInFor;
	}

	/** Whether the turning should start now; once it has, the plan is spent. */
	public function isDue(now:Float):Bool {
		if (turnsAt == null || now < turnsAt)
			return false;
		turnsAt = null;
		return true;
	}

	/** How far the close-in has got, from 0 (not started) to 1 (right on the star, the moment the turning starts). */
	public function closedIn(now:Float):Float {
		return turnsAt == null ? 0 : Ease.gentlyBetween(turnsAt - closesInFor, now, turnsAt);
	}
}
