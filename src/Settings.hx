/**
 * Every number, colour and name that shapes the piece lives here, once.
 * To change how it looks or listens, change it here and nowhere else.
 *
 * Lengths are counted in "edges": every tile in every tiling has edges of
 * length 1, so one edge is the natural ruler for the whole picture.
 */
class Settings {
	// ——— The track that plays before anyone brings their own ———
	public static inline final defaultTrackAddress = "audio/amelie2.mp3";
	public static inline final defaultTrackName = "amelie2";

	// ——— How the ear listens ———

	/**
	 * The ear keeps two spectrums (see sound/Spectrum.hx). The detailed one
	 * tells notes apart but runs about a tenth of a second late; the quick
	 * one is blurry about pitch but on the beat. Slices must be powers of two.
	 * Blending is how much each answer keeps of the last (0 = none, 1 = frozen).
	 */
	public static inline final detailedSpectrumSlices = 8192;

	public static inline final detailedSpectrumBlending = 0.3;
	public static inline final quickSpectrumSlices = 2048;
	public static inline final quickSpectrumBlending = 0.0;

	/**
	 * Loudness is read in decibels between the quietest and the loudest below
	 * (as 0 and 255). The quick spectrum's ceiling sits high: with the beat
	 * in, the bass is loud enough to hit a lower ceiling, and a slice stuck at
	 * the ceiling can't show the next kick landing.
	 */
	public static inline final quietestDecibels = -100.0;

	public static inline final detailedLoudestDecibels = -30.0;
	public static inline final quickLoudestDecibels = -10.0;

	/** Notes are only listened for between these two pitches (about C2 to C7). */
	public static inline final lowestNoteHz = 65.0;

	public static inline final highestNoteHz = 2100.0;

	/** Concert A, the pitch every other note is measured from, and its place on a piano. */
	public static inline final concertAHz = 440.0;

	public static inline final concertANoteNumber = 69;

	/** A note lights up fast and fades slowly, like a struck string (both per second). */
	public static inline final noteRisesPerSecond = 40.0;

	public static inline final noteFadesPerSecond = 5.0;

	/** Above 1, quieter notes are pushed down so only the notes that matter light up. */
	public static inline final noteContrast = 3.5;

	/** However quiet the music, its strongest note still shows this brightly (0 to 1)… */
	public static inline final quietNotesStillShowAt = 0.75;

	/** …and at this loudness and above, notes show at full brightness. */
	public static inline final loudnessForFullBrightness = 0.22;

	/** Sound with less energy than this in its strongest note is hiss, not a note, and shows nothing. */
	public static inline final energyOfFaintestClearNote = 4000.0;

	/** How quickly the slow loudness (the "level" of the music) catches up, per second. */
	public static inline final slowLoudnessPerSecond = 0.35;

	// ——— The bassline ———

	/** The bassline is listened for between these two pitches (about E1 to C4). */
	public static inline final lowestBassHz = 40.0;

	public static inline final highestBassNoteHz = 260.0;

	/** Bass loudness that counts as "barely there" and as "full" (0 to 1). */
	public static inline final bassBarelyThere = 0.39;

	public static inline final bassAtFull = 0.72;
	public static inline final bassRisesPerSecond = 15.0;
	public static inline final bassFadesPerSecond = 8.0;

	// ——— Drums (see sound/RiseListener.hx and sound/Hits.hx) ———

	/**
	 * How much of the wave is looked at each frame (a power of two; at 48 000
	 * a second this is about 0.09 s). It must be longer than a frame, or a
	 * hit could fall between two frames unseen: this is enough down to about
	 * 12 frames a second.
	 */
	public static inline final hitWaveSamples = 4096;

	/** Loudness is followed as the average over this long, and a rise is measured over this long. */
	public static inline final hitLoudnessSmoothedOverSeconds = 0.004;

	public static inline final hitRiseMeasuredOverSeconds = 0.01;

	/** Sound quieter than this never counts, so hiss in a silence can't jump about. */
	public static inline final quietestHitDecibels = -60.0;

	/** The smallest wave size worth turning into decibels (anything less counts as silence). */
	public static inline final silenceLevel = 0.0000001;

	/** One drum is never counted twice: hits of one kind are at least this far apart. */
	public static inline final shortestGapBetweenHits = 0.12;

	/**
	 * The kick lives in the low end. In amelie2 a kick rises about 26 dB
	 * in a hundredth of a second (rarely under 19); the bassline and the
	 * hits in between about 8 (rarely over 16); the piano chords about 29.
	 * This caught 201 of the 210 main-beat kicks. Size starts well below the
	 * threshold, so even the softest kick that counts makes a clear move.
	 */
	public static final kickDrum = {
		lowestHz: 35.0,
		highestHz: 110.0,
		risesAtLeastDecibels: 16.0,
		sizeCountsFromDecibels: 6.0,
		fullRiseDecibels: 30.0,
		fadesPerSecond: 7.0
	};

