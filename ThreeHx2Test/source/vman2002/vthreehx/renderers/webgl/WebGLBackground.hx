package vman2002.vthreehx.renderers.webgl;

import vman2002.vthreehx.Constants.BackSide;
import vman2002.vthreehx.Constants.CubeUVReflectionMapping;
import vman2002.vthreehx.Constants.FrontSide;
import vman2002.vthreehx.Constants.SRGBTransfer;
import vman2002.vthreehx.geometries.BoxGeometry;
import vman2002.vthreehx.geometries.PlaneGeometry;
import vman2002.vthreehx.materials.ShaderMaterial;
import vman2002.vthreehx.math.Color;
import vman2002.vthreehx.math.ColorManagement;
import vman2002.vthreehx.math.Euler;
import vman2002.vthreehx.math.Matrix4;
import vman2002.vthreehx.objects.Mesh;
import vman2002.vthreehx.renderers.shaders.ShaderLib;
import vman2002.vthreehx.renderers.shaders.UniformsUtils.cloneUniforms;
import vman2002.vthreehx.renderers.shaders.UniformsUtils.getUnlitUniformColorSpace;

class WebGLBackground {

    public function new(renderer, cubemaps, cubeuvmaps, state, objects, alpha, premultipliedAlpha) {
        this.renderer = renderer;
        this.cubemaps = cubemaps;
        this.cubeuvmaps = cubeuvmaps;
        this.state = state;
        this.objects = objects;
        this.alpha = alpha;
        this.premultipliedAlpha = premultipliedAlpha;
    }
    var renderer:WebGLRenderer;
    var cubemaps:WebGLCubeMaps;
    var cubeuvmaps:WebGLCubeUVMaps;
    var state:WebGLState;
    var objects:WebGLObjects;
    var alpha:Float;
    var premultipliedAlpha:Float;

	var clearColor = new Color( 0x000000 );
	var clearAlpha = alpha == true ? 0 : 1;

	var planeMesh:Mesh;
	var boxMesh:Mesh;

	var currentBackground = null;
	var currentBackgroundVersion = 0;
	var currentTonemapping = null;

	public function getBackground( scene ) {

		var background = scene.isScene == true ? scene.background : null;

		if ( background && background.isTexture ) {

			var usePMREM = scene.backgroundBlurriness > 0; // use PMREM if the user wants to blur the background
			background = ( usePMREM ? cubeuvmaps : cubemaps ).get( background );

		}

		return background;

	}

	public function render( scene ) {

		var forceClear = false;
		var background = getBackground( scene );

		if ( background == null ) {

			setClear( clearColor, clearAlpha );

		} else if ( background && background.isColor ) {

			setClear( background, 1 );
			forceClear = true;

		}

		var environmentBlendMode = renderer.xr.getEnvironmentBlendMode();

		if ( environmentBlendMode == 'additive' ) {

			state.buffers.color.setClear( 0, 0, 0, 1, premultipliedAlpha );

		} else if ( environmentBlendMode == 'alpha-blend' ) {

			state.buffers.color.setClear( 0, 0, 0, 0, premultipliedAlpha );

		}

		if ( renderer.autoClear || forceClear ) {

			// buffers might not be writable which is required to ensure a correct clear

			state.buffers.depth.setTest( true );
			state.buffers.depth.setMask( true );
			state.buffers.color.setMask( true );

			renderer.clear( renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil );

		}

	}

