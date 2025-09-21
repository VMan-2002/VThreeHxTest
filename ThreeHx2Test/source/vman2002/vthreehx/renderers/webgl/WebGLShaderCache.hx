package vman2002.vthreehx.renderers.webgl;

class WebGLShaderCache {

	public function new() {

		this.shaderCache = new Map();
		this.materialCache = new Map();

	}

	public function update( material ) {

		var vertexShader = material.vertexShader;
		var fragmentShader = material.fragmentShader;

		var vertexShaderStage = this._getShaderStage( vertexShader );
		var fragmentShaderStage = this._getShaderStage( fragmentShader );

		var materialShaders = this._getShaderCacheForMaterial( material );

		if ( materialShaders.has( vertexShaderStage ) == false ) {

			materialShaders.add( vertexShaderStage );
			vertexShaderStage.usedTimes ++;

		}

		if ( materialShaders.has( fragmentShaderStage ) == false ) {

			materialShaders.add( fragmentShaderStage );
			fragmentShaderStage.usedTimes ++;

		}

		return this;

	}

	public function remove( material ) {

		var materialShaders = this.materialCache.get( material );

		for ( shaderStage in materialShaders ) {

			shaderStage.usedTimes --;

			if ( shaderStage.usedTimes == 0 ) this.shaderCache.delete( shaderStage.code );

		}

		this.materialCache.delete( material );

		return this;

	}

	public function getVertexShaderID( material ) {

		return this._getShaderStage( material.vertexShader ).id;

	}

	public function getFragmentShaderID( material ) {

		return this._getShaderStage( material.fragmentShader ).id;

	}

	public function dispose() {

		this.shaderCache.clear();
		this.materialCache.clear();

	}

	public function _getShaderCacheForMaterial( material ) {

		var cache = this.materialCache;
		var set = cache.get( material );

		if ( set == null ) {

			set = new Set();
			cache.set( material, set );

		}

		return set;

	}

	public function _getShaderStage( code ) {

		var cache = this.shaderCache;
		var stage = cache.get( code );

		if ( stage == null ) {

			stage = new WebGLShaderStage( code );
			cache.set( code, stage );

		}

		return stage;

	}

}

class WebGLShaderStage {
    static var _id = 0;

	public function new( code ) {

		this.id = _id ++;

		this.code = code;
		this.usedTimes = 0;

	}

}