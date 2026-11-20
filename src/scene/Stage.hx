package scene;

import js.Browser;
import js.html.Element;
import pattern.Geometry;
import pattern.Tilings.Tiling;
import picture.Palette;
import three.Three;

/** A place, or a direction, in the 3D world. */
typedef Spot = {x:Float, y:Float, z:Float};

/**
 * The 3D world: soft matte light from behind the camera (so every wall is
 * lit alike, block faces towards you bright and faces away dark), and a fog in the tiling's own deep
 * colour, so the far end of the corridor fades into the pattern's colour,
 * never into black. The camera sits in the middle of the corridor looking
 * down it, swaying a little, and a kick makes it lunge.
 */
class Stage {
	final scene = new Scene();
	final camera:PerspectiveCamera;
	final renderer = new WebGLRenderer({antialias: true});
	final fog = new Fog(Settings.nightColour, Settings.fogStartsCorridorWidths, Settings.corridorLength);

	public function new(holder:Element) {
		camera = new PerspectiveCamera(Settings.fieldOfViewDegrees, 1, Settings.nearestSeen, Settings.furthestSeen);
		scene.background = new Color(Settings.nightColour);
		scene.fog = fog;
		holder.appendChild(renderer.domElement);
		light();
		fitToWindow();
	}

	/** Puts something (a wall) into the world. */
	public function add(thing:Object3D) {
		scene.add(thing);
	}

	/** Soft, matte light: the sky behind the camera, night ahead, and one gentle sun (see Settings). */
	function light() {
		final sky = new HemisphereLight(Settings.skyLightColour, Settings.groundLightColour, Settings.skyLightStrength);
		sky.position.set(Settings.skyLightComesFrom.x, Settings.skyLightComesFrom.y, Settings.skyLightComesFrom.z);
		scene.add(sky);
		final sun = new DirectionalLight(Settings.sunColour, Settings.sunStrength);
		sun.position.set(Settings.sunComesFrom.x, Settings.sunComesFrom.y, Settings.sunComesFrom.z);
		scene.add(sun);
	}

	/** Matches the drawing to the window, pixel for pixel even on sharp screens (up to a limit). */
	public function fitToWindow() {
		final window = Browser.window;
		renderer.setPixelRatio(Math.min(window.devicePixelRatio, Settings.sharpestPixelRatio));
		renderer.setSize(window.innerWidth, window.innerHeight);
		camera.aspect = window.innerWidth / window.innerHeight;
		camera.updateProjectionMatrix();
	}

	/** The fog and the far end take the tiling's own deep colour. */
	public function tintFor(tiling:Tiling) {
		tintHex(tiling.colours.deep);
	}

	/** The fog and the far end in any colour (passing through a doorway, a blend of the old deep and the new). */
	public function tint(colour:Colour) {
		tintHex(Palette.hexOf(colour));
	}

	function tintHex(hex:Int) {
		fog.color.setHex(hex);
		scene.background = new Color(hex);
	}

	/** Draws one frame. `lunge` above 1 narrows the view for a moment (a kick); `now` is seconds since the page opened. */
	public function show(lunge:Float, now:Float) {
		camera.fov = Settings.fieldOfViewDegrees / lunge;
		camera.updateProjectionMatrix();
		camera.position.set(0, 0, 0);
		camera.lookAt(Settings.cameraWanders * wave(now, Settings.cameraWandersAcrossPerSecond),
			Settings.cameraWanders * wave(now, Settings.cameraWandersUpPerSecond), -Settings.cameraLooksThisFarAhead);
		camera.rotation.z += Geometry.radians(Settings.cameraRollsDegrees) * wave(now, Settings.cameraRollsPerSecond);
		renderer.render(scene, camera);
	}

	/** A slow swing between -1 and 1, `perSecond` times a second. */
	static function wave(now:Float, perSecond:Float):Float {
		return Math.sin(now * perSecond * Geometry.fullTurn);
	}
}
