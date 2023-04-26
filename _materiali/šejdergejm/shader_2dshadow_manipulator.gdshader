shader_type canvas_item;

// šejder v1 - prepoznava 100% transparenco in aplicira novo barvo na te pixle
// šejder v2 - prepoznava tudi cutout barvo, ki jo potem manipulira
// šejder v3 - prepoznava barvo, ki ji mora dodat senco
// šejder v4 - prepoznava različne barve, ki jim dodaj različne sence
// šejder v5 - dodaja sence za prizemljene objekte

//... simple nadgradnja je če dodam več barv za manipulirat ... al pa celo gradient

// barve
uniform vec4 manipulate_color : hint_color = vec4(1.0, 0.0, 0.0, 1.0); // select color to regirster and manipulate
uniform bool manipulate_other_colors = true;
uniform vec4 transparent_to_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0

// shadow
uniform vec4 shadow_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float shadow_offset_x = 1.0; // smer offseta ... to niso texli ampak pixli
uniform float shadow_offset_y = 1.0; // smer offseta ... to niso texli ampak pixli
uniform float texture_altitude = 5.0; // količina offseta ... višin texture

// dimenzija teksture za uskladitev texlov s pixli (1/texture original size)  
uniform float texture_width = 640.0;
uniform float texture_height = 360.0;



void fragment(){

	// preračun pravge offseta sence ... pixle konvertamo v texle
	vec2 shadow_offset = vec2(shadow_offset_x / texture_width, shadow_offset_y / texture_height);
	vec2 uvs = UV + shadow_offset * texture_altitude;
	
	// poberemo prikaz texture in apliciramo samo offset še predno apliciramo barvo 
	vec4 color = texture(TEXTURE, uvs);

	
	// manipuliramo izbrano barvo
	if (manipulate_other_colors == false){
		
		// če je barva texture enaka izbrani apliciramo efekt
		if (color == manipulate_color){
			color = shadow_color * color.a;
		}
		// druge barve so brez efekta
		else {
			color.a = 0.0; // 100% transparenca
			color = texture(TEXTURE, UV); // original barva in pozicija
		}
	}
	
	// manipuliramo vse razen izbrane barve
	else if (manipulate_other_colors == true){
		
		// če barva texture ni transparenta apliciramo efekt
		if (color.a > 0.0){
			
			// barva enaka izbrani barvi je brez efekta
			if (color == manipulate_color){
				color.a = 0.0;
				color = texture(TEXTURE, UV);
			}
			// aplciramo efekt na vse druge barve
			else {
				color = shadow_color * color.a;
			}
		}
		// barva transparentnega dela tekture
		else {
			color = transparent_to_color;
		}
		
	}
	
	COLOR = color;
}