package scene;

/**
 * How the field passes from one pattern to the next: a wave of turning
 * blocks running out from the middle. Every block is like a card with the
 * old pattern on its front and the new one on its back. As the wave
 * reaches a block it turns over, rolling outwards: the old block turns up
 * onto its edge, and the new one comes down from its edge in its place.
 *
 * Keeps how far out the wave has got, and answers how far each block has
 * turned, by how far it is from the middle.
 */
class TurnWave {
	public var going(default, null) = false;

	/** How far out the wave has travelled (edges), and how far it has to go to turn the whole field. */
	var front = 0.0;

	var reach = 1.0;

	/** What to do once every block has turned over (the new pattern takes over), once. */
	var whenTurned:Null<() -> Void> = null;

	public function new() {}

	/** Sets the wave running from the middle out to `reach` (edges). */
	public function start(reach:Float, whenTurned:() -> Void) {
		going = true;
		front = 0;
		this.reach = reach;
		this.whenTurned = whenTurned;
	}

	/** Moves the wave on: it crosses the whole field in the same time, however big the field. */
	public function advance(seconds:Float) {
		if (!going)
			return;
		front += seconds * reach * (1 + Settings.blockTurnsWhileWaveTravels) / Settings.turnWaveSeconds;
		if (progress() >= 1)
			finish();
	}

	function finish() {
		going = false;
		final turned = whenTurned;
		whenTurned = null;
		if (turned != null)
			turned();
	}

	/** How far through the whole change the wave is, from 0 to 1. */
	public function progress():Float {
		return going ? Math.min(1, front / (reach * (1 + Settings.blockTurnsWhileWaveTravels))) : 0;
	}

	/**
	 * How far a block `fromMiddle` (edges) away has turned over, from 0
	 * (the wave not there yet) to 1 (turned): each block turns while the
	 * wave travels on a share of the field's reach.
	 */
	function turnedAt(fromMiddle:Float):Float {
		return Ease.gentlyBetween(fromMiddle, front, fromMiddle + reach * Settings.blockTurnsWhileWaveTravels);
	}

	/** How far an old block has turned (radians): up onto its edge in the first half of its turn, then gone. */
	public function oldBlockTurn(fromMiddle:Float):Float {
		return Math.min(turnedAt(fromMiddle) * Math.PI, Math.PI / 2);
	}

	/** How far a new block still has to turn (radians, below 0): on its edge until its half of the turn comes, then down flat. */
	public function newBlockTurn(fromMiddle:Float):Float {
		return Math.max(turnedAt(fromMiddle) * Math.PI - Math.PI, -Math.PI / 2);
	}
}
