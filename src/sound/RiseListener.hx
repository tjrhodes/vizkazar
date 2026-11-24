package sound;

import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.html.audio.AudioNode;
import js.html.audio.BiquadFilterNode;
import js.lib.Float32Array;

/**
 * Listens for drum hits in the sound wave itself, not in a spectrum.
 *
 * What makes a drum a drum is how FAST it arrives: a kick makes the low
 * end jump by about 25 decibels within a hundredth of a second, while a
 * bass note swells in much more gently (about 8), even when it ends up
 * just as loud. A snare does the same in the middle-high band (1 to 4
 * thousand a second). A spectrum can't see that difference, because it
 * only looks at the sound in chunks of about 45 thousandths of a second;
 * the wave itself can.
 *
 * So: keep only one band of pitches (two filters), follow how loud it is
 * from moment to moment, and report the steepest rise in the last few
 * hundredths of a second. (A hit stays in view for two or three frames;
 * see Hits for how it is only counted the first time.)
 */
class RiseListener {
	final context:AudioContext;
	final analyser:AnalyserNode;
	final wave:Float32Array;
	final loudness:Float32Array;
	final samplesToSmoothOver:Int;
	final samplesToRiseOver:Int;

	/** Listens to `sound`, but only between `lowestHz` and `highestHz`. */
	public function new(context:AudioContext, sound:AudioNode, lowestHz:Float, highestHz:Float) {
		this.context = context;
		final keepAboveLowest = filter("highpass", lowestHz);
		final keepBelowHighest = filter("lowpass", highestHz);
		analyser = context.createAnalyser();
		analyser.fftSize = Settings.hitWaveSamples;
		sound.connect(keepAboveLowest);
		keepAboveLowest.connect(keepBelowHighest);
		keepBelowHighest.connect(analyser);
		samplesToSmoothOver = samplesIn(Settings.hitLoudnessSmoothedOverSeconds);
		samplesToRiseOver = samplesIn(Settings.hitRiseMeasuredOverSeconds);
		wave = new Float32Array(Settings.hitWaveSamples);
		loudness = new Float32Array(Settings.hitWaveSamples - samplesToSmoothOver + 1);
	}

	function filter(kind:String, hz:Float):BiquadFilterNode {
		final made = context.createBiquadFilter();
		made.type = cast kind;
		made.frequency.value = hz;
		return made;
	}

	function samplesIn(seconds:Float):Int {
		return Math.round(seconds * context.sampleRate);
	}

	/** How long ago (seconds) the steepest rise found by the last listen reached its top. */
	public var steepestSecondsAgo(default, null) = 0.0;

	/** The steepest rise, in decibels, anywhere in the last few hundredths of a second of sound. */
	public function steepestRecentRise():Float {
		analyser.getFloatTimeDomainData(wave);
		followLoudness();
		var steepest = 0.0, steepestAt = loudness.length - 1;
		for (moment in samplesToRiseOver...loudness.length) {
			final rise = loudness[moment] - loudness[moment - samplesToRiseOver];
			if (loudness[moment] > Settings.quietestHitDecibels && rise > steepest) {
				steepest = rise;
				steepestAt = moment;
			}
		}
		steepestSecondsAgo = (loudness.length - 1 - steepestAt) / context.sampleRate;
		return steepest;
	}

	/**
	 * How loud the wave is at every moment, in decibels: the average size
	 * of the wave over a short stretch ending at that moment. (A running
	 * total makes this quick: add the newest sample, drop the oldest.)
	 */
	function followLoudness() {
		var total = 0.0;
		for (sample in 0...wave.length) {
			total += Math.abs(wave[sample]);
			if (sample >= samplesToSmoothOver)
				total -= Math.abs(wave[sample - samplesToSmoothOver]);
			if (sample >= samplesToSmoothOver - 1)
				loudness[sample - samplesToSmoothOver + 1] = decibels(total / samplesToSmoothOver);
		}
	}

	static function decibels(level:Float):Float {
		return 20 * Math.log(Math.max(level, Settings.silenceLevel)) / Math.log(10);
	}

}
