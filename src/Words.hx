import js.Browser;
import js.html.URLSearchParams;

/** Everything the page says, in one language. */
typedef Said = {
	title:String,
	intro:String,
	start:String,
	play:String,
	pause:String,
	ownAudio:String,
	microphone:String,
	microphoneRefused:String,
	complexity:String,
	followTheMusic:String,
	fullScreen:String,
	picture:String,
	timeIntoTrack:String,
	/** A tiling's name in the menu, from its number of folds (4, 6, 8, 12). */
	folds:Int->String
}

/**
 * The page's words in English and Italian. The language comes from the
 * page's address (`?lang=it`, as the Lab page on tomrhodes.it asks for),
 * or else from the browser's own language.
 */
class Words {
	static final english:Said = {
		title: "Vizkazar",
		intro: "Star patterns from the tiles of Seville, built from solid blocks that the music raises, colours and turns over.",
		start: "Play",
		play: "Play",
		pause: "Pause",
		ownAudio: "Your own audio",
		microphone: "Microphone",
		microphoneRefused: "Microphone not allowed",
		complexity: "Complexity",
		followTheMusic: "Follow the music",
		fullScreen: "Full screen",
		picture: "A field of star-shaped blocks that rise, change colour and turn over with the music",
		timeIntoTrack: "Time into the track",
		folds: count -> '$count-fold'
	};

	static final italian:Said = {
		title: "Vizkazar",
		intro: "Le stelle delle piastrelle di Siviglia, fatte di blocchi solidi che la musica alza, colora e capovolge.",
		start: "Avvia",
		play: "Avvia",
		pause: "Pausa",
		ownAudio: "Il tuo audio",
		microphone: "Microfono",
		microphoneRefused: "Microfono non consentito",
		complexity: "Complessità",
		followTheMusic: "Segui la musica",
		fullScreen: "Schermo intero",
		picture: "Un campo di blocchi a forma di stella che si alzano, cambiano colore e si capovolgono con la musica",
		timeIntoTrack: "Tempo trascorso",
		folds: count -> 'Simmetria $count'
	};

	/** The words in the page's language. */
	public static final said:Said = isItalian() ? italian : english;

	public static final language = isItalian() ? "it" : "en";

	static function isItalian():Bool {
		final asked = new URLSearchParams(Browser.location.search).get("lang");
		final language = asked != null ? asked : Browser.navigator.language;
		return language.toLowerCase().indexOf("it") == 0;
	}
}
