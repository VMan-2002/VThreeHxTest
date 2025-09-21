package vman2002.vthreehx.renderers.webgl;

class WebGLUniformsGroups {

    public function new(gl, info, capabilities, state) {
        this.gl = gl;
        this.info = info;
        this.capabilities = capabilities;
        this.state = state;
    }

    var gl:GL;
    var info:WebGLInfo;
    var capabilities:WebGLCapabilities;
    var state:WebGLState;

	var buffers = {};
	var updateList = {};
	var allocatedBindingPoints = [];

	var maxBindingPoints = gl.getParameter( gl.MAX_UNIFORM_BUFFER_BINDINGS ); // binding points are global whereas block indices are per shader program

	function bind( uniformsGroup, program ) {

		var webglProgram = program.program;
		state.uniformBlockBinding( uniformsGroup, webglProgram );

	}

	function update( uniformsGroup, program ) {

		var buffer = buffers[ uniformsGroup.id ];

		if ( buffer == undefined ) {

			prepareUniformsGroup( uniformsGroup );

			buffer = createBuffer( uniformsGroup );
			buffers[ uniformsGroup.id ] = buffer;

			uniformsGroup.addEventListener( 'dispose', onUniformsGroupsDispose );

		}

		// ensure to update the binding points/block indices mapping for this program

		var webglProgram = program.program;
		state.updateUBOMapping( uniformsGroup, webglProgram );

		// update UBO once per frame

		var frame = info.render.frame;

		if ( updateList[ uniformsGroup.id ] != frame ) {

			updateBufferData( uniformsGroup );

			updateList[ uniformsGroup.id ] = frame;

		}

	}

	function createBuffer( uniformsGroup ) {

		// the setup of an UBO is independent of a particular shader program but global

		var bindingPointIndex = allocateBindingPointIndex();
		uniformsGroup.__bindingPointIndex = bindingPointIndex;

		var buffer = gl.createBuffer();
		var size = uniformsGroup.__size;
		var usage = uniformsGroup.usage;

		gl.bindBuffer( gl.UNIFORM_BUFFER, buffer );
		gl.bufferData( gl.UNIFORM_BUFFER, size, usage );
		gl.bindBuffer( gl.UNIFORM_BUFFER, null );
		gl.bindBufferBase( gl.UNIFORM_BUFFER, bindingPointIndex, buffer );

		return buffer;

	}

	function allocateBindingPointIndex() {

		for ( i in 0...maxBindingPoints ) {

			if ( allocatedBindingPoints.indexOf( i ) == - 1 ) {

				allocatedBindingPoints.push( i );
				return i;

			}

		}

		console.error( 'THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached.' );

		return 0;

	}

	function updateBufferData( uniformsGroup ) {

		var buffer = buffers[ uniformsGroup.id ];
		var uniforms = uniformsGroup.uniforms;
		var cache = uniformsGroup.__cache;

		gl.bindBuffer( gl.UNIFORM_BUFFER, buffer );

		for ( i in 0...uniforms.length ) {

			var uniformArray = Array.isArray( uniforms[ i ] ) ? uniforms[ i ] : [ uniforms[ i ] ];

			for ( j in 0...uniformArray.length ) {

				var uniform = uniformArray[ j ];

				if ( hasUniformChanged( uniform, i, j, cache ) == true ) {

					var offset = uniform.__offset;

					var values = Array.isArray( uniform.value ) ? uniform.value : [ uniform.value ];

					var arrayOffset = 0;

					for ( k in 0...values.length ) {

						var value = values[ k ];

						var info = getUniformSize( value );

						// TODO add integer and struct support
						if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

							uniform.__data[ 0 ] = value;
							gl.bufferSubData( gl.UNIFORM_BUFFER, offset + arrayOffset, uniform.__data );

						} else if ( value.isMatrix3 ) {

							// manually converting 3x3 to 3x4

							uniform.__data[ 0 ] = value.elements[ 0 ];
							uniform.__data[ 1 ] = value.elements[ 1 ];
							uniform.__data[ 2 ] = value.elements[ 2 ];
							uniform.__data[ 3 ] = 0;
							uniform.__data[ 4 ] = value.elements[ 3 ];
							uniform.__data[ 5 ] = value.elements[ 4 ];
							uniform.__data[ 6 ] = value.elements[ 5 ];
							uniform.__data[ 7 ] = 0;
							uniform.__data[ 8 ] = value.elements[ 6 ];
							uniform.__data[ 9 ] = value.elements[ 7 ];
							uniform.__data[ 10 ] = value.elements[ 8 ];
							uniform.__data[ 11 ] = 0;

						} else {

							value.toArray( uniform.__data, arrayOffset );

							arrayOffset += info.storage / Float32Array.BYTES_PER_ELEMENT;

						}

					}

					gl.bufferSubData( gl.UNIFORM_BUFFER, offset, uniform.__data );

				}

			}

		}

