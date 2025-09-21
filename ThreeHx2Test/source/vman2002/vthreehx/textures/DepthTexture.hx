package vman2002.vthreehx.textures;

import vman2002.vthreehx.Constants.DepthFormat;
import vman2002.vthreehx.Constants.DepthStencilFormat;
import vman2002.vthreehx.Constants.NearestFilter;
import vman2002.vthreehx.Constants.UnsignedIntType;
import vman2002.vthreehx.textures.Source;
import vman2002.vthreehx.textures.Texture;

/**
 * This class can be used to automatically save the depth information of a
 * rendering into a texture.
 *
 * @augments Texture
 */
class DepthTexture extends Texture {

	/**
	 * Constructs a new depth texture.
	 *
	 * @param {number} width - The width of the texture.
	 * @param {number} height - The height of the texture.
	 * @param {number} [type=UnsignedIntType] - The texture type.
	 * @param {number} [mapping=Texture.DEFAULT_MAPPING] - The texture mapping.
	 * @param {number} [wrapS=ClampToEdgeWrapping] - The wrapS value.
	 * @param {number} [wrapT=ClampToEdgeWrapping] - The wrapT value.
	 * @param {number} [magFilter=LinearFilter] - The mag filter value.
	 * @param {number} [minFilter=LinearFilter] - The min filter value.
	 * @param {number} [anisotropy=Texture.DEFAULT_ANISOTROPY] - The anisotropy value.
	 * @param {number} [format=DepthFormat] - The texture format.
	 */
	public function new( width, height, type = UnsignedIntType, mapping, wrapS, wrapT, magFilter = NearestFilter, minFilter = NearestFilter, anisotropy, format = DepthFormat ) {

		if ( format != DepthFormat && format != DepthStencilFormat ) {

			throw ( 'DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat' );

		}

		super( null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy );

		/**
		 * This flag can be used for type testing.
		 *
		 * @type {boolean}
		 * @readonly
		 * @default true
		 */
		this.isDepthTexture = true;

		/**
		 * The image property of a depth texture just defines its dimensions.
		 *
		 * @type {{width:number,height:number}}
		 */
		this.image = { width: width, height: height };

		/**
		 * If set to `true`, the texture is flipped along the vertical axis when
		 * uploaded to the GPU.
		 *
		 * Overwritten and set to `false` by default.
		 *
		 * @type {boolean}
		 * @default false
		 */
		this.flipY = false;

		/**
		 * Whether to generate mipmaps (if possible) for a texture.
		 *
		 * Overwritten and set to `false` by default.
		 *
		 * @type {boolean}
		 * @default false
		 */
		this.generateMipmaps = false;

		/**
		 * Code corresponding to the depth compare function.
		 *
		 * @type {?(NeverCompare|LessCompare|EqualCompare|LessEqualCompare|GreaterCompare|NotEqualCompare|GreaterEqualCompare|AlwaysCompare)}
		 * @default null
		 */
		this.compareFunction = null;

	}


	public function copy( source ) {

		super.copy( source );

		this.source = new Source( Object.assign( {}, source.image ) ); // see #30540
		this.compareFunction = source.compareFunction;

		return this;

	}

	public function toJSON( meta ) {

		var data = super.toJSON( meta );

		if ( this.compareFunction != null ) data.compareFunction = this.compareFunction;

		return data;

	}

}