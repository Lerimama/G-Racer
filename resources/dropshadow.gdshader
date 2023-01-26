shader_type canvas_item;
//render_mode blend_mix;

uniform float radius = 5.0;

uniform vec2 offset = vec2(8.0, 8.0);
uniform vec4 modulate : hint_color;

// iz dš
uniform vec4 background_color : hint_color;
uniform vec4 shadow_color : hint_color;
// Currently pixels always in application size, so zooming in further wouldn't increase the size of the dropdown
// but changing that would also be relatively trivial
uniform vec2 offset_in_pixels;

const vec4 color1 = vec4 (1.0,1.0,1.0,1.0);
const vec4 color2 = vec4 (0.0,0.5,0.5,1.0);


void fragment() {

	vec4 col = texture(TEXTURE, UV);


	vec4 offset_color;

	offset_color += texture(TEXTURE, UV - vec2(5.0 , 5.0) * TEXTURE_PIXEL_SIZE, 0.0);
//	vec4 offset_color = vec4(modulate.rgb, texture(TEXTURE, UV -  vec2(5.0 , 5.0) * TEXTURE_PIXEL_SIZE, 0.0).r);

	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV - offset * TEXTURE_PIXEL_SIZE).a * modulate.a);
//	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV - offset * ps).a * modulate.a);
//	col += texture(TEXTURE, UV + vec2(5.0 , 5.0) * TEXTURE_PIXEL_SIZE,0.0);

	// displace
//	col += texture(TEXTURE, UV + vec2(0.0, -radius) * ps);
//	col += texture(TEXTURE, UV + vec2(0.0, radius) * ps);
//	col += texture(TEXTURE, UV + vec2(-radius, 0.0) * ps);
//	col += texture(TEXTURE, UV + vec2(radius, 0.0) * ps);
//	col /= 5.0;

//	COLOR = mix(shadow, col, col.a);

// 	col = texture(TEXTURE, UV - offset * ps);

	COLOR = offset_color;
//	COLOR = col;
//	COLOR.rgb = col.rgb;
	COLOR.a = 1.5;
//	COLOR = mix(shadow , offset_color, 0.5);


	// ORIG senčka
//	vec2 ps = TEXTURE_PIXEL_SIZE;
//	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV -  vec2(5.0 , 5.0) * ps).a * modulate.a);
//	vec4 col = texture(TEXTURE, UV);
//
//	COLOR = mix(shadow, col, col.a);
}

//
//void vertex() {
//	VERTEX += vec2(10.0, 0.0);
//  // Animate Sprite moving in big circle around its location
//	VERTEX += vec2(cos(TIME)*1.0, sin(TIME)*1.0);
//}







//
//
//void fragment() {
//	vec2 ps = TEXTURE_PIXEL_SIZE;
//
//	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV - offset * ps).a * modulate.a);
//	vec4 col = texture(TEXTURE, UV);
//
//	COLOR = mix(shadow, col, shadow.a);
//}

//
//
//void fragment() {
//
//	// Read screen texture
////	vec4 current_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
//	vec4 current_color = texture(TEXTURE, UV, 0.0);
//
//	// Check if the current color is our background color
//	if (length(current_color - background_color) < 0.01) {
//
////		vec4 offset_color = textureLod(SCREEN_TEXTURE, SCREEN_UV - offset_in_pixels * SCREEN_PIXEL_SIZE, 0.0);
//		vec4 offset_color = texture(TEXTURE, UV - offset_in_pixels * TEXTURE_PIXEL_SIZE, 0.0);
//
//		// Check if at our offset position we have a color which is not the background (meaning here we need a shadow actually)
//		if (length(offset_color - background_color) > 0.01) {
//			// If so set it to our shadow color
//			current_color = shadow_color;
//		}
//	}
//
//	COLOR = current_color;
//}