package vman2002.vthreehx.textures;

import vman2002.vthreehx.Constants.ClampToEdgeWrapping;
import vman2002.vthreehx.Constants.NearestFilter;
import vman2002.vthreehx.textures.Texture;
/**
 * Creates an array of textures directly from raw buffer data.
 *
 * @augments Texture
 */
class DataArrayTexture extends Texture {

	/**
	 * Constructs a new data array texture.
	 *
	 * @param {?TypedArray} [data=null] - The buffer data.
	 * @param {number} [width=1] - The width of the texture.
	 * @param {number} [height=1] - The height of the texture.
	 * @param {number} [depth=1] - The depth of the texture.
	 */
	public function new( data = null, width = 1, height = 1, depth = 1 ) {

		super( null );

		/**
		 * The image definition of a data texture.
		 *
		 * @type {{data:TypedArray,width:number,height:number,depth:number}}
		 */
		this.image = { data: data, width: width, height: height, depth: depth };

		/**
		 * How the texture is sampled when a texel covers more than one pixel.
		 *
		 * Overwritten and set to `NearestFilter` by default.
		 *
		 * @type {(NearestFilter|NearestMipmapNearestFilter|NearestMipmapLinearFilter|LinearFilter|LinearMipmapNearestFilter|LinearMipmapLinearFilter)}
		 * @default NearestFilter
		 */
		this.magFilter = NearestFilter;

		/**
		 * How the texture is sampled when a texel covers less than one pixel.
		 *
		 * Overwritten and set to `NearestFilter` by default.
		 *
		 * @type {(NearestFilter|NearestMipmapNearestFilter|NearestMipmapLinearFilter|LinearFilter|LinearMipmapNearestFilter|LinearMipmapLinearFilter)}
		 * @default NearestFilter
		 */
		this.minFilter = NearestFilter;

		/**
		 * This defines how the texture is wrapped in the depth and corresponds to
		 * *W* in UVW mapping.
		 *
		 * @type {(RepeatWrapping|ClampToEdgeWrapping|MirroredRepeatWrapping)}
		 * @default ClampToEdgeWrapping
		 */
		this.wrapR = ClampToEdgeWrapping;

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
		 * Specifies the alignment requirements for the start of each pixel row in memory.
		 *
		 * Overwritten and set to `1` by default.
		 *
		 * @type {boolean}
		 * @default 1
		 */
		this.unpackAlignment = 1;

		/**
		 * A set of all layers which need to be updated in the texture.
		 *
		 * @type {Set<number>}
		 */
		this.layerUpdates = new Set();

	}

	/**
	 * Describes that a specific layer of the texture needs to be updated.
	 * Normally when {@link Texture#needsUpdate} is set to `true`, the
	 * entire data texture array is sent to the GPU. Marking specific
	 * layers will only transmit subsets of all mipmaps associated with a
	 * specific depth in the array which is often much more performant.
	 *
	 * @param {number} layerIndex - The layer index that should be updated.
	 */
	public function addLayerUpdate( layerIndex ) {

		this.layerUpdates.add( layerIndex );

	}

	/**
	 * Resets the layer updates registry.
	 */
	public function clearLayerUpdates() {

		this.layerUpdates.clear();

	}

}