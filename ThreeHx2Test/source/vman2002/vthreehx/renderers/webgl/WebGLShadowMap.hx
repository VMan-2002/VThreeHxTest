package vman2002.vthreehx.renderers.webgl;

//TODO: what
// import * as vsm from '../shaders/ShaderLib/vsm.glsl.js';
import vman2002.vthreehx.Constants.BackSide;
import vman2002.vthreehx.Constants.DoubleSide;
import vman2002.vthreehx.Constants.FrontSide;
import vman2002.vthreehx.Constants.NearestFilter;
import vman2002.vthreehx.Constants.NoBlending;
import vman2002.vthreehx.Constants.PCFShadowMap;
import vman2002.vthreehx.Constants.RGBADepthPacking;
import vman2002.vthreehx.Constants.VSMShadowMap;
import vman2002.vthreehx.core.BufferAttribute;
import vman2002.vthreehx.core.BufferGeometry;
import vman2002.vthreehx.materials.MeshDepthMaterial;
import vman2002.vthreehx.materials.MeshDistanceMaterial;
import vman2002.vthreehx.materials.ShaderMaterial;
import vman2002.vthreehx.math.Frustum;
import vman2002.vthreehx.math.Vector2;
import vman2002.vthreehx.math.Vector4;
import vman2002.vthreehx.objects.Mesh;
import vman2002.vthreehx.renderers.WebGLRenderTarget;

class WebGLShadowMap {

    public function new(renderer, objects, capabilities) {
        this.renderer = renderer;
        this.objects = objects;
        this.capabilities = capabilities;

	    shadowMaterialHorizontal.defines.HORIZONTAL_PASS = 1;
        fullScreenTri.setAttribute(
            'position',
            new BufferAttribute(
                new Float32Array( [ - 1, - 1, 0.5, 3, - 1, 0.5, - 1, 3, 0.5 ] ),
                3
            )
        );
    }
    var renderer:WebGLRenderer;
    var objects:WebGLObjects;
    var capabilities:WebGLCapabilities;

	var _frustum = new Frustum();

	var _shadowMapSize = new Vector2();
	var	_viewportSize = new Vector2();

    var	_viewport = new Vector4();

	var	_depthMaterial = new MeshDepthMaterial( { depthPacking: RGBADepthPacking } );
	var	_distanceMaterial = new MeshDistanceMaterial();

	var	_materialCache = {};

	var	_maxTextureSize = capabilities.maxTextureSize;

	var shadowSide = [ FrontSide => BackSide, BackSide => FrontSide, DoubleSide => DoubleSide ];

	var shadowMaterialVertical = new ShaderMaterial( {
		defines: {
			VSM_SAMPLES: 8
		},
		uniforms: {
			shadow_pass: { value: null },
			resolution: { value: new Vector2() },
			radius: { value: 4.0 }
		},

		vertexShader: vsm.vertex,
		fragmentShader: vsm.fragment

	} );

	var shadowMaterialHorizontal = shadowMaterialVertical.clone();

	var fullScreenTri = new BufferGeometry();

	var fullScreenMesh = new Mesh( fullScreenTri, shadowMaterialVertical );

	var scope = this;

	var enabled = false;

	var autoUpdate = true;
	var needsUpdate = false;

	var type = PCFShadowMap;
	var _previousType = this.type;

