uniform vec3 u_Viewport;

#if MSAA_FACTOR
uniform sampler2DMS u_FramebufferSampler;
#else
uniform sampler2D   u_FramebufferSampler;
#endif

// -------------------------------------------------------------------------------------------------
/**
 * Vertex Shader
 *
 * This vertex shader draws a fullscreen quad
 */
#ifdef VERTEX_SHADER
layout(location = 0) out vec2 o_TexCoord;

void main(void)
{
    o_TexCoord  = vec2(gl_VertexID & 1, gl_VertexID >> 1 & 1);
    gl_Position = vec4(2.0 * o_TexCoord - 1.0, 0.0, 1.0);
}
#endif

// -------------------------------------------------------------------------------------------------
/**
 * Fragment Shader
 *
 * This fragment shader post-processes the scene framebuffer by applying
 * tone mapping, gamma correction and image scaling.
 */
#ifdef FRAGMENT_SHADER
layout(location = 0) in vec2 i_TexCoord;
layout(location = 0) out vec4 o_FragColor;

void main(void)
{
    vec4 color = vec4(0);
    ivec2 P = ivec2(gl_FragCoord.xy);

    // get framebuffer data
#if MSAA_FACTOR
    for (int i = 0; i < MSAA_FACTOR; ++i) {
        vec4 c = texelFetch(u_FramebufferSampler, P, i);
        color+= c;
    }
    color/= vec4(MSAA_FACTOR);
#else
    color = texelFetch(u_FramebufferSampler, P, 0);
#endif
    if (color.a > 1.0) color.rgb/= (color.a - 1.0);

    // make fragments store positive values
    if (any(lessThan(color.rgb, vec3(0)))) {
        o_FragColor = vec4(1, 0, 0, 1);
        return;
    }

    // final color
    o_FragColor = vec4(color.rgb, 1.0);

    // make sure the fragments store real values
    if (any(isnan(color.rgb)))
        o_FragColor = vec4(1, 0, 0, 1);

    //o_FragColor = vec4(o_FragColor.aaa / 2.0, 1);
}
#endif

