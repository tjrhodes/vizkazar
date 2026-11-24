package sound;

/**
 * Keeps time with the music: where the bars start, so changes can land
 * on the first beat of a bar, and of a phrase (a few bars together).
 *
 * It counts from the moment the beat comes in. The first kick after a
 * silence is taken as beat one of bar one: in most music the beat comes
 * in on the one, and phrases (4, 8, 16 bars) run on from there. The bar
 * length comes from the kicks (see BarLength); after that the clock keeps
 * in step by following the kicks that land on beat one, so a length a
 * hair out doesn't drift.
 *
 * Times are the track's own seconds (see SoundDesk.trackTime), so the bars
 * stay where they are in the music when the visitor jumps about in it.
 */
class BarClock {
	static inline final sixteenthsInABar = 16;

	/** When bar one began, and how long a bar is (null until the kicks have shown it). */
	var startedAt = 0.0;

	var barSeconds:Null<Float> = null;

	/** The latest kick on beat one, and its bar: later bars are counted on from it, so small errors don't add up. */
	var latestBeatOne = {bar: 0, at: 0.0};

	/** The kicks since the beat came in (the most recent stretch of them). */
	var kicks:Array<Float> = [];

	/**
	 * Every kick heard on beat one since the bars were found, by bar: a
	 * long record, kept through jumps in the track, so the bars can be fitted
	 * very closely however far the visitor jumps.
	 */
	final beatOnes = new Map<Int, Float>();

	public function new() {}

	/**
	 * A kick landed `at` (seconds). The bar length is worked out afresh
	 * from the kicks, and taken if it is new or quite different; then the
	 * clock keeps in step with the beat-one kicks.
	 */
	public function hearKick(at:Float) {
		if (isNewBeat(at))
			restartAt(at);
		kicks.push(at);
		kicks = kicks.filter(kick -> at - kick <= Settings.barClockRemembersSeconds);
		final found = BarLength.fromKicks(kicks);
		if (found != null && (barSeconds == null || isClearlyDifferent(found)))
			takeBarLength(found);
		if (barSeconds != null)
			keepInStep();
	}

	/**
	 * Whether a kick `at` starts the beat afresh: the first kick of all,
	 * or one after a silence. (After a jump in the track the kicks heard
	 * so far are let go, but the bars stay where they were.)
	 */
	function isNewBeat(at:Float):Bool {
		if (kicks.length == 0)
			return barSeconds == null;
		return at - kicks[kicks.length - 1] > silenceThatRestarts();
	}

	/** The visitor jumped to another place in the track: the bars stay put (they are in the track's time); the kicks heard so far are let go. */
	public function trackJumped() {
		kicks = [];
	}

	/** A new sound (another track, or the microphone): nothing heard so far counts. */
	public function forget() {
		kicks = [];
		barSeconds = null;
		beatOnes.clear();
	}

	/** Whether a newly worked-out bar length is really different: quite a lot, and over enough bars to be sure (not a few kicks after a jump). */
	function isClearlyDifferent(length:Float):Bool {
		final heard = kicks[kicks.length - 1] - kicks[0];
		return Math.abs(length / barSeconds - 1) > Settings.barLengthChangesBy && heard >= length * Settings.barsHeardBeforeNewLength;
	}

	/** A new bar length: bars are counted afresh from bar one, the old count being in the old length. */
	function takeBarLength(length:Float) {
		barSeconds = length;
		countFrom(startedAt);
	}

	/** Bar one starts `at`; the old beat-one record no longer fits. */
	function countFrom(at:Float) {
		startedAt = at;
		latestBeatOne = {bar: 0, at: at};
		beatOnes.clear();
	}

	/** The beat has come in (again): bar one starts now. The bar length is kept as a first guess. */
	function restartAt(at:Float) {
		kicks = [];
		countFrom(at);
	}

	/** A gap in the kicks this long means the beat has stopped, and its next kick is a new beat one. */
	function silenceThatRestarts():Float {
		return barSeconds == null ? Settings.secondsWithoutKicksBeforeNewStart : barSeconds * Settings.barsWithoutKicksBeforeNewStart;
	}

	/** Whether the clock knows the bars right now: the bar length is known, and the kicks haven't long stopped. */
	public function isRunning(now:Float):Bool {
		return barSeconds != null && kicks.length > 0 && now - kicks[kicks.length - 1] <= barSeconds * Settings.barsClockRunsOnWithoutKicks;
	}

	/** How long a bar is, if the clock is running. */
	public function barLength(now:Float):Null<Float> {
		return isRunning(now) ? barSeconds : null;
	}

	/** When the first bar of a phrase of `phraseBars` bars next begins, at `earliest` or after; null if the clock isn't running. */
	public function nextPhraseStart(earliest:Float, phraseBars:Int, now:Float):Null<Float> {
		if (!isRunning(now))
			return null;
		final bar = Math.ceil((earliest - startedAt) / barSeconds - Settings.kickTimingSlack / barSeconds);
		final phrase = Math.ceil(bar / phraseBars) * phraseBars;
		return latestBeatOne.at + (phrase - latestBeatOne.bar) * barSeconds;
	}

	/** The kicks that landed on beat one of a bar, each with the number of its bar. */
	function downbeatKicks():Array<{bar:Int, at:Float}> {
		final found = [], slack = barSeconds / sixteenthsInABar * Settings.downbeatSlackSixteenths;
		for (kick in kicks) {
			final bar = Math.round((kick - startedAt) / barSeconds);
			if (Math.abs(kick - startedAt - bar * barSeconds) <= slack)
				found.push({bar: bar, at: kick});
		}
		return found;
	}

	/**
	 * Keeps in step: adds this stretch's beat-one kicks to the record, and
	 * fits a straight line through it (when each landed, against its bar).
	 * Its slope is the bar length, and where it starts is bar one. If the
	 * record is too short (the kick it started from was a stray), beat one
	 * moves to the busiest kick first.
	 */
	function keepInStep() {
		final points = downbeatKicks();
		for (point in points)
			beatOnes.set(point.bar, point.at);
		final bars = [for (bar in beatOnes.keys()) bar];
		if (bars.length < Settings.downbeatKicksToKeepStep)
			return moveToBusiestSixteenth();
		final line = Fit.straightLine([for (bar in bars) bar], [for (bar in bars) beatOnes[bar]]);
		if (Math.abs(line.slope / barSeconds - 1) > Settings.barLengthChangesBy)
			return;
		barSeconds = line.slope;
		startedAt = line.start;
		if (points.length > 0)
			latestBeatOne = points[points.length - 1];
	}

	/** Moves beat one to the sixteenth of the bar where kicks land most often (the first of them, if several tie). */
	function moveToBusiestSixteenth() {
		final sixteenth = barSeconds / sixteenthsInABar, counts = [for (_ in 0...sixteenthsInABar) 0];
		for (kick in kicks) {
			final place = Math.round((kick - startedAt) / sixteenth) % sixteenthsInABar;
			counts[(place + sixteenthsInABar) % sixteenthsInABar]++;
		}
		var busiest = 0;
		for (place in 1...sixteenthsInABar)
			if (counts[place] > counts[busiest])
				busiest = place;
		countFrom(startedAt + busiest * sixteenth);
	}
}
