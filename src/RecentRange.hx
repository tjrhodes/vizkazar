/**
 * Remembers the quietest and loudest something has been lately, and says
 * where a new value sits between them: 0 at the quietest, 1 at the
 * loudest. Both slowly close in on the present, so after a while only
 * recent music counts.
 *
 * This is what lets a quiet recording use the whole range too, and lets
 * the treble move as much as the bass even though it is much softer.
 */
class RecentRange {
	final forgetsPerSecond:Float;
	final narrowest:Float;
	var quietest = 0.0;
	var loudest = 0.0;

	/** `narrowest`: a range narrower than this is treated as this wide, so near-silence doesn't count as a swing. */
	public function new(forgetsPerSecond:Float, narrowest:Float) {
		this.forgetsPerSecond = forgetsPerSecond;
		this.narrowest = narrowest;
	}

	/** Takes in this frame's value (`seconds` since the last) and answers where it sits, 0 to 1 (or beyond, at a new extreme). */
	public function place(value:Float, seconds:Float):Float {
		quietest = Math.min(value, Ease.toward(quietest, value, forgetsPerSecond, seconds));
		loudest = Math.max(value, Ease.toward(loudest, value, forgetsPerSecond, seconds));
		return (value - quietest) / Math.max(loudest - quietest, narrowest);
	}
}
