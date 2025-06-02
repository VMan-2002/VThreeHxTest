package;

import flixel.FlxState;
import flixel.text.FlxText;
import vman2002.vthreehx.scenes.Scene;
import vman2002.vthreehx.cameras.PerspectiveCamera;
import flixel.FlxG;
import vman2002.vthreehx.geometries.BoxGeometry;
import vman2002.vthreehx.materials.MeshBasicMaterial;
import vman2002.vthreehx.objects.Mesh;

class PlayState extends FlxState {
	var cube:Mesh;
	var text:FlxText;
	
	override public function create() {
		super.create();

		var scene = new Scene();
		var camera = new PerspectiveCamera(75, FlxG.width / FlxG.height, 0.1, 1000);

		/*var renderer = new WebGLRenderer();
		renderer.setSize(FlxG.width, FlxG.height);
		add(renderer.createFlxViewSprite(scene, camera));*/

		var geometry = new BoxGeometry(1, 1, 1);
		var material = new MeshBasicMaterial({color: 0x00ff00});
		cube = new Mesh(geometry, material);
		scene.add(cube);
		camera.position.z = 5;

		add(text = new FlxText(0, 0, 0, "It works"));
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		text.x += 1;
		if (text.x >= 200)
			text.x = 0;
		
		/*cube.rotation.x += 0.01;
		cube.rotation.y += 0.01;*/
	}
}
