#[compute]
#version 450

// Invocations in the (x, y, z) dimension.
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D OUTPUT_TEXTURE;
layout(set = 0, binding = 1) uniform sampler2D INPUT_TEXTURE;

/*
float getNeighbors(sampler2D tex, vec2 uv, vec2 tex_pixel_size) {
    float total = 0.0;

    for (float x = -1.0; x < 2.0; x++) {
        for (float y = -1.0; y < 2.0; y++) {
            total += textureLod(tex, uv + vec2(tex_pixel_size.x * x, tex_pixel_size.y * y), 0.0).x;
        }
    }

    return total / 9.0;
}*/

// The code we want to execute in each invocation
void main() {
    //vec2 screen_size = 1.0 / vec2(textureSize(screen_texture, 0));

    //float result = getNeighbors(screen_texture, UV, screen_size);
    //COLOR = vec4(result + 0.5, result, result, 1.0);

    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    
    vec2 uv = texel / 512.0;
    //uv.x += texel.x / 512.0;
    
    vec4 color = texture(INPUT_TEXTURE, uv);
    
    imageStore(OUTPUT_TEXTURE, texel, vec4(1.0, 0.0, 0.0, 1.0));
    
    //imageStore(color.xy, texel, color);

}

