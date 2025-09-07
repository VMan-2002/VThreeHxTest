package vman2002.vthreehx.math;

import vman2002.vthreehx.core.BufferAttribute;
import vman2002.vthreehx.math.Vector3;
import vman2002.vthreehx.math.Vector4;

/**
 * A geometric triangle as defined by three vectors representing its three corners.
 */
class Triangle {

		/**
		 * The first corner of the triangle.
		 *
		 * @type {Vector3}
		 */
		public var a:Vector3;

		/**
		 * The second corner of the triangle.
		 *
		 * @type {Vector3}
		 */
		public var b:Vector3;

		/**
		 * The third corner of the triangle.
		 *
		 * @type {Vector3}
		 */
		public var c:Vector3;

	/**
	 * Constructs a new triangle.
	 *
	 * @param {Vector3} [a=(0,0,0)] - The first corner of the triangle.
	 * @param {Vector3} [b=(0,0,0)] - The second corner of the triangle.
	 * @param {Vector3} [c=(0,0,0)] - The third corner of the triangle.
	 */
	public function new( ?a:Vector3, ?b:Vector3, ?c:Vector3 ) {

		this.a = a ?? new Vector3();
		this.b = b ?? new Vector3();
		this.c = c ?? new Vector3();

	}

	/**
	 * Computes the normal vector of a triangle.
	 *
	 * @param {Vector3} a - The first corner of the triangle.
	 * @param {Vector3} b - The second corner of the triangle.
	 * @param {Vector3} c - The third corner of the triangle.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {Vector3} The triangle's normal.
	 */
	public static function s_getNormal( a:Vector3, b:Vector3, c:Vector3, target:Vector3 ) {

		target.subVectors( c, b );
		_v0.subVectors( a, b );
		target.cross( _v0 );

		var targetLengthSq = target.lengthSq();
		if ( targetLengthSq > 0 ) {

			return target.multiplyScalar( 1 / Math.sqrt( targetLengthSq ) );

		}

		return target.set( 0, 0, 0 );

	}

	/**
	 * Computes a barycentric coordinates from the given vector.
	 * Returns `null` if the triangle is degenerate.
	 *
	 * @param {Vector3} point - A point in 3D space.
	 * @param {Vector3} a - The first corner of the triangle.
	 * @param {Vector3} b - The second corner of the triangle.
	 * @param {Vector3} c - The third corner of the triangle.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {?Vector3} The barycentric coordinates for the given point
	 */
	public static function s_getBarycoord( point:Vector3, a:Vector3, b:Vector3, c:Vector3, target:Vector3 ) {

		// based on: http://www.blackpawn.com/texts/pointinpoly/default.html

		_v0.subVectors( c, a );
		_v1.subVectors( b, a );
		_v2.subVectors( point, a );

		var dot00 = _v0.dot( _v0 );
		var dot01 = _v0.dot( _v1 );
		var dot02 = _v0.dot( _v2 );
		var dot11 = _v1.dot( _v1 );
		var dot12 = _v1.dot( _v2 );

		var denom = ( dot00 * dot11 - dot01 * dot01 );

		// collinear or singular triangle
		if ( denom == 0 ) {

			target.set( 0, 0, 0 );
			return null;

		}

		var invDenom = 1 / denom;
		var u = ( dot11 * dot02 - dot01 * dot12 ) * invDenom;
		var v = ( dot00 * dot12 - dot01 * dot02 ) * invDenom;

		// barycentric coordinates must always sum to 1
		return target.set( 1 - u - v, v, u );

	}

	/**
	 * Returns `true` if the given point, when projected onto the plane of the
	 * triangle, lies within the triangle.
	 *
	 * @param {Vector3} point - The point in 3D space to test.
	 * @param {Vector3} a - The first corner of the triangle.
	 * @param {Vector3} b - The second corner of the triangle.
	 * @param {Vector3} c - The third corner of the triangle.
	 * @return {boolean} Whether the given point, when projected onto the plane of the
	 * triangle, lies within the triangle or not.
	 */
	public static function s_containsPoint( point:Vector3, a:Vector3, b:Vector3, c:Vector3 ) {

		// if the triangle is degenerate then we can't contain a point
		if ( s_getBarycoord( point, a, b, c, _v3 ) == null ) {

			return false;

		}

		return ( _v3.x >= 0 ) && ( _v3.y >= 0 ) && ( ( _v3.x + _v3.y ) <= 1 );

	}

