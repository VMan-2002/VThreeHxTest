package vman2002.vthreehx.renderers.webgl;

class WebGLObjects {

    public function new(gl, geometries, attributes, info) {
        this.gl = gl;
        this.geometries = geometries;
        this.attributes = attributes;
        this.info = info;
    }

    var gl:GL;
    var geometries:WebGLGeometries;
    var attributes:WebGLAttributes;
    var info:WebGLInfo;

	var updateMap = new WeakMap();

	function update( object ) {

		var frame = info.render.frame;

		var geometry = object.geometry;
		var buffergeometry = geometries.get( object, geometry );

		// Update once per frame

		if ( updateMap.get( buffergeometry ) != frame ) {

			geometries.update( buffergeometry );

			updateMap.set( buffergeometry, frame );

		}

		if ( object.isInstancedMesh ) {

			if ( object.hasEventListener( 'dispose', onInstancedMeshDispose ) == false ) {

				object.addEventListener( 'dispose', onInstancedMeshDispose );

			}

			if ( updateMap.get( object ) != frame ) {

				attributes.update( object.instanceMatrix, gl.ARRAY_BUFFER );

				if ( object.instanceColor != null ) {

					attributes.update( object.instanceColor, gl.ARRAY_BUFFER );

				}

				updateMap.set( object, frame );

			}

		}

		if ( object.isSkinnedMesh ) {

			var skeleton = object.skeleton;

			if ( updateMap.get( skeleton ) != frame ) {

				skeleton.update();

				updateMap.set( skeleton, frame );

			}

		}

		return buffergeometry;

	}

	function dispose() {

		updateMap = new WeakMap();

	}

	function onInstancedMeshDispose( event ) {

		var instancedMesh = event.target;

		instancedMesh.removeEventListener( 'dispose', onInstancedMeshDispose );

		attributes.remove( instancedMesh.instanceMatrix );

		if ( instancedMesh.instanceColor != null ) attributes.remove( instancedMesh.instanceColor );

	}

}