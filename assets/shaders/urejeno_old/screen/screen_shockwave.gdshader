shader_type canvas_item;
render_mode blend_mix;

uniform bool mask_on = true;// = vec2(0.5, 0.5);
uniform vec2 center;// = vec2(0.5, 0.5);
uniform float force = 0.5; // displacement vector ... globina podomače
uniform float size = 0.2; 
uniform float hole_thickness = 0.2;
uniform float inside_trans = 0.2;
uniform float outside_trans = 0.2;


void fragment() {
	
	// razmerje ekrana, da ni elipsaste oblike (pixel size x = 1/text oz. screen width)
	float screen_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	// (1/640) / (1/360) = 0,5625

	// korektura centra, ker je x = y
	
	vec2 center_corrected = vec2((center.x - (1.0 - screen_ratio)/2.0)/screen_ratio, center.y);
	// od original x pozicije odštejem polovico od nezasedene x dolžine (
	// zasedena dolžine je screen_ratio -> nezasedena je 1 - screen_ratio)
	// zamaknjeno x pozicijo potem delimo z screen_ratio, da se 1.0 x vektor raztegne na širino ekrana
	// delimo s šrino in višino ekrana, da enote iz texlov spremenimo v pixle
	
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
//	float mask = 1.0 - smoothstep(mask_size - 0.05, mask_size, length(scale_uv - center)); // odštejemo od 1.0 in je inverted
	// smoothstep funkcija naredi prehod med zapisanima vrednostima ... smoothstep(vrednosti pas 1, vrednosti pas 2, vrednosti pas 3)
	
	// masked donut
//	float mask = (1.0 - smoothstep(mask_size - 0.05, mask_size, length(scale_uv - center))) *
//		smoothstep(mask_size - 0.12, mask_size - 0.05, length(scale_uv - center));
	// multiply oba koraka (smoothstepa) med sabo, da videz dveh prehodov ... drugi je manjši in ni invertan
	// dodamo debelino
	float mask = (1.0 - smoothstep(size - outside_trans, size, length(scale_uv - center_corrected))) *
		smoothstep(hole_thickness - inside_trans, hole_thickness, length(scale_uv - center_corrected));
	
	
	
	// mavrični stožec
//	vec2 disp = normalize(SCREEN_UV - center) * force; 
//	vec2 disp = normalize(scale_uv - center) * force; // namesto skrin_uv damo popravljeno razmerje "scale_uv"
	vec2 disp = normalize(scale_uv - center_corrected) * force * mask; // apliciramo masko (multiply pomeni, da je vidna samo, kjer je bele barve ... kot prava maska)
	
	// tukaj grebamo teksturo in jo vmešamo s šejpom
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - disp);
	
	// čb test maske
	if (mask_on == true){
		COLOR.rgb = vec3(mask);
	}
	
}