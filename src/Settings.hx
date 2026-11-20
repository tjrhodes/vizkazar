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

	/** A snare lightens the pieces it reaches this far towards cream (at full strength). */
	public static inline final snareLightensTowardsCream = 0.55;

	// ——— How sound travels down the corridor ———

	/** A block one corridor-width further away shows the sound from this much earlier. */
	public static inline final echoSecondsPerCorridorWidth = 0.1;

	/** How far back the memory goes: long enough to reach the far end of the corridor. */
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

	/** A kick also narrows the camera's view a touch, like a lunge forward (share of the view). */
	public static inline final kickPushesIn = 0.06;

	// ——— Colours ———
	public static inline final nightColour = 0x0d1322; // the grout between tiles, and the sky
	public static inline final starAsleepColour = 0x0b0b10; // the black stars of the zellige
	public static inline final bandColour = 0xefe6d2; // the cream strapwork

	/** A star takes the shade of the bassline's note; this is how far it goes at full bass (0 to 1). */
	public static inline final starGlowAtFullBass = 0.6;

	/**
	 * One colour family per tiling (see Palette.Family): `deep` when nothing
	 * sounds, `shades` round the pitch wheel. Cobalt and ochre are from the
	 * Seville tiles; green and purple from the RAI 3 and RAI 4 idents.
	 */
	public static final cobaltFamily = {deep: 0x16234d, shades: [0x2e63b8, 0x4f8fd6, 0x9cc8f0]};

	public static final greenFamily = {deep: 0x11301f, shades: [0x1f8a4c, 0x3fd27a, 0xa8ecbe]};
	public static final purpleFamily = {deep: 0x251240, shades: [0x6d3f8f, 0xa646d9, 0xe596f2]};
	public static final ochreFamily = {deep: 0x2e1a0e, shades: [0xb9432e, 0xdd7a1f, 0xe6a91f]};

	/** The strapwork's width in edges with no bass, and how much wider full bass makes it. */
	public static inline final bandWidth = 0.05;

	public static inline final bassWidensBands = 1.6;

	// ——— The corridor (see scene/Corridor.hx and scene/WallBlocks.hx) ———
	// Corridor units: half the corridor's width is 1.

	/**
	 * How wide half the corridor is, in edges: about this share of the
	 * tiling's own scale (so big shapes, a few across a wall), moved to the
	 * nearest line the pattern is mirrored along (see MirrorLines).
	 */
	public static inline final wallHalfWidthTimesScreen = 0.13;

	/**
	 * A corner block's 45° face, across the inside of the fold, runs this
	 * many times the block's height from the corner along each wall: the
	 * higher the block stands, the further out the face.
	 */
	public static inline final cornerBevelTimesHeight = 3.0;

	/** How far the corridor runs ahead of the camera, and behind it. */
	public static inline final corridorLength = 10.0;

	public static inline final corridorBehindCamera = 1.5;

	/** Tiles are laid this far (edges) beyond where they are needed, so none is missing at the edges. */
	public static inline final spareEdgesBeyondScreen = 2.0;

	/** How far the cream wall behind the blocks stands out, and how much wider it is than the wall (it runs on behind the neighbours). */
	public static inline final creamWallDepth = 0.03;

	public static inline final creamWallWiderTimes = 1.1;

	/** Every block stands out this far at rest, up to this much more at full band, and this much more on a kick. */
	public static inline final blockRestsOut = 0.05;

	public static inline final bandPushesOut = 0.22;
	public static inline final kickPushesOut = 0.08;

	/** A kite's face is this bright (0 deep to 1 its shade) with its notes silent, and full when they sound. */
	public static inline final faceAtRest = 0.4;

	/** A block's sides are this bright (0 deep to 1 its shade) at rest, and full at full band. */
	public static inline final sidesAtRest = 0.25;

	/** The walls slide towards the camera this fast (corridor units a second), and this much faster at a full kick. */
	public static inline final travelPerSecond = 0.35;

	public static inline final kickRushesOn = 1.5;

	// ——— The doorway between tilings (see scene/Doorway.hx and scene/Door.hx) ———

	/**
	 * The door appears (open) this far down the corridor, has closed by this
	 * distance, starts opening again this close (when it fills the screen)
	 * and is wide open by this close. The next corridor takes over once the
	 * door is the last distance behind the camera.
	 */
	public static inline final doorwayAppearsAt = 3.6;

	public static inline final doorShutBy = 2.6;
	public static inline final doorStartsOpeningAt = 1.1;
	public static inline final doorFullyOpenAt = 0.3;
	public static inline final doorwayPassedBehind = 0.5;

	/** The door's cream frame: this thick when it has risen out of the walls, and standing this far out, as a share of half the width. */
	public static inline final doorFrame = 0.08;

	/** Wide open, each block has slid this many half widths out from the middle, and turned this far, like an iris. */
	public static inline final doorOpensWidths = 1.8;

	public static inline final doorTwistsDegrees = 30.0;

	// ——— The camera and the light ———

	/** How wide the camera sees (up to down, degrees). */
	public static inline final fieldOfViewDegrees = 75.0;

	/** Nothing nearer or further than these (corridor units) is drawn. */
	public static inline final nearestSeen = 0.01;

	public static inline final furthestSeen = 100.0;

	/** Fog: none before this far, full (the tiling's deep colour) at the end of the corridor. */
	public static inline final fogStartsCorridorWidths = 1.5;

	/** Sharper than this many pixels per screen point isn't drawn, to keep phones smooth. */
	public static inline final sharpestPixelRatio = 2.0;

	/** The camera looks this far ahead, wandering this far off the middle, and rolls a little; each drifts at its own pace. */
	public static inline final cameraLooksThisFarAhead = 5.0;

	public static inline final cameraWanders = 0.35;
	public static inline final cameraWandersAcrossPerSecond = 0.023;
	public static inline final cameraWandersUpPerSecond = 0.013;
	public static inline final cameraRollsDegrees = 4.0;
	public static inline final cameraRollsPerSecond = 0.017;

	/**
	 * Soft, matte light. The "sky" is behind the camera (and a little
	 * above), the night ahead, so every wall is lit alike: block faces
	 * turned towards you are bright, faces turned away are dark. A gentle
	 * sun from above, to one side and behind tells the four walls apart.
	 */
	public static inline final skyLightColour = 0xfff1dc;

	public static inline final groundLightColour = 0x0d1322;
	public static inline final skyLightStrength = 0.8;
	public static final skyLightComesFrom = {x: 0.0, y: 0.5, z: 1.0};
	public static inline final sunColour = 0xffffff;
	public static inline final sunStrength = 0.7;
	public static final sunComesFrom = {x: 0.6, y: 0.5, z: 0.6};
}
