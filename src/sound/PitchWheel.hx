package sound;

/**
 * Lays the twelve notes round a circle, so a place round the edge of a
 * tile can stand for a note.
 *
 * The notes are not in piano order but in the CIRCLE OF FIFTHS: each
 * place is seven semitones on from the last. Notes that sound good
 * together sit side by side this way, so a chord lights up a few
 * neighbouring petals instead of scattered ones.
 *
 * Places are measured in turns: 0 is the first place, 0.5 is halfway round.
 */
class PitchWheel {
	static inline final semitonesInAFifth = 7;
	static inline final placesOnWheel = Spectrum.notesInAnOctave;

	/**
	 * How strongly the notes around one place on the wheel are sounding.
	 * `arc` is how much of the wheel the asker covers (a petal of a
	 * twelve-sided tile covers a twelfth: exactly one note; a corner of a
	 * square covers a quarter, so it listens to a note and its neighbours).
	 */
	public static function strengthAround(noteStrengths:Array<Float>, place:Float, arc:Float):Float {
		final reach = Math.max(arc, 1 / placesOnWheel);
		var heard = 0.0;
		var listenedTo = 0.0;
		for (index in 0...placesOnWheel) {
			final attention = nearness(index / placesOnWheel, place, reach);
			heard += attention * noteStrengths[acrossTheWheel(index)];
			listenedTo += attention;
		}
		return heard / listenedTo;
	}

	/** 1 when two places on the wheel are the same, falling to 0 once they are `reach` apart. */
	static function nearness(placeA:Float, placeB:Float, reach:Float):Float {
		final apart = Math.abs(placeA - placeB) % 1;
		final shortestWayRound = Math.min(apart, 1 - apart);
		return Math.max(0, 1 - shortestWayRound / reach);
	}

	/** Where a note sits on the wheel, in turns. */
	public static function placeOfNote(note:Int):Float {
		return acrossTheWheel(note) / placesOnWheel;
	}

	/**
	 * Turns a place on the wheel into its note, AND a note into its place:
	 * stepping by fifths twice over lands back where you started (7 × 7 is
	 * 49, one more than four octaves of 12), so the same sum works both ways.
	 */
	static function acrossTheWheel(noteOrPlace:Int):Int {
		return (noteOrPlace * semitonesInAFifth) % placesOnWheel;
	}
}
