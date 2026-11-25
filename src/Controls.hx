import js.Browser;
import js.html.Element;
import js.html.InputElement;
import js.html.SelectElement;
import pattern.Tilings;
import sound.SoundDesk;

/**
 * The few things a visitor can press: start, play/pause, bring your own
 * audio, use the microphone, hold the pattern at one complexity, and fill
 * the screen. Each control only passes the wish on; the desk and conductor
 * do the work. Their words come from Words, in the page's language.
 */
class Controls {
	static inline final followTheMusic = "auto";

	final desk:SoundDesk;
	final conductor:Conductor;

	public function new(desk:SoundDesk, conductor:Conductor) {
		this.desk = desk;
		this.conductor = conductor;
		sayEverything();
		listTilingsInMenu();
		whenClicked("start", start);
		whenClicked("play-pause", desk.playOrPause);
		whenClicked("microphone", useMicrophone);
		whenClicked("full-screen", fillTheScreen);
		part("own-audio").onchange = playChosenFile;
		part("complexity").onchange = pinChosenTiling;
		Browser.document.addEventListener("fullscreenchange", showFullScreenOrNot);
		part("full-screen").hidden = !Browser.document.fullscreenEnabled; // an iPhone can't fill the screen with a page
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
		desk.listenToMicrophone().then(_ -> nowPlaying(Words.said.microphone)).catchError(_ -> nowPlaying(Words.said.microphoneRefused));
	}

	/** The whole screen for the pattern (from inside the Lab page's frame too); pressed again, back to the page. */
	function fillTheScreen() {
		final document = Browser.document;
		if (document.fullscreenElement != null)
			document.exitFullscreen();
		else
			document.documentElement.requestFullscreen();
	}

	/** The full-screen button offers the way back while the screen is filled. */
	function showFullScreenOrNot() {
		final filled = Browser.document.fullscreenElement != null;
		name("full-screen", filled ? Words.said.exitFullScreen : Words.said.fullScreen);
		showIcon("full-screen", filled ? "exit-full-screen" : "full-screen");
	}

	/** Every word on the page, in its language. */
	function sayEverything() {
		final said = Words.said;
		Browser.document.documentElement.lang = Words.language;
		Browser.document.title = said.title;
		say("welcome-title", said.title);
		say("welcome-intro", said.intro);
		say("start", said.start);
		name("play-pause", said.pause);
		name("own-audio-chooser", said.ownAudio);
		name("microphone", said.microphone);
		say("follow-the-music", said.followTheMusic);
		name("complexity-chooser", said.complexity);
		say("complexity-chooser .words", said.followTheMusic);
		part("complexity").setAttribute("aria-label", said.complexity);
		name("full-screen", said.fullScreen);
		part("stage").setAttribute("aria-label", said.picture);
		part("time").setAttribute("aria-label", said.timeIntoTrack);
	}

	/** Words into the part with this id, or into the part a selector like "complexity-chooser .words" picks. */
	static function say(id:String, words:String) {
		Browser.document.querySelector('#$id').textContent = words;
	}

	/** A control's words: beside its icon on a wide screen, and on any screen as its tooltip and for screen readers. */
	static function name(id:String, words:String) {
		say('$id .words', words);
		part(id).title = words;
	}

	/** Swap the icon on a control for another of the page's icons (`icon-<icon>` in index.html). */
	static function showIcon(id:String, icon:String) {
		Browser.document.querySelector('#$id use').setAttribute("href", '#icon-$icon');
	}

	/** The menu offers "follow the music" plus every tiling there is, named by its folds (the sides of its middle tile). */
	function listTilingsInMenu() {
		for (tiling in Tilings.simplestFirst) {
			final choice = Browser.document.createOptionElement();
			choice.value = tiling.name;
			choice.textContent = Words.said.folds(tiling.tiles[0].sides);
			part("complexity").appendChild(choice);
		}
	}

	function pinChosenTiling() {
		final menu:SelectElement = cast part("complexity");
		final chosen = menu.value;
		say("complexity-chooser .words", menu.options[menu.selectedIndex].textContent);
		conductor.pinnedTiling = chosen == followTheMusic ? null : Tilings.simplestFirst.filter(tiling -> tiling.name == chosen)[0];
	}

	function showPlayingOrPaused() {
		final paused = desk.player.paused;
		name("play-pause", paused ? Words.said.play : Words.said.pause);
		showIcon("play-pause", paused ? "play" : "pause");
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
