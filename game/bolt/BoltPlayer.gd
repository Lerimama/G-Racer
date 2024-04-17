extends Bolt
class_name Player


#var player_name: String # za opredelitev statistike
var controller_profile: Dictionary

#onready var player_profile: Dictionary = Pro.player_profiles[bolt_id]
onready var controller_profiles: Dictionary = Pro.controller_profiles
onready var controller_profile_name: String = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var feature_action: String = controller_actions["feature_action"]
onready var slow_start_engine_power: float = fwd_engine_power # poveča se samo če zgrešiš start

#neu

func _input(event: InputEvent) -> void:

			
	if Input.is_action_just_pressed(fwd_action):
		if not bolt_active and engines_on:
			$Sounds/EngineRevup.play()
		elif Ref.game_manager.fast_start_window:
			$Sounds/EngineRevup.play()
			
	if not bolt_active:
		return
	
	# fast start detection
	if Ref.game_manager.game_settings["race_mode"]:
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
	
	# feature select
	if Ref.game_manager.game_settings["race_mode"]:
		if Input.is_action_pressed(feature_action):# and Ref.game_manager.game_settings["full_equip_mode"]:
			select_feature()
	else:
		if Input.is_action_just_pressed(feature_action):
			select_feature()
	
	# select feature and shoot
	if Input.is_action_just_pressed(shoot_action):
		shoot()
		
	
func _ready() -> void:
	
	add_to_group(Ref.group_players)
	
#	# player setup
#	player_name = player_profile["player_name"]
#	bolt_color = player_profile["player_color"]
#	bolt_sprite.modulate = bolt_color


func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	
	if current_motion_state == MotionStates.IDLE: # aplikacija free rotacije
		rotate(delta * rotation_angle * free_rotation_multiplier)
	
	# poraba bencina
	if Ref.game_manager.game_settings["race_mode"]:
		if current_motion_state == MotionStates.FWD:
			manage_gas(fwd_gas_usage)
		elif current_motion_state == MotionStates.REV:
			manage_gas(rev_gas_usage)


func shoot():
	
	if Set.debug_mode:
		selected_feature_index = 3
		
	match selected_feature_index:
		0: # no feature
			return
		1: # bullet
			shooting("bullet")
		2: # misile
			shooting("misile")
		3: # mina
			shooting("mina")
		4: # shocker 
			shooting("shocker")


func select_feature():
	
	# timer setup
	var selector_timer: Timer = $BoltHud/VBoxContainer/FeatureSelector/SelectorTimer
	var selector_visibily_time: float = 1
	selector_timer.wait_time = selector_visibily_time
	selector_timer.start()

	if not feat_selector.visible:
		feat_selector.show() # prižgem z ikono trenutnega
		
	selected_feature_index += 1
	if selected_feature_index > available_features.size(): # reset, če je prevelik
		selected_feature_index = 1 # 0 je prazen feature
		
	# vidnost ikon
	for feature in available_features:
		feature.hide() # najprej vse skrijem
		if feature == available_features[selected_feature_index - 1]: # potem pokažem izbrano .. - 1, ker je 0 prazen feature
			
			feature.show()		


func pull_bolt_on_screen(pull_position: Vector2, leader_laps_finished: int, leader_checkpoints_reached: Array):
	
	if not bolt_active:
		return
		
	bolt_collision.disabled = true
	shield_collision.disabled = true
	
	# reštartam trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false

#	printt ("pre", checkpoints_reached)
#	if not leader_checkpoints_reached.empty():
##		if not checkpoints_reached.size() == leader_checkpoints_reached.size():
#		checkpoints_reached = leader_checkpoints_reached
#	printt ("aft", checkpoints_reached)
		
	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	yield(pull_tween, "finished")
	# če preskoči ciljno linijo in checkpoint
	if laps_finished_count < leader_laps_finished:
		laps_finished_count = leader_laps_finished
	
	# ne dela
#	if Ref.game_manager.current_pull_positions.has(pull_position):
#		Ref.game_manager.current_pull_positions.erase(pull_position)
	emit_signal("stat_changed", bolt_id, "laps_finished_count", laps_finished_count) 
	manage_gas(Ref.game_manager.game_settings["pull_gas_penalty"])


func _on_SelectorTimer_timeout() -> void:
	
	feat_selector.hide()

