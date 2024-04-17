shader_type canvas_item;
//render_mode blend_premul_alpha;

// za popravit
// dodaj kaj dela?
// dodaj pixelizacijo
// speed in threshold naj imata slider


uniform sampler2D noise_texture;
uniform float speed1 = 0.02;
uniform float speed2 = 0.05;
uniform float threshold_min = 0.5;
uniform float threshold_max = 0.58;

//uniform float noise_resolution_x = 64.0;
//uniform float noise_resolution_y = 360.0;
uniform vec2 node_size = vec2(320, 320);

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void fragment() {
	
	vec4 col0 = texture(noise_texture, mod(UV + TIME * speed1, vec2(1, 1)));
	vec4 col1 = texture(noise_texture, mod(UV + TIME * speed2, vec2(1, 1)));
	
	//we apply red channel as alpha
	col0.a = col0.r;
	col1.a = col1.r;
	
	//step function return 0 if last parameter is < threshold and 1 otherwise
	//here we want 1 if value between threshold_min and threshold_max
	//same result as following code:
//	/*
	float col = (col0. r + col1.r) / 2.0;
	if(col > threshold_min && col < threshold_max){
		COLOR = vec4(1.0, 1.0, 1.0, 1.0);
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, 0.0);
	}
//	*/
	vec4 water_color;
	vec4 pixelated_color;
	
	//here we normalize col0 + col1 (/ 2.0) to have result between [0,1]
	water_color = step(threshold_min, (col0 + col1) / 2.0) * (1.0 - step(threshold_max, (col0 + col1) / 2.0));
	
	//as UV is between [0;1] we multiply with noise_resolution factor to have noise_resolution differents values
	float val = random(floor(UV * node_size.x));
	pixelated_color = vec4(val,val,val,1.0);
	COLOR =  mix(pixelated_color, water_color, 0.5);
	
	COLOR = water_color;
}