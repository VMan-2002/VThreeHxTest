package vman2002.vthreehx.renderers.webgl;

import vman2002.vthreehx.Utils.arrayNeedsUint32;
import vman2002.vthreehx.core.BufferAttribute.Uint16BufferAttribute;
import vman2002.vthreehx.core.BufferAttribute.Uint32BufferAttribute;
import vman2002.vthreehx.core.BufferGeometry;

class WebGLGeometries {

    public function new(gl, attributes, info, bindingStates) {
        this.gl = gl;
        this.attributes = attributes;
        this.info = info;
        this.bindingStates = bindingStates;
    }

    var gl:GL;
    var attributes:WebGLAttributes;
    var info:WebGLInfo;
    var bindingStates:WebGLBindingStates;

	var geometries = new Map<String, BufferGeometry>();
	var wireframeAttributes = new WeakMap();

	function onGeometryDispose( event ) {

		var geometry = event.target;

		if ( geometry.index != null ) {

			attributes.remove( geometry.index );

		}

		for ( name in geometry.attributes ) {

			attributes.remove( geometry.attributes[ name ] );

		}

		geometry.removeEventListener( 'dispose', onGeometryDispose );

		geometries.delete(geometry.id);

		var attribute = wireframeAttributes.get( geometry );

		if ( attribute ) {

			attributes.remove( attribute );
			wireframeAttributes.delete( geometry );

		}

		bindingStates.releaseStatesOfGeometry( geometry );

		if ( geometry.isInstancedBufferGeometry == true ) {

			geometry.delete(_maxInstanceCount);

		}

		//

		info.memory.geometries --;

	}

	function get( object, geometry ) {

		if ( geometries[ geometry.id ] == true ) return geometry;

		geometry.addEventListener( 'dispose', onGeometryDispose );

		geometries[ geometry.id ] = true;

		info.memory.geometries ++;

		return geometry;

	}

	function update( geometry ) {

		var geometryAttributes = geometry.attributes;

		// Updating index buffer in VAO now. See WebGLBindingStates.

		for ( name in geometryAttributes ) {

			attributes.update( geometryAttributes[ name ], gl.ARRAY_BUFFER );

		}

	}

	function updateWireframeAttribute( geometry ) {

		var indices = [];

		var geometryIndex = geometry.index;
		var geometryPosition = geometry.attributes.position;
		var version = 0;

		if ( geometryIndex != null ) {

			var array = geometryIndex.array;
			version = geometryIndex.version;

			for ( i in CustomIterator(0, array.length, 3) ) {

				var a = array[ i + 0 ];
				var b = array[ i + 1 ];
				var c = array[ i + 2 ];

				indices.push( a, b, b, c, c, a );

			}

		} else if ( geometryPosition != undefined ) {

			var array = geometryPosition.array;
			version = geometryPosition.version;

			for ( i in CustomIterator(0, Std.int( array.length / 3 ) - 1, 3) ) {

				var a = i + 0;
				var b = i + 1;
				var c = i + 2;

				indices.push( a, b, b, c, c, a );

			}

		} else {

			return;

		}

		var attribute = ( arrayNeedsUint32( indices ) ? new Uint32BufferAttribute(indices, 1) : new Uint16BufferAttribute(indices, 1) );
		attribute.version = version;

		// Updating index buffer in VAO now. See WebGLBindingStates

		//

		var previousAttribute = wireframeAttributes.get( geometry );

		if ( previousAttribute ) attributes.remove( previousAttribute );

		//

		wireframeAttributes.set( geometry, attribute );

	}

	function getWireframeAttribute( geometry ) {

		var currentAttribute = wireframeAttributes.get( geometry );

		if ( currentAttribute ) {

			var geometryIndex = geometry.index;

			if ( geometryIndex != null ) {

				// if the attribute is obsolete, create a new one

				if ( currentAttribute.version < geometryIndex.version ) {

					updateWireframeAttribute( geometry );

				}

			}

		} else {

			updateWireframeAttribute( geometry );

		}

		return wireframeAttributes.get( geometry );

	}

}