	public function render ( lights, scene, camera ) {

		if ( scope.enabled == false ) return;
		if ( scope.autoUpdate == false && scope.needsUpdate == false ) return;

		if ( lights.length == 0 ) return;

		var currentRenderTarget = renderer.getRenderTarget();
		var activeCubeFace = renderer.getActiveCubeFace();
		var activeMipmapLevel = renderer.getActiveMipmapLevel();

		var _state = renderer.state;

		// Set GL state for depth map.
		_state.setBlending( NoBlending );
		_state.buffers.color.setClear( 1, 1, 1, 1 );
		_state.buffers.depth.setTest( true );
		_state.setScissorTest( false );

		// check for shadow map type changes

		var toVSM = ( _previousType != VSMShadowMap && this.type == VSMShadowMap );
		var fromVSM = ( _previousType == VSMShadowMap && this.type != VSMShadowMap );

		// render depth map

		for ( i in 0...lights.length ) {

			var light = lights[ i ];
			var shadow = light.shadow;

			if ( shadow == undefined ) {

				Common.warn( 'THREE.WebGLShadowMap:', light, 'has no shadow.' );
				continue;

			}

			if ( shadow.autoUpdate == false && shadow.needsUpdate == false ) continue;

			_shadowMapSize.copy( shadow.mapSize );

			var shadowFrameExtents = shadow.getFrameExtents();

			_shadowMapSize.multiply( shadowFrameExtents );

			_viewportSize.copy( shadow.mapSize );

			if ( _shadowMapSize.x > _maxTextureSize || _shadowMapSize.y > _maxTextureSize ) {

				if ( _shadowMapSize.x > _maxTextureSize ) {

					_viewportSize.x = Math.floor( _maxTextureSize / shadowFrameExtents.x );
					_shadowMapSize.x = _viewportSize.x * shadowFrameExtents.x;
					shadow.mapSize.x = _viewportSize.x;

				}

				if ( _shadowMapSize.y > _maxTextureSize ) {

					_viewportSize.y = Math.floor( _maxTextureSize / shadowFrameExtents.y );
					_shadowMapSize.y = _viewportSize.y * shadowFrameExtents.y;
					shadow.mapSize.y = _viewportSize.y;

				}

			}

			if ( shadow.map == null || toVSM == true || fromVSM == true ) {

				var pars = ( this.type != VSMShadowMap ) ? { minFilter: NearestFilter, magFilter: NearestFilter } : {};

				if ( shadow.map != null ) {

					shadow.map.dispose();

				}

				shadow.map = new WebGLRenderTarget( _shadowMapSize.x, _shadowMapSize.y, pars );
				shadow.map.texture.name = light.name + '.shadowMap';

				shadow.camera.updateProjectionMatrix();

			}

			renderer.setRenderTarget( shadow.map );
			renderer.clear();

			var viewportCount = shadow.getViewportCount();

			for ( vp in 0...viewportCount ) {

				var viewport = shadow.getViewport( vp );

				_viewport.set(
					_viewportSize.x * viewport.x,
					_viewportSize.y * viewport.y,
					_viewportSize.x * viewport.z,
					_viewportSize.y * viewport.w
				);

				_state.viewport( _viewport );

				shadow.updateMatrices( light, vp );

				_frustum = shadow.getFrustum();

				renderObject( scene, camera, shadow.camera, light, this.type );

			}

			// do blur pass for VSM

			if ( shadow.isPointLightShadow != true && this.type == VSMShadowMap ) {

				VSMPass( shadow, camera );

			}

			shadow.needsUpdate = false;

		}

		_previousType = this.type;

		scope.needsUpdate = false;

		renderer.setRenderTarget( currentRenderTarget, activeCubeFace, activeMipmapLevel );

	};

	function VSMPass( shadow, camera ) {

		var geometry = objects.update( fullScreenMesh );

		if ( shadowMaterialVertical.defines.VSM_SAMPLES != shadow.blurSamples ) {

			shadowMaterialVertical.defines.VSM_SAMPLES = shadow.blurSamples;
			shadowMaterialHorizontal.defines.VSM_SAMPLES = shadow.blurSamples;

			shadowMaterialVertical.needsUpdate = true;
			shadowMaterialHorizontal.needsUpdate = true;

		}

		if ( shadow.mapPass == null ) {

			shadow.mapPass = new WebGLRenderTarget( _shadowMapSize.x, _shadowMapSize.y );

		}

		// vertical pass

		shadowMaterialVertical.uniforms.shadow_pass.value = shadow.map.texture;
		shadowMaterialVertical.uniforms.resolution.value = shadow.mapSize;
		shadowMaterialVertical.uniforms.radius.value = shadow.radius;
		renderer.setRenderTarget( shadow.mapPass );
		renderer.clear();
		renderer.renderBufferDirect( camera, null, geometry, shadowMaterialVertical, fullScreenMesh, null );

		// horizontal pass

		shadowMaterialHorizontal.uniforms.shadow_pass.value = shadow.mapPass.texture;
		shadowMaterialHorizontal.uniforms.resolution.value = shadow.mapSize;
		shadowMaterialHorizontal.uniforms.radius.value = shadow.radius;
		renderer.setRenderTarget( shadow.map );
		renderer.clear();
		renderer.renderBufferDirect( camera, null, geometry, shadowMaterialHorizontal, fullScreenMesh, null );

	}

