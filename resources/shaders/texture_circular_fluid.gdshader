shader_type canvas_item;
render_mode blend_add;


uniform float intensity = 0.5f;
uniform float layers = 5.0f;
uniform float speed = 4.0f;

uniform vec4 color_to_cut = vec4(1.0, 1.0, 1.0, 1.0);
//uniform vec4 color_to_cut: hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_to_add: hint_color = vec4(1.0, 0.0, 0.0, 1.0);

//uniform sampler2D svetlost: hint_white;

float gradient(vec2 uv){
	
	// čekiramo razdaljo od centra sprajta do koordinate trenutne pike
	return (0.5f - distance(vec2(uv.x, uv.y), vec2(0.5f, 0.5f))); // nastane krog, ker je razdalja od centra konstantna
}

vec4 colorize (float col, float a) {
	
	vec4 pallete;
	
//	// grayscale
	pallete = vec4(col, col, col, a);  // col je podan red kanal
	
//	// monochrome
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col >= 0.0f); // en kanal setamo, da je ves čas 0, razen ko je poln (? ... full je white?)
//
////
//////	// darken vse kar ni belo
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
//	pallete.g = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
//	pallete.b = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
	
//	// raznobarvno
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.3 && col < 0.7 || col > 0.9); 
//	pallete.g = float(col > 0.7); // višja vrednost od dveh ...?
//	pallete.b = float(col > 0.5 || col > 0.9); // višja vrednost od dveh ...?
	
//	// ta bi bila za ščit
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.3); // višja vrednost od dveh ...?
//	pallete.g = float(col > 0.3); // višja vrednost od dveh ...?
//	pallete.b = float(col > 0.3); // višja vrednost od dveh ...?
	
////	// by lerimama
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.0f); // en kanal setamo, da je ves čas 0, razen ko je poln (? ... full je white?)
//	pallete.rb = vec2(1.0);
	
	return pallete; // ta vrednost gre v barvo
}


void fragment(){
	vec4 bg = texture(TEXTURE, UV - TIME/speed); // tukjaj je že notri premikanje
	
	COLOR = bg;
	COLOR.r = gradient(UV); // red kanal damo rezultat gradient funkcije 
	
	// množimo oz. združimo red channel z intensity in teksturo noisa
	COLOR.r = clamp(COLOR.r * bg.r * intensity * 10.0f, 0.0f, 1.0f); // klempam, da ne gre pod nulo in ne nad ena (ker je to barvni kanal)
	// current color * intensity
	COLOR.r = floor(COLOR.r * layers) / layers; // floor ... zaokrožimo zato, ker ker je št. lejerja zmeraj cela številka ... delimo z lejerji, da je vsak lejer na 0.2 vrednosti
	COLOR.a = float(COLOR.r > 0.0f); // ?

	vec4 color = colorize(COLOR.r, COLOR.a); // igranje z barvami
	
	if (color == color_to_cut){
		color.a = 0.0;
	}
	else {
		// invert colos
		color.rgb = vec3(1.0,1.0,1.0) - color.rgb ;
		
//		COLOR.rgb = color.rgb;
	}
	
	
	vec4 color2 = vec4 (1.0);
	
	
//	barva je transparenta
	if (color.a == 0.0){
		
	}
//	barva je polna
	else{
		color2 = color * color_to_add;
//		color2.rgb = vec3(1,1,1) - color.rgb; // invert colors
		COLOR.rgb = color2.rgb;
		COLOR.a = color2.a;
	}
	
	
	
}