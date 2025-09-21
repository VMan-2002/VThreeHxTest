package vman2002.vthreehx.renderers.webgl;

import vman2002.vthreehx.renderers.webgl.WebGLLights;

function WebGLRenderState( extensions ) {

	var lights = new WebGLLights( extensions );

	var lightsArray = [];
	var shadowsArray = [];

	function init( camera ) {

		state.camera = camera;

		lightsArray.length = 0;
		shadowsArray.length = 0;

	}

	function pushLight( light ) {

		lightsArray.push( light );

	}

	function pushShadow( shadowLight ) {

		shadowsArray.push( shadowLight );

	}

	function setupLights() {

		lights.setup( lightsArray );

	}

	function setupLightsView( camera ) {

		lights.setupView( lightsArray, camera );

	}

	var state = {
		lightsArray: lightsArray,
		shadowsArray: shadowsArray,

		camera: null,

		lights: lights,

		transmissionRenderTarget: {}
	};

	return {
		init: init,
		state: state,
		setupLights: setupLights,
		setupLightsView: setupLightsView,

		pushLight: pushLight,
		pushShadow: pushShadow
	};

}

class WebGLRenderStates {

    public function new(extensions) {
        this.extensions = extensions;
    }
    var extensions:WebGLExtensions;

	var renderStates = new WeakMap();

	public function get( scene, renderCallDepth = 0 ) {

		var renderStateArray = renderStates.get( scene );
		var renderState;

		if ( renderStateArray == undefined ) {

			renderState = new WebGLRenderState( extensions );
			renderStates.set( scene, [ renderState ] );

		} else {

			if ( renderCallDepth >= renderStateArray.length ) {

				renderState = new WebGLRenderState( extensions );
				renderStateArray.push( renderState );

			} else {

				renderState = renderStateArray[ renderCallDepth ];

			}

		}

		return renderState;

	}

	public function dispose() {

		renderStates = new WeakMap();

	}

}