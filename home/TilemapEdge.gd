extends TileMap


var light_color: Color = Color.white # za barvanje debrisa

onready var edge_shadows: ColorRect = $EdgeShadows
onready var shadows_direction: Vector2 = Refs.game_manager.game_settings["shadows_direction"] setget _on_shadow_direction_change

func _ready() -> void:

	# setam senco
#	var screen_size: Vector2 = get_viewport_rect().size * 0.25
#	edge_shadows.material.set_shader_param("screen_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
	var edge_shadows_deg: float = get_angle_to(shadows_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadows.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadows_deg))




func _on_shadow_direction_change(new_shadows_direction: Vector2):

	var edge_shadows_rotation: float = get_angle_to(new_shadows_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadows.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadows_rotation))


func _on_EdgeShadows_resized() -> void:
	pass
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
