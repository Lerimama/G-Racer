shader_type canvas_item;


// KAJ ŠEJDER DELA?
// v prvem koraku naredi senco, jo zamakne ... potem jo izreže, da ne prekriva original barve 
// n-krat se kopira prvi korak, z vsako kopijo se poveča foktor zamika
// senca je tako zmeraj večja (barve se prekrivajo in na čuden način mešajo transparenco)
// po vseh kopiranjih na celotno nastalo senco ponovno apliciramo željeno barvo sence
// končno barvo senčenega objekta ali ozadja lahko poljubno nastavimo
// zaenkrat primeren predvsem za dvobarvno teksturo

// UPGRADE
// - multi barve
// - automatske mere ekrana
// - usklajevanje št. korakov s svetlostjo teksture

uniform vec4 casting_color_1: hint_color = vec4(1.0, 1.0, 1.0, 1.0); // senčena barva
uniform vec4 casting_color_2: hint_color = vec4(1.0, 0.0, 0.0, 0.0); // senčena barva
uniform vec4 casting_color_3: hint_color = vec4(0.0, 1.0, 0.0, 0.0); // senčena barva

uniform vec4 shadow_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform bool switch_cast_and_receive = false;
uniform vec4 new_casting_color: hint_color = vec4(0.0, 0.0, 0.0, 0.0);
//uniform vec4 shadow_receiving_color: hint_color = vec4(1.0, 1.0, 0.0, 1.0); // barva, ki sprejema senco ... trenutno ni v uporabi
uniform vec4 new_receiving_color: hint_color = vec4(0.0, 0.0, 0.0, 0.0);

uniform float shadow_rotation_deg: hint_range(0.0, 360.0) = 180; // rotacija v stopinjah (dol)
uniform float shadow_distance_px: hint_range(0.0, 640.0, 1.0) = 0.0; // imitacija višine z odmikom celotne sence od senčenega objekta

uniform int offset_steps = 3; // število korakov ... imitira dolžino sence
uniform float step_to_px: hint_range(0.0, 1.0) = 1.0; // offset per step v pixlih

//uniform vec2 screen_size = vec2(640.0, 360.0);

void fragment(){
	
//	vec4 new_shadow_receiving_color = vec4(0.0, 0.0, 0.0, 0.0);
	vec2 screen_size = vec2(640.0, 360.0);

	vec4 original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
//	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV); // textura pred editiranjem
	vec4 step_offset_color; // zamik teksture na korak
	vec4 offset_color; // barva vsek korakov skupaj
	
	float shadow_rotation_rad = radians(shadow_rotation_deg);
	float step_pixel_offset_y = cos(shadow_rotation_rad) * step_to_px;
	float step_pixel_offset_x = sin(shadow_rotation_rad) * step_to_px;
	
	float step_count = 0.0;
	
	// multiplikacija sence
	for (int i = 0; i < offset_steps; i++) {
		
		step_count += 1.0; // štejemo korake ... pusti na ena
		
		// zamik texture v smeri (preračun texlov v pixle) ... z vsakim korakom se prišteje zamik-na-korak
		vec2 uvs = SCREEN_UV + vec2(step_pixel_offset_x / screen_size.x, step_pixel_offset_y / screen_size.y) * -1.0 * step_count; 
		
		// opredelimo barvo zamaknjene tekstue in jo premaknemo še za željeno oddaljenost teksture (preračunano v pixle)
		step_offset_color = texture(SCREEN_TEXTURE, uvs + vec2(step_pixel_offset_x * shadow_distance_px / screen_size.x, step_pixel_offset_y * shadow_distance_px / screen_size.y) * -1.0); 
		
		// ne switchamo
		if (switch_cast_and_receive != true){
			// kjer je zamaknjena senčena barva, damo barvo sence
			if (length(step_offset_color - casting_color_1) < 0.01 || length(step_offset_color - casting_color_2) < 0.01 || length(step_offset_color - casting_color_3) < 0.01){
//			if (step_offset_color == casting_color_1 || step_offset_color == casting_color_2 || step_offset_color == casting_color_3){
				step_offset_color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else {
				step_offset_color.a = 0.0;
			}
		}
		// switchamo ... samo obrnemo pogoj
		else if (switch_cast_and_receive == true){
			if (length(step_offset_color - casting_color_1) > 0.01){
//			if (step_offset_color != casting_color_1  /*&& original_color != casting_color_2 && original_color != casting_color_3*/){
				step_offset_color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else {
				step_offset_color.a = 0.0;
			}	
		}
		
		// dodajanje teksture korakov v skupno teksturo
		offset_color += step_offset_color; // barve se čudno mešajo ... zato dodam pravo barvo sence kasneje
	}
	
	
	// FINAL COLOR 
	
	// ne switchamo
	if (switch_cast_and_receive != true){
		// kjer je original barva enaka senčeni barvi, damo original barvo 
		if (length(original_color - casting_color_1) < 0.01 || length(original_color - casting_color_2) < 0.01 || length(original_color - casting_color_3) < 0.01){
//		if (original_color == casting_color_1 || original_color == casting_color_2 || original_color == casting_color_3){
		// alfa 100%, če ne se ne vidi ...  to bom popravil, da se aplcira alpha teksture	
			COLOR =  new_casting_color;
			}
		// kjer skupna zamaknjena tekstura NI transparentna, damo željeno barvo sence 
		else if (offset_color.a > 0.0){
			COLOR = mix(new_receiving_color, shadow_color , shadow_color.a);
		}
		// kjer skupna zamaknjena tekstura JE transparentna, damo željeno barvo ozadja
		else{
			COLOR = new_receiving_color; 
		}
	}
	// switchamo ... samo obrnemo pogoj
	else if (switch_cast_and_receive == true) {
		if (length(original_color - casting_color_1) > 0.01){
//		if (original_color != casting_color_1  && original_color != casting_color_2 && original_color != casting_color_3) {
		// alfa 100%, če ne se ne vidi ...  to bom popravil, da se aplcira alpha teksture
			COLOR =  new_casting_color; // alfa 100%, če ne se ne vidi ...  to bom popravil, da se aplcira alpha teksture
			}
		else if (offset_color.a > 0.0){
			COLOR = mix(new_receiving_color, shadow_color , shadow_color.a);
		}
		else{
			COLOR = new_receiving_color; 
		}		
		
	}
}
