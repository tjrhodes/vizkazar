package picture;

/** A colour as red, green and blue, each from 0 to 255. */
typedef Colour = {red:Float, green:Float, blue:Float};

/**
 * A colour family: each tiling is drawn in one (see Tilings), the way
 * each RAI ident keeps to one colour plus white and near-black. `deep`
 * is a kite with nothing sounding; `shades` are met going once round the
 * pitch wheel, so each note has its own shade within the family.
 */
typedef Family = {deep:Colour, shades:Array<Colour>};

/** The same, written the web way (0xRRGGBB), as Settings keeps them. */
typedef FamilyInHex = {deep:Int, shades:Array<Int>};

/** Turns the colours in Settings into colours to draw with, and blends between them. */
class Palette {
	static inline final brightest = 255;

	public static final starAsleep = fromHex(Settings.starAsleepColour);
	public static final band = fromHex(Settings.bandColour);

	/** Splits a colour written the web way (0xRRGGBB) into its three parts. */
	static function fromHex(hex:Int):Colour {
		return {red: (hex >> 16) & brightest, green: (hex >> 8) & brightest, blue: hex & brightest};
	}

	/** A colour written the web way again (0xRRGGBB), for the fog. */
	public static function hexOf(colour:Colour):Int {
		return (Math.round(colour.red) << 16) | (Math.round(colour.green) << 8) | Math.round(colour.blue);
	}

	public static function family(inHex:FamilyInHex):Family {
		return {deep: fromHex(inHex.deep), shades: inHex.shades.map(fromHex)};
	}

	/** A blend of two colours: all `from` at 0, all `to` at 1. */
	public static function blend(from:Colour, to:Colour, amount:Float):Colour {
		return {
			red: from.red + (to.red - from.red) * amount,
			green: from.green + (to.green - from.green) * amount,
			blue: from.blue + (to.blue - from.blue) * amount
		};
	}

	/**
	 * The family's shade at a place on the pitch wheel (in turns, see
	 * PitchWheel). The shades are spaced evenly round it and blend into
	 * each other, the last blending back into the first.
	 */
	public static function inFamily(family:Family, place:Float):Colour {
		final shades = family.shades;
		final along = (place % 1) * shades.length;
		final before = Math.floor(along);
		return blend(shades[before % shades.length], shades[(before + 1) % shades.length], along - before);
	}
}
