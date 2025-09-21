package vman2002.vthreehx.renderers.webgl;

import vman2002.vthreehx.Constants.IntType;

class WebGLBindingStates {

    public function new(gl, attributes) {
        this.gl = gl;
        this.attributes = attributes;
    }

    public var gl:GL;
    public var attributes:WebGLAttributes;

	var maxVertexAttributes = GL.getParameter( GL.MAX_VERTEX_ATTRIBS );

	var bindingStates = {};

	var defaultState = createBindingState( null );
	var currentState = defaultState;
	var forceUpdate = false;

	function setup( object, material, program, geometry, index ) {

		var updateBuffers = false;

		var state = getBindingState( geometry, program, material );

		if ( currentState != state ) {

			currentState = state;
			bindVertexArrayObject( currentState.object );

		}

		updateBuffers = needsUpdate( object, geometry, program, index );

		if ( updateBuffers ) saveCache( object, geometry, program, index );

		if ( index != null ) {

			attributes.update( index, gl.ELEMENT_ARRAY_BUFFER );

		}

		if ( updateBuffers || forceUpdate ) {

			forceUpdate = false;

			setupVertexAttributes( object, material, program, geometry );

			if ( index != null ) {

				gl.bindBuffer( gl.ELEMENT_ARRAY_BUFFER, attributes.get( index ).buffer );

			}

		}

	}

	function createVertexArrayObject() {

		return gl.createVertexArray();

	}

	function bindVertexArrayObject( vao ) {

		return gl.bindVertexArray( vao );

	}

	function deleteVertexArrayObject( vao ) {

		return gl.deleteVertexArray( vao );

	}

	function getBindingState( geometry, program, material ) {

		var wireframe = ( material.wireframe == true );

		var programMap = bindingStates[ geometry.id ];

		if ( programMap == undefined ) {

			programMap = {};
			bindingStates[ geometry.id ] = programMap;

		}

		var stateMap = programMap[ program.id ];

		if ( stateMap == undefined ) {

			stateMap = {};
			programMap[ program.id ] = stateMap;

		}

		var state = stateMap[ wireframe ];

		if ( state == undefined ) {

			state = createBindingState( createVertexArrayObject() );
			stateMap[ wireframe ] = state;

		}

		return state;

	}

	function createBindingState( vao ) {

		var newAttributes = [];
		var enabledAttributes = [];
		var attributeDivisors = [];

		for ( i in 0...maxVertexAttributes ) {

			newAttributes[ i ] = 0;
			enabledAttributes[ i ] = 0;
			attributeDivisors[ i ] = 0;

		}

		return {

			// for backward compatibility on non-VAO support browser
			geometry: null,
			program: null,
			wireframe: false,

			newAttributes: newAttributes,
			enabledAttributes: enabledAttributes,
			attributeDivisors: attributeDivisors,
			object: vao,
			attributes: {},
			index: null

		};

	}

	function needsUpdate( object, geometry, program, index ) {

		var cachedAttributes = currentState.attributes;
		var geometryAttributes = geometry.attributes;

		var attributesNum = 0;

		var programAttributes = program.getAttributes();

		for ( name in programAttributes ) {

			var programAttribute = programAttributes[ name ];

			if ( programAttribute.location >= 0 ) {

				var cachedAttribute = cachedAttributes[ name ];
				var geometryAttribute = geometryAttributes[ name ];

				if ( geometryAttribute == undefined ) {

					if ( name == 'instanceMatrix' && object.instanceMatrix ) geometryAttribute = object.instanceMatrix;
					if ( name == 'instanceColor' && object.instanceColor ) geometryAttribute = object.instanceColor;

				}

				if ( cachedAttribute == undefined ) return true;

				if ( cachedAttribute.attribute != geometryAttribute ) return true;

				if ( geometryAttribute && cachedAttribute.data != geometryAttribute.data ) return true;

				attributesNum ++;

			}

		}

		if ( currentState.attributesNum != attributesNum ) return true;

		if ( currentState.index != index ) return true;

		return false;

	}

