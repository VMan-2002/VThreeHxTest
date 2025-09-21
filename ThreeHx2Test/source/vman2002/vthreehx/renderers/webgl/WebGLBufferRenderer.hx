package vman2002.vthreehx.renderers.webgl;

class WebGLBufferRenderer {

    public function new(gl, extensions, info) {
        this.gl = gl;
        this.extensions = extensions;
        this.info = info;
    }

    var gl:GL;
    var extensions:WebGLExtensions;
    var info:WebGLInfo;
	var mode:Int;

	function setMode( value ) {

		mode = value;

	}

	function render( start, count ) {

		gl.drawArrays( mode, start, count );

		info.update( count, mode, 1 );

	}

	function renderInstances( start, count, primcount ) {

		if ( primcount == 0 ) return;

		gl.drawArraysInstanced( mode, start, count, primcount );

		info.update( count, mode, primcount );

	}

	function renderMultiDraw( starts, counts, drawCount ) {

		if ( drawCount == 0 ) return;

		var extension = extensions.get( 'WEBGL_multi_draw' );
		extension.multiDrawArraysWEBGL( mode, starts, 0, counts, 0, drawCount );

		var elementCount = 0;
		for ( i in 0...drawCount ) {

			elementCount += counts[ i ];

		}

		info.update( elementCount, mode, 1 );

	}

	function renderMultiDrawInstances( starts, counts, drawCount, primcount ) {

		if ( drawCount == 0 ) return;

		var extension = extensions.get( 'WEBGL_multi_draw' );

		if ( extension == null ) {

			for ( i in 0...starts.length ) {

				renderInstances( starts[ i ], counts[ i ], primcount[ i ] );

			}

		} else {

			extension.multiDrawArraysInstancedWEBGL( mode, starts, 0, counts, 0, primcount, 0, drawCount );

			var elementCount = 0;
			for ( i in 0...drawCount ) {

				elementCount += counts[ i ] * primcount[ i ];

			}

			info.update( elementCount, mode, 1 );

		}

	}

}