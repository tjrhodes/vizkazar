package sound;

import js.html.audio.AudioContext;
import js.html.audio.AudioNode;

/** What makes one kind of drum: where it lives and how steeply it arrives (see Settings). */
typedef DrumKind = {
	/** It is listened for between these two pitches. */
	lowestHz:Float,
	highestHz:Float,
	/** A rise this steep (decibels in a hundredth of a second) or steeper counts as a hit… */
	risesAtLeastDecibels:Float,
	/** …and its size grows from nothing at the first rise to full at the second. */
	sizeCountsFromDecibels:Float,
	fullRiseDecibels:Float,
	/** After a hit, what it moved settles back this quickly (per second). */
	fadesPerSecond:Float
}

/**
 * Turns one kind of drum into a number the picture can use: it jumps up
 * the instant a hit lands, further the steeper the hit (up to 1), and
 * then fades. A hit stays in the listener's view for a few frames, so
 * hits closer together than `Settings.shortestGapBetweenHits` count once.
 */
class Hits {
	final kind:DrumKind;
	final listener:RiseListener;
	var strength = 0.0;
	var secondsSinceHit = 0.0;

	public function new(context:AudioContext, sound:AudioNode, kind:DrumKind) {
		this.kind = kind;
		listener = new RiseListener(context, sound, kind.lowestHz, kind.highestHz);
	}

	/** Listens for this frame (`seconds` since the last) and answers the strength now. */
	public function follow(seconds:Float):Float {
		final steepness = listener.steepestRecentRise();
		final isHit = steepness >= kind.risesAtLeastDecibels && secondsSinceHit >= Settings.shortestGapBetweenHits;
		final size = (steepness - kind.sizeCountsFromDecibels) / (kind.fullRiseDecibels - kind.sizeCountsFromDecibels);
		strength = isHit ? Math.max(strength, Ease.within(0, size, 1)) : Ease.toward(strength, 0, kind.fadesPerSecond, seconds);
		secondsSinceHit = isHit ? 0 : secondsSinceHit + seconds;
		return strength;
	}
}