	/**
	 * The snare snaps in the middle-high band. In amelie2 a snare rises
	 * about 30 dB there (the 7th and 15th sixteenths of each bar), other
	 * hits rarely over 20; hi-hats sit higher still and hardly show. It
	 * fades fast, so its brightness travels out as a thin ring.
	 */
	public static final snareDrum = {
		lowestHz: 1000.0,
		highestHz: 4000.0,
		risesAtLeastDecibels: 20.0,
		sizeCountsFromDecibels: 18.0,
		fullRiseDecibels: 34.0,
		fadesPerSecond: 10.0
	};

	// ——— Keeping time: the bars (see sound/BarClock.hx and sound/BarLength.hx) ———

	/** Two kicks this close (seconds) count as at the same moment, when matching kicks to bars. */
	public static inline final kickTimingSlack = 0.035;

	/** A bar is looked for between these lengths (seconds; about 60 to 150 beats a minute in 4/4), this finely. */
	public static inline final shortestBarSeconds = 1.6;

	public static inline final longestBarSeconds = 4.2;
	public static inline final barSearchStepSeconds = 0.005;

	/** The bar length is worked out once this many kicks have come in, if the best length fits at least this well (0 to 1)… */
	public static inline final kicksBeforeBarIsKnown = 6;

	public static inline final barMustFitAtLeast = 0.4;

	/** …and of the lengths that fit nearly as well as the best (this share of it), the shortest is taken. */
	public static inline final nearlyAsGoodAsBest = 0.9;

	/** The clock looks back over this long (seconds) of kicks, and keeps in step once this many have landed on beat one. */
	public static inline final barClockRemembersSeconds = 24.0;

	public static inline final downbeatKicksToKeepStep = 2;

	/** A kick this close to beat one (a share of a sixteenth) counts as on it, and a newly worked-out bar length this different (a share) replaces the old. */
	public static inline final downbeatSlackSixteenths = 0.45;

	public static inline final barLengthChangesBy = 0.03;

	/** A gap in the kicks this long (seconds, before the bar is known; then bars) means the beat stopped: its next kick is beat one again. */
	public static inline final secondsWithoutKicksBeforeNewStart = 4.0;

	public static inline final barsWithoutKicksBeforeNewStart = 2;

	/** With no kicks, the clock keeps counting bars for this many, then gives up. */
	public static inline final barsClockRunsOnWithoutKicks = 16;

	/**
	 * The pictures already wait for the speakers (the browser says how long
	 * its sound takes to come out; see SoundDesk.picturesWait). This much
	 * more (seconds) can be added, or taken away if below 0, to taste.
	 * `?delay=40` in the page's address overrides it, in thousandths.
	 */
	public static inline final picturesExtraWaitSeconds = 0.0;

	// ——— How sound ripples outwards ———

	/** How far back the memory goes: long enough for sound to ripple out past the screen's corners. */
	public static inline final secondsRemembered = 1.5;

	// ——— The graphic equaliser (see sound/Equaliser.hx) ———

	/** How many bands, and the pitches they run between (the lowest bass to the top of the treble). */
	public static inline final equaliserBands = 16;

	public static inline final lowestBandHz = 40.0;
	public static inline final highestBandHz = 12000.0;

	/** Each band is judged against its own recent range, which forgets this quickly (per second)… */
	public static inline final bandRangeForgetsPerSecond = 0.1;

	/** …and is never treated as narrower than this (so near-silence doesn't jump about). */
	public static inline final narrowestBandRange = 0.08;

	/** Levels jump up this quickly and fall back this quickly (per second), like a meter's needle. */
	public static inline final bandRisesPerSecond = 30.0;

	public static inline final bandFallsPerSecond = 6.0;

	// ——— How the pattern grows more complex with the level ———

	/** A new tiling must stay at least this long, so the picture never flickers between two. */
	public static inline final secondsATilingMustStay = 10.0;

	/**
	 * "Full" is judged against how quiet and how loud the music has been
	 * lately, not against a fixed level: a finished track sits at much the
	 * same level throughout, and it is its swells and breakdowns that matter.
	 * This is how quickly "lately" forgets (per second).
	 */
	public static inline final recentRangeForgetsPerSecond = 0.04;

	/** A range narrower than this is treated as this wide, so near-silence does not count as a swell. */
	public static inline final narrowestRecentRange = 0.06;

	// ——— How the stars move ———

	/** The contact angle (see StarCutter) may never leave this range, in degrees. */
	public static inline final narrowestContactAngle = 18.0;

