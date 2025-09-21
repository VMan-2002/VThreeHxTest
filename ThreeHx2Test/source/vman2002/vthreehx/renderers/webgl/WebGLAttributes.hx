package vman2002.vthreehx.renderers.webgl;

class WebGLAttributes {
    public var gl:GL;

    public function new(gl) {
        this.gl = gl;
    }

	//TODO: better typing for this weakmap
	var buffers = new WeakMap<Dynamic, Dynamic>();

	public function createBuffer( attribute, bufferType ) {

		var array = attribute.array;
		var usage = attribute.usage;
		var size = array.byteLength;

		var buffer = GL.createBuffer();

		GL.bindBuffer( bufferType, buffer );
		GL.bufferData( bufferType, array, usage );

		attribute.onUploadCallback();

		var type;

		if ( Std.isOfType(array, Float32Array) ) {

			type = GL.FLOAT;

		} else if ( Std.isOfType(array, Uint16Array) ) {

			if ( attribute.isFloat16BufferAttribute ) {

				type = GL.HALF_FLOAT;

			} else {

				type = GL.UNSIGNED_SHORT;

			}

		} else if ( Std.isOfType(array, Int16Array) ) {

			type = GL.SHORT;

		} else if ( Std.isOfType(array, Uint32Array) ) {

			type = GL.UNSIGNED_INT;

		} else if ( Std.isOfType(array, Int32Array) ) {

			type = GL.INT;

		} else if ( Std.isOfType(array, Int8Array) ) {

			type = GL.BYTE;

		} else if ( Std.isOfType(array, Uint8Array) ) {

			type = GL.UNSIGNED_BYTE;

		} else if ( Std.isOfType(array, Uint8ClampedArray) ) {

			type = GL.UNSIGNED_BYTE;

		} else {

			throw ( 'THREE.WebGLAttributes: Unsupported buffer data format: ' + array );

		}

		return {
			buffer: buffer,
			type: type,
			bytesPerElement: array.BYTES_PER_ELEMENT,
			version: attribute.version,
			size: size
		};

	}

	public function updateBuffer( buffer, attribute, bufferType ) {

		var array = attribute.array;
		var updateRanges = attribute.updateRanges;

		GL.bindBuffer( bufferType, buffer );

		if ( updateRanges.length == 0 ) {

			// Not using update ranges
			GL.bufferSubData( bufferType, 0, array );

		} else {

			// Before applying update ranges, we merge any adjacent / overlapping
			// ranges to reduce load on `gl.bufferSubData`. Empirically, this has led
			// to performance improvements for applications which make heavy use of
			// update ranges. Likely due to GPU command overhead.
			//
			// Note that to reduce garbage collection between frames, we merge the
			// update ranges in-place. This is safe because this method will clear the
			// update ranges once updated.

			updateRanges.sort( function( a, b ) { return a.start - b.start; } );

			// To merge the update ranges in-place, we work from left to right in the
			// existing updateRanges array, merging ranges. This may result in a final
			// array which is smaller than the original. This index tracks the last
			// index representing a merged range, any data after this index can be
			// trimmed once the merge algorithm is completed.
			var mergeIndex = 0;

			for ( i in 1...updateRanges.length ) {

				var previousRange = updateRanges[ mergeIndex ];
				var range = updateRanges[ i ];

				// We add one here to merge adjacent ranges. This is safe because ranges
				// operate over positive integers.
				if ( range.start <= previousRange.start + previousRange.count + 1 ) {

					previousRange.count = Math.max(
						previousRange.count,
						range.start + range.count - previousRange.start
					);

				} else {

					++ mergeIndex;
					updateRanges[ mergeIndex ] = range;

				}

			}

			// Trim the array to only contain the merged ranges.
			updateRanges.resize(mergeIndex + 1);

			for ( i in 0...updateRanges.length ) {

				var range = updateRanges[ i ];

				GL.bufferSubData( bufferType, range.start * array.BYTES_PER_ELEMENT,
					array, range.start, range.count );

			}

			attribute.clearUpdateRanges();

		}

		attribute.onUploadCallback();

	}

	//

	public function get( attribute ) {

		if ( attribute.isInterleavedBufferAttribute ) attribute = attribute.data;

		return buffers.get( attribute );

	}

	public function remove( attribute ) {

		if ( attribute.isInterleavedBufferAttribute ) attribute = attribute.data;

		var data = buffers.get( attribute );

		if ( data ) {

			GL.deleteBuffer( data.buffer );

			buffers.remove( attribute );

		}

	}

	public function update( attribute:Dynamic, bufferType ) {

		if ( attribute.isInterleavedBufferAttribute ) attribute = attribute.data;

		if ( attribute.isGLBufferAttribute ) {

			var cached = buffers.get( attribute );

			if ( !cached || cached.version < attribute.version ) {

				buffers.set( attribute, {
					buffer: attribute.buffer,
					type: attribute.type,
					bytesPerElement: attribute.elementSize,
					version: attribute.version
				} );

			}

			return;

		}

		var data = buffers.get( attribute );

		if ( data == null ) {

			buffers.set( attribute, createBuffer( attribute, bufferType ) );

		} else if ( data.version < attribute.version ) {

			if ( data.size != attribute.array.byteLength ) {

				throw ( 'THREE.WebGLAttributes: The size of the buffer attribute\'s array buffer does not match the original size. Resizing buffer attributes is not supported.' );

			}

			updateBuffer( data.buffer, attribute, bufferType );

			data.version = attribute.version;

		}

	}

}