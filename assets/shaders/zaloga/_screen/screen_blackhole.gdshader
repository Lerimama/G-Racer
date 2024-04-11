shader_type canvas_item;
render_mode blend_mix;

uniform vec2 center = vec2(0.5, 0.5);
uniform float force = 0.5; // displacement vector ... globina podomače
uniform float mask_size = 0.2; 


void fragment() {
	
	// razmerje ekrana, da ni elipsaste oblike
	float screen_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	
	// aplikacija razmerja ekrana
	vec2 scale_uv = (SCREEN_UV - vec2(0.5, 0.0)) / vec2 (screen_ratio, 1.0) + vec2 (0.5, 0.0);
	// scale_uv = (skrin uv - offset x, da ga premaknemo v origin, da ga lahko pravilno skejlamo) / ratio x osi, ker je popačeno samo v eno smer + offset x, da ga popravimo s tistim, ki smo ga želeli
	
	// gradient masked circle 
//	float mask = length(scale_uv - center);
	
	// sharp masked circle 
//	float mask = step(mask_size, length(scale_uv - center)); 
	// step funkcija vse vrednosti pripne na zapisani vrednosti ... izbrana, ki prestavlja size, in dolžina od našega centra
	
	// smooth masked circle 
//	float mask = smoothstep(mask_size - 0.05, mask_size, length(scale_uv - center)); 
	float mask = 1.0 - smoothstep(mask_size - 0.05, mask_size, length(scale_uv - center)); // odštejemo od 1.0 in je inverted
	// smoothstep funkcija naredi prehod med zapisanima vrednostima ... smoothstep(vrednosti pas 1, vrednosti pas 2, vrednosti pas 3)
	
	// mavrični stožec
//	vec2 disp = normalize(SCREEN_UV - center) * force; 
//	vec2 disp = normalize(scale_uv - center) * force; // namesto skrin_uv damo popravljeno razmerje "scale_uv"
	vec2 disp = normalize(scale_uv - center) * force * mask; // apliciramo masko (multiply pomeni, da je vidna samo, kjer je bele barve ... kot prava maska)
	
	// tukaj grebamo teksturo in jo vmešamo s šejpom
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - disp);
	
	// čb test maske
//	COLOR.rgb =  vec3(mask);
}