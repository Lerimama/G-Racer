shader_type canvas_item;

// KAJ DELA?
// menja do 3 barve (nima transparentne barve, ker je nikoli ne zazna)
// ---
// pixelizira screen na barvi
// animira screen
uniform vec2 node_size = vec2(320, 320); // more bit točen, da so pixli pravih dimenzij

// pixelate
uniform bool pixelate;
//uniform vec2 node_size = vec2(640, 360);
uniform	float pixel_size_multiplier = 1.0;
uniform	vec2 pixel_offset = vec2(0.0, 0.0);
// animate
uniform float speed_x : hint_range (-10, 10) = 0;
uniform float speed_y : hint_range (-10, 10) = 0;
uniform float speed_scale : hint_range (0, 1, 0.01)= 0.1; // da ni prehitro


void fragment() {

	// pixelate
	vec2 pixelated_uvs = SCREEN_UV;
	if (pixelate == true) {
		float xFactor = float(textureSize(SCREEN_TEXTURE, 0).x) / pixel_size_multiplier; // * SCREEN_PIXEL_SIZE.x;
		float yFactor = float(textureSize(SCREEN_TEXTURE, 0).y) / pixel_size_multiplier;// * SCREEN_PIXEL_SIZE.y;
		float grid_uv_x = round(SCREEN_UV.x * xFactor + pixel_offset.x) / xFactor;
		float grid_uv_y = round(SCREEN_UV.y * yFactor + pixel_offset.y) / yFactor;
		pixelated_uvs = vec2(grid_uv_x, grid_uv_y);
	}
	
	// animate
	pixelated_uvs.x += TIME * speed_x * speed_scale;
	pixelated_uvs.y += TIME * speed_y * speed_scale;		
		
	COLOR = texture(SCREEN_TEXTURE, pixelated_uvs);
	
}