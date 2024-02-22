shader_type canvas_item;
//render_mode unshaded;
render_mode blend_add;

uniform float noise_intensity = 0.0f;
uniform int noise_layers = 5;   // deluje mi bolje
//uniform float noise_layers = 5.0f;
uniform float noise_speed = 4.0f;

uniform bool inverse_output = false;
uniform vec4 colorize: hint_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 color_to_cut: hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float color_intensity = 1.0;
uniform vec2 texture_size = vec2(48.0, 48.0);


float gradient(vec2 uv){
	// čekiramo razdaljo od centra sprajta do koordinate trenutne pike
	return (0.5f - distance(vec2(uv.x, uv.y), vec2(0.5f, 0.5f))); // nastane krog, ker je razdalja od centra konstantna
}

vec4 zaloga_colorize (float col, float a) {
// tole gre v fragment ...	vec4 color = colorize(COLOR.r, COLOR.a); // igranje z barvami	
	vec4 pallete;
	
	// grayscale
	pallete = vec4(col, col, col, a);  // col je podan red kanal
	
	// monochrome
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col >= 0.0f); // en kanal setamo, da je ves čas 0, razen ko je poln (? ... full je white?)

	// darken vse kar ni belo
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
//	pallete.g = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
//	pallete.b = max(float(col >= 1.0f), col / 3.0f); // višja vrednost od dveh ...?
	
	// raznobarvno
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.3 && col < 0.7 || col > 0.9); 
//	pallete.g = float(col > 0.7); // višja vrednost od dveh ...?
//	pallete.b = float(col > 0.5 || col > 0.9); // višja vrednost od dveh ...?
	
	// ta bi bila za ščit
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.3); // višja vrednost od dveh ...?
//	pallete.g = float(col > 0.3); // višja vrednost od dveh ...?
//	pallete.b = float(col > 0.3); // višja vrednost od dveh ...?
	
	// by lerimama
//	pallete = vec4(col, col, col, a);  // col je podan red kanal
//	pallete.r = float(col > 0.0f); // en kanal setamo, da je ves čas 0, razen ko je poln (? ... full je white?)
//	pallete.rb = vec2(1.0);
	
	return pallete; // ta vrednost gre v barvo
}

void fragment(){
	
	vec2 grid_uv = round(UV * texture_size.x ) / texture_size.y; // pixelizacija efekta
	vec4 bg = texture(TEXTURE, grid_uv - TIME/noise_speed); // tukaj je že notri premikanje
	
	COLOR = bg;
	COLOR.r = gradient(grid_uv); // red kanal damo rezultat gradient funkcije 
	
	// množimo oz. združimo red channel z intensity in teksturo noisa
	COLOR.r = clamp(COLOR.r * bg.r * noise_intensity * 10.0f, 0.0f, 1.0f); // klempam, da ne gre pod nulo in ne nad ena (ker je to barvni kanal)
	COLOR.r = floor(COLOR.r * float(noise_layers)) / float(noise_layers); // floor ... zaokrožimo zato, ker ker je št. lejerja zmeraj cela številka ... delimo z lejerji, da je vsak lejer na 0.2 vrednosti
	COLOR.a = float(COLOR.r > 0.0f); // ?
	
	vec4 color = vec4(COLOR.r, COLOR.r, COLOR.r, COLOR.r); // grayscale
	
	// invert colos
	if (inverse_output == true )
		color.rgb = vec3(1.0,1.0,1.0) - color.rgb;
	
	// skoraj črna barva je transparentna
	if (length(color - color_to_cut) < 0.01){
		 COLOR.a = 0.0;	
	}
	// barva je polna
	else{
		vec4 final_color = color * colorize * color_intensity; // add color
		COLOR = final_color;
	}
}