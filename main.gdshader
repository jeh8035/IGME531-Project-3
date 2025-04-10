shader_type canvas_item;

uniform sampler2D screen_texture : repeat_disable, filter_nearest;


void vertex() {
	// Called for every vertex the material is visible on.
}

float getNeighbors(sampler2D tex, vec2 uv, vec2 tex_pixel_size) {
	float total = 0.0;

	for (float x = -1.0; x < 2.0; x++) {
		for (float y = -1.0; y < 2.0; y++) {
			total += textureLod(tex, uv + vec2(tex_pixel_size.x * x, tex_pixel_size.y * y), 0.0).x;
		}
	}

	return total / 9.0;
}

void fragment() {
	vec2 screen_size = 1.0 / vec2(textureSize(screen_texture, 0));

	float result = getNeighbors(screen_texture, UV, screen_size);
	COLOR = vec4(result + 0.5, result, result, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
