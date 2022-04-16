varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    // SSAO without normals fix for beacon
    const vec4 colortex1ClearColor = vec4(0.5, 0.5, 1, 0.5);

    uniform sampler2D colortex2;

    #ifdef SSAO
        uniform sampler2D depthtex0;
        uniform sampler2D colortex1;

        /* Matrix uniforms */
        // View matrix uniforms
        uniform mat4 gbufferModelView;

        // Projection matrix uniforms
        uniform mat4 gbufferProjection;
        uniform mat4 gbufferProjectionInverse;
        
        #if ANTI_ALIASING == 2
            // Get frame time
            uniform float frameTimeCounter;
        #endif

        #include "/lib/utility/convertViewSpace.glsl"
        #include "/lib/utility/convertScreenSpace.glsl"
        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/lighting/SSAO.glsl"
    #endif

    void main(){
        #ifdef SSAO
            float ambientOcclusion = 1.0;

            // Declare and get positions
            float depth = texture2D(depthtex0, texCoord).x;
            
            if(depth > 0.56 && depth != 1){
                vec3 normal = texture2D(colortex1, texCoord).xyz * 2.0 - 1.0;

                // Check if normal has direction
                // if(length(normal) != 0){
                    #if ANTI_ALIASING == 2
                        vec3 dither = toRandPerFrame(getRand3(gl_FragCoord.xy * 0.03125), frameTimeCounter);
                    #else
                        vec3 dither = getRand3(gl_FragCoord.xy * 0.03125);
                    #endif

                    ambientOcclusion = getSSAO(toView(vec3(texCoord, depth)), mat3(gbufferModelView) * normal, dither);
                // }
            }
            
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texture2D(colortex2, texCoord).rgb, ambientOcclusion); //colortex2
        #else
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(texture2D(colortex2, texCoord).rgb, 1); //colortex2
        #endif
    }
#endif