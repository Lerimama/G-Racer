shader_type canvas_item;

// KAJ DELA?
// menja do 3 barve
// menja barvo za prosojnost
// ---
// doda noise na texturo
// pixelizira noise texturo (različne velikosti pixla)
// animira noise texturo
// noise samo na določeni barvi (če je menjava barv vključena)
// noise texture color value hue shift (ramp)
// ---
// all texture color value hue shift (ramp)
// pixelizacija je pravilna, če je vnešena točna dimenzija node texture
// BUG
// barve izbira avtomatsko samo na črni in beli ... ostale delajo šele, če je izbran med predvajanjem scene


uniform vec2 node_size = vec2(320, 320); // more bit točen, da so pixli pravih dimenzij

// noise
uniform sampler2D noise;
uniform bool shade_noise;
uniform sampler2D noise_color_ramp : hint_albedo;
// pixelate
uniform bool pixelate_noise;
uniform	float pixel_size_multiplier = 1.0;
uniform	vec2 pixel_offset = vec2(0.5, 0.5);
// animate
uniform float speed_x : hint_range (-10, 10) = 0;
uniform float speed_y : hint_range (-10, 10) = 0;
uniform float speed_scale : hint_range (0, 1, 0.01)= 0.1; // da ni prehitro


void fragment() {

	COLOR = texture(TEXTURE, UV);

	// pixelate and animate
	vec2 noise_uvs;
	if (pixelate_noise == true) {
		float xFactor = node_size.x / pixel_size_multiplier;
		float yFactor = node_size.y / pixel_size_multiplier;
		float grid_uv_x = round(UV.x * xFactor + pixel_offset.x) / xFactor + TIME * speed_x * speed_scale;
		float grid_uv_y = round(UV.y * yFactor + pixel_offset.y) / yFactor + TIME * speed_y * speed_scale;
		noise_uvs = vec2(grid_uv_x, grid_uv_y);
	} else {
	// animate
		noise_uvs.x = UV.x + TIME * speed_x * speed_scale;
		noise_uvs.y = UV.y + TIME * speed_y * speed_scale;			
	}
	
	vec4 noise_texture = texture(noise, noise_uvs);			
	vec3 noise_color = noise_texture.rgb;
	float noise_alpha = noise_texture.a; 
	
	// shade noise 
	if (shade_noise == true){
		
		float color_value;
		// get the greyscale value through the highest of r, g, and b
		{
			vec3 c = noise_color.rgb;
			float max1 = max(c.r, c.g);
			float max2 = max(max1, c.b);
			color_value = max2;
		}
		
		vec3 noise_color_out; 
		float noise_alpha_out;
		// Read the colormap and use the greyscale value to map in the new color.
		{
			vec4 n_tex_read = texture(noise_color_ramp, vec2(color_value, 0.0));
			noise_color_out = n_tex_read.rgb;
			noise_alpha_out = n_tex_read.a;
		}
		
		// noise je povsod
		COLOR.rgb = noise_color_out;
		COLOR.a = noise_alpha_out; //alphaIn;
		
		
	} //else {
	// noise brez shadinga
	COLOR.rgb = noise_color;
	COLOR.a = noise_alpha; //alphaIn;
//	}
	
}