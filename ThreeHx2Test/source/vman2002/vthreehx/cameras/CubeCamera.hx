package vman2002.vthreehx.cameras;

import vman2002.vthreehx.Constants.WebGLCoordinateSystem;
import vman2002.vthreehx.Constants.WebGPUCoordinateSystem;
import vman2002.vthreehx.cameras.PerspectiveCamera;
import vman2002.vthreehx.core.Object3D;
import vman2002.vthreehx.renderers.WebGLRenderTarget;

/**
 * A special type of camera that is positioned in 3D space to render its surroundings into a
 * cube render target. The render target can then be used as an environment map for rendering
 * realtime reflections in your scene.
 *
 * ```js
 * // Create cube render target
 * const cubeRenderTarget = new THREE.WebGLCubeRenderTarget( 256, { generateMipmaps: true, minFilter: THREE.LinearMipmapLinearFilter } );
 *
 * // Create cube camera
 * const cubeCamera = new THREE.CubeCamera( 1, 100000, cubeRenderTarget );
 * scene.add( cubeCamera );
 *
 * // Create car
 * const chromeMaterial = new THREE.MeshLambertMaterial( { color: 0xffffff, envMap: cubeRenderTarget.texture } );
 * const car = new THREE.Mesh( carGeometry, chromeMaterial );
 * scene.add( car );
 *
 * // Update the render target cube
 * car.visible = false;
 * cubeCamera.position.copy( car.position );
 * cubeCamera.update( renderer, scene );
 *
 * // Render the scene
 * car.visible = true;
 * renderer.render( scene, camera );
 * ```
 *
 * @augments Object3D
 */
class CubeCamera extends Object3D {

		/**
		 * A reference to the cube render target.
		 *
		 * @type {WebGLCubeRenderTarget}
		 */
    public var renderTarget:WebGLRenderTarget;

		/**
		 * The current active coordinate system.
		 *
		 * @type {?(WebGLCoordinateSystem|WebGPUCoordinateSystem)}
		 * @default null
		 */
    public var coordinateSystem:Int;

		/**
		 * The current active mipmap level
		 *
		 * @type {number}
		 * @default 0
		 */
    public var activeMipmapLevel:Int;

    public function getType() {
        return Common.typeName(this);
    }

	/**
	 * Constructs a new cube camera.
	 *
	 * @param {number} near - The camera's near plane.
	 * @param {number} far - The camera's far plane.
	 * @param {WebGLCubeRenderTarget} renderTarget - The cube render target.
	 */
	public function new( near, far, renderTarget ) {

		super();

		this.renderTarget = renderTarget;
		this.coordinateSystem = null;
		this.activeMipmapLevel = 0;

		var cameraPX = new PerspectiveCamera( fov, aspect, near, far );
		cameraPX.layers = this.layers;
		this.add( cameraPX );

		var cameraNX = new PerspectiveCamera( fov, aspect, near, far );
		cameraNX.layers = this.layers;
		this.add( cameraNX );

		var cameraPY = new PerspectiveCamera( fov, aspect, near, far );
		cameraPY.layers = this.layers;
		this.add( cameraPY );

		var cameraNY = new PerspectiveCamera( fov, aspect, near, far );
		cameraNY.layers = this.layers;
		this.add( cameraNY );

		var cameraPZ = new PerspectiveCamera( fov, aspect, near, far );
		cameraPZ.layers = this.layers;
		this.add( cameraPZ );

		var cameraNZ = new PerspectiveCamera( fov, aspect, near, far );
		cameraNZ.layers = this.layers;
		this.add( cameraNZ );

	}

