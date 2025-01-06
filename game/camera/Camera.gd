extends Camera2D


var follow_target: Node = null setget _on_follow_target_change

var bolt_explosion_shake = 0
var bullet_hit_shake = 0.02
var misile_hit_shake = 0.05

# dinamic zoom
var camera_max_zoom: float = 1.5
var camera_min_zoom: float = 1
var camera_zoom_speed_factor: float = 0.01
var min_zoom_target_speed: float = 1000
var max_zoom_target_speed: float = 1500

onready var test_ui = $TestUI

var debug_max_zoom_out: = false


func _ready():

	print("KAMERA")
	if Refs.current_camera == null:
		Refs.current_camera = self
	zoom = Vector2.ONE


func _process(delta: float) -> void:

	if Refs.current_camera == self:
		if not test_ui.test_view_on:
			if follow_target:
				position = follow_target.global_position

				if Refs.game_manager.game_settings["max_zoomout"]:
					zoom.x = camera_max_zoom * 2# OPT ... zoom podvajanje
				else:
					# zoom
					if follow_target.is_in_group(Refs.group_bolts) and not follow_target.bolt_velocity == null:
						var follow_target_speed: float = abs(follow_target.bolt_velocity.length())
						# če je nad min limit
						if follow_target_speed > min_zoom_target_speed:
							var max_zoom_velocity_span: float = abs(max_zoom_target_speed - min_zoom_target_speed)
							 # vel, čez min span limit, nam da procent zasedenosti zoom spanao
							var target_speed_part_in_span: float = (follow_target_speed - min_zoom_target_speed) / max_zoom_velocity_span # %
							var camera_zoom_span: float = abs(camera_max_zoom - camera_min_zoom)
							# dobljen procent zasedenosti vel span, apliciram na procenz zoom spana
							var camera_zoom_adon_in_span: float = camera_zoom_span * target_speed_part_in_span
							zoom.x = lerp(zoom.x, camera_min_zoom + camera_zoom_adon_in_span, camera_zoom_speed_factor)
						# če je zunaj zoom območja lerpam do minimum zooma
						else:
							zoom.x = lerp(zoom.x, camera_min_zoom, camera_zoom_speed_factor)
					else:
						zoom.x = lerp(zoom.x, camera_min_zoom, camera_zoom_speed_factor) # OPT ... zoom podvajanje

			# default zoom ... lerp za mehkobo prehodov

#			if not debug_max_zoom_out:
			zoom.x = lerp(zoom.x, camera_min_zoom, camera_zoom_speed_factor)
			# debug
			if not Refs.game_manager.game_settings["max_zoomout"]:
				zoom.x = clamp(zoom.x, camera_min_zoom, camera_max_zoom)
			zoom.y = zoom.x


func _on_follow_target_change(new_follow_target):

	if not new_follow_target == null:
		if new_follow_target.is_in_group(Refs.group_bolts) or Refs.game_manager.game_on: # RFK ... kamera - hitrost setanja poizicije
			var transition_time: float = 2
			var transition_tween = get_tree().create_tween()
			transition_tween.tween_property(self, "position", new_follow_target.position, transition_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			yield(transition_tween, "finished")
			follow_target = new_follow_target
	else:
		follow_target = new_follow_target



func shake_camera(shake_power: float):
	print("shake izklopljen")
	# time, power in nivo popuščanja

	#	test_ui.shake_camera(shake_power) # debug
	pass


func set_camera_limits():

	if Refs.game_manager.game_settings["max_zoomout"]:
		 return

	var corner_TL: float
	var corner_TR: float
	var corner_BL: float
	var corner_BR: float

	var limits_rectangle: Control = Refs.current_level.camera_limits_rect
	var limits_rectangle_position: Vector2 = limits_rectangle.rect_position
	corner_TL = limits_rectangle.rect_position.x
	corner_TR = limits_rectangle.rect_size.x
	corner_BL = limits_rectangle.rect_position.y
	corner_BR = limits_rectangle.rect_size.y

	if limit_left <= corner_TL and limit_right <= corner_TR and limit_top <= corner_BL and limit_bottom <= corner_BR: # če so meje manjše od kamere
		return

	limit_left = corner_TL
	limit_right = corner_TR
	limit_top = corner_BL
	limit_bottom = corner_BR
