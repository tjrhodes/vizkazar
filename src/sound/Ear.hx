package sound;

import js.html.audio.AudioContext;
import js.html.audio.AudioNode;

/** What the ear made of the sound in one frame. Strengths run from 0 (nothing) to 1 (lots). */
typedef Moment = {
	/** How strongly each of the twelve notes (C, C sharp, D … B) is sounding, in any octave. */
	noteStrengths:Array<Float>,
	/** Jumps up the instant a kick drum lands, further the sharper the kick (up to 1), then fades. */
	kick:Float,
	/** The same for a snare. */
	snare:Float,
	/** Which of the twelve notes the bassline is on, and how strongly the bass is sounding. */
	bassNote:Int,
	bassStrength:Float,
	/** The graphic equaliser: a level (0 to 1) for each band, deepest first. */
	bands:Array<Float>,
	/** The level of the music over the last few seconds: what "how full is it" means. */
	slowLoudness:Float
}

/**
 * Listens to whatever is playing and turns it into a few plain numbers
 * the picture can use: which notes are sounding, was that a kick or a
 * snare, what the bassline is doing, and how full the music is.
 *
 * It listens twice over (see Spectrum for why): a DETAILED spectrum that
 * can tell notes apart, and a QUICK one that is right on the beat.
 */
class Ear {
	/** Whatever should be heard gets plugged into this. */
	public final input:AudioNode;

	final detailed:Spectrum;
	final quick:Spectrum;
	final equaliser = new Equaliser();
	final kicks:Hits;
	final snares:Hits;

	var noteStrengths = silentNotes();
	var bassNoteStrengths = silentNotes();
	var bassStrength = 0.0;
	var slowLoudness = 0.0;

	public function new(context:AudioContext) {
		input = context.createGain();
		detailed = new Spectrum(context, input, Settings.detailedSpectrumSlices, Settings.detailedSpectrumBlending, Settings.detailedLoudestDecibels);
		quick = new Spectrum(context, input, Settings.quickSpectrumSlices, Settings.quickSpectrumBlending, Settings.quickLoudestDecibels);
		kicks = new Hits(context, input, Settings.kickDrum);
		snares = new Hits(context, input, Settings.snareDrum);
	}

	static function silentNotes():Array<Float> {
		return [for (_ in 0...Spectrum.notesInAnOctave) 0.0];
	}

	/** Listens to this frame's sound; `seconds` is how long since the last listen. */
	public function hear(seconds:Float):Moment {
		detailed.refresh();
		quick.refresh();
		followNotes(seconds);
		followBassline(seconds);
		return {
			noteStrengths: noteStrengths.copy(),
			kick: kicks.follow(seconds),
			snare: snares.follow(seconds),
			bands: equaliser.follow(quick, seconds),
			bassNote: strongestOf(bassNoteStrengths),
			bassStrength: bassStrength,
			slowLoudness: slowLoudness
		};
	}

	/** The notes of the tune, and how full the music is. */
	function followNotes(seconds:Float) {
		final loudness = detailed.loudnessBetween(Settings.lowestNoteHz, Settings.highestNoteHz);
		slowLoudness = Ease.toward(slowLoudness, loudness, Settings.slowLoudnessPerSecond, seconds);
		final energies = detailed.energyOfEachNoteBetween(Settings.lowestNoteHz, Settings.highestNoteHz);
		easeTowardShares(noteStrengths, energies, brightnessAt(loudness), seconds);
	}

	/**
	 * Notes are shown against the strongest note of the moment, not against
	 * a fixed level, so a quiet intro still colours the picture. Loudness
	 * only tops the brightness up, from `quietNotesStillShowAt` to full.
	 */
	function brightnessAt(loudness:Float):Float {
		final howLoud = Ease.within(0, loudness / Settings.loudnessForFullBrightness, 1);
		return Settings.quietNotesStillShowAt + (1 - Settings.quietNotesStillShowAt) * howLoud;
	}

	/** Which note the bass is on (from the detailed spectrum) and how hard it is playing (from the quick one). */
	function followBassline(seconds:Float) {
		final energies = detailed.energyOfEachNoteBetween(Settings.lowestBassHz, Settings.highestBassNoteHz);
		easeTowardShares(bassNoteStrengths, energies, 1, seconds);
		final bass = quick.loudnessBetween(Settings.lowestBassHz, Settings.highestBassNoteHz);
		final share = Ease.within(0, (bass - Settings.bassBarelyThere) / (Settings.bassAtFull - Settings.bassBarelyThere), 1);
		bassStrength = Ease.unevenly(bassStrength, share, Settings.bassRisesPerSecond, Settings.bassFadesPerSecond, seconds);
	}

	/**
	 * Each note eases towards its share of the strongest note's energy:
	 * quick to light, slower to fade, like a struck string. Sound too faint
	 * to be a clear note (hiss, near-silence) fades everything out instead.
	 */
	function easeTowardShares(strengths:Array<Float>, energies:Array<Float>, brightness:Float, seconds:Float) {
		final strongest = Lambda.fold(energies, Math.max, 1);
		final clearEnough = Ease.within(0, strongest / Settings.energyOfFaintestClearNote, 1);
		for (note in 0...strengths.length) {
			final goal = Math.pow(energies[note] / strongest, Settings.noteContrast) * brightness * clearEnough;
			strengths[note] = Ease.unevenly(strengths[note], goal, Settings.noteRisesPerSecond, Settings.noteFadesPerSecond, seconds);
		}
	}

	static function strongestOf(strengths:Array<Float>):Int {
		var strongest = 0;
		for (note in 0...strengths.length)
			if (strengths[note] > strengths[strongest])
				strongest = note;
		return strongest;
	}

}
