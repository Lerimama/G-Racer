shader_type canvas_item;

// KAJ DELA ŠEJDER
// manipulira do 3 barve in vse preostale barve
// če barva ni izbrana za manipulirat, je enaka original teksturi
// kar je transparentno, ostane transparentno oz. lahko določiš svojo barvo


// barve za manipulirat
uniform vec4 manipulate_color_1 : hint_color = vec4(1.0, 0.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_1 : hint_color = vec4(1.0, 1.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 manipulate_color_2 : hint_color = vec4(0.0, 1.0, 0.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_2 : hint_color = vec4(0.0, 1.0, 1.0, 1.0); // select color to regirster and manipulate
uniform vec4 manipulate_color_3 : hint_color = vec4(0.0, 0.0, 1.0, 1.0); // select color to regirster and manipulate
uniform vec4 new_color_3 : hint_color = vec4(1.0, 0.0, 1.0, 1.0); // select color to regirster and manipulate

// če želim manipulirat barvo preostalih barv
uniform bool manipulate_other = false;
uniform vec4 new_color_other : hint_color = vec4(0.5, 0.5, 0.5, 1.0); // select color to regirster and manipulate

// če želim manipulirat barvo preostalih barv
uniform bool manipulate_all = false; 
uniform vec4 new_color_manipulate_all : hint_color = vec4(0.5, 0.5, 0.5, 1.0); // select color to regirster and manipulate

uniform vec4 transparent_to_color : hint_color = vec4(0.0, 0.0, 0.0, 0.0); // apply color to texture with alpha 0.0


void fragment(){

	// poberemo prikaz texture in apliciramo samo offset še predno apliciramo barvo 
	vec4 color = texture(TEXTURE, UV);
	
	// kjer je prisotna barva
	if (color.a > 0.0){
		
		// če manipuliramo vse barve
		if (manipulate_all == true){
			color = new_color_manipulate_all * color.a;
		}
		// če manipuliramo izbrane barve
		else {
			// tri izbrane barve
			if (color == manipulate_color_1 ){
				color = new_color_1 * color.a;
			}
			else if (color == manipulate_color_2){
				color = new_color_2 * color.a;
			}
			else if (color == manipulate_color_3){
				color = new_color_3 * color.a;
			}
			// vse preostale barve
			else {
				// če je možnost vključena dodaj novo barvno
				if(manipulate_other == true){
					color = new_color_other;
				}
				// drugače pa original barvo
				else {
					color = texture(TEXTURE, UV);
					// color.a = 0.0; // 100% transparenca
				}
			}
		}
	// kjer je barva transparentna
	else if (color.a == 0.0) {
		color = transparent_to_color;
	}

	COLOR = color;
}