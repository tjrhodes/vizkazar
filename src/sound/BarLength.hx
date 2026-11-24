package sound;

/**
 * How long one bar of the music is, worked out from when the kicks land.
 *
 * A bar's kicks come round again a bar later, so the bar length is a
 * stretch of time after which most kicks find another kick. But so does
 * every whole number of bars, and in four-to-the-floor music every whole
 * number of beats too. Two more things pick out the bar:
 *   - its kicks sit on its sixteenth notes (one bar cut into 16), however
 *     syncopated they are, while a wrong length cuts the bar elsewhere;
 *   - of the lengths that fit almost as well as the best, the shortest is
 *     the bar (two bars fit just as well as one).
 */
class BarLength {
	static inline final sixteenthsInABar = 16;

	/** The bar length (seconds) the kicks `kicks` (their times, oldest first) show, or null if they are too few to tell. */
	public static function fromKicks(kicks:Array<Float>):Null<Float> {
		if (kicks.length < Settings.kicksBeforeBarIsKnown)
			return null;
		final scores = [for (length in candidates(kicks)) {length: length, score: fit(kicks, length)}];
		final best = Lambda.fold(scores, (candidate, top) -> Math.max(candidate.score, top), 0.0);
		if (best < Settings.barMustFitAtLeast)
			return null;
		final nearlyAsGood = scores.filter(candidate -> candidate.score >= best * Settings.nearlyAsGoodAsBest);
		return nearlyAsGood[0].length;
	}

	/** Every bar length worth trying, shortest first, up to half the time the kicks cover (two bars at least). */
	static function candidates(kicks:Array<Float>):Array<Float> {
		final longest = Math.min(Settings.longestBarSeconds, (kicks[kicks.length - 1] - kicks[0]) / 2);
		final steps = Math.floor((longest - Settings.shortestBarSeconds) / Settings.barSearchStepSeconds);
		return [for (step in 0...steps + 1) Settings.shortestBarSeconds + step * Settings.barSearchStepSeconds];
	}

	/**
	 * How well a bar length fits the kicks, from 0 to 1: the share of
	 * kicks with another kick a bar before or after, times how well those
	 * sit on its sixteenths. (Stray kicks, a bass note mistaken for one,
	 * don't come round again, so they are left out of the second test.)
	 */
	static function fit(kicks:Array<Float>, length:Float):Float {
		final recurring = kicks.filter(kick -> comesRoundAgain(kick, kicks, length));
		return recurring.length == 0 ? 0 : recurring.length / kicks.length * onTheGrid(recurring, length / sixteenthsInABar);
	}

	/** Whether there is another kick a bar before or after this one. */
	static function comesRoundAgain(kick:Float, kicks:Array<Float>, length:Float):Bool {
		return Lambda.exists(kicks, other -> Math.abs(Math.abs(other - kick) - length) <= Settings.kickTimingSlack);
	}

	/**
	 * How well the kicks sit on one grid of `step` seconds, from 0 to 1:
	 * each kick is a pointer round a clock face going round once a step,
	 * and if they all point the same way, their average is 1 long.
	 */
	static function onTheGrid(kicks:Array<Float>, step:Float):Float {
		var across = 0.0, up = 0.0;
		for (kick in kicks) {
			final angle = 2 * Math.PI * (kick - kicks[0]) / step;
			across += Math.cos(angle);
			up += Math.sin(angle);
		}
		return Math.sqrt(across * across + up * up) / kicks.length;
	}
}
