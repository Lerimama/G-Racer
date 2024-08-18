shader_type canvas_item;
//render_mode blend_;

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

uniform vec2 node_size = vec2(320.0, 320.0);
uniform vec2 screen_size = vec2(640.0, 360.0);

uniform vec4 casting_color_1: hint_color = vec4(1.0, 1.0, 1.0, 1.0); // senčena barva
uniform vec4 casting_color_2: hint_color = vec4(1.0, 0.0, 0.0, 0.0); // senčena barva
uniform vec4 casting_color_3: hint_color = vec4(0.0, 1.0, 0.0, 0.0); // senčena barva

uniform bool casting_object_is_flat = false; // ploščata alai debela senčka
uniform vec4 shadow_color: hint_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform int shadow_distance = 3; // število pixlov ... imitira dolžino sence
uniform float shadow_rotation_deg: hint_range(0.0, 360.0) = 90; // rotacija v stopinjah (dol)
uniform float pixel_scale = 1.0; // 3.0 je fajn adaptacija, da je vsak korak en pixel

uniform bool switch_cast_and_receive = false;
uniform vec4 new_casting_color: hint_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 new_receiving_color: hint_color = vec4(0.0, 0.0, 0.0, 0.0);



void fragment(){
	
	vec4 original_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	vec4 step_offset_color; // zamik teksture na korak
	vec4 offset_color; // barva vsek korakov skupaj
	
	float shadow_rotation_rad = radians(shadow_rotation_deg);
	float step_pixel_offset_y = cos(shadow_rotation_rad) ;//* pixel_scale;
	float step_pixel_offset_x = sin(shadow_rotation_rad);// * pixel_scale;
	
	float step_count = 0.0;
	
	// multiplikacija sence
	for (int i = 0; i < shadow_distance; i++) {
		
		step_count += 1.0; // štejemo korake ... pusti na ena
		
		// zamik texture v smeri (preračun texlov v pixle) ... z vsakim korakom se prišteje zamik-na-korak
		vec2 uvs;
		if (casting_object_is_flat != true){
			// če je metalec sence debel je senčka brez odmika
//			uvs = SCREEN_UV + vec2(step_pixel_offset_x / node_size.x, step_pixel_offset_y / node_size.y) * -1.0 * step_count; 
			uvs = SCREEN_UV + vec2(step_pixel_offset_x / screen_size.x, step_pixel_offset_y / screen_size.y) * -1.0 * step_count; 
		} else {
			// če je metalec sence ploščat ma senčka odmik
//			uvs = SCREEN_UV + vec2(step_pixel_offset_x * float(shadow_distance) / node_size.x, step_pixel_offset_y * float(shadow_distance) / node_size.y) * -1.0
			uvs = SCREEN_UV + vec2(step_pixel_offset_x * float(shadow_distance) / screen_size.x, step_pixel_offset_y * float(shadow_distance) / screen_size.y) * -1.0
		}
		step_offset_color = texture(SCREEN_TEXTURE, uvs); 
		
		// ne switchamo
		if (switch_cast_and_receive != true){
			// kjer je zamaknjena senčena barva, damo barvo sence
			if (length(step_offset_color - casting_color_1) < 0.01 || length(step_offset_color - casting_color_2) < 0.01 || length(step_offset_color - casting_color_3) < 0.01){
				step_offset_color = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else {
				step_offset_color.a = 0.0;
			}
		}
		// switchamo ... samo obrnemo pogoj
		else if (switch_cast_and_receive == true){
			if (length(step_offset_color - casting_color_1) > 0.01){
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
