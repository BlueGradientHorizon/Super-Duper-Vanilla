/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender Studios.

    Copyright (C) 2020 Eldeston


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file.

    Violating these terms may be penalized with actions according to the Digital Millennium Copyright Act (DMCA),
    the Information Society Directive and/or similar laws depending on your country.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, direct shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

    out vec2 texCoord;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color;
        
	    #ifdef WORLD_CURVATURE
            // Get vertex position (feet player pos)
            vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            // Apply curvature distortion
            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Convert to clip pos and output as position
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in vec4 vertexColor;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    void main(){
        vec4 albedo = textureLod(tex, texCoord, 0) * vertexColor;

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            albedo.rgb = vertexColor.rgb;
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo.rgb * EMISSIVE_INTENSITY, albedo.a); // gcolor
    }
#endif