	/**
	 * Computes the value barycentrically interpolated for the given point on the
	 * triangle. Returns `null` if the triangle is degenerate.
	 *
	 * @param {Vector3} point - Position of interpolated point.
	 * @param {Vector3} p1 - The first corner of the triangle.
	 * @param {Vector3} p2 - The second corner of the triangle.
	 * @param {Vector3} p3 - The third corner of the triangle.
	 * @param {Vector3} v1 - Value to interpolate of first vertex.
	 * @param {Vector3} v2 - Value to interpolate of second vertex.
	 * @param {Vector3} v3 - Value to interpolate of third vertex.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {?Vector3} The interpolated value.
	 */
	public static function s_getInterpolation( point:Vector3, p1:Vector3, p2:Vector3, p3:Vector3, v1:Vector3, v2:Vector3, v3:Vector3, target:Vector3 ) {

		if ( s_getBarycoord( point, p1, p2, p3, _v3 ) == null ) {

			target.x = 0;
			target.y = 0;
			target.z = 0;
			return null;

		}

		target.setScalar( 0 );
		target.addScaledVector( v1, _v3.x );
		target.addScaledVector( v2, _v3.y );
		target.addScaledVector( v3, _v3.z );

		return target;

	}

	/**
	 * Computes the value barycentrically interpolated for the given attribute and indices.
	 *
	 * @param {BufferAttribute} attr - The attribute to interpolate.
	 * @param {number} i1 - Index of first vertex.
	 * @param {number} i2 - Index of second vertex.
	 * @param {number} i3 - Index of third vertex.
	 * @param {Vector3} barycoord - The barycoordinate value to use to interpolate.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {Vector3} The interpolated attribute value.
	 */
	public static function getInterpolatedAttribute( attr:BufferAttribute, i1:Int, i2:Int, i3:Int, barycoord:Vector3, target:Vector3 ) {

		_v40.setScalar( 0 );
		_v41.setScalar( 0 );
		_v42.setScalar( 0 );

		_v40.fromBufferAttribute( attr, i1 );
		_v41.fromBufferAttribute( attr, i2 );
		_v42.fromBufferAttribute( attr, i3 );

		target.setScalar( 0 );
        target.x += _v40.x * barycoord.x;
        target.y += _v40.y * barycoord.x;
        target.z += _v40.z * barycoord.x;
        target.x += _v41.x * barycoord.y;
        target.y += _v41.y * barycoord.y;
        target.z += _v41.z * barycoord.y;
        target.x += _v42.x * barycoord.z;
        target.y += _v42.y * barycoord.z;
        target.z += _v42.z * barycoord.z;

		return target;

	}

	/**
	 * Returns `true` if the triangle is oriented towards the given direction.
	 *
	 * @param {Vector3} a - The first corner of the triangle.
	 * @param {Vector3} b - The second corner of the triangle.
	 * @param {Vector3} c - The third corner of the triangle.
	 * @param {Vector3} direction - The (normalized) direction vector.
	 * @return {boolean} Whether the triangle is oriented towards the given direction or not.
	 */
	public static function s_isFrontFacing( a:Vector3, b:Vector3, c:Vector3, direction:Vector3 ) {

		_v0.subVectors( c, b );
		_v1.subVectors( a, b );

		// strictly front facing
		return ( _v0.cross( _v1 ).dot( direction ) < 0 ) ? true : false;

	}

	/**
	 * Sets the triangle's vertices by copying the given values.
	 *
	 * @param {Vector3} a - The first corner of the triangle.
	 * @param {Vector3} b - The second corner of the triangle.
	 * @param {Vector3} c - The third corner of the triangle.
	 * @return {Triangle} A reference to this triangle.
	 */
	public function set( a, b, c ) {

		this.a.copy( a );
		this.b.copy( b );
		this.c.copy( c );

		return this;

	}

	/**
	 * Sets the triangle's vertices by copying the given array values.
	 *
	 * @param {Array<Vector3>} points - An array with 3D points.
	 * @param {number} i0 - The array index representing the first corner of the triangle.
	 * @param {number} i1 - The array index representing the second corner of the triangle.
	 * @param {number} i2 - The array index representing the third corner of the triangle.
	 * @return {Triangle} A reference to this triangle.
	 */
	public function setFromPointsAndIndices( points, i0, i1, i2 ) {

		this.a.copy( points[ i0 ] );
		this.b.copy( points[ i1 ] );
		this.c.copy( points[ i2 ] );

		return this;

	}

