shader_type canvas_item;
//render_mode blend_mix;
//render_mode unshaded;




uniform int intensity = 50;
uniform float precision : hint_range(0,0.02);
uniform bool flipColors;		//Flip coloring 90 degrees.

//If not using a texture, will blend between these two colors
uniform vec4 outline_color : hint_color;
uniform vec4 outline_color_2 : hint_color;

uniform bool use_outline_uv;	//Use the outline_uv for coloring or not. Recomended not, but sometimes might be good.

uniform bool useTexture;		//Use a texture for the coloring
uniform sampler2D outlineTexture;	//This is the texture that will be used for coloring. Recomended to use a gradient texture, but I guess anything else works.

uniform vec2 offset = vec2(8.0, 8.0);
uniform vec4 modulate : hint_color;

varying vec2 o;
varying vec2 f;


void vertex()
{
	//Expands the vertexes so we have space to draw the outline if we were on the edge.
	o = VERTEX;
	vec2 uv = (UV - 0.5);
	VERTEX += uv * float(intensity);
	f = VERTEX;
}

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * float(intensity) * precision;

	vec4 shadow = vec4(modulate.rgb, texture(TEXTURE, UV - offset * ps).a * modulate.a);
	vec4 col = texture(TEXTURE, UV);

	COLOR = mix(shadow, col, col.a);
}
