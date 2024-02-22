shader_type canvas_item;
render_mode blend_mix;


// KAJ DELA ŠEJDER?
// naredi drop shadow in jo zamaskira, tako, da je oritginal textura vidna
// shadow steps 1 da flat senco brez debeline ... več kot je korakov bolj debela je senca
// shadow_offset zamika senco, tako da dobimo občutek oddaljenosti od tal (če je nič, je objekt na tleh)

// UPGRADE?
// 3 barve za 3 različne nastavitve (višina in dvignjenost)
// razmerja pixel/texel

uniform vec4 shadow_color : hint_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform int shadow_steps = 1; // debelina oz. dolžina sence ... je število duplikatov, ki so zamaknjeni za "en" pixel vsak
uniform float shadow_step_offset : hint_range(0, 10) = 1.0; // zamik posameznega koraka za en pixel
uniform float shadow_offset = 0.0; // zamik celotne sence ... 
uniform vec2 shadow_direction = vec2(-1,-1);

// dimenzija teksture za uskladitev texlov s pixli (1/texture original size)  
uniform float texture_width = 640.0;
uniform float texture_height = 360.0;


void fragment(){

	// preračun pravega offseta sence ... pixle konvertamo v texle
//	vec2 shadow_offset = vec2(shadow_direction.x / texture_width, shadow_direction.y / texture_height);
	
	vec2 size = TEXTURE_PIXEL_SIZE * shadow_step_offset;
	float shadow = 0.0;
	
	float stretch_factor = 0.0;
	float offset_x = shadow_offset * shadow_direction.x / 100.0; // z deljenjem dobimo bolj normalen slide
	float offset_y = shadow_offset * shadow_direction.y / 100.0;
	
	for (int i = 0; i < shadow_steps; i++) {
		stretch_factor += 1.0; // lahko bi uporabil "i" pa mi ne pusti
		shadow += texture(TEXTURE, UV + (size * shadow_direction * stretch_factor) + vec2(offset_x, offset_y)).a;
		
	}
	
	// ta vrstica maska senco, da je kao pod teksturo ... podobno kot step funkcij?
	shadow = min(shadow, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = mix(color, shadow_color, shadow - color.a);
}
