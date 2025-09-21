package vman2002.vthreehx.renderers.webgl;

class WebGLIndexedBufferRenderer {
    public function new(gl, extensions, info) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    var gl:GL;
    var extensions:WebGLExtensions;
    var info:WebGLInfo;

	var mode;

	public function setMode( value ) {

		mode = value;

	}

	var type:Dynamic;
    var bytesPerElement:Int;

	public function setIndex( value ) {

		type = value.type;
		bytesPerElement = value.bytesPerElement;

	}

	public function render( start, count ) {

		gl.drawElements( mode, count, type, start * bytesPerElement );

		info.update( count, mode, 1 );

	}

	public function renderInstances( start, count, primcount ) {

		if ( primcount == 0 ) return;

		gl.drawElementsInstanced( mode, count, type, start * bytesPerElement, primcount );

		info.update( count, mode, primcount );

	}

	public function renderMultiDraw( starts, counts, drawCount ) {

		if ( drawCount == 0 ) return;

		var extension = extensions.get( 'WEBGL_multi_draw' );
		extension.multiDrawElementsWEBGL( mode, counts, 0, type, starts, 0, drawCount );

		var elementCount = 0;
		for ( i in 0...drawCount ) {

			elementCount += counts[ i ];

		}

		info.update( elementCount, mode, 1 );


	}

	public function renderMultiDrawInstances( starts, counts, drawCount, primcount ) {

		if ( drawCount == 0 ) return;

		var extension = extensions.get( 'WEBGL_multi_draw' );

		if ( extension == null ) {

			for ( i in 0...starts.length ) {

				renderInstances( starts[ i ] / bytesPerElement, counts[ i ], primcount[ i ] );

			}

		} else {

			extension.multiDrawElementsInstancedWEBGL( mode, counts, 0, type, starts, 0, primcount, 0, drawCount );

			var elementCount = 0;
			for ( i in 0...drawCount ) {

				elementCount += counts[ i ] * primcount[ i ];

			}

			info.update( elementCount, mode, 1 );

		}

	}

}