		gl.bindBuffer( gl.UNIFORM_BUFFER, null );

	}

	function hasUniformChanged( uniform, index, indexArray, cache ) {

		var value = uniform.value;
		var indexString = index + '_' + indexArray;

		if ( cache[ indexString ] == undefined ) {

			// cache entry does not exist so far

			if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

				cache[ indexString ] = value;

			} else {

				cache[ indexString ] = value.clone();

			}

			return true;

		} else {

			var cachedObject = cache[ indexString ];

			// compare current value with cached entry

			if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

				if ( cachedObject != value ) {

					cache[ indexString ] = value;
					return true;

				}

			} else {

				if ( cachedObject.equals( value ) == false ) {

					cachedObject.copy( value );
					return true;

				}

			}

		}

		return false;

	}

	function prepareUniformsGroup( uniformsGroup ) {

		// determine total buffer size according to the STD140 layout
		// Hint: STD140 is the only supported layout in WebGL 2

		var uniforms = uniformsGroup.uniforms;

		var offset = 0; // global buffer offset in bytes
		var chunkSize = 16; // size of a chunk in bytes

		for ( i in 0...uniforms.length ) {

			var uniformArray = Array.isArray( uniforms[ i ] ) ? uniforms[ i ] : [ uniforms[ i ] ];

			for ( j in 0...uniformArray.length ) {

				var uniform = uniformArray[ j ];

				var values = Array.isArray( uniform.value ) ? uniform.value : [ uniform.value ];

				for ( k in 0...values.length ) {

					var value = values[ k ];

					var info = getUniformSize( value );

					var chunkOffset = offset % chunkSize; // offset in the current chunk
					var chunkPadding = chunkOffset % info.boundary; // required padding to match boundary
					var chunkStart = chunkOffset + chunkPadding; // the start position in the current chunk for the data

					offset += chunkPadding;

					// Check for chunk overflow
					if ( chunkStart != 0 && ( chunkSize - chunkStart ) < info.storage ) {

						// Add padding and adjust offset
						offset += ( chunkSize - chunkStart );

					}

					// the following two properties will be used for partial buffer updates
					uniform.__data = new Float32Array( info.storage / Float32Array.BYTES_PER_ELEMENT );
					uniform.__offset = offset;

					// Update the global offset
					offset += info.storage;

				}

			}

		}

		// ensure correct final padding

		var chunkOffset = offset % chunkSize;

		if ( chunkOffset > 0 ) offset += ( chunkSize - chunkOffset );

		//

		uniformsGroup.__size = offset;
		uniformsGroup.__cache = {};

		return this;

	}

	function getUniformSize( value ) {

		var info = {
			boundary: 0, // bytes
			storage: 0 // bytes
		};

		// determine sizes according to STD140

		if ( Std.isOfType(value, Float) || Std.isOfType(value, Bool) ) {

			// float/int/bool

			info.boundary = 4;
			info.storage = 4;

		} else if ( value.isVector2 ) {

			// vec2

			info.boundary = 8;
			info.storage = 8;

		} else if ( value.isVector3 || value.isColor ) {

			// vec3

			info.boundary = 16;
			info.storage = 12; // evil: vec3 must start on a 16-byte boundary but it only consumes 12 bytes

		} else if ( value.isVector4 ) {

			// vec4

			info.boundary = 16;
			info.storage = 16;

		} else if ( value.isMatrix3 ) {

			// mat3 (in STD140 a 3x3 matrix is represented as 3x4)

			info.boundary = 48;
			info.storage = 48;

		} else if ( value.isMatrix4 ) {

			// mat4

			info.boundary = 64;
			info.storage = 64;

		} else if ( value.isTexture ) {

			console.warn( 'THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group.' );

		} else {

			console.warn( 'THREE.WebGLRenderer: Unsupported uniform value type.', value );

		}

		return info;

	}

	function onUniformsGroupsDispose( event ) {

		var uniformsGroup = event.target;

		uniformsGroup.removeEventListener( 'dispose', onUniformsGroupsDispose );

		var index = allocatedBindingPoints.indexOf( uniformsGroup.__bindingPointIndex );
		allocatedBindingPoints.splice( index, 1 );

		gl.deleteBuffer( buffers[ uniformsGroup.id ] );

		Reflect.deleteField(buffers, uniformsGroup.id );
		Reflect.deleteField(updateList, uniformsGroup.id );

	}

	function dispose() {

		for ( id in buffers ) {

			gl.deleteBuffer( buffers[ id ] );

		}

		allocatedBindingPoints = [];
		buffers = {};
		updateList = {};

	}

}