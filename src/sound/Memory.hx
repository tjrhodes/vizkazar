package sound;

import sound.Ear.Moment;

/** A moment, and when it was heard (in seconds since the page opened). */
typedef Remembered = {moment:Moment, heardAt:Float};

/**
 * Remembers the last second or so of what the ear heard, newest first.
 *
 * This is what makes sound travel through the picture: the blocks nearest
 * the camera show what is playing now, and those further down the
 * corridor show what played a little earlier, so every sound runs away
 * down the walls.
 */
class Memory {
	final newestFirst:Array<Remembered> = [];

	public function new() {}

	public function remember(moment:Moment, now:Float) {
		newestFirst.unshift({moment: moment, heardAt: now});
		while (newestFirst[newestFirst.length - 1].heardAt < now - Settings.secondsRemembered)
			newestFirst.pop();
	}

	/** The moment heard `secondsAgo` (or the oldest kept, if that is further back). */
	public function momentFrom(secondsAgo:Float, now:Float):Moment {
		for (remembered in newestFirst)
			if (remembered.heardAt <= now - secondsAgo)
				return remembered.moment;
		return newestFirst[newestFirst.length - 1].moment;
	}
}
