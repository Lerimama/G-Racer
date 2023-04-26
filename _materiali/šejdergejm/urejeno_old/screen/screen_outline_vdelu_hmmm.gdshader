shader_type canvas_item;


// KAJ ŠEJDER DELA?
// v prvem koraku naredi otline v eno smeri, v vsakem naslednjem pa outline zarotira za 90 stopinj
// po vseh kopiranjih na celotno nastalo senco ponovno apliciramo željeno barvo sence
// regulira debelino outileta (ki naj ne bo večja od debeline ozadja)

uniform vec4 outlined_color: hint_color = vec4(0.0, 0.0, 0.0, 1.0); // senčena barva
uniform vec4 outline_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform float outline_width_px: hint_range(0, 100, 1) = 1.0; // imitacija višine z odmikom celotne sence od senčenega objekta
uniform float new_outline_steps: hint_range(0, 100, 1) = 1.0; // imitacija višine z odmikom celotne sence od senčenega objekta
uniform int step_count_max = 5;
uniform int minus = 0;

const vec2 FOUR_SIDES[4] = {
	
	vec2(0, -1), // w
	vec2(0, 1), // e
	vec2(1, 0), // n
	vec2(-1, 0) // s
};

const vec2 XTRA_SIDES[8] = {
	
	vec2(0, -1), // w
	vec2(0, 1), // e
	vec2(1, 0), // n
	vec2(-1, 0), // s

	vec2(1, 1), // nw
	vec2(-1, 1), // ne
	vec2(1, -1), // wn
	vec2(-1, -1) // ws

//	vec2(1, 1), // nw
//	vec2(-1, 1), // ne
//	vec2(1, -1), // wn
//	vec2(-1, -1) // ws

//	vec2(1, 0),
//	vec2(1, -1),
//	vec2(1, 1),
//	vec2(-1, 0),
//	vec2(-1, -1),
//	vec2(-1, 1),
////	vec2(0, 0),
//	vec2(0, -1),
//	vec2(0, 1)

};

void fragment(){
	
			
	vec4 gradient_color1 = vec4(1.0);
	vec4 gradient_color2 = vec4(0.0, 0.0, 0.0, 1.0); 
	
	vec4 gradient = smoothstep(0.3, 0.3, gradient_color1);

	vec2 screen_size = vec2(640.0, 360.0);
	float step_offset_px = 1.0;  // step width v pixlih
	
	vec4 original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0); // textura pred editiranjem
	
	vec4 step_offset_color; // barva zamaknjene teksture koraka
	vec4 offset_color; // barva vsek korakov skupaj
	vec4 one_side_color; // barva zamaknjene teksture koraka
	vec4 four_sides_color; // barva vsek korakov skupaj
	vec4 all_color;
	
	const int step_count = 0;
//	int step_count_max = 5;
	
	
//	int all_together = FOUR_SIDES.length() * step_count;
	
//	for (int st = 1; st < step_count_max; st++) {
//
////		// multiplikacija na 4 strani v GDQuest
////		vec4 GDQ_original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
////		float alpha = -4.0 * GDQ_original_color.a;
////		alpha += texture(TEXTURE, UV + vec2(0.1, 0.0)).a;
////		alpha += texture(TEXTURE, UV + vec2(-0.1, 0.0)).a;
////		alpha += texture(TEXTURE, UV + vec2(0.0, 0.1)).a;
////		alpha += texture(TEXTURE, UV + vec2(0.0, -0.1)).a;
////		COLOR = vec4(outline_color.rgb, alpha);
//
//
//		// multiplikacija na 4 strani
//		for (int i = 0; i < FOUR_SIDES.length(); i++) {
//
//			// original barvo premaknemo za en pixel 
//			vec2 uvs = SCREEN_UV + vec2(FOUR_SIDES[i] / screen_size) * outline_width_px * float(st) ;
//			one_side_color = texture(SCREEN_TEXTURE, uvs ); 
//
//			// barva ene strani != outilined barva ... damo outline barvo
//			if (length(one_side_color - outlined_color) < 0.01){
//				one_side_color = outline_color;
//			}
//			// barva ene strani == outilined barva ... damo transparetno outline barvo
//			else {
//				one_side_color.a = 0.0;
//			}
//
//			// dodajanje teksture korakov v skupno teksturo
//			four_sides_color += one_side_color; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
////			four_sides_color += one_side_color + vec4(0.0, 0.0, 0.0, 0.1); // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
////			four_sides_color.a -= one_side_color.a; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
//		}
//
//		all_color += four_sides_color;
//
//	// širjenje ... z vsakim korakom večjim od ena naredimo vmesno kopijo 
//
////			vec4 add_one_side_color;
//
//
//
//	}
	
	

	// PO 4 korakih
	
	int temp_step_count_max = 7;
	
	for (int st = 1; st < step_count_max; st++) {
		
		// multiplikacija na 4 strani
		for (int i = 0; i < XTRA_SIDES.length(); i++) {
			
			if (i < 4){
				// original barvo premaknemo za en pixel 
				vec2 uvs = SCREEN_UV + vec2(XTRA_SIDES[i] / screen_size) * float(st) ;
				one_side_color = texture(SCREEN_TEXTURE, uvs); 
			}
			else {
				// original barvo premaknemo za en pixel 
				vec2 uvs = SCREEN_UV + vec2(XTRA_SIDES[i] / screen_size) * float(st - minus) ;
				one_side_color = texture(SCREEN_TEXTURE, uvs); 
			}			
			
				
			// barva ene strani != outilined barva ... damo outline barvo
			if (length(one_side_color - outlined_color) < 0.01){
//				one_side_color += xtra_side_color;
				one_side_color = outline_color;
			}
			// barva ene strani == outilined barva ... damo transparetno outline barvo
			else {
				one_side_color.a = 0.0;
			}

			// dodajanje teksture korakov v skupno teksturo
			four_sides_color += one_side_color; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
//			four_sides_color += one_side_color + vec4(0.0, 0.0, 0.0, 0.1); // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
//			four_sides_color.a -= one_side_color.a; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
		}
	
		all_color += four_sides_color;
			
	}




	// FINAL COLOR 
	
	// kjer je original barva enaka senčeni barvi, damo original barvo 
	if (length(original_color - outlined_color) < 0.01){
//		if (original_color == outlined_color){
		COLOR =  original_color;
		}
	// kjer skupna zamaknjena tekstura NI transparentna, damo željeno barvo sence 
	else {
//	else if (four_sides_color.a > 0.0){
//			COLOR = mix(original_color, outline_color , outline_color.a);
//		COLOR = four_sides_color;
		COLOR = all_color;
	}
	// kjer skupna zamaknjena tekstura JE transparentna, damo transparenco
//	else{
//		COLOR.a = 0.0; 
//	}
}
