package scene;

import js.Browser;
import js.html.Element;
import pattern.Geometry;
import picture.Palette;
import three.Three;

/** A place, or a direction, in the 3D world. */
typedef Spot = {x:Float, y:Float, z:Float};

/**
 * The 3D world, drawn the RAI 2 way: flat. There is no light and no
 * perspective. The camera looks down at the field of blocks from a little
 * in front, so you see the tops of the blocks and their sides hanging
 * below them, every face in a flat tone (see MeshWriter). Things further
 * away are not smaller, so the field reads as a clean drawing.
 *
 * The field lies flat (x across, y up the screen), blocks stand up out of
 * it (z), and the camera looks at its middle.
 */
class Stage {
	/** The camera stands this far from the middle of the field: far enough that every block is in front of it. */
	static inline final cameraDistance = 100.0;

	final scene = new Scene();
	final camera = new OrthographicCamera(-1, 1, 1, -1, 0.1, 2 * cameraDistance);
	final renderer = new WebGLRenderer({antialias: true});
	var aspect = 1.0;

	public function new(holder:Element) {
		scene.background = new Color(Settings.nightColour);
		holder.appendChild(renderer.domElement);
		placeCamera();
		fitToWindow();
	}

	/** Puts something (a field of blocks) into the world. */
	public function add(thing:Object3D) {
		scene.add(thing);
	}

	/** In front of the field and above it, tilted so the blocks' tops and front sides both show. */
	function placeCamera() {
		final tilt = Geometry.radians(Settings.viewTiltDegrees);
		camera.position.set(0, -Math.sin(tilt) * cameraDistance, Math.cos(tilt) * cameraDistance);
		camera.lookAt(0, 0, 0);
	}

	/** Matches the drawing to the window, pixel for pixel even on sharp screens (up to a limit). */
	public function fitToWindow() {
		final window = Browser.window;
		renderer.setPixelRatio(Math.min(window.devicePixelRatio, Settings.sharpestPixelRatio));
		renderer.setSize(window.innerWidth, window.innerHeight);
		aspect = window.innerWidth / window.innerHeight;
	}

	/** The ground between the blocks, in any colour (between scenes, a blend of the old and the new). */
	public function tint(colour:Colour) {
		scene.background = new Color(Palette.hexOf(colour));
	}

	/** Draws one frame, showing `width` edges of the field across the screen; `zoom` above 1 moves in (a kick). */
	public function show(width:Float, zoom:Float) {
		final halfWidth = width / 2 / zoom, halfHeight = width / 2 / zoom / aspect;
		camera.left = -halfWidth;
		camera.right = halfWidth;
		camera.top = halfHeight;
		camera.bottom = -halfHeight;
		camera.updateProjectionMatrix();
		renderer.render(scene, camera);
	}
}
