package sound;

import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.lib.Uint8Array;

/**
 * The sound sorted by pitch: thousands of thin slices from low to high,
 * each with a loudness from 0 to 255. The browser's analyser makes it.
 *
 * There is a trade to choose when making one. MORE slices tell close
 * notes apart, but need a longer stretch of sound, so the answer arrives
 * late and smeared. FEWER slices are blurry about pitch but right on time.
 * The ear keeps one of each (see Ear).
 */
class Spectrum {
	public static inline final notesInAnOctave = 12;
	static inline final loudestSlice = 255;

	final analyser:AnalyserNode;
	final slices:Uint8Array;
	final hzPerSlice:Float;

	/** For every slice, which of the twelve notes it belongs to (worked out once). */
	final noteOfSlice:Array<Int>;

	/**
	 * `detail` is the trade above (a power of two); `blending` is how much
	 * each answer keeps of the last (0 to 1); `loudestDecibels` is the level
	 * read as 255. Anything louder is cut off there, so a spectrum that
	 * listens to loud bass needs that ceiling well above the music's loudest.
	 */
	public function new(context:AudioContext, sound:AudioNode, detail:Int, blending:Float, loudestDecibels:Float) {
		analyser = context.createAnalyser();
		analyser.fftSize = detail;
		analyser.smoothingTimeConstant = blending;
		analyser.minDecibels = Settings.quietestDecibels;
		analyser.maxDecibels = loudestDecibels;
		sound.connect(analyser);
		slices = new Uint8Array(analyser.frequencyBinCount);
		hzPerSlice = context.sampleRate / detail;
		noteOfSlice = [for (slice in 0...slices.length) noteAtPitch(slice * hzPerSlice)];
	}

	/** Asks the browser for the sound as it is right now. */
	public function refresh() {
		analyser.getByteFrequencyData(slices);
	}

	/** The average loudness (0 to 1) of everything between two pitches. */
	public function loudnessBetween(lowHz:Float, highHz:Float):Float {
		final first = firstSliceAt(lowHz), last = lastSliceAt(highHz);
		var total = 0;
		for (slice in first...last + 1)
			total += slices[slice];
		return total / (last - first + 1) / loudestSlice;
	}

	/** Adds up the sound between two pitches note by note. Squaring lets clear tones stand out from hiss. */
	public function energyOfEachNoteBetween(lowHz:Float, highHz:Float):Array<Float> {
		final energies = [for (_ in 0...notesInAnOctave) 0.0];
		for (slice in firstSliceAt(lowHz)...lastSliceAt(highHz) + 1)
			energies[noteOfSlice[slice]] += slices[slice] * slices[slice];
		return energies;
	}

	/** Slice 0 is no pitch at all (a standing push on the speaker), so listening starts at slice 1. */
	function firstSliceAt(hz:Float):Int {
		return Std.int(Math.max(1, Math.ceil(hz / hzPerSlice)));
	}

	function lastSliceAt(hz:Float):Int {
		return Std.int(Math.max(firstSliceAt(0), Math.min(slices.length - 1, Math.floor(hz / hzPerSlice))));
	}

	/**
	 * Which of the twelve notes a pitch is. Going up an octave doubles the
	 * pitch, so notes are evenly spaced on a doubling (log2) scale, twelve
	 * to each doubling, counted from concert A.
	 */
	function noteAtPitch(hz:Float):Int {
		if (hz <= 0)
			return 0;
		final semitonesFromA = Math.round(notesInAnOctave * Math.log(hz / Settings.concertAHz) / Math.log(2));
		final manyOctavesUp = notesInAnOctave * 100; // keeps the sum positive for pitches below A
		return (semitonesFromA + Settings.concertANoteNumber + manyOctavesUp) % notesInAnOctave;
	}
}
