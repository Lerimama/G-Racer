//shader_type canvas_item;
//
//uniform vec4 line_color : hint_color = vec4(1.0);
//uniform float line_thickness : hint_range(0, 10) = 1.0;
//
//const vec2 OFFSETS[8] = {
//	vec2(-1, -1), vec2(-1, 0), vec2(-1, 1), vec2(0, -1), vec2(0, 1), 
//	vec2(1, -1), vec2(1, 0), vec2(1, 1)
//};
//
//void fragment() {
//	vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
//	float outline = 1.0;
//
//	for (int i = 0; i < OFFSETS.length(); i++) {
//		outline *= texture(TEXTURE, UV + size * OFFSETS[i]).a;
//	}
//	outline = 1.0 - outline;
//
//	vec4 color = texture(TEXTURE, UV);
//	vec4 outlined_result = mix(color, line_color, outline * color.a);
//	COLOR = mix(color, outlined_result, outlined_result.a);
//}


shader_type canvas_item;

uniform vec4 background_color : hint_color;
uniform vec4 shadow_color : hint_color;
// Currently pixels always in application size, so zooming in further wouldn't increase the size of the dropdown
// but changing that would also be relatively trivial
uniform vec2 offset_in_pixels;

void fragment() {

	// Read screen texture
//	vec4 current_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	vec4 current_color = texture(TEXTURE, UV, 0.0);

	// Check if the current color is our background color
	if (length(current_color - background_color) < 0.01) {

//		vec4 offset_color = textureLod(SCREEN_TEXTURE, SCREEN_UV - offset_in_pixels * SCREEN_PIXEL_SIZE, 0.0);
		vec4 offset_color = texture(TEXTURE, UV - offset_in_pixels * TEXTURE_PIXEL_SIZE, 0.0);

		// Check if at our offset position we have a color which is not the background (meaning here we need a shadow actually)
		if (length(offset_color - background_color) > 0.01) {
			// If so set it to our shadow color
			current_color = shadow_color;
		}
	}

	COLOR = current_color;
}