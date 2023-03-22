shader_type canvas_item;
render_mode blend_mix;

// KAJ DELA ŠEJDER?
// skrine šejder transparence ne pozna, lahko pa mu jo opredelimo z barvo transparetnega ozadja ali barvo, ki jo manipuliramo
// kromakey off omogoča maskanje vseh barv razen izbrane barve ... 
// kromakey on omogoča maskanje izbrane barve ...

uniform vec4 chromakey_color : hint_color = vec4(1.0); // barva označuje območje manipulacije
uniform bool chromakey_other_colors = true; // opredelimo ali manipuliramo chromakey barvo, ali ostale
uniform vec4 new_color_keyed : hint_color = vec4(1.0, 1.0, 0.0, 1.0); // če je barva transparentna se kaže original tekstura
uniform vec4 new_color_nonkeyed : hint_color = vec4(0.0, 1.0, 0.5, 0.5); // če je barva transparentna se kaže original tekstura


void fragment(){
	
	// grebamo barvo original teksture
	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	float alpha = original_color.a;
	vec3 calculated_color_rgb = original_color.rgb;
	
	// maskanje izbrane barve
	if (chromakey_other_colors != true){
		// kjer original barva JE enaka izbrani barvi, barvamo z izbrano barvo
		if (original_color == chromakey_color){
			
			calculated_color_rgb = new_color_keyed.rgb; // barvamo v izbrano barvo
			alpha = new_color_keyed.a; // damo alpha nove barve
		}
		// kjer barve NISO enake izbrani barvi, damo barvo "other
		else {
			calculated_color_rgb = new_color_nonkeyed.rbg;
			alpha = new_color_nonkeyed.a; //
		}
	// maskanje ostalih barv
	else if (chromakey_other_colors == true){
		// kjer original barva NI enaka izbrani barvi, barvamo z izbrano barvo
		if (original_color == chromakey_color){
			calculated_color_rgb = new_color_nonkeyed.rgb; 
			alpha = new_color_nonkeyed.a;
		}
		// kjer barva JE enaka izbrani, damo barvo "other"
		else {
//			calculated_color_rgb =  texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
			calculated_color_rgb = new_color_keyed.rgb;
			alpha = new_color_keyed.a;
		}
	}

//		vec3 original_color_rgb = original_color.rgb;
//		float alpha = original_color.a;

	COLOR = vec4(calculated_color_rgb, alpha);
	
}


//uniform bool manipulate_other_colors = true;
//uniform vec4 transparent_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0
//uniform vec4 transparent_new_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0
//
//// shadow
//uniform vec4 shadow_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
//uniform vec2 shadow_offset_direction = vec2(1.0, 1.0); // smer offseta ... to niso texli ampak pixli
////uniform float shadow_offset_x = 1.0; // smer offseta ... to niso texli ampak pixli
////uniform float shadow_offset_y = 1.0; // smer offseta ... to niso texli ampak pixli
//uniform float texture_altitude = 5.0; // količina offseta ... višin texture
//
//// dimenzija teksture za uskladitev texlov s pixli (1/texture original size)  
//uniform float texture_width = 640.0;
//uniform float texture_height = 360.0;
