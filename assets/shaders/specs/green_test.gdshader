shader_type canvas_item;

uniform sampler2D noise;
uniform mat4 view_to_local;

varying vec2 local;
//
//void vertex()
//{
//    local = (view_to_local * WORLD_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
//}

void fragment()
{
    vec2 uv = local / vec2(textureSize(noise, 0));
    COLOR = vec4(texture(noise, uv).rgb, texture(TEXTURE, UV).a);
}