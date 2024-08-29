shader_type canvas_item;

// KAJ DELA?
// menja do 3 barve (nima transparentne barve, ker je nikoli ne zazna)
// ---
// all texture color value hue shift (ramp)

// colors
uniform bool change_colors;
uniform vec4 color_1: hint_color = vec4(0);
uniform vec4 new_color_1: hint_color;
uniform vec4 color_2: hint_color = vec4(0);
uniform vec4 new_color_2: hint_color;
uniform vec4 color_3: hint_color = vec4(0);
uniform vec4 new_color_3: hint_color;
uniform vec4 color_to_noise: hint_color = vec4(0);

// shading all
uniform bool shift_colors;
uniform sampler2D shades_color_ramp : hint_albedo;


void fragment() {


//	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0); // textura pred editiranjem
	
	// COLORS change
	if (change_colors == true){
		if (length(COLOR - color_1) < 0.01 ){COLOR = new_color_1;}
		if (length(COLOR - color_2) < 0.01 ){COLOR = new_color_2;}
		if (length(COLOR - color_3) < 0.01 ){COLOR = new_color_3;}
	}
	
	// post all color shading
	if (shift_colors == true){
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