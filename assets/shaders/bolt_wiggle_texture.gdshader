shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float noise_factor=0.2;
uniform float speed=0.2;

void fragment() {
	//We read noise texture with TIME offset
	float noise_val = texture(noise_texture, mod(UV + speed * TIME, vec2(1.0 ,1.0))).r;
	//UV is altered with noise value
	COLOR = texture(TEXTURE, mod(UV + noise_factor * noise_val, vec2(1.0, 1.0)));
}