shader_type canvas_item;


uniform vec4 outlined_color: hint_color = vec4(0.0, 0.0, 0.0, 1.0); // senčena barva
uniform vec4 outline_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform int outline_px_width: hint_range(0, 4, 1) = 1; // imitacija višine z odmikom celotne sence od senčenega objekta

uniform bool outline_is_inside = false;


const vec2 FOUR_SIDES[4] = {
	vec2(0, -1),
	vec2(0, 1),
	vec2(1, 0),
	vec2(-1, 0)
};

void fragment(){

	vec2 screen_size = vec2(640.0, 360.0);
	
	vec4 original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	vec4 one_side_color;
	vec4 four_sides_color;
	vec4 all_slides_color;
	
	// koraki za dodajanje debeline
	for (int width_steps = 0; width_steps < outline_px_width; width_steps++) {

		// multiplikacija na 4 strani
		for (int side = 0; side < FOUR_SIDES.length(); side++) {

			// original barvo premaknemo za en pixel 
			vec2 uvs = SCREEN_UV + vec2(FOUR_SIDES[side] / screen_size) * float(outline_px_width) ;
			one_side_color = texture(SCREEN_TEXTURE, uvs ); 
			
			if (outline_is_inside != true){
				// barva ene strani != outilined barva ... damo outline barvo
				if (length(one_side_color - outlined_color) < 0.01){
					one_side_color = outline_color;
				}
				// barva ene strani == outilined barva ... damo transparetno outline barvo
				else {
					one_side_color.a = 0.0;
				}
			}
			else {
				// barva ene strani != outilined barva ... damo outline barvo
				if (length(one_side_color - outlined_color) > 0.01){
					one_side_color = outline_color;
				}
				// barva ene strani == outilined barva ... damo transparetno outline barvo
				else {
					one_side_color.a = 0.0;
				}
			}			
			
			
			// dodajanje teksture korakov v skupno teksturo
			four_sides_color += one_side_color; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
		}
		all_slides_color += four_sides_color;
	}

	// FINAL COLOR 
	
	
	if (outline_is_inside != true){
		// kjer je original barva enaka senčeni barvi, damo original barvo 
		if (length(original_color - outlined_color) < 0.01){
			COLOR =  original_color;
			}
		// kjer skupna zamaknjena tekstura NI transparentna, damo željeno barvo sence 
		else if (all_slides_color.a > 0.0){
			COLOR = mix(original_color, outline_color , outline_color.a);
		}
		// kjer skupna zamaknjena tekstura JE transparentna, damo transparenco
		else{
			COLOR.a = 0.0; 
		}
	}
	else {
		// kjer je original barva enaka senčeni barvi, damo original barvo 
		if (length(original_color - outlined_color) > 0.01){
			COLOR =  original_color;
			}
		// kjer skupna zamaknjena tekstura NI transparentna, damo željeno barvo sence 
		else if (all_slides_color.a > 0.0){
			COLOR = mix(original_color, outline_color , outline_color.a);
		}
		// kjer skupna zamaknjena tekstura JE transparentna, damo transparenco
		else{
			COLOR.a = 0.0; 
		}
	}
}
