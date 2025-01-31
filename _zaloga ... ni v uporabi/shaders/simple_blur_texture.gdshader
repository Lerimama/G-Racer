shader_type canvas_item;

uniform vec4 tint_color: hint_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float blur_amount : hint_range(0.0, 500.0) = 2.0;

void fragment() {
    vec4 orig_tex = texture(TEXTURE, UV);
    vec4 blurred_texture = textureLod(TEXTURE, UV, blur_amount);
    COLOR = mix(blurred_texture, orig_tex, tint_color.a);
//    COLOR.a = orig	_tex.a;
}