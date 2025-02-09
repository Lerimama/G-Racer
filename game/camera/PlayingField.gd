extends Node2D


signal body_exited_playing_field(body)

var playing_field_enabled: bool = false # začne disejban

onready var camera_to_follow: Camera2D = get_parent()
onready var field_area: Area2D = $FieldArea
onready var field_edge_collision: CollisionPolygon2D = $FieldEdge/CollisionPolygon2D


#func _ready() -> void:
#	enable_playing_field(playing_field_enabled)


func _process(delta: float) -> void:

	if camera_to_follow:
		global_position = camera_to_follow.get_camera_screen_center()
		scale = camera_to_follow.zoom


func enable_playing_field(enable: bool, with_edge: bool = false):

	if enable:
		if with_edge:
			field_area.set_deferred("monitoring", false)
			field_edge_collision.set_deferred("disabled", false)
		else:
			field_area.set_deferred("monitoring", true)
			field_edge_collision.set_deferred("disabled", true)
		playing_field_enabled = true
	else:
		field_area.set_deferred("monitoring", false)
		field_edge_collision.set_deferred("disabled", true)
		playing_field_enabled = false


func _on_ScreenArea_body_exited(body: Node) -> void:

	emit_signal("body_exited_playing_field", body)
