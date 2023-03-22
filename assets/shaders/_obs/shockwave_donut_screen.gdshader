shader_type canvas_item;
render_mode blend_mix;

uniform vec2 center = vec2(0.5, 0.5);
uniform float force = 0.5; // displacement vector ... globina podomače

void fragment() {
	
	// razmerje ekrana, da ni elipsaste oblike
	float screen_ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	
	// aplikacija razmerja ekrana
	vec2 scale_uv = (SCREEN_UV - vec2(0.5, 0.0)) / vec2 (screen_ratio, 1.0) + vec2 (0.5, 0.0);
	// scale_uv = (skrin uv - offset x, da ga premaknemo v origin, da ga lahko pravilno skejlamo) / ratio x osi, ker je popačeno samo v eno smer + offset x, da ga popravimo s tistim, ki smo ga želeli
	
	// donut shape ... masked circle
	float mask = length(scale_uv - center); // dolžina od našega centra
	
	
	// mavrični stožec
//	vec2 disp = normalize(SCREEN_UV - center) * force; 
	vec2 disp = normalize(scale_uv - center) * force; // namesto skrin_uv damo popravljeno razmerje "scale_uv"
	
	// tukaj grebamo teksturo in jo vmešamo s šejpom
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV - disp);
	
	// čb test maske
	COLOR.rgb =  vec3(mask);
}