	/**
	 * Must be called when the coordinate system of the cube camera is changed.
	 */
	public function updateCoordinateSystem() {

		var coordinateSystem = this.coordinateSystem;

		var cameras = this.children.concat();

        var cameraPX = cameras[0];
        var cameraNX = cameras[1];
        var cameraPY = cameras[2];
        var cameraNY = cameras[3];
        var cameraPZ = cameras[4];
        var cameraNZ = cameras[5];

		for ( camera in cameras ) this.remove( camera );

		if ( coordinateSystem == WebGLCoordinateSystem ) {

			cameraPX.up.set( 0, 1, 0 );
			cameraPX.lookAt( 1, 0, 0 );

			cameraNX.up.set( 0, 1, 0 );
			cameraNX.lookAt( - 1, 0, 0 );

			cameraPY.up.set( 0, 0, - 1 );
			cameraPY.lookAt( 0, 1, 0 );

			cameraNY.up.set( 0, 0, 1 );
			cameraNY.lookAt( 0, - 1, 0 );

			cameraPZ.up.set( 0, 1, 0 );
			cameraPZ.lookAt( 0, 0, 1 );

			cameraNZ.up.set( 0, 1, 0 );
			cameraNZ.lookAt( 0, 0, - 1 );

		} else if ( coordinateSystem == WebGPUCoordinateSystem ) {

			cameraPX.up.set( 0, - 1, 0 );
			cameraPX.lookAt( - 1, 0, 0 );

			cameraNX.up.set( 0, - 1, 0 );
			cameraNX.lookAt( 1, 0, 0 );

			cameraPY.up.set( 0, 0, 1 );
			cameraPY.lookAt( 0, 1, 0 );

			cameraNY.up.set( 0, 0, - 1 );
			cameraNY.lookAt( 0, - 1, 0 );

			cameraPZ.up.set( 0, - 1, 0 );
			cameraPZ.lookAt( 0, 0, 1 );

			cameraNZ.up.set( 0, - 1, 0 );
			cameraNZ.lookAt( 0, 0, - 1 );

		} else {

			throw new Error( 'THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: ' + coordinateSystem );

		}

		for ( camera in cameras ) {

			this.add( camera );

			camera.updateMatrixWorld();

		}

	}

	/**
	 * Calling this method will render the given scene with the given renderer
	 * into the cube render target of the camera.
	 *
	 * @param {(Renderer|WebGLRenderer)} renderer - The renderer.
	 * @param {Scene} scene - The scene to render.
	 */
	public function update( renderer, scene ) {

		if ( this.parent == null ) this.updateMatrixWorld();

        var renderTarget = this.renderTarget;
        var activeMipmapLevel = this.activeMipmapLevel;

		if ( this.coordinateSystem != renderer.coordinateSystem ) {

			this.coordinateSystem = renderer.coordinateSystem;

			this.updateCoordinateSystem();

		}

        var cameraPX = this.children[0];
        var cameraNX = this.children[1];
        var cameraPY = this.children[2];
        var cameraNY = this.children[3];
        var cameraPZ = this.children[4];
        var cameraNZ = this.children[5];

		var currentRenderTarget = renderer.getRenderTarget();
		var currentActiveCubeFace = renderer.getActiveCubeFace();
		var currentActiveMipmapLevel = renderer.getActiveMipmapLevel();

		var currentXrEnabled = renderer.xr.enabled;

		renderer.xr.enabled = false;

		var generateMipmaps = renderTarget.texture.generateMipmaps;

		renderTarget.texture.generateMipmaps = false;

		renderer.setRenderTarget( renderTarget, 0, activeMipmapLevel );
		renderer.render( scene, cameraPX );

		renderer.setRenderTarget( renderTarget, 1, activeMipmapLevel );
		renderer.render( scene, cameraNX );

		renderer.setRenderTarget( renderTarget, 2, activeMipmapLevel );
		renderer.render( scene, cameraPY );

		renderer.setRenderTarget( renderTarget, 3, activeMipmapLevel );
		renderer.render( scene, cameraNY );

		renderer.setRenderTarget( renderTarget, 4, activeMipmapLevel );
		renderer.render( scene, cameraPZ );

		// mipmaps are generated during the last call of render()
		// at this point, all sides of the cube render target are defined

		renderTarget.texture.generateMipmaps = generateMipmaps;

		renderer.setRenderTarget( renderTarget, 5, activeMipmapLevel );
		renderer.render( scene, cameraNZ );

		renderer.setRenderTarget( currentRenderTarget, currentActiveCubeFace, currentActiveMipmapLevel );

		renderer.xr.enabled = currentXrEnabled;

		renderTarget.texture.needsPMREMUpdate = true;

	}

    var fov = - 90; // negative fov is not an error
    var aspect = 1;
}