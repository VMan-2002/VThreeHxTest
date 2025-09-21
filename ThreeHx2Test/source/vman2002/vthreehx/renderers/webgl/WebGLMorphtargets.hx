package vman2002.vthreehx.renderers.webgl;

import vman2002.vthreehx.Constants.FloatType;
import vman2002.vthreehx.math.Vector2;
import vman2002.vthreehx.math.Vector4;
import vman2002.vthreehx.textures.DataArrayTexture;

function WebGLMorphtargets( gl, capabilities, textures ) {

	var morphTextures = new WeakMap();
	var morph = new Vector4();

	function update( object, geometry, program ) {

		var objectInfluences = object.morphTargetInfluences;

		// the following encodes morph targets into an array of data textures. Each layer represents a single morph target.

		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount = ( morphAttribute != undefined ) ? morphAttribute.length : 0;

		var entry = morphTextures.get( geometry );

		if ( entry == undefined || entry.count != morphTargetsCount ) {

			if ( entry != undefined ) entry.texture.dispose();

			var hasMorphPosition = geometry.morphAttributes.position != undefined;
			var hasMorphNormals = geometry.morphAttributes.normal != undefined;
			var hasMorphColors = geometry.morphAttributes.color != undefined;

			var morphTargets = geometry.morphAttributes.position || [];
			var morphNormals = geometry.morphAttributes.normal || [];
			var morphColors = geometry.morphAttributes.color || [];

			var vertexDataCount = 0;

			if ( hasMorphPosition == true ) vertexDataCount = 1;
			if ( hasMorphNormals == true ) vertexDataCount = 2;
			if ( hasMorphColors == true ) vertexDataCount = 3;

			var width = geometry.attributes.position.count * vertexDataCount;
			var height = 1;

			if ( width > capabilities.maxTextureSize ) {

				height = Math.ceil( width / capabilities.maxTextureSize );
				width = capabilities.maxTextureSize;

			}

			var buffer = new Float32Array( width * height * 4 * morphTargetsCount );

			var texture = new DataArrayTexture( buffer, width, height, morphTargetsCount );
			texture.type = FloatType;
			texture.needsUpdate = true;

			// fill buffer

			var vertexDataStride = vertexDataCount * 4;

			for ( i in 0...morphTargetsCount ) {

				var morphTarget = morphTargets[ i ];
				var morphNormal = morphNormals[ i ];
				var morphColor = morphColors[ i ];

				var offset = width * height * 4 * i;

				for ( j in 0...morphTarget.count ) {

					var stride = j * vertexDataStride;

					if ( hasMorphPosition == true ) {

						morph.fromBufferAttribute( morphTarget, j );

						buffer[ offset + stride + 0 ] = morph.x;
						buffer[ offset + stride + 1 ] = morph.y;
						buffer[ offset + stride + 2 ] = morph.z;
						buffer[ offset + stride + 3 ] = 0;

					}

					if ( hasMorphNormals == true ) {

						morph.fromBufferAttribute( morphNormal, j );

						buffer[ offset + stride + 4 ] = morph.x;
						buffer[ offset + stride + 5 ] = morph.y;
						buffer[ offset + stride + 6 ] = morph.z;
						buffer[ offset + stride + 7 ] = 0;

					}

					if ( hasMorphColors == true ) {

						morph.fromBufferAttribute( morphColor, j );

						buffer[ offset + stride + 8 ] = morph.x;
						buffer[ offset + stride + 9 ] = morph.y;
						buffer[ offset + stride + 10 ] = morph.z;
						buffer[ offset + stride + 11 ] = ( morphColor.itemSize == 4 ) ? morph.w : 1;

					}

				}

			}

			entry = {
				count: morphTargetsCount,
				texture: texture,
				size: new Vector2( width, height )
			};

			morphTextures.set( geometry, entry );

			function disposeTexture() {

				texture.dispose();

				morphTextures.delete( geometry );

				geometry.removeEventListener( 'dispose', disposeTexture );

			}

			geometry.addEventListener( 'dispose', disposeTexture );

		}

		//
		if ( object.isInstancedMesh == true && object.morphTexture != null ) {

			program.getUniforms().setValue( gl, 'morphTexture', object.morphTexture, textures );

		} else {

			var morphInfluencesSum = 0;

			for ( i in 0...objectInfluences.length ) {

				morphInfluencesSum += objectInfluences[ i ];

			}

			var morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;


			program.getUniforms().setValue( gl, 'morphTargetBaseInfluence', morphBaseInfluence );
			program.getUniforms().setValue( gl, 'morphTargetInfluences', objectInfluences );

		}

		program.getUniforms().setValue( gl, 'morphTargetsTexture', entry.texture, textures );
		program.getUniforms().setValue( gl, 'morphTargetsTextureSize', entry.size );

	}

}