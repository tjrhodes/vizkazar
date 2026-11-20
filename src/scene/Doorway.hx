package scene;

/**
 * How the corridor passes from one scene (tiling) to the next, without
 * changing pace. A short way down the tunnel, a door grows across it: its
 * frame rises out of the walls and its blocks slide in from the frame,
 * like a camera's iris closing. Once it is shut, the next corridor is
 * built behind it, unseen. You travel on to it at the usual speed, and
 * when you are close it opens again the same way, onto the next corridor.
 * Keeps the door's distance and answers how shut it is.
 */
class Doorway {
	/** How far down the corridor the door is now (corridor units; below 0 it is behind the camera). */
	public var distance(default, null) = 0.0;

	public var going(default, null) = false;

	/** What to do once the door is behind the camera (the next corridor takes over), once. */
	var whenThrough:Null<() -> Void> = null;

	public function new() {}

	/** Puts an open door a short way down the corridor; it closes as you travel towards it. */
	public function start(whenThrough:() -> Void) {
		going = true;
		distance = Settings.doorwayAppearsAt;
		this.whenThrough = whenThrough;
	}

	/** The camera travels `travel` (corridor units) towards the door; once it is through, the next corridor takes over. */
	public function approach(travel:Float) {
		if (!going)
			return;
		distance -= travel;
		if (distance < -Settings.doorwayPassedBehind)
			goThrough();
	}

	function goThrough() {
		going = false;
		final through = whenThrough;
		whenThrough = null;
		if (through != null)
			through();
	}

	/** How far the door has closed across the tunnel since it appeared: 0 not at all, 1 shut. */
	public function closed():Float {
		return going ? 1 - Ease.gentlyBetween(Settings.doorShutBy, distance, Settings.doorwayAppearsAt) : 0;
	}

	/** How far it has opened again as you came close: 0 not yet, 1 wide open. */
	public function opening():Float {
		return going ? 1 - Ease.gentlyBetween(Settings.doorFullyOpenAt, distance, Settings.doorStartsOpeningAt) : 0;
	}

	/** How shut the door is right now: closing as it appears, opening as you reach it. */
	public function shut():Float {
		return closed() * (1 - opening());
	}

	/** Whether the next corridor is behind the door yet: only once the door has shut, so it is never seen arriving. */
	public function nextIsBehind():Bool {
		return going && distance <= Settings.doorShutBy;
	}
}
