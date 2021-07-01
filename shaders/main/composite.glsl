#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/gameUniforms.glsl"
#include "/lib/globalVars/matUniforms.glsl"
#include "/lib/globalVars/posUniforms.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"
#include "/lib/globalVars/timeUniforms.glsl"
#include "/lib/globalVars/universalVars.glsl"

#include "/lib/lighting/shdDistort.glsl"
#include "/lib/utility/spaceConvert.glsl"
#include "/lib/utility/texFunctions.glsl"
#include "/lib/rayTracing/rayTracer.glsl"

#include "/lib/atmospherics/fog.glsl"
#include "/lib/atmospherics/sky.glsl"

#include "/lib/lighting/shdMapping.glsl"
#include "/lib/lighting/GGX.glsl"
#include "/lib/lighting/SSR.glsl"
#include "/lib/lighting/SSGI.glsl"
#include "/lib/rayTracing/volLight.glsl"
#include "/lib/post/outline.glsl"

#include "/lib/lighting/complexShadingDeferred.glsl"

#include "/lib/assemblers/PBRAssembler.glsl"
#include "/lib/assemblers/posAssembler.glsl"

INOUT vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        // Declare and get positions
        positionVectors posVector;
	    getPosVectors(posVector, screenCoord);

	    // Declare and get materials
	    matPBR materials;
	    getPBR(materials, screenCoord);

        vec3 sceneCol = texture2D(gcolor, screenCoord).rgb;

        vec3 dither = getRand3(screenCoord, 8);
        // Depth with transparents
        float depth0 = toView(posVector.screenPos.z);
        // Depth with no transparents
        float depth1 = toView(texture2D(depthtex1, screenCoord).r);

        // If the object is transparent render lighting sperately
        if(depth0 - depth1 > 0.01){
            float skyMask = float(posVector.screenPos.z == 1);
            float cloudMask = texture2D(colortex4, screenCoord).g;

            // Get sky color
            vec3 skyRender = getSkyRender(posVector.eyePlayerPos, skyCol, lightCol, skyMask, 1.0, 1.0);

            if(cloudMask == 0) sceneCol = complexShadingDeferred(materials, posVector, sceneCol, dither);

            // Fog calculation
            sceneCol = getFog(posVector.eyePlayerPos, sceneCol, skyRender, posVector.worldPos.y, skyMask, cloudMask);
        }

        // Volumetric lighting
        sceneCol += getGodRays(posVector.feetPlayerPos, posVector.worldPos.y, dither.y) * lightCol;

    /* DRAWBUFFERS:02 */
        gl_FragData[0] = vec4(sceneCol, 1); //gcolor
        // Clear this buffer
        gl_FragData[1] = vec4(0); //colortex2
    }
#endif