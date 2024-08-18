shader_type canvas_item;

// KAJ DELA?
// pixelizacija je pravilna, če je vnešena točna dimenzija node texture

uniform vec2 node_size = vec2(320, 320); // more bit točen, da so pixli pravih dimenzij

// pixelate
uniform bool pixelate;
uniform	float pixel_size_multiplier = 1.0;
uniform	vec2 pixel_offset = vec2(0.0, 0.0);
// animate
uniform float speed_x : hint_range (-10, 10) = 0;
uniform float speed_y : hint_range (-10, 10) = 0;
uniform float speed_scale : hint_range (0, 1, 0.01) = 0.1; // da ni prehitro

void fragment() {

//	COLOR = texture(TEXTURE, UV);
		
	// pixelate
	vec2 pixelated_uvs;
	if (pixelate == true) {
		float xFactor = node_size.x / pixel_size_multiplier;
		float yFactor = node_size.y / pixel_size_multiplier;
		float grid_uv_x = round(UV.x * xFactor + pixel_offset.x) / xFactor;// + TIME * speed_x * speed_scale;
		float grid_uv_y = round(UV.y * yFactor + pixel_offset.y) / yFactor;// + TIME * speed_y * speed_scale;
		pixelated_uvs = vec2(grid_uv_x, grid_uv_y);
	} 
	
	// animate
	pixelated_uvs.x += TIME * speed_x * speed_scale;
	pixelated_uvs.y += TIME * speed_y * speed_scale;			
	
	COLOR = texture(TEXTURE, pixelated_uvs);
		
	
}