	/**
	 * Sets the triangle's vertices by copying the given attribute values.
	 *
	 * @param {BufferAttribute} attribute - A buffer attribute with 3D points data.
	 * @param {number} i0 - The attribute index representing the first corner of the triangle.
	 * @param {number} i1 - The attribute index representing the second corner of the triangle.
	 * @param {number} i2 - The attribute index representing the third corner of the triangle.
	 * @return {Triangle} A reference to this triangle.
	 */
	public function setFromAttributeAndIndices( attribute, i0, i1, i2 ) {

		this.a.fromBufferAttribute( attribute, i0 );
		this.b.fromBufferAttribute( attribute, i1 );
		this.c.fromBufferAttribute( attribute, i2 );

		return this;

	}

	/**
	 * Returns a new triangle with copied values from this instance.
	 *
	 * @return {Triangle} A clone of this instance.
	 */
	public function clone() {

		return new Triangle().copy( this );

	}

	/**
	 * Copies the values of the given triangle to this instance.
	 *
	 * @param {Triangle} triangle - The triangle to copy.
	 * @return {Triangle} A reference to this triangle.
	 */
	public function copy( triangle ) {

		this.a.copy( triangle.a );
		this.b.copy( triangle.b );
		this.c.copy( triangle.c );

		return this;

	}

	/**
	 * Computes the area of the triangle.
	 *
	 * @return {number} The triangle's area.
	 */
	public function getArea() {

		_v0.subVectors( this.c, this.b );
		_v1.subVectors( this.a, this.b );

		return _v0.cross( _v1 ).length() * 0.5;

	}

	/**
	 * Computes the midpoint of the triangle.
	 *
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {Vector3} The triangle's midpoint.
	 */
	public function getMidpoint( target ) {

		return target.addVectors( this.a, this.b ).add( this.c ).multiplyScalar( 1 / 3 );

	}

	/**
	 * Computes the normal of the triangle.
	 *
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {Vector3} The triangle's normal.
	 */
	public function getNormal( target:Vector3 ) {

		return Triangle.s_getNormal( this.a, this.b, this.c, target );

	}

	/**
	 * Computes a plane the triangle lies within.
	 *
	 * @param {Plane} target - The target vector that is used to store the method's result.
	 * @return {Plane} The plane the triangle lies within.
	 */
	public function getPlane( target:Plane ) {

		return target.setFromCoplanarPoints( this.a, this.b, this.c );

	}

	/**
	 * Computes a barycentric coordinates from the given vector.
	 * Returns `null` if the triangle is degenerate.
	 *
	 * @param {Vector3} point - A point in 3D space.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {?Vector3} The barycentric coordinates for the given point
	 */
	public function getBarycoord( point:Vector3, target:Vector3 ) {

		return Triangle.s_getBarycoord( point, this.a, this.b, this.c, target );

	}

	/**
	 * Computes the value barycentrically interpolated for the given point on the
	 * triangle. Returns `null` if the triangle is degenerate.
	 *
	 * @param {Vector3} point - Position of interpolated point.
	 * @param {Vector3} v1 - Value to interpolate of first vertex.
	 * @param {Vector3} v2 - Value to interpolate of second vertex.
	 * @param {Vector3} v3 - Value to interpolate of third vertex.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {?Vector3} The interpolated value.
	 */
	public function getInterpolation( point, v1, v2, v3, target ) {

		return Triangle.s_getInterpolation( point, this.a, this.b, this.c, v1, v2, v3, target );

	}

	/**
	 * Returns `true` if the given point, when projected onto the plane of the
	 * triangle, lies within the triangle.
	 *
	 * @param {Vector3} point - The point in 3D space to test.
	 * @return {boolean} Whether the given point, when projected onto the plane of the
	 * triangle, lies within the triangle or not.
	 */
	public function containsPoint( point ) {

		return Triangle.s_containsPoint( point, this.a, this.b, this.c );

	}

	/**
	 * Returns `true` if the triangle is oriented towards the given direction.
	 *
	 * @param {Vector3} direction - The (normalized) direction vector.
	 * @return {boolean} Whether the triangle is oriented towards the given direction or not.
	 */
	public function isFrontFacing( direction ) {

		return Triangle.s_isFrontFacing( this.a, this.b, this.c, direction );

	}

