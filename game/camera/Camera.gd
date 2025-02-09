extends Camera2D

var camera_player: Node2D
var follow_target: Node setget _on_follow_target_change

# shake izklopljen ... še vedno je v test ui-nodetu"
var bolt_explosion_shake = 0
var bullet_hit_shake = 0.02
var misile_hit_shake = 0.05

# dinamic zoom in offset
var camera_zoom_range: Array = Sts.camera_zoom_range # [1, 1.5]
var camera_zoom_lerp_factor: float = 0.01
var min_zoom_target_speed: float = 1000
var max_zoom_target_speed: float = 1500
var change_follow_target_time: float = 2
var target_velocity_offset_factor: float = 1
var target_velocity_lerp_factor: float = 0.2

onready var test_ui = $TestUI
onready var playing_field: Node2D = $PlayingField
onready var setup_table: Control = $TestUI/SetupPanel/SetupTable


func _ready():

	add_to_group(Rfs.group_player_cameras)
#	if Rfs.game_camera == null:
	Rfs.game_camera = self
	zoom = Vector2.ONE

	playing_field.hide()

	test_ui.hide()
	if OS.is_debug_build():
		test_ui.show()


func _process(delta: float) -> void:


#	if Rfs.game_camera == self and not test_ui.test_view_on:
	if not test_ui.test_view_on:

		# trojček, ki more bit, če ne je kamera zrcalna ... posledica implementacije šejka (dokler šejk ne bo v tem skriptu)
		offset.x = 0
		offset.y = 0
		rotation_degrees = 0

		if follow_target:

			# follow
			var dynamic_offset: Vector2 = Vector2.ZERO
			if "velocity" in follow_target:
				var target_velocity_offset: Vector2 = follow_target.velocity * target_velocity_offset_factor
				dynamic_offset = lerp(dynamic_offset, target_velocity_offset, target_velocity_lerp_factor)
			position = follow_target.global_position + dynamic_offset

			# zoom ... dinamic
			if follow_target.is_in_group(Rfs.group_bolts) and not follow_target.velocity == Vector2.ZERO:
				# samo, če je nad minimumom limit
				if follow_target.velocity.length() > min_zoom_target_speed:
					var max_zoom_velocity_span: float = abs(max_zoom_target_speed - min_zoom_target_speed)
					 # vel, čez min span limit, nam da procent zasedenosti zoom spanao
					var target_speed_part_in_span: float = (follow_target.velocity.length() - min_zoom_target_speed) / max_zoom_velocity_span # %
					var camera_zoom_span: float = abs(camera_zoom_range[1] - camera_zoom_range[0])
					var camera_zoom_addon_in_span: float = camera_zoom_span * target_speed_part_in_span
					zoom.x = lerp(zoom.x, camera_zoom_range[0] + camera_zoom_addon_in_span, camera_zoom_lerp_factor)
			else:
				zoom.x = lerp(zoom.x, camera_zoom_range[0], camera_zoom_lerp_factor)

		# default zoom ... lerp za mehkobo prehodov
		zoom.x = lerp(zoom.x, camera_zoom_range[0], camera_zoom_lerp_factor)
		zoom.x = clamp(zoom.x, camera_zoom_range[0], camera_zoom_range[1])
		zoom.y = zoom.x


func _on_follow_target_change(new_follow_target: Node):

	if new_follow_target and not new_follow_target == follow_target:
		#		print ("change camera target")
		#		smoothing_enabled = false
		##		if new_follow_target.is_in_group(Rfs.group_bolts):# or Rfs.game_manager.game_on: # RFK ... kamera - hitrost setanja poizicije
		#		var transition_tween = get_tree().create_tween()
		##			transition_tween.tween_property(self, "position", new_follow_target.position, change_follow_target_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		#		transition_tween.tween_property(self, "position", follow_target.global_position, change_follow_target_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		#		yield(transition_tween, "finished")
		#		smoothing_enabled = true
		follow_target = new_follow_target


func shake_camera(shake_power: float):
	print("shake izklopljen ... še vedno je v test ui-nodetu")
	# time, power in nivo popuščanja
	#	test_ui.shake_camera(shake_power) # debug
	pass


func setup(limits_rect: Control, camera_position: Vector2):

	position = camera_position
	if limits_rect:
		_set_camera_limits(limits_rect)
	else:
		_release_camera_limits()


func _set_camera_limits(limits_rectangle: Control):

	var corner_TL: float = limits_rectangle.rect_position.x
	var corner_TR: float = limits_rectangle.rect_size.x
	var corner_BL: float = limits_rectangle.rect_position.y
	var corner_BR: float = limits_rectangle.rect_size.y

	# če so meje manjše od kamere
	if limit_left <= corner_TL and limit_right <= corner_TR and limit_top <= corner_BL and limit_bottom <= corner_BR:
		pass
	else:
		limit_left = corner_TL
		limit_right = corner_TR
		limit_top = corner_BL
		limit_bottom = corner_BR


func _release_camera_limits():

	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000