	function getDepthMaterial( object, material, light, type ) {

		var result = null;

		var customMaterial = ( light.isPointLight == true ) ? object.customDistanceMaterial : object.customDepthMaterial;

		if ( customMaterial != undefined ) {

			result = customMaterial;

		} else {

			result = ( light.isPointLight == true ) ? _distanceMaterial : _depthMaterial;

			if ( ( renderer.localClippingEnabled && material.clipShadows == true && Array.isArray( material.clippingPlanes ) && material.clippingPlanes.length != 0 ) ||
				( material.displacementMap && material.displacementScale != 0 ) ||
				( material.alphaMap && material.alphaTest > 0 ) ||
				( material.map && material.alphaTest > 0 ) ||
				( material.alphaToCoverage == true ) ) {

				// in this case we need a unique material instance reflecting the
				// appropriate state

				var keyA = result.uuid, keyB = material.uuid;

				var materialsForVariant = _materialCache[ keyA ];

				if ( materialsForVariant == undefined ) {

					materialsForVariant = {};
					_materialCache[ keyA ] = materialsForVariant;

				}

				var cachedMaterial = materialsForVariant[ keyB ];

				if ( cachedMaterial == undefined ) {

					cachedMaterial = result.clone();
					materialsForVariant[ keyB ] = cachedMaterial;
					material.addEventListener( 'dispose', onMaterialDispose );

				}

				result = cachedMaterial;

			}

		}

		result.visible = material.visible;
		result.wireframe = material.wireframe;

		if ( type == VSMShadowMap ) {

			result.side = ( material.shadowSide != null ) ? material.shadowSide : material.side;

		} else {

			result.side = ( material.shadowSide != null ) ? material.shadowSide : shadowSide[ material.side ];

		}

		result.alphaMap = material.alphaMap;
		result.alphaTest = ( material.alphaToCoverage == true ) ? 0.5 : material.alphaTest; // approximate alphaToCoverage by using a fixed alphaTest value
		result.map = material.map;

		result.clipShadows = material.clipShadows;
		result.clippingPlanes = material.clippingPlanes;
		result.clipIntersection = material.clipIntersection;

		result.displacementMap = material.displacementMap;
		result.displacementScale = material.displacementScale;
		result.displacementBias = material.displacementBias;

		result.wireframeLinewidth = material.wireframeLinewidth;
		result.linewidth = material.linewidth;

		if ( light.isPointLight == true && result.isMeshDistanceMaterial == true ) {

			var materialProperties = renderer.properties.get( result );
			materialProperties.light = light;

		}

		return result;

	}

	function renderObject( object, camera, shadowCamera, light, type ) {

		if ( object.visible == false ) return;

		var visible = object.layers.test( camera.layers );

		if ( visible && ( object.isMesh || object.isLine || object.isPoints ) ) {

			if ( ( object.castShadow || ( object.receiveShadow && type == VSMShadowMap ) ) && ( ! object.frustumCulled || _frustum.intersectsObject( object ) ) ) {

				object.modelViewMatrix.multiplyMatrices( shadowCamera.matrixWorldInverse, object.matrixWorld );

				var geometry = objects.update( object );
				var material = object.material;

				if ( Array.isArray( material ) ) {

					var groups = geometry.groups;

					for ( k in 0...groups.length ) {

						var group = groups[ k ];
						var groupMaterial = material[ group.materialIndex ];

						if ( groupMaterial && groupMaterial.visible ) {

							var depthMaterial = getDepthMaterial( object, groupMaterial, light, type );

							object.onBeforeShadow( renderer, object, camera, shadowCamera, geometry, depthMaterial, group );

							renderer.renderBufferDirect( shadowCamera, null, geometry, depthMaterial, object, group );

							object.onAfterShadow( renderer, object, camera, shadowCamera, geometry, depthMaterial, group );

						}

					}

				} else if ( material.visible ) {

					var depthMaterial = getDepthMaterial( object, material, light, type );

					object.onBeforeShadow( renderer, object, camera, shadowCamera, geometry, depthMaterial, null );

					renderer.renderBufferDirect( shadowCamera, null, geometry, depthMaterial, object, null );

					object.onAfterShadow( renderer, object, camera, shadowCamera, geometry, depthMaterial, null );

				}

			}

		}

		var children = object.children;

		for ( i in 0...children.length ) {

			renderObject( children[ i ], camera, shadowCamera, light, type );

		}

	}

	function onMaterialDispose( event ) {

		var material = event.target;

		material.removeEventListener( 'dispose', onMaterialDispose );

		// make sure to remove the unique distance/depth materials used for shadow map rendering

		for ( id in _materialCache ) {

			var cache = _materialCache[ id ];

			var uuid = event.target.uuid;

			if ( uuid in cache ) {

				var shadowMaterial = cache[ uuid ];
				shadowMaterial.dispose();
				Reflect.deleteField(cache, uuid);

			}

		}

	}

}