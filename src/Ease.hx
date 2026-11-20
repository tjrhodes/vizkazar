/** Smooth catching-up: how a value drifts towards where it wants to be. */
class Ease {
	/**
	 * Moves `now` part of the way to `goal`. `perSecond` is the eagerness:
	 * higher closes the gap sooner. Because it is told how many `seconds`
	 * went by, the motion looks the same on a fast screen and a slow one.
	 */
	public static function toward(now:Float, goal:Float, perSecond:Float, seconds:Float):Float {
		return now + (goal - now) * (1 - Math.exp(-perSecond * seconds));
	}

	/** The same, but more eager going up than coming down (or the other way round). */
	public static function unevenly(now:Float, goal:Float, risingPerSecond:Float, fallingPerSecond:Float, seconds:Float):Float {
		return toward(now, goal, goal > now ? risingPerSecond : fallingPerSecond, seconds);
	}

	/** Keeps a value between a lowest and a highest. */
	public static function within(lowest:Float, value:Float, highest:Float):Float {
		return Math.max(lowest, Math.min(highest, value));
	}

	/** How far a value has come from `low` to `high`, from 0 to 1, starting and finishing gently. */
	public static function gentlyBetween(low:Float, value:Float, high:Float):Float {
		final share = within(0, (value - low) / (high - low), 1);
		return share * share * (3 - 2 * share);
	}
}