	/**
	 * Returns `true` if this triangle intersects with the given box.
	 *
	 * @param {Box3} box - The box to intersect.
	 * @return {boolean} Whether this triangle intersects with the given box or not.
	 */
	public function intersectsBox( box ) {

		return box.intersectsTriangle( this );

	}

	/**
	 * Returns the closest point on the triangle to the given point.
	 *
	 * @param {Vector3} p - The point to compute the closest point for.
	 * @param {Vector3} target - The target vector that is used to store the method's result.
	 * @return {Vector3} The closest point on the triangle.
	 */
	public function closestPointToPoint( p, target ) {

		var a = this.a, b = this.b, c = this.c;
		var v, w;

		// algorithm thanks to Real-Time Collision Detection by Christer Ericson,
		// published by Morgan Kaufmann Publishers, (c) 2005 Elsevier Inc.,
		// under the accompanying license; see chapter 5.1.5 for detailed explanation.
		// basically, we're distinguishing which of the voronoi regions of the triangle
		// the point lies in with the minimum amount of redundant computation.

		_vab.subVectors( b, a );
		_vac.subVectors( c, a );
		_vap.subVectors( p, a );
		var d1 = _vab.dot( _vap );
		var d2 = _vac.dot( _vap );
		if ( d1 <= 0 && d2 <= 0 ) {

			// vertex region of A; barycentric coords (1, 0, 0)
			return target.copy( a );

		}

		_vbp.subVectors( p, b );
		var d3 = _vab.dot( _vbp );
		var d4 = _vac.dot( _vbp );
		if ( d3 >= 0 && d4 <= d3 ) {

			// vertex region of B; barycentric coords (0, 1, 0)
			return target.copy( b );

		}

		var vc = d1 * d4 - d3 * d2;
		if ( vc <= 0 && d1 >= 0 && d3 <= 0 ) {

			v = d1 / ( d1 - d3 );
			// edge region of AB; barycentric coords (1-v, v, 0)
			return target.copy( a ).addScaledVector( _vab, v );

		}

		_vcp.subVectors( p, c );
		var d5 = _vab.dot( _vcp );
		var d6 = _vac.dot( _vcp );
		if ( d6 >= 0 && d5 <= d6 ) {

			// vertex region of C; barycentric coords (0, 0, 1)
			return target.copy( c );

		}

		var vb = d5 * d2 - d1 * d6;
		if ( vb <= 0 && d2 >= 0 && d6 <= 0 ) {

			w = d2 / ( d2 - d6 );
			// edge region of AC; barycentric coords (1-w, 0, w)
			return target.copy( a ).addScaledVector( _vac, w );

		}

		var va = d3 * d6 - d5 * d4;
		if ( va <= 0 && ( d4 - d3 ) >= 0 && ( d5 - d6 ) >= 0 ) {

			_vbc.subVectors( c, b );
			w = ( d4 - d3 ) / ( ( d4 - d3 ) + ( d5 - d6 ) );
			// edge region of BC; barycentric coords (0, 1-w, w)
			return target.copy( b ).addScaledVector( _vbc, w ); // edge region of BC

		}

		// face region
		var denom = 1 / ( va + vb + vc );
		// u = va * denom
		v = vb * denom;
		w = vc * denom;

		return target.copy( a ).addScaledVector( _vab, v ).addScaledVector( _vac, w );

	}

	/**
	 * Returns `true` if this triangle is equal with the given one.
	 *
	 * @param {Triangle} triangle - The triangle to test for equality.
	 * @return {boolean} Whether this triangle is equal with the given one.
	 */
	public function equals( triangle ) {

		return triangle.a.equals( this.a ) && triangle.b.equals( this.b ) && triangle.c.equals( this.c );

	}


static var _v0 = /*@__PURE__*/ new Vector3();
static var _v1 = /*@__PURE__*/ new Vector3();
static var _v2 = /*@__PURE__*/ new Vector3();
static var _v3 = /*@__PURE__*/ new Vector3();

static var _vab = /*@__PURE__*/ new Vector3();
static var _vac = /*@__PURE__*/ new Vector3();
static var _vbc = /*@__PURE__*/ new Vector3();
static var _vap = /*@__PURE__*/ new Vector3();
static var _vbp = /*@__PURE__*/ new Vector3();
static var _vcp = /*@__PURE__*/ new Vector3();

static var _v40 = /*@__PURE__*/ new Vector4();
static var _v41 = /*@__PURE__*/ new Vector4();
static var _v42 = /*@__PURE__*/ new Vector4();
}