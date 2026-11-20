package sound;

/**
 * A graphic equaliser: the sound split into bands, from the deepest bass
 * to the highest treble, each with a level from 0 to 1, like the bars of
 * the RAI 4 ident.
 *
 * The bands are spaced evenly on a doubling scale (each a little over
 * half an octave), the way we hear pitch. Each is judged against its own
 * recent range, so every band uses its whole height. Levels jump up
 * quickly and fall back more slowly, like the needles of a real meter.
 */
class Equaliser {
	final edgesHz:Array<Float>;
	final ranges:Array<RecentRange>;
	final levels:Array<Float>;

	public function new() {
		final bands = Settings.equaliserBands;
		final ratio = Math.pow(Settings.highestBandHz / Settings.lowestBandHz, 1 / bands);
		edgesHz = [for (edge in 0...bands + 1) Settings.lowestBandHz * Math.pow(ratio, edge)];
		ranges = [for (_ in 0...bands) new RecentRange(Settings.bandRangeForgetsPerSecond, Settings.narrowestBandRange)];
		levels = [for (_ in 0...bands) 0.0];
	}

	/** Reads every band from `spectrum` for this frame and answers their levels (a fresh copy). */
	public function follow(spectrum:Spectrum, seconds:Float):Array<Float> {
		for (band in 0...levels.length) {
			final loudness = spectrum.loudnessBetween(edgesHz[band], edgesHz[band + 1]);
			final wanted = Ease.within(0, ranges[band].place(loudness, seconds), 1);
			levels[band] = Ease.unevenly(levels[band], wanted, Settings.bandRisesPerSecond, Settings.bandFallsPerSecond, seconds);
		}
		return levels.copy();
	}
}
