shader_type canvas_item;

// pixelate
uniform float pixelFactor : hint_range(0, 10) = 2;

// noise
uniform sampler2D noise;
uniform float speed : hint_range (0, 30) = 14;

void fragment() {
	
	
	vec2 pixelNumber = vec2(textureSize(TEXTURE, 0)) / pixelFactor; // število pixlov
	vec2 pixelatedUV = ((floor(UV * pixelNumber) + 0.5) / pixelNumber) + TIME/speed; // These pixelizations are aligned to the top left. If you do a bit of trickery with offsets, you can centre them. 
	
	COLOR = texture(noise,pixelatedUV);
//	COLOR.rgb = vec3(noise_static, 0.5, noise_val);
	

}
