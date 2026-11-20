import js.Browser;
import js.html.Element;
import js.html.InputElement;
import js.html.SelectElement;
import pattern.Tilings;
import sound.SoundDesk;

/**
 * The few things a visitor can press: start, play/pause, bring your own
 * audio, use the microphone, and hold the pattern at one complexity.
 * Each control only passes the wish on; the desk and conductor do the work.
 */
class Controls {
	static inline final followTheMusic = "auto";

	final desk:SoundDesk;
	final conductor:Conductor;

	public function new(desk:SoundDesk, conductor:Conductor) {
		this.desk = desk;
		this.conductor = conductor;
		listTilingsInMenu();
		whenClicked("start", start);
		whenClicked("play-pause", desk.playOrPause);
		whenClicked("microphone", useMicrophone);
		part("own-audio").onchange = playChosenFile;
		part("complexity").onchange = pinChosenTiling;
		desk.player.onplay = desk.player.onpause = showPlayingOrPaused;
		desk.player.ontimeupdate = showWhereWeAre;
	}

	/** The first click anywhere useful: browsers only allow sound after one. */
	function start() {
		part("welcome").hidden = true;
		part("controls").hidden = false;
		desk.playDefaultTrack();
		nowPlaying(Settings.defaultTrackName);
	}

	function playChosenFile() {
		final file = (cast part("own-audio") : InputElement).files[0];
		if (file == null)
			return;
		desk.playFile(file);
		nowPlaying(file.name);
	}

	function useMicrophone() {
		desk.listenToMicrophone().then(_ -> nowPlaying(part("microphone").textContent))
			.catchError(_ -> nowPlaying(part("microphone").dataset.refused));
	}

	/** The menu offers "follow the music" plus every tiling there is, by name. */
	function listTilingsInMenu() {
		for (tiling in Tilings.simplestFirst) {
			final choice = Browser.document.createOptionElement();
			choice.value = choice.textContent = tiling.name;
			part("complexity").appendChild(choice);
		}
	}

	function pinChosenTiling() {
		final chosen = (cast part("complexity") : SelectElement).value;
		conductor.pinnedTiling = chosen == followTheMusic ? null : Tilings.simplestFirst.filter(tiling -> tiling.name == chosen)[0];
	}

	function showPlayingOrPaused() {
		final button = part("play-pause");
		button.textContent = desk.player.paused ? button.dataset.play : button.dataset.pause;
	}

	/** Minutes and seconds into the track, so a moment can be pointed at ("it goes wrong at 2:13"). */
	function showWhereWeAre() {
		final seconds = Std.int(desk.player.currentTime);
		part("time").textContent = '${Std.int(seconds / 60)}:${StringTools.lpad(Std.string(seconds % 60), "0", 2)}';
	}

	function nowPlaying(name:String) {
		part("now-playing").textContent = name;
	}

	function whenClicked(id:String, wish:() -> Void) {
		part(id).onclick = wish;
	}

	static function part(id:String):Element {
		return Browser.document.getElementById(id);
	}
}
