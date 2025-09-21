package vman2002.vthreehx.geometries;

import vman2002.vthreehx.core.BufferAttribute;
import vman2002.vthreehx.core.BufferGeometry;

/**
 * A geometry class for representing a plane.
 *
 * ```js
 * var geometry = new THREE.PlaneGeometry( 1, 1 );
 * var material = new THREE.MeshBasicMaterial( { color: 0xffff00, side: THREE.DoubleSide } );
 * var plane = new THREE.Mesh( geometry, material );
 * scene.add( plane );
 * ```
 *
 * @augments BufferGeometry
 */
class PlaneGeometry extends BufferGeometry {

	/**
	 * Constructs a new plane geometry.
	 *
	 * @param {number} [width=1] - The width along the X axis.
	 * @param {number} [height=1] - The height along the Y axis
	 * @param {number} [widthSegments=1] - The number of segments along the X axis.
	 * @param {number} [heightSegments=1] - The number of segments along the Y axis.
	 */
	public function new( width:Float = 1, height:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1 ) {

		super();

		/**
		 * Holds the constructor parameters that have been
		 * used to generate the geometry. Any modification
		 * after instantiation does not change the geometry.
		 *
		 * @type {Object}
		 */
		this.parameters = {
			width: width,
			height: height,
			widthSegments: widthSegments,
			heightSegments: heightSegments
		};

		var width_half = width / 2;
		var height_half = height / 2;

		var gridX = Math.floor( widthSegments );
		var gridY = Math.floor( heightSegments );

		var gridX1 = gridX + 1;
		var gridY1 = gridY + 1;

		var segment_width = width / gridX;
		var segment_height = height / gridY;

		//

		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		for ( iy in 0...gridY1 ) {

			var y = iy * segment_height - height_half;

			for ( ix in 0...gridX1 ) {

				var x = ix * segment_width - width_half;

				vertices.push( x);
				vertices.push( -y);
				vertices.push( 0 );

				normals.push( 0 );
				normals.push( 0 );
				normals.push( 1 );

				uvs.push( ix / gridX );
				uvs.push( 1 - ( iy / gridY ) );

			}

		}

		for ( iy in 0...gridY ) {

			for ( ix in 0...gridX ) {

				var a = ix + gridX1 * iy;
				var b = ix + gridX1 * ( iy + 1 );
				var c = ( ix + 1 ) + gridX1 * ( iy + 1 );
				var d = ( ix + 1 ) + gridX1 * iy;

				indices.push( a );
				indices.push( b );
				indices.push( d );
				indices.push( b );
				indices.push( c );
				indices.push( d );

			}

		}

		this.setIndex( indices );
		this.setAttribute( 'position', new Float32BufferAttribute( vertices, 3 ) );
		this.setAttribute( 'normal', new Float32BufferAttribute( normals, 3 ) );
		this.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );

	}

	public override function copy( source ) {

		super.copy( source );

		this.parameters = Common.assign( {}, source.parameters );

		return this;

	}

	/**
	 * Factory method for creating an instance of this class from the given
	 * JSON object.
	 *
	 * @param {Object} data - A JSON object representing the serialized geometry.
	 * @return {PlaneGeometry} A new instance.
	 */
	public static function fromJSON( data ) {

		return new PlaneGeometry( data.width, data.height, data.widthSegments, data.heightSegments );

	}

}