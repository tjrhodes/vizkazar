package three;

import js.html.CanvasElement;

/*
 * Haxe descriptions ("externs") of the parts of three.js the piece uses,
 * and only those. three.js itself is loaded by the page as the global
 * `THREE` (version r128, its last build with a global, as in shunt).
 */

@:native("THREE") extern class Three {
	/** Draw both faces of every triangle, so a piece that hinges over still shows its back. */
	static var DoubleSide(default, null):Int;

	/** Shadows with soft, blurred edges. */
	static var PCFSoftShadowMap(default, null):Int;
}

@:native("THREE.Vector3") extern class Vector3 {
	var x:Float;
	var y:Float;
	var z:Float;
	function set(x:Float, y:Float, z:Float):Vector3;
}

@:native("THREE.Euler") extern class Euler {
	var x:Float;
	var y:Float;
	var z:Float;
}

@:native("THREE.Color") extern class Color {
	function new(colour:Int);
	function setHex(colour:Int):Color;
}

/** A grid of sixteen numbers that moves, turns, stretches and mirrors things in one go. */
@:native("THREE.Matrix4") extern class Matrix4 {
	function set(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float, n31:Float, n32:Float,
		n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float):Matrix4;
}

@:native("THREE.Object3D") extern class Object3D {
	var position(default, null):Vector3;
	var rotation(default, null):Euler;

	/** Whether three.js may skip drawing it when it thinks it is off screen. */
	var frustumCulled:Bool;

	var visible:Bool;
	var castShadow:Bool;
	var receiveShadow:Bool;

	/** Where it is, set directly; with `matrixAutoUpdate` off, three.js leaves it as set. */
	var matrix(default, null):Matrix4;

	var matrixAutoUpdate:Bool;
	var matrixWorldNeedsUpdate:Bool;

	function add(child:Object3D):Void;
	function lookAt(x:Float, y:Float, z:Float):Void;
}

@:native("THREE.Scene") extern class Scene extends Object3D {
	function new();
	var background:Color;
	var fog:Fog;
}

/** Fades things into a colour with distance: nothing before `near`, everything by `far`. */
@:native("THREE.Fog") extern class Fog {
	function new(colour:Int, near:Float, far:Float);
	var color(default, null):Color;
	var near:Float;
	var far:Float;
}

@:native("THREE.Group") extern class Group extends Object3D {
	function new();
}

/** A camera that sees as an eye does: further things smaller. */
@:native("THREE.PerspectiveCamera") extern class PerspectiveCamera extends Object3D {
	function new(fieldOfView:Float, aspect:Float, near:Float, far:Float);
	var aspect:Float;
	var fov:Float;
	function updateProjectionMatrix():Void;
}

@:native("THREE.WebGLRenderer") extern class WebGLRenderer {
	function new(options:{antialias:Bool});
	var domElement(default, null):CanvasElement;
	function setSize(width:Float, height:Float):Void;
	function setPixelRatio(ratio:Float):Void;
	var shadowMap(default, null):{enabled:Bool, type:Int};
	function render(scene:Scene, camera:PerspectiveCamera):Void;
}

/** A list of numbers handed to the graphics card: three to a corner for places and colours. */
@:native("THREE.BufferAttribute") extern class BufferAttribute {
	function new(numbers:js.lib.ArrayBufferView, itemSize:Int);

	/** Set to true after changing the numbers, so the new ones are sent again. */
	var needsUpdate:Bool;
}

@:native("THREE.BufferGeometry") extern class BufferGeometry {
	function new();
	function setAttribute(name:String, attribute:BufferAttribute):BufferGeometry;
	function setIndex(index:BufferAttribute):BufferGeometry;

	/** Draws only `count` indices from `start` (the shape changes size from frame to frame). */
	function setDrawRange(start:Int, count:Int):Void;

	/** Lets the graphics card forget this shape. */
	function dispose():Void;
}

@:native("THREE.PlaneGeometry") extern class PlaneGeometry extends BufferGeometry {
	function new(width:Float, height:Float);
}

@:native("THREE.Material") extern class Material {}

/** A surface lit like real material; at full roughness and no metal it is matte, like painted plaster. */
@:native("THREE.MeshStandardMaterial") extern class MeshStandardMaterial extends Material {
	function new(options:{
		?color:Int,
		?vertexColors:Bool,
		?flatShading:Bool,
		?roughness:Float,
		?metalness:Float,
		?side:Int
	});
}

@:native("THREE.Mesh") extern class Mesh extends Object3D {
	function new(geometry:BufferGeometry, material:Material);
	var geometry:BufferGeometry;
}

/** Light from the whole sky: one colour from above, another from below. */
@:native("THREE.HemisphereLight") extern class HemisphereLight extends Object3D {
	function new(sky:Int, ground:Int, intensity:Float);
}

/** A camera that sees without perspective: the sun uses one to work out its shadows. */
@:native("THREE.OrthographicCamera") extern class OrthographicCamera extends Object3D {
	var left:Float;
	var right:Float;
	var top:Float;
	var bottom:Float;
	var near:Float;
	var far:Float;
	function updateProjectionMatrix():Void;
}

/** Light like the sun: parallel rays from one direction, which can cast shadows. */
@:native("THREE.DirectionalLight") extern class DirectionalLight extends Object3D {
	function new(colour:Int, intensity:Float);

	/** What it shines at: it must be in the scene for that to count. */
	var target(default, null):Object3D;

	var shadow(default, null):{
		mapSize:{width:Int, height:Int},
		camera:OrthographicCamera,
		bias:Float,
		normalBias:Float
	};
}
