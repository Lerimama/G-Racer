extends RayCast2D


var aim_distance: float = 1000
var ray_angle: float
var aim_target: Node2D = null setget _change_aim_target
var aiming_on_target: bool = false # cilja in išče nove
var locked_on_target: bool = false # cilja in ne išče novih
var available_targets: Dictionary
var ray_rotating_speed: float = 6 # množim z delto
var turret_rotating_speed: float = 10 # množim z delto
var ai_weapon: Node2D
var ai_enabled: bool = false


func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("left_click"):
		var ai_target = Mts.spawn_indikator(get_global_mouse_position(), Color(Color.blue, 0), 0, Rfs.node_creation_parent)
		lock_on_target(ai_target)
	if Input.is_action_just_pressed("no3"): # idle
		self.aim_target = null


func set_ai(weapon_owner: Node2D, turn_on: bool = true):

	if turn_on:
		ai_weapon = get_parent()
		add_exception(weapon_owner)
		enabled = true
		ai_enabled = true
	else:
		self.aim_target = null
		enabled = false
		ai_enabled = false
#		enabled = true
#		ai_enabled = true


func _process(delta: float) -> void:


	if not ai_enabled:
		self.aim_target = null
	else:
		# nabiranje tarč ... apdejta na vsak krog

		if not is_instance_valid(aim_target):
		# alt stop searching when lockerd ... tole dokler ne pogruntam samostojne rotacije
		#		if locked_on_target and is_instance_valid(aim_target):
			# ... želel bi, da rotacija orožja ne vpliva na rotacijo rays ... vpliv na gejmplej je majhen
			#			ray_angle -= get_parent().global_rotation
			# kr neki da bi se ray poravnal ...  ne rabim
			ray_angle = deg2rad(0) + 0.5
		else:
			ray_angle += delta * ray_rotating_speed# - get_parent().global_rotation
			var target_in_reach: Node2D = Mts.get_rotating_raycast_collision(self, Vector2.RIGHT.rotated(ray_angle), aim_distance)
			if target_in_reach:
				if target_in_reach.is_in_group(Rfs.group_drivers) or target_in_reach.is_in_group(Rfs.group_ai):
					available_targets[target_in_reach] = global_position.distance_to(target_in_reach.global_position)
			# nov krog
			if ray_angle >= deg2rad(360):
				if not available_targets.empty():
					self.aim_target = _get_best_target()
					# reset
					available_targets = {}
					ray_angle = 0

		# sledenje izbrani tarči
		if aiming_on_target and is_instance_valid(aim_target):
			#			if aim_target and is_instance_valid(aim_target):
			var angle_to_target: float = global_position.angle_to_point(aim_target.global_position) - deg2rad(180)
			ai_weapon.global_rotation = lerp_angle(ai_weapon.global_rotation, angle_to_target, turret_rotating_speed * delta)
		else:
			self.aim_target = null


func _get_best_target(): # po distanci

	var current_min_distance_to_target: float = available_targets.values().min()
	var closest_target: Node2D = available_targets.find_key(current_min_distance_to_target)

	if aim_target and is_instance_valid(aim_target):
		if current_min_distance_to_target > global_position.distance_to(aim_target.global_position):
			closest_target = aim_target
	else:
		closest_target = null

	return closest_target


func _change_aim_target(new_target: Node2D):

	aim_target = new_target

	if aim_target and is_instance_valid(aim_target):
		aiming_on_target = true
	else:
		aim_target = null # rabim, če ni validen
		aiming_on_target = false
		locked_on_target = false


func lock_on_target(new_target:  Node2D):

	locked_on_target = true
	self.aim_target = new_target
