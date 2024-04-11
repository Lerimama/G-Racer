shader_type canvas_item;


// KAJ ŠEJDER DELA?
// v prvem koraku naredi outline v eno smeri, v vsakem naslednjem pa outline zarotira za 90 stopinj
// po vseh kopiranjih na celotno nastalo senco ponovno apliciramo željeno barvo sence
// regulira debelino outileta (ki naj ne bo večja od debeline ozadja)

uniform vec4 outlined_color: hint_color = vec4(0.0, 0.0, 0.0, 1.0); // senčena barva
uniform vec4 outline_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform bool outline_is_inside = false;
uniform float outline_width_px: hint_range(0, 8, 1) = 1; // imitacija višine z odmikom celotne sence od senčenega objekta


void fragment(){
	
	vec2 screen_size = vec2(640.0, 360.0);
	float step_offset_px = 1.0;  // step width v pixlih
	
	vec4 original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0); // textura pred editiranjem
	vec4 step_offset_color; // barva zamaknjene teksture koraka
	vec4 offset_color; // barva vsek korakov skupaj
	
	float step_count = 0.0;
	
	// multiplikacija sence
	for (int i = 0; i < 4; i++) {
		
		// rotacija ... v vsakem koraku obrnemo za 90 stopinj
		float shadow_rotation_deg = step_count * 90.0;
		float shadow_rotation_rad = radians(shadow_rotation_deg);
		float step_pixel_offset_y = cos(shadow_rotation_rad) * step_offset_px;
		float step_pixel_offset_x = sin(shadow_rotation_rad) * step_offset_px;
		
		// zamik texture v smeri (preračun texlov v pixle)
		vec2 uvs = SCREEN_UV + vec2(step_pixel_offset_x / screen_size.x, step_pixel_offset_y / screen_size.y) * -1.0 * outline_width_px;
		// opredelimo barvo zamaknjene teksture
		step_offset_color = texture(SCREEN_TEXTURE, uvs); 
		
		// ne switchamo
		if (outline_is_inside != true){
			// kjer je zamaknjena senčena barva, damo barvo sence
			
			if (length(step_offset_color - outlined_color) < 0.01){
//			if (step_offset_color == outlined_color){
				step_offset_color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else {
				step_offset_color.a = 0.0;
			}
		}
		// switchamo ... samo obrnemo pogoj
		else if (outline_is_inside == true){
			if (length(step_offset_color - outlined_color) > 0.01){
//			if (step_offset_color != outlined_color){
				step_offset_color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else {
				step_offset_color.a = 0.0;
			}	
		}
		
		// dodajanje teksture korakov v skupno teksturo
		offset_color += step_offset_color; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
		
		step_count += 1.0; // dodamo korak
	}
	

	// ne switchamo
	if (outline_is_inside != true){
		// kjer je original barva enaka senčeni barvi, damo original barvo 
		if (length(original_color - outlined_color) < 0.01){
//		if (original_color == outlined_color){
			COLOR =  original_color;
			}
		// kjer skupna zamaknjena tekstura NI transparentna, damo željeno barvo sence 
		else if (offset_color.a > 0.0){
			COLOR = mix(original_color, outline_color , outline_color.a);
		}
		// kjer skupna zamaknjena tekstura JE transparentna, damo transparenco
		else{
			COLOR.a = 0.0; 
		}
	}
	// switchamo ... samo obrnemo pogoj
	else if (outline_is_inside == true) {
		if (length(original_color - outlined_color) > 0.01){
//		if (original_color != outlined_color) {
		// alfa 100%, če ne se ne vidi ...  to bom popravil, da se aplcira alpha teksture
			COLOR =  original_color; // alfa 100%, če ne se ne vidi ...  to bom popravil, da se aplcira alpha teksture
			}
		else if (offset_color.a > 0.0){
			COLOR = mix(original_color, outline_color , outline_color.a);
		}
		else{
			COLOR.a = 0.0; 
		}		
		
	}
}
