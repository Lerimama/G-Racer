shader_type canvas_item;
render_mode blend_mix;

uniform vec2 center = vec2(0.5, 0.5);
uniform float force = 0.5; // displacement vector ... globina podomače

void fragment() {
//	vec2 disp = normalize(UV - center * force);
//	COLOR = vec4(UV - disp, 0.0, 1.0);
//	COLOR = texture(TEXTURE, UV - disp);
	
	// tale del je samo mavrični stožec
	vec2 disp = normalize(UV - center) * force;
	COLOR = vec4 (UV - disp, 0.0, 1.0);
//	
	// tukaj pa potem grebamo teksturo in jo vmešamo
	COLOR = texture(TEXTURE, UV - disp);
}