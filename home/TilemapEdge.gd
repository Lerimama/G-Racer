extends TileMap


var light_color: Color = Color.white # za barvanje debrisa

onready var edge_shadow: ColorRect = $EdgeShadows
onready var shadow_direction: Vector2 = Vector2(1,1) setget _on_shadow_direction_change

func _ready() -> void:

	# setam senco
#	var screen_size: Vector2 = get_viewport_rect().size * 0.25
#	edge_shadows.material.set_shader_param("screen_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
	var edge_shadows_deg: float = get_angle_to(shadow_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadow.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadows_deg))




func _on_shadow_direction_change(new_shadow_direction: Vector2):

	var edge_shadow_rotation: float = get_angle_to(new_shadow_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadow.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadow_rotation))


func _on_EdgeShadows_resized() -> void:
	pass
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
