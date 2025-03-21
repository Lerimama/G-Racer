extends Camera2D


export (Resource) var shake_profile_game
export (Resource) var shake_profile_projectile
export (Resource) var shake_profile_vehicle

var camera_player: Node2D
var follow_target: Node setget _change_follow_target
var shake_camera_on: bool = true
var dynamic_zoom_on: bool = true

# dinamic zoom in offset
var camera_zoom_range: Vector2 = Sets.camera_zoom_range # [1, 1.5]
var camera_zoom_lerp_factor: float = 0.01
var min_zoom_target_speed: float = 1000
var max_zoom_target_speed: float = 1500
var change_follow_target_time: float = 2
var target_velocity_offset_factor: float = 1
var target_velocity_lerp_factor: float = 0.2

onready var test_ui = $TestUI
onready var playing_field: Node2D = $PlayingField
onready var setup_table: Control = $TestUI/SetupPanel/SetupTable
onready var shaker: Node = $Shaker


#func _input(event: InputEvent) -> void:
#
#	if Input.is_action_pressed("ui_accept"):
#		shake_camera(Refs.game_manager)


func _ready():

	add_to_group(Refs.group_player_cameras)

	shake_camera_on = Sets.camera_shake_on
	zoom = Vector2.ONE

	playing_field.hide()

	test_ui.hide()
#	if OS.is_debug_build():
#		test_ui.show()


func _process(delta: float) -> void:

	if OS.is_debug_build() and test_ui.test_view_on:
		return

	# trojček, ki more bit, če ne je kamera zrcalna ... posledica implementacije šejka (dokler šejk ne bo v tem skriptu)
	offset.x = 0
	offset.y = 0
	rotation_degrees = 0

	if not is_instance_valid(follow_target):
		follow_target = null

	if follow_target:

		# follow
		var dynamic_offset: Vector2 = Vector2.ZERO
		if "velocity" in follow_target:
			var target_velocity_offset: Vector2 = follow_target.velocity * target_velocity_offset_factor
			dynamic_offset = lerp(dynamic_offset, target_velocity_offset, target_velocity_lerp_factor)
		position = follow_target.global_position + dynamic_offset

		# zoom ... dinamic
		if dynamic_zoom_on:
			if follow_target.is_in_group(Refs.group_drivers) and not follow_target.velocity == Vector2.ZERO:
				# samo, če je nad minimumom limit
				if follow_target.velocity.length() > min_zoom_target_speed:
					var max_zoom_velocity_span: float = abs(max_zoom_target_speed - min_zoom_target_speed)
					 # vel, čez min span limit, nam da procent zasedenosti zoom spanao
					var target_speed_part_in_span: float = (follow_target.velocity.length() - min_zoom_target_speed) / max_zoom_velocity_span # %
					var camera_zoom_span: float = abs(camera_zoom_range.y - camera_zoom_range.x)
					var camera_zoom_addon_in_span: float = camera_zoom_span * target_speed_part_in_span
					zoom.x = lerp(zoom.x, camera_zoom_range.x + camera_zoom_addon_in_span, camera_zoom_lerp_factor)
			else:
				zoom.x = lerp(zoom.x, camera_zoom_range.x, camera_zoom_lerp_factor)

		# default zoom ... lerp za mehkobo prehodov
		zoom.x = lerp(zoom.x, camera_zoom_range.x, camera_zoom_lerp_factor)
		zoom.x = clamp(zoom.x, camera_zoom_range.x, camera_zoom_range.y)
		zoom.y = zoom.x


func set_camera(limits_rect: Control, camera_position_2d: Position2D, enable_playing_field: bool):

	if limits_rect:
		_set_camera_limits(limits_rect)
	else:
		_release_camera_limits()

	follow_target = camera_position_2d

	playing_field.enable_playing_field(enable_playing_field)


func shake_camera(source: Node):

	if shake_camera_on:
		var shake_trauma: float = 0
		if source.is_in_group(Refs.group_projectiles) and shake_profile_projectile:
			shaker.shake_profile = shake_profile_projectile
		if source.is_in_group(Refs.group_drivers) and shake_profile_vehicle:
			shaker.shake_profile = shake_profile_vehicle
		elif source is Game and shake_profile_game:
			shaker.shake_profile = shake_profile_game

		shaker.call_deferred("shake_it")


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


func _change_follow_target(new_follow_target: Node):

	if not new_follow_target == follow_target:
		#		print ("change camera target")
		#		smoothing_enabled = false
		##		if new_follow_target.is_in_group(Refs.group_drivers):# or Refs.game_manager game_on: # RFK ... kamera - hitrost setanja poizicije
		#		var transition_tween = get_tree().create_tween()
		##			transition_tween.tween_property(self, "position", new_follow_target.position, change_follow_target_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		#		transition_tween.tween_property(self, "position", follow_target.global_position, change_follow_target_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		#		yield(transition_tween, "finished")
		#		smoothing_enabled = true
		follow_target = new_follow_target
