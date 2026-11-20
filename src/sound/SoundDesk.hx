package sound;

import js.Browser;
import js.html.AudioElement;
import js.html.File;
import js.html.MediaStream;
import js.html.URL;
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
	public final ear:Ear;
	public final player:AudioElement;

	final context = new AudioContext();
	var microphone:Null<MediaStreamAudioSourceNode> = null;
	var microphoneStream:Null<MediaStream> = null;

	/** A file brought by the visitor is lent to the player as a temporary address. */
	var lentAddress:Null<String> = null;

	public function new(player:AudioElement) {
		this.player = player;
		ear = new Ear(context);
		final playerSound = context.createMediaElementSource(player);
		playerSound.connect(ear.input);
		playerSound.connect(context.destination);
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