	public function addToRenderList( renderList, scene ) {

		var background = getBackground( scene );

		if ( background && ( background.isCubeTexture || background.mapping == CubeUVReflectionMapping ) ) {

			if ( boxMesh == null ) {

				boxMesh = new Mesh(
					new BoxGeometry( 1, 1, 1 ),
					new ShaderMaterial( {
						name: 'BackgroundCubeMaterial',
						uniforms: cloneUniforms( ShaderLib.backgroundCube.uniforms ),
						vertexShader: ShaderLib.backgroundCube.vertexShader,
						fragmentShader: ShaderLib.backgroundCube.fragmentShader,
						side: BackSide,
						depthTest: false,
						depthWrite: false,
						fog: false,
						allowOverride: false
					} )
				);

				boxMesh.geometry.deleteAttribute( 'normal' );
				boxMesh.geometry.deleteAttribute( 'uv' );

				boxMesh.onBeforeRender = function ( renderer, scene, camera ) {

					this.matrixWorld.copyPosition( camera.matrixWorld );

				};

				// add "envMap" material property so the renderer can evaluate it like for built-in materials
				Object.defineProperty( boxMesh.material, 'envMap', {

					get: function () {

						return this.uniforms.envMap.value;

					}

				} );

				objects.update( boxMesh );

			}

			_e1.copy( scene.backgroundRotation );

			// accommodate left-handed frame
			_e1.x *= - 1; _e1.y *= - 1; _e1.z *= - 1;

			if ( background.isCubeTexture && background.isRenderTargetTexture == false ) {

				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= - 1;
				_e1.z *= - 1;

			}

			boxMesh.material.uniforms.envMap.value = background;
			boxMesh.material.uniforms.flipEnvMap.value = ( background.isCubeTexture && background.isRenderTargetTexture == false ) ? - 1 : 1;
			boxMesh.material.uniforms.backgroundBlurriness.value = scene.backgroundBlurriness;
			boxMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			boxMesh.material.uniforms.backgroundRotation.value.setFromMatrix4( _m1.makeRotationFromEuler( _e1 ) );
			boxMesh.material.toneMapped = ColorManagement.getTransfer( background.colorSpace ) != SRGBTransfer;

			if ( currentBackground != background ||
				currentBackgroundVersion != background.version ||
				currentTonemapping != renderer.toneMapping ) {

				boxMesh.material.needsUpdate = true;

				currentBackground = background;
				currentBackgroundVersion = background.version;
				currentTonemapping = renderer.toneMapping;

			}

			boxMesh.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift( boxMesh, boxMesh.geometry, boxMesh.material, 0, 0, null );

		} else if ( background && background.isTexture ) {

			if ( planeMesh == null ) {

				planeMesh = new Mesh(
					new PlaneGeometry( 2, 2 ),
					new ShaderMaterial( {
						name: 'BackgroundMaterial',
						uniforms: cloneUniforms( ShaderLib.background.uniforms ),
						vertexShader: ShaderLib.background.vertexShader,
						fragmentShader: ShaderLib.background.fragmentShader,
						side: FrontSide,
						depthTest: false,
						depthWrite: false,
						fog: false,
						allowOverride: false
					} )
				);

				planeMesh.geometry.deleteAttribute( 'normal' );

				// add "map" material property so the renderer can evaluate it like for built-in materials
				Object.defineProperty( planeMesh.material, 'map', {

					get: function () {

						return this.uniforms.t2D.value;

					}

				} );

				objects.update( planeMesh );

			}

			planeMesh.material.uniforms.t2D.value = background;
			planeMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
			planeMesh.material.toneMapped = ColorManagement.getTransfer( background.colorSpace ) != SRGBTransfer;

			if ( background.matrixAutoUpdate == true ) {

				background.updateMatrix();

			}

			planeMesh.material.uniforms.uvTransform.value.copy( background.matrix );

			if ( currentBackground != background ||
				currentBackgroundVersion != background.version ||
				currentTonemapping != renderer.toneMapping ) {

				planeMesh.material.needsUpdate = true;

				currentBackground = background;
				currentBackgroundVersion = background.version;
				currentTonemapping = renderer.toneMapping;

			}

			planeMesh.layers.enableAll();

			// push to the pre-sorted opaque render list
			renderList.unshift( planeMesh, planeMesh.geometry, planeMesh.material, 0, 0, null );

		}

	}

	public function setClear( color, alpha ) {

		color.getRGB( _rgb, getUnlitUniformColorSpace( renderer ) );

		state.buffers.color.setClear( _rgb.r, _rgb.g, _rgb.b, alpha, premultipliedAlpha );

	}

	public function dispose() {

		if ( boxMesh != null ) {

			boxMesh.geometry.dispose();
			boxMesh.material.dispose();

			boxMesh = null;

		}

		if ( planeMesh != null ) {

			planeMesh.geometry.dispose();
			planeMesh.material.dispose();

			planeMesh = null;

		}

	}


    var _rgb = { r: 0, b: 0, g: 0 };
    var _e1 = /*@__PURE__*/ new Euler();
    var _m1 = /*@__PURE__*/ new Matrix4();
}