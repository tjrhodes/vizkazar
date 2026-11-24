/** A straight line through some points: `start` where it crosses 0 across, `slope` how much it rises per 1 across. */
typedef Line = {start:Float, slope:Float};

/** Fitting lines through points the usual way ("least squares"): the line the points stray from least, all told. */
class Fit {
	/** The straight line through the points (`across[i]`, `up[i]`); with every point at one place across, a flat line through their middle. */
	public static function straightLine(across:Array<Float>, up:Array<Float>):Line {
		final middleAcross = average(across), middleUp = average(up);
		var spread = 0.0, together = 0.0;
		for (point in 0...across.length) {
			spread += (across[point] - middleAcross) * (across[point] - middleAcross);
			together += (across[point] - middleAcross) * (up[point] - middleUp);
		}
		final slope = spread > 0 ? together / spread : 0;
		return {start: middleUp - slope * middleAcross, slope: slope};
	}

	static function average(values:Array<Float>):Float {
		return Lambda.fold(values, (value, total) -> total + value, 0.0) / values.length;
	}
}
