float getCellNoise(in vec2 uv){
    float animateTime = CURRENT_SPEED * newFrameTimeCounter * 0.0625;
    return (textureLod(noisetex, uv + animateTime, 0).z + textureLod(noisetex, animateTime - uv, 0).z) * 0.5;
}

// Convert height map of water to a normal map
vec4 H2NWater(in vec2 uv){
    const float waterPixel = WATER_BLUR_SIZE * 0.00390625;

	float d0 = getCellNoise(uv);
	float d1 = getCellNoise(vec2(uv.x + waterPixel, uv.y));
	float d2 = getCellNoise(vec2(uv.x, uv.y + waterPixel));
    
    return vec4(fastNormalize(vec3(d0 - d1, d0 - d2, waterPixel * WATER_DEPTH_SIZE)), d0);
}