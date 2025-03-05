extends Node2D


signal body_exited_playing_field(body)

var playing_field_enabled: bool = false # začne disejban
var vehicles_out_of_playing_screen: Array = []

onready var camera_to_follow: Camera2D = get_parent()
onready var field_area: Area2D = $FieldArea
onready var field_edge_collision: CollisionPolygon2D = $FieldEdge/CollisionPolygon2D


func _ready() -> void:
	#	enable_playing_field(playing_field_enabled)
	pass


func _process(delta: float) -> void:

	if playing_field_enabled:

		global_position = camera_to_follow.get_camera_screen_center()
		scale = camera_to_follow.zoom

		for veh in vehicles_out_of_playing_screen:
			emit_signal("body_exited_playing_field", veh)


func enable_playing_field(enable: bool, with_edge: bool = false):

	vehicles_out_of_playing_screen.clear()
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


func _on_FieldArea_player_exited(player_vehicle: Node) -> void:

	if not player_vehicle in vehicles_out_of_playing_screen:
		vehicles_out_of_playing_screen.append(player_vehicle)


func _on_FieldArea_player_entered(player_vehicle: Node) -> void:

	vehicles_out_of_playing_screen.erase(player_vehicle)