	function saveCache( object, geometry, program, index ) {

		var cache = {};
		var attributes = geometry.attributes;
		var attributesNum = 0;

		var programAttributes = program.getAttributes();

		for ( name in programAttributes ) {

			var programAttribute = programAttributes[ name ];

			if ( programAttribute.location >= 0 ) {

				var attribute = attributes[ name ];

				if ( attribute == undefined ) {

					if ( name == 'instanceMatrix' && object.instanceMatrix ) attribute = object.instanceMatrix;
					if ( name == 'instanceColor' && object.instanceColor ) attribute = object.instanceColor;

				}

				var data = {};
				data.attribute = attribute;

				if ( attribute && attribute.data ) {

					data.data = attribute.data;

				}

				cache[ name ] = data;

				attributesNum ++;

			}

		}

		currentState.attributes = cache;
		currentState.attributesNum = attributesNum;

		currentState.index = index;

	}

	function initAttributes() {

		var newAttributes = currentState.newAttributes;

		for ( i in 0...newAttributes.length ) {

			newAttributes[ i ] = 0;

		}

	}

	function enableAttribute( attribute ) {

		enableAttributeAndDivisor( attribute, 0 );

	}

	function enableAttributeAndDivisor( attribute, meshPerAttribute ) {

		var newAttributes = currentState.newAttributes;
		var enabledAttributes = currentState.enabledAttributes;
		var attributeDivisors = currentState.attributeDivisors;

		newAttributes[ attribute ] = 1;

		if ( enabledAttributes[ attribute ] == 0 ) {

			gl.enableVertexAttribArray( attribute );
			enabledAttributes[ attribute ] = 1;

		}

		if ( attributeDivisors[ attribute ] != meshPerAttribute ) {

			gl.vertexAttribDivisor( attribute, meshPerAttribute );
			attributeDivisors[ attribute ] = meshPerAttribute;

		}

	}

	function disableUnusedAttributes() {

		var newAttributes = currentState.newAttributes;
		var enabledAttributes = currentState.enabledAttributes;

		for ( i in 0...enabledAttributes.length ) {

			if ( enabledAttributes[ i ] != newAttributes[ i ] ) {

				gl.disableVertexAttribArray( i );
				enabledAttributes[ i ] = 0;

			}

		}

	}

	function vertexAttribPointer( index, size, type, normalized, stride, offset, integer ) {

		if ( integer == true ) {

			gl.vertexAttribIPointer( index, size, type, stride, offset );

		} else {

			gl.vertexAttribPointer( index, size, type, normalized, stride, offset );

		}

	}

