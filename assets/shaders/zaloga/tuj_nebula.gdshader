shader_type canvas_item;

uniform bool stars_on = true;

uniform float timeScaleFactor = .04;

// Make sure to use a seamless noise texture
uniform sampler2D noise_texture;//: repeat_enable, filter_linear;

uniform vec4 colour_muiltiplier: hint_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 colour_muiltiplier2: hint_color = vec4(1.0,1.0,1.0,1.0);

uniform float brightness: hint_range(0.0, 3.0, 0.01) = 1.0;
uniform float clouds_resolution: hint_range(0.0, 10.0, 0.01) = 3.0;
uniform float clouds_intesity: hint_range(-0.06, 0.0, 0.001) = 0.0;
uniform float waveyness: hint_range(0.0, 10.0, 0.01) = 0.5;
uniform float fragmentation: hint_range(0.0, 100.0, 0.01) = 7.0;
uniform float distortion: hint_range(0.0, 10.0, 0.01) = 0.5;
uniform float clouds_alpha: hint_range(0.4, 0.6, 0.01) = 0.5;
uniform float movement: hint_range(0.7, 1.3, 0.01) = 1.0;
uniform float blur: hint_range(0.0, 10.0, 0.01) = 1.4;
uniform float blur2: hint_range(0.0, 0.01, 0.00001) = 0.01;

//uniform vec2 direction = vec2(1.0);

//uniform float red =  0.001;
//uniform float blue = 0.001;
//uniform float green = 0.001;

float localTime() {
	return TIME * timeScaleFactor;
}

mat2 makem2(float theta) {
	float c = cos(theta);
	float s = sin(theta);
	return mat2(vec2(c, -s), vec2(s, c));
}

float noise(vec2 x) {
	return texture(noise_texture, x * blur2).x;
}
float noisey(vec2 y) {
	return texture(noise_texture, y * blur2).y;
}

vec2 gradn(vec2 p) {
	float ep = .09;
	float gradx = noise(vec2(p.x + ep, p.y)) - noise(vec2(p.x - ep, p.y));
	float grady = noisey(vec2(p.x, p.y + ep)) - noisey(vec2(p.x, p.y - ep));
	return vec2(gradx, grady);
}

float flow(vec2 p) {
	float z = 2.;
	float rz = clouds_intesity;
	vec2 bp = p;
	
	for(float i = 1.; i < 7.; ++i) {
		p += localTime() * .6;
		bp += localTime() * 5.9;
		vec2 gr = gradn(i * p * .34 + localTime() * 1.);
		gr *= makem2(localTime() * 6. - (.05 * p.x + .03 * p.y) * 90.);
		p += gr * waveyness;
		rz += (sin(noise(p) * fragmentation) * distortion + clouds_alpha) / z;
		p = mix(bp, p, movement);
		z *= blur;
		p *= 2.;
		bp *= 1.9;
	}
	return rz;
}

float rand(vec2 st) {
	
    return fract(sin(dot(st.xy, vec2(12.9898,72.233))) * 53758.5453123);
}



void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 fragCoord = FRAGCOORD.xy;
	fragCoord = vec2(fragCoord.x, fragCoord.y - resolution.y );//resolution.y 
	
	vec2 p = fragCoord / resolution - 0.5;
	
	p.x *= resolution.x / resolution.y;
	
	p *= clouds_resolution;
	
	//float red = flow(p * (0.1 / sin(TIME * timeScaleFactor)));
	//float blue = flow(p * (0.1 / cos(TIME * timeScaleFactor)));
	//float green = flow(p * (0.1 / sin(TIME * timeScaleFactor)));
	//float new_red = (red * sin(TIME));
	//float new_blue = (blue * cos(TIME));
	//float new_green = (green * sin(TIME));
	float red = 0.2 * (sin(TIME * 0.1));
	float blue = 0.1 ;
	float green = 0.1 ;
	
	
	float rz = flow(p);
	vec3 col = vec3(red, blue, green) / rz;
	col = pow(col, vec3(brightness));
	
	float stars = 0.0;
	
	if (rand(SCREEN_UV.xy / 20.0) > 0.995) //0.996
	{
		float r = rand(SCREEN_UV.xy);
		stars = r * (0.5 * sin(TIME * (r * 2.0) + 1000.0 * r) + 0.5);
	}
	
	if (stars_on) {
		COLOR = vec4((col + stars) * colour_muiltiplier.rgb, 1.0) * colour_muiltiplier2;
	}
	else {
		COLOR = vec4((col) * colour_muiltiplier.rgb, 1.0) * colour_muiltiplier2;
	}
	
}