	public static inline final widestContactAngle = 86.0;

	/** A kick swings the contact angle by this many degrees, then it settles back. */
	public static inline final kickSwingsContactAngle = 14.0;

	/** With no kick at all the angle still drifts gently: by this much, this often. */
	public static inline final contactAngleDrift = 5.0;

	public static inline final contactAngleDriftsPerSecond = 0.23;

	/** A kick also moves the camera in a touch (share of the view). */
	public static inline final kickPushesIn = 0.06;

	// ——— Colours: the RAI 2 way, one colour family plus white and a near-black ———

	/** The ground before any pattern is laid, and the white every RAI ident keeps beside its colour. */
	public static inline final nightColour = 0x0d1322;

	public static inline final whiteColour = 0xffffff;

	/**
	 * One colour family per tiling (see Palette.Family): `deep` is the
	 * ground between the columns and darkens their sides, `shades` go round
	 * the pitch wheel. Like the RAI channels, each tiling has its own hue.
	 */
	public static final cobaltFamily = {deep: 0x16234d, shades: [0x2e63b8, 0x4f8fd6, 0x9cc8f0]};

	public static final greenFamily = {deep: 0x11301f, shades: [0x1f8a4c, 0x3fd27a, 0xa8ecbe]};
	public static final purpleFamily = {deep: 0x251240, shades: [0x6d3f8f, 0xa646d9, 0xe596f2]};
	public static final ochreFamily = {deep: 0x2e1a0e, shades: [0xb9432e, 0xdd7a1f, 0xe6a91f]};

	/** A column's sides are its shade darkened this far towards the deep colour (0 not at all, 1 all the way): left, then right. */
	public static inline final leftSidesDarken = 0.3;

	public static inline final rightSidesDarken = 0.6;

	/** A face pointing up at least this much (0 sideways, 1 straight up) takes the top's tone. */
	public static inline final facesCountAsTopsFrom = 0.5;

	/** A kite's white top takes on this much of its shade (0 to 1) when its notes sound fully. */
	public static inline final kiteTopTakesNoteShade = 0.7;

	/** A full snare turns the wedges' tops this far towards white (0 to 1). */
	public static inline final snareWhitensWedges = 0.6;

	/** The strapwork's width in edges with no bass, and how much wider full bass makes it. */
	public static inline final bandWidth = 0.05;

	public static inline final bassWidensBands = 1.6;

	// ——— The field of columns (see scene/Field.hx) ———

	/** How many edges show across the screen: this share of the tiling's own scale, so the pieces look much the same size in every tiling. */
	public static inline final fieldShownTimesScreen = 0.55;

	/** The field is laid out to this many screen widths from the middle, past the screen's corners. */
	public static inline final fieldLaidOutToWidths = 0.9;

	/** Tiles are laid this far (edges) beyond where they are needed, so none is missing at the edges. */
	public static inline final spareEdgesBeyondScreen = 2.0;

	/** Every column stands this tall at rest (edges), up to this much taller at full band, and this much more on a kick. */
	public static inline final columnRests = 0.06;

	public static inline final columnRisesWithBand = 0.45;
	public static inline final columnRisesWithKick = 0.15;

	/** Sound takes this long to ripple from the middle of the screen to its edge (seconds). */
	public static inline final echoSecondsAcrossScreen = 0.5;

	// ——— The wave of turning blocks between tilings (see scene/TurnWave.hx) ———

	/**
	 * A change of tiling lands on beat one of the first bar of a phrase of
	 * this many bars (counted from when the beat came in): 4, 8 or 16. A
	 * change picked from the menu lands on the next bar instead.
	 */
	public static inline final phraseBars = 4;

	/** The view closes in on the middle star during this many bars before the change, and the wave turns the whole field over in this many. */
	public static inline final closeUpBars = 1;

	public static inline final turnWaveBars = 1;

	/** With no beat to keep time by, the close-in and the wave take this long instead (seconds). */
	public static inline final closeUpSecondsWithoutBeat = 1.5;

	public static inline final turnWaveSecondsWithoutBeat = 2.4;

	/** Closed in, the screen is this many times as wide as the middle star. */
	public static inline final closeUpTimesStar = 1.6;

	/** Each block turns over while the wave travels on this share of the field's reach: more is a wider, softer wave. */
	public static inline final blockTurnsWhileWaveTravels = 0.25;

	// ——— The camera ———

	/** The camera looks down at the field tilted this far from straight down (degrees), so the columns' fronts show below their tops. */
	public static inline final viewTiltDegrees = 35.0;

	/** Sharper than this many pixels per screen point isn't drawn, to keep phones smooth. */
	public static inline final sharpestPixelRatio = 2.0;
}
