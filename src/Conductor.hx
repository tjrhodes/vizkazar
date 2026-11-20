import pattern.Geometry;
import pattern.Tilings;
import sound.Ear.Moment;

/** How the pattern holds itself for one frame. */
typedef Pose = {
	/** The angle a tiling's stars are cut at (see StarCutter), in radians: each tiling has its own resting angle. */
	contactAngleFor:Tiling->Float,
	/** The width of the cream bands, in edges. */
	bandWidth:Float,
	/** How far the picture is pushed in: 1 is its resting size. */
	zoom:Float
}

/**
 * Decides the big moves from what the ear hears: which tiling to show
 * (more complex as the music fills out) and how the stars should be
 * breathing right now (the contact angle).
 */
class Conductor {
	/** The tiling on show now. */
	public var tiling(default, null):Tiling = Tilings.simplestFirst[0];

	/** Set by the complexity menu to hold one tiling whatever the music does; null follows the music. */
	public var pinnedTiling:Null<Tiling> = null;

	/** "Full" is judged against how quiet and loud the music has been lately (see RecentRange). */
	final level = new RecentRange(Settings.recentRangeForgetsPerSecond, Settings.narrowestRecentRange);

	var secondsWithThisTiling = 0.0;

	public function new() {}

	/** Follows the music for one frame. Answers true when the tiling has just changed. */
	public function follow(moment:Moment, seconds:Float):Bool {
		secondsWithThisTiling += seconds;
		final fullness = level.place(moment.slowLoudness, seconds);
		final wanted = pinnedTiling != null ? pinnedTiling : tilingForFullness(fullness);
		if (wanted == tiling || !mayChangeNow())
			return false;
		tiling = wanted;
		secondsWithThisTiling = 0;
		return true;
	}

	/**
	 * The pose for this frame. A kick squeezes the stars and pushes the
	 * picture in, the instant it lands, and both settle back together. The
	 * bassline swells and thins the cream bands as it goes.
	 */
	public function pose(moment:Moment, secondsSinceStart:Float):Pose {
		return {
			contactAngleFor: shown -> contactAngle(shown, moment.kick, secondsSinceStart),
			bandWidth: Settings.bandWidth * (1 + moment.bassStrength * Settings.bassWidensBands),
			zoom: 1 + moment.kick * Settings.kickPushesIn
		};
	}

	/** The tiling's resting angle, swung by the kick, with a slow drift so it is never quite still. */
	function contactAngle(shown:Tiling, kick:Float, secondsSinceStart:Float):Float {
		final drift = Math.sin(secondsSinceStart * Settings.contactAngleDriftsPerSecond * Geometry.fullTurn);
		final degrees = shown.restingContactDegrees + kick * Settings.kickSwingsContactAngle + drift * Settings.contactAngleDrift;
		return Geometry.radians(Ease.within(Settings.narrowestContactAngle, degrees, Settings.widestContactAngle));
	}

	/** The most complex tiling the music is currently full enough to wake. */
	function tilingForFullness(fullness:Float):Tiling {
		var fullest = Tilings.simplestFirst[0];
		for (candidate in Tilings.simplestFirst)
			if (fullness >= candidate.wakesAtFullness)
				fullest = candidate;
		return fullest;
	}

	/** A pinned choice changes at once; the music has to wait its turn. */
	function mayChangeNow():Bool {
		return pinnedTiling != null || secondsWithThisTiling >= Settings.secondsATilingMustStay;
	}
}
