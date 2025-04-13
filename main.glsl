#[compute]
#version 450

#define WIDTH 512
#define HEIGHT 512

// Invocations in the (x, y, z) dimension.
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D OUTPUT_TEXTURE;
layout(set = 0, binding = 1) uniform sampler2D INPUT_TEXTURE;

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = 512.0/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(3.14159*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p){
    p *= 1000.0;
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == 1) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}


vec2 getFlowField(vec2 uv) {
    //return vec2(cos(uv.x * 10.0), sin(uv.y * 10.0));
    return vec2(cos(uv.y * 5.0 * sqrt(pNoise(uv).x)), 0.0);// +
        //vec2(pNoise(uv * 10.0), pNoise(uv * 10.0 + vec2(500.0)));
}

float getNeighbors(sampler2D tex, vec2 uv, vec2 tex_pixel_size) {
    float total = 0.0;

    float avg = 1.0;
    for (float x = -1.0; x < 2.0; x++) {
        for (float y = -1.0; y < 2.0; y++) {
            vec2 dir = normalize(-vec2(x, y));
            vec2 pos = uv + vec2(tex_pixel_size.x * x, tex_pixel_size.y * y);
            
            float effect = (dot(dir, getFlowField(pos)) + 1.0) / 2.0; 
            if (x == 0 && y == 0) {
                effect = 1.0;
            } else { 
                avg += effect;
            }
            
            total += effect * texture(tex, pos).x;
        }
    }

    return total / avg;
}

// The code we want to execute in each invocation
void main() {
    vec2 screen_size = 1.0 / vec2(WIDTH, HEIGHT);

    ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
    vec2 uv = texel / vec2(WIDTH, HEIGHT);
    
    float result = getNeighbors(INPUT_TEXTURE, uv, screen_size);
    //COLOR = vec4(result + 0.5, result, result, 1.0);
    
    vec4 color = vec4(result, result, result, 1.0);
    
    imageStore(OUTPUT_TEXTURE, texel, color);
    
    //imageStore(color.xy, texel, color);

}

