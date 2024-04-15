shader_type canvas_item;

// KAJ DELA?
// menja do 3 barve (nima transparentne barve, ker je nikoli ne zazna)
// ---
// doda noise na texturo
// pixelizira noise texturo (različne velikosti pixla)
// animira noise texturo
// noise samo na določeni barvi (če je menjava barv vključena)
// noise texture color value hue shift (ramp)
// ---
// all texture color value hue shift (ramp)
// pixelizacija je pravilna, če je vnešena točna dimenzija node texture

// colors
uniform bool change_colors;
uniform vec4 color_1: hint_color = vec4(0);
uniform vec4 new_color_1: hint_color;
uniform vec4 color_2: hint_color = vec4(0);
uniform vec4 new_color_2: hint_color;
uniform vec4 color_3: hint_color = vec4(0);
uniform vec4 new_color_3: hint_color;
uniform vec4 color_to_noise: hint_color = vec4(0);

// noise
uniform bool ad_noise; // če je change colors je zbirčen glede barve
uniform bool shade_noise;
uniform sampler2D noise;
uniform sampler2D noise_color_ramp : hint_albedo;
// pixelate
uniform bool pixelate_noise;
//uniform vec2 node_size = vec2(640, 360);
uniform	float pixel_size_multiplier = 1.0;
uniform	vec2 pixel_offset = vec2(0.0, 0.0);
// animate
uniform float speed_x : hint_range (-10, 10) = 0;
uniform float speed_y : hint_range (-10, 10) = 0;
uniform float speed_scale : hint_range (0, 1, 0.01)= 0.1; // da ni prehitro

// shading all
uniform bool shade_all_colors;
uniform sampler2D shades_color_ramp : hint_albedo;

uniform vec2 node_size = vec2(320,320);


void fragment() {


//	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0); // textura pred editiranjem
	
	// COLORS change
	if (change_colors == true){
		if (length(COLOR - color_1) < 0.01 ){COLOR = new_color_1;}
		if (length(COLOR - color_2) < 0.01 ){COLOR = new_color_2;}
		if (length(COLOR - color_3) < 0.01 ){COLOR = new_color_3;}
	}
	
	// NOISE
	if (ad_noise == true){
		
		// pixelate and animate
		vec2 noise_uvs;
		if (pixelate_noise == true) {
			// varianta, ko se pixel ne resiza z oknom igre
			float xFactor = float(node_size.x) / pixel_size_multiplier; 
			float yFactor = float(node_size.y) / pixel_size_multiplier;
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
	
			
			// noise samo na noise barvo ali povsod
			if (change_colors == true){
				if (length(COLOR - color_to_noise) < 0.01){
//				if (COLOR == color_to_noise){
					COLOR.rgb = noise_color_out;
					COLOR.a = noise_alpha_out;
				}
			} else {
			// noise je povsod
				COLOR.rgb = noise_color_out;
				COLOR.a = noise_alpha_out; //alphaIn;
			}
		} else {
		// noise brez shadinga
			// noise samo na noise barvo ali povsod
			if (change_colors == true){
				if (length(COLOR - color_to_noise) < 0.01){
//				if (COLOR == color_to_noise){
					COLOR.rgb = noise_color;
					COLOR.a = noise_alpha;
				}
			} else {
				COLOR.rgb = noise_color;
				COLOR.a = noise_alpha; //alphaIn;
			}
		}
	}
	
	// post all color shading
	if (shade_all_colors == true){
		vec3 color_in;
		float alpha_in;
		{
			vec4 TEXTURE_tex_read = COLOR;
			color_in = TEXTURE_tex_read.rgb;
			alpha_in = TEXTURE_tex_read.a;
		}
		// get the greyscale value through the highest of r, g, and b
		float color_grey_value; 
		{
			vec3 c = color_in.rgb;
			float max1 = max(c.r, c.g);
			float max2 = max(max1, c.b);
			color_grey_value = max2;
		}
		// Read the colormap and use the greyscale value to map in the new color.
		vec3 color_out;
		float alpha_out;
		{
			vec4 n_tex_read = texture(shades_color_ramp, vec2(color_grey_value, 0.0));
			color_out = n_tex_read.rgb;
			alpha_out = n_tex_read.a;
		}
		// apliciraj barvo
		COLOR.rgb = color_out;
		COLOR.a = alpha_out;
	}
	
}