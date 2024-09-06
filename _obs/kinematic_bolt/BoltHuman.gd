extends KinematicBolt


onready var controller_profiles: Dictionary = Pro.controller_profiles
onready var controller_profile_name: int = player_profile["controller_type"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]
onready var slow_start_engine_power: float = fwd_engine_power # poveča se samo če zgrešiš start


func _input(event: InputEvent) -> void:

			
	if Input.is_action_just_pressed(fwd_action):
		if not bolt_active and engines_on:
			$Sounds/EngineRevup.play()
		elif Ref.game_manager.fast_start_window:
			$Sounds/EngineRevup.play()
			
	if not bolt_active:
		return
	
	# fast start detection
	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		if Input.is_action_just_pressed(fwd_action) and Ref.game_manager.fast_start_window: # če še ni štartal (drugače bi bila slow start power še defoltna)
			slow_start_engine_power = 0
	else:
		slow_start_engine_power = 0
		
	if Input.is_action_pressed(fwd_action):
		# slow start
		if slow_start_engine_power == fwd_engine_power:
			var slow_start_tween = get_tree().create_tween()
			slow_start_tween.tween_property(self, "slow_start_engine_power", 0, 1).set_ease(Tween.EASE_IN)
		engine_power = fwd_engine_power - slow_start_engine_power
		
	elif Input.is_action_pressed(rev_action):
		engine_power = - rev_engine_power
	else:			
		engine_power = 0
		
	# rotation ... rotation_angle se računa na inputu (turn_angle)
	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
	
	# weapon select
	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		if Input.is_action_pressed(selector_action):
			bolt_hud.selected_active_weapon_index += 1
	else:
		if Input.is_action_just_pressed(selector_action):
			bolt_hud.selected_active_weapon_index += 1
	
	# select weapon and shoot
	if Input.is_action_just_pressed(shoot_action):
		shoot(bolt_hud.selected_weapon_index)
		
	
func _ready() -> void:
	
	add_to_group(Ref.group_humans)
	
	
	

func _physics_process(delta: float) -> void:

	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	
	if current_motion == MotionStates.IDLE: # aplikacija free rotacije
		rotate(delta * rotation_angle * free_rotation_multiplier)
	
	# poraba bencina
	if not Ref.current_level.level_type == Ref.current_level.LEVEL_TYPE.BATTLE:
		if current_motion == MotionStates.FWD:
			manage_gas(fwd_gas_usage)
		elif current_motion == MotionStates.REV:
			manage_gas(rev_gas_usage)


func pull_bolt_on_screen(pull_position: Vector2, current_leader: Node2D):
	
	if not bolt_active:
		return
		
	bolt_collision.set_deferred("disabled", true)
	shield_collision.set_deferred("disabled", true)	
	
	# reštartam trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	yield(pull_tween, "finished")
	
	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	if player_stats["laps_count"] < current_leader.player_stats["laps_count"]:
		var laps_finished_difference: int = current_leader.player_stats["laps_count"] - player_stats["laps_count"]
		update_stat("laps_count", laps_finished_difference)
	
	# če preskoči checkpoint, ga dodaj, če ga leader ima
	var all_checked_bolts: Array = Ref.game_manager.bolts_checked
	if all_checked_bolts.has(current_leader):
		all_checked_bolts.append(self)

	# ne dela
	#	if Ref.game_manager.current_pull_positions.has(pull_position):
	#		Ref.game_manager.current_pull_positions.erase(pull_position)

	manage_gas(Ref.game_manager.game_settings["pull_gas_penalty"])