	function setupVertexAttributes( object, material, program, geometry ) {

		initAttributes();

		var geometryAttributes = geometry.attributes;

		var programAttributes = program.getAttributes();

		var materialDefaultAttributeValues = material.defaultAttributeValues;

		for ( name in programAttributes ) {

			var programAttribute = programAttributes[ name ];

			if ( programAttribute.location >= 0 ) {

				var geometryAttribute = geometryAttributes[ name ];

				if ( geometryAttribute == undefined ) {

					if ( name == 'instanceMatrix' && object.instanceMatrix ) geometryAttribute = object.instanceMatrix;
					if ( name == 'instanceColor' && object.instanceColor ) geometryAttribute = object.instanceColor;

				}

				if ( geometryAttribute != undefined ) {

					var normalized = geometryAttribute.normalized;
					var size = geometryAttribute.itemSize;

					var attribute = attributes.get( geometryAttribute );

					// TODO Attribute may not be available on context restore

					if ( attribute == undefined ) continue;

					var buffer = attribute.buffer;
					var type = attribute.type;
					var bytesPerElement = attribute.bytesPerElement;

					// check for integer attributes

					var integer = ( type == gl.INT || type == gl.UNSIGNED_INT || geometryAttribute.gpuType == IntType );

					if ( geometryAttribute.isInterleavedBufferAttribute ) {

						var data = geometryAttribute.data;
						var stride = data.stride;
						var offset = geometryAttribute.offset;

						if ( data.isInstancedInterleavedBuffer ) {

							for ( i in 0...programAttribute.locationSize ) {

								enableAttributeAndDivisor( programAttribute.location + i, data.meshPerAttribute );

							}

							if ( object.isInstancedMesh != true && geometry._maxInstanceCount == undefined ) {

								geometry._maxInstanceCount = data.meshPerAttribute * data.count;

							}

						} else {

							for ( i in 0...programAttribute.locationSize ) {

								enableAttribute( programAttribute.location + i );

							}

						}

						gl.bindBuffer( gl.ARRAY_BUFFER, buffer );

						for ( i in 0...programAttribute.locationSize ) {

							vertexAttribPointer(
								programAttribute.location + i,
								size / programAttribute.locationSize,
								type,
								normalized,
								stride * bytesPerElement,
								( offset + ( size / programAttribute.locationSize ) * i ) * bytesPerElement,
								integer
							);

						}

					} else {

						if ( geometryAttribute.isInstancedBufferAttribute ) {

							for ( i in 0...programAttribute.locationSize ) {

								enableAttributeAndDivisor( programAttribute.location + i, geometryAttribute.meshPerAttribute );

							}

							if ( object.isInstancedMesh != true && geometry._maxInstanceCount == undefined ) {

								geometry._maxInstanceCount = geometryAttribute.meshPerAttribute * geometryAttribute.count;

							}

						} else {

							for ( i in 0...programAttribute.locationSize ) {

								enableAttribute( programAttribute.location + i );

							}

						}

						gl.bindBuffer( gl.ARRAY_BUFFER, buffer );

						for ( i in 0...programAttribute.locationSize ) {

							vertexAttribPointer(
								programAttribute.location + i,
								size / programAttribute.locationSize,
								type,
								normalized,
								size * bytesPerElement,
								( size / programAttribute.locationSize ) * i * bytesPerElement,
								integer
							);

						}

					}

				} else if ( materialDefaultAttributeValues != undefined ) {

					var value = materialDefaultAttributeValues[ name ];

					if ( value != undefined ) {

						switch ( value.length ) {

							case 2:
								gl.vertexAttrib2fv( programAttribute.location, value );
								break;

							case 3:
								gl.vertexAttrib3fv( programAttribute.location, value );
								break;

							case 4:
								gl.vertexAttrib4fv( programAttribute.location, value );
								break;

							default:
								gl.vertexAttrib1fv( programAttribute.location, value );

						}

					}

				}

			}

		}

		disableUnusedAttributes();

	}

	function dispose() {

		reset();

		for ( geometryId in bindingStates ) {

			var programMap = bindingStates[ geometryId ];

			for ( programId in programMap ) {

				var stateMap = programMap[ programId ];

				for ( wireframe in stateMap ) {

					deleteVertexArrayObject( stateMap[ wireframe ].object );

					Reflect.deleteField(stateMap, wireframe);

				}

				Reflect.deleteField(programMap, programId);

			}

			Reflect.deleteField(bindingStates, geometryId);

		}

	}

	function releaseStatesOfGeometry( geometry ) {

		if ( bindingStates[ geometry.id ] == undefined ) return;

		var programMap = bindingStates[ geometry.id ];

		for ( programId in programMap ) {

			var stateMap = programMap[ programId ];

			for ( wireframe in stateMap ) {

				deleteVertexArrayObject( stateMap[ wireframe ].object );

				Reflect.deleteField(stateMap, wireframe );

			}

			Reflect.deleteField( programMap,  programId);

		}

		Reflect.deleteField( bindingStates,  geometry.id);

	}

	function releaseStatesOfProgram( program ) {

		for ( geometryId in bindingStates ) {

			var programMap = bindingStates[ geometryId ];

			if ( programMap[ program.id ] == undefined ) continue;

			var stateMap = programMap[ program.id ];

			for ( wireframe in stateMap ) {

				deleteVertexArrayObject( stateMap[ wireframe ].object );

				Reflect.deleteField( stateMap, wireframe);

			}

			Reflect.deleteField( programMap,  program.id );

		}

	}

	function reset() {

		resetDefaultState();
		forceUpdate = true;

		if ( currentState == defaultState ) return;

		currentState = defaultState;
		bindVertexArrayObject( currentState.object );

	}

	// for backward-compatibility

	function resetDefaultState() {

		defaultState.geometry = null;
		defaultState.program = null;
		defaultState.wireframe = false;

	}

}