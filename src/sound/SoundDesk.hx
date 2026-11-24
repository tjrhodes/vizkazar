package sound;

import js.Browser;
import js.html.AudioElement;
import js.html.File;
import js.html.MediaStream;
import js.html.URL;
import js.html.URLSearchParams;
import js.html.audio.AudioContext;
import js.html.audio.MediaStreamAudioSourceNode;
import js.lib.Promise;

/**
 * Chooses what the ear listens to: the page's audio player (the default
 * track, or any file you bring) or the microphone.
 *
 * The player is wired to the ear AND to the speakers. The microphone is
 * wired to the ear only: playing a room back into itself would howl.
 */
class SoundDesk {
	static inline final millisecondsInASecond = 1000;

	public final ear:Ear;
	public final player:AudioElement;

	final context = new AudioContext();
	var microphone:Null<MediaStreamAudioSourceNode> = null;
	var microphoneStream:Null<MediaStream> = null;

	/** A file brought by the visitor is lent to the player as a temporary address. */
	var lentAddress:Null<String> = null;

	/** What to do when the visitor jumps to another place in the track, and when a new sound starts (a track, or the microphone). */
	public var whenJumped:() -> Void = () -> {};

	public var whenNewSound:() -> Void = () -> {};

	/** How far the track's clock is ahead of the page's (see trackTime). */
	var trackAhead = 0.0;

	public function new(player:AudioElement) {
		this.player = player;
		ear = new Ear(context);
		final playerSound = context.createMediaElementSource(player);
		playerSound.connect(ear.input);
		playerSound.connect(context.destination);
		player.addEventListener("seeked", () -> whenJumped());
	}

	/**
	 * The time (seconds) by the sound's own clock: where the track has got
	 * to, so a moment in the music keeps its time however the visitor jumps
	 * about. The player reports it a little unevenly, so it is followed
	 * gently, and taken at its word after a jump or a pause. The microphone
	 * has no track, so it goes by the page's clock.
	 */
	public function trackTime(now:Float):Float {
		if (microphone != null)
			return now;
		final reported = player.currentTime - now;
		if (Math.abs(reported - trackAhead) > Settings.trackClockTrustedAfterJumpOf)
			trackAhead = reported;
		else
			trackAhead += (reported - trackAhead) * Settings.trackClockFollows;
		return now + trackAhead;
	}

	/**
	 * How far behind the sound the pictures should run (seconds), so they
	 * move as you hear it, not before. The ear hears the sound as it goes
	 * into the speakers' queue; the sound card and the computer then take a
	 * while (often 20 to 60 thousandths of a second, more over Bluetooth)
	 * to play it, and the browser says how long. The microphone's sound is
	 * already in the room, so it gets no wait of its own. On top comes any
	 * extra wait set in Settings, or in the page's address (`?delay=40`, in
	 * thousandths of a second), to tune by eye.
	 */
	public function picturesWait():Float {
		final speakersWait = microphone != null ? 0 : reported(untyped context.baseLatency) + reported(untyped context.outputLatency);
		return Math.max(0, speakersWait + extraWait);
	}

	/** A latency the browser may not report: none if it doesn't. */
	static function reported(seconds:Null<Float>):Float {
		return seconds == null || Math.isNaN(seconds) ? 0 : seconds;
	}

	/** The extra wait for the pictures: from the page's address if it gives one, otherwise from Settings. */
	static final extraWait = {
		final asked = Std.parseFloat(new URLSearchParams(Browser.location.search).get("delay"));
		Math.isNaN(asked) ? Settings.picturesExtraWaitSeconds : asked / millisecondsInASecond;
	}

	public function playDefaultTrack() {
		playFrom(Settings.defaultTrackAddress);
	}

	/** Plays a file from the visitor's own computer. It never leaves their machine. */
	public function playFile(file:File) {
		returnLentAddress();
		lentAddress = URL.createObjectURL(file);
		playFrom(lentAddress);
	}

	public function listenToMicrophone():Promise<Void> {
		player.pause();
		wake();
		return Browser.navigator.mediaDevices.getUserMedia({audio: true}).then(plugInMicrophone);
	}

	public function playOrPause() {
		wake();
		if (player.paused) player.play() else player.pause();
	}

	function playFrom(address:String) {
		unplugMicrophone();
		whenNewSound();
		wake();
		player.src = address;
		player.play();
	}

	/** Browsers keep sound switched off until the visitor clicks something; this switches it on. */
	function wake() {
		context.resume();
	}

	function plugInMicrophone(stream:MediaStream) {
		unplugMicrophone();
		whenNewSound();
		microphoneStream = stream;
		microphone = context.createMediaStreamSource(stream);
		microphone.connect(ear.input);
	}

	/** Lets go of the microphone properly, so the browser's "recording" light goes out. */
	function unplugMicrophone() {
		if (microphone == null)
			return;
		microphone.disconnect();
		for (track in microphoneStream.getTracks())
			track.stop();
		microphone = null;
		microphoneStream = null;
	}

	function returnLentAddress() {
		if (lentAddress != null)
			URL.revokeObjectURL(lentAddress);
		lentAddress = null;
	}
}
