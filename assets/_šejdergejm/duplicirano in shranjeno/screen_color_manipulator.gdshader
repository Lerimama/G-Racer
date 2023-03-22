shader_type canvas_item;
render_mode blend_mix;

// šejder v1 - prepoznava 100% transparenco in aplicira novo barvo na te pixle
// šejder v2 - prepoznava tudi cutout barvo, ki jo potem manipulira
// šejder v3 - prepoznava barvo, ki ji mora dodat senco
// šejder v4 - prepoznava različne barve, ki jim dodaj različne sence
// šejder v5 - dodaja sence za prizemljene objekte

//... simple nadgradnja je če dodam več barv za manipulirat ... al pa celo gradient

// barve
uniform vec4 manipulate_color_1 : hint_color = vec4(1.0, 0.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_1 : hint_color = vec4(1.0, 1.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 manipulate_color_2 : hint_color = vec4(0.0, 1.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_2 : hint_color = vec4(0.0, 1.0, 1.0, 1.0); // select color to regirster and manipulate
uniform vec4 manipulate_color_3 : hint_color = vec4(0.0, 0.0, 1.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_3 : hint_color = vec4(1.0, 0.0, 1.0, 1.0); // select color to regirster and manipulate

uniform bool manipulate_other = false;
uniform vec4 new_color_other : hint_color = vec4(0.5, 0.5, 0.5, 1.0); // select color to regirster and manipulate

uniform vec4 transparent_to_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0
uniform vec4 transparent_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0


void fragment(){

	// poberemo prikaz texture in apliciramo samo offset še predno apliciramo barvo 
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

	
	// manipuliramo izbrane barve
	if (manipulate_other == false){
		
		// če je barva texture enaka izbrani apliciramo novo (s transparenco)
		if (color == manipulate_color_1 ){
			color = new_color_1 * color.a;
		}
		else if (color.rgb == manipulate_color_2.rgb){
			color.rgb = new_color_2.bgr;
			
			float white_level = 0.5; 
			color.rgb = vec3(white_level);
			color.a = white_level
		
		}
		else if (color == manipulate_color_3){
			color = new_color_3 * color.a;
		}
		
		// druge barve so brez efekta
		else {
			color.a = 0.0; // 100% transparenca
//			color = texture(TEXTURE, UV); // original barva in pozicija
		}
	}
	
	// manipuliramo vse druge barve
	else if (manipulate_other == true){
		
		// če barva texture ni transparenta apliciramo efekt
		if (color.a > 0.0){
			
			// barva enaka izbrani barvi je brez efekta
			if (color == manipulate_color_1){
				color.a = 0.0;
			}
			else if (color == manipulate_color_2){
				color.a = 0.0;
			}
			else if (color == manipulate_color_3){
				color.a = 0.0;
			}
			
			// aplciramo prvo barve efekt na vse druge barve
			else {
				color = new_color_other * color.a;
			}
		}
		// barva transparentnega dela tekture
		else {
			color = transparent_to_color;
		}
		
	}
	
	COLOR = color;
}