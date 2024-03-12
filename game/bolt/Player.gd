extends Bolt
class_name Player


var player_name: String # za opredelitev statistike
var controller_profile: Dictionary

onready var player_profile: Dictionary = Pro.default_player_profiles[bolt_id]
onready var controller_profiles: Dictionary = Pro.default_controller_actions
onready var controller_profile_name: String = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var feature_action: String = controller_actions["feature_action"]

# neu
var feat_selector_alpha: float = 0.3			
onready var feat_selector:  = $BoltHud/VBoxContainer/FeatSelector
onready var selected_feat_index: int = 0
var available_features: Array
onready var tilt_input_timer: Timer = $TiltTimer
var tilt_input_time: float = 0.12

# debug
onready var ray_cast_2d: RayCast2D = $RayCast2D
onready var ray_cast_2d_2: RayCast2D = $RayCast2D2	


func _input(event: InputEvent) -> void:
	
	if not bolt_active:
		return
	
#	if Input.is_action_just_pressed("f"):
#		on_item_picked("BULLET")

	# velocity
	if Input.is_action_pressed(fwd_action):
		engine_power = fwd_engine_power
	elif Input.is_action_pressed(rev_action):
		engine_power = - rev_engine_power
	else:			
		engine_power = 0
	
	# rotation ... rotation_angle se računa na inputu (turn_angle)
	# tilt na timer
	if not Ref.game_manager.game_settings["race_mode"]:
		if Input.is_action_pressed(left_action):
			if tilt_input_timer.is_stopped() and rotation_dir == 0:
				tilt_input_timer.start(tilt_input_time)
			rotation_dir = -1
		elif Input.is_action_just_released(left_action):
			rotation_dir = 0
			if not tilt_input_timer.is_stopped():
				tilt_input_timer.stop()				
				tilt_bolt(Vector2.LEFT)
				
		if Input.is_action_pressed(right_action):
			if tilt_input_timer.is_stopped() and rotation_dir == 0:
				tilt_input_timer.start(tilt_input_time)
			rotation_dir = 1
		elif Input.is_action_just_released(right_action):
			rotation_dir = 0
			if not tilt_input_timer.is_stopped():
				tilt_input_timer.stop()				
				tilt_bolt(Vector2.RIGHT)
	# tilt na feature tipko	
	else:
		if tilt_ready:
			rotation_dir = 0
			var tilt_dir = Input.get_axis(left_action, right_action)
			if tilt_dir == -1:
				tilt_bolt(Vector2.LEFT)
			elif tilt_dir == 1:
				tilt_bolt(Vector2.RIGHT)
			else:
				tilt_speed_call = 0 # reset štetja klicov tilta
				
			
		else:	
			rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
	
	# select feature and shoot
	if not Ref.game_manager.game_settings["race_mode"]:
		if Input.is_action_just_pressed(feature_action):
				select_feature()
		if Input.is_action_just_pressed(shoot_action):
				shoot()
	# feature select is tilt
	else:
		if Input.is_action_pressed(feature_action):
			tilt_ready = true
		else:
			tilt_ready = false
		if Input.is_action_just_pressed(shoot_action):
			shoot() 
			
		
var tilt_ready: bool
	
func _ready() -> void:
	
	add_to_group(Ref.group_players)
	
	# player setup
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"]
	bolt_sprite.modulate = bolt_color
	
#	feat_selector.modulate.a = feat_selector_alpha
	feat_selector.hide()
	available_features.append(feat_selector.get_node("Icons/IconBullet"))
	available_features.append(feat_selector.get_node("Icons/IconMisile"))
	available_features.append(feat_selector.get_node("Icons/IconShocker"))


func _process(delta: float) -> void:
	ray_cast_2d.cast_to = Vector2(velocity.length(),0)
	
#	if camera_follow:
#		camera.position = position

		
	if Ref.game_manager.game_settings["select_feature_mode"]:
		update_feature_selector()

	
func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	if current_motion_state == MotionStates.IDLE: # aplikacija free rotacije
		rotate(delta * rotation_angle * free_rotation_multiplier)




func update_feature_selector():
	
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconBullet.get_node("Label").text = "%02d" % bullet_count
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconMisile.get_node("Label").text = "%02d" % misile_count
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconShocker.get_node("Label").text = "%02d" % shocker_count
	

	
func shoot():
	
	match selected_feat_index:
		0: # bullet
			shooting("bullet")
		1: # misile
			shooting("misile")
		2: # shocker
			shooting("shocker")
			


func select_feature():
	
	var selector_timer: Timer = $BoltHud/VBoxContainer/FeatSelector/SelectorTimer
	var selector_visibily_time: float = 1
	selector_timer.wait_time = selector_visibily_time
	selector_timer.start()

	if not feat_selector.visible:
		feat_selector.show() # samo prižgem
	elif feat_selector.visible: # samo dvignem index
		selected_feat_index += 1
	
	
	# reset indexa, če je prevelik
	if selected_feat_index > available_features.size() - 1:
		selected_feat_index = 0
	
	# setam vidnost ikon
	for feature in available_features:
		feature.hide() # najprej jo skrijem
		if feature == available_features[selected_feat_index]: # potem pokažem izbrano 
			feature.show()		


func pull_bolt_on_screen(pull_position: Vector2):
	
	if not bolt_active:
		return
		
	bolt_collision.disabled = true
	shield_collision.disabled = true
	
	var pull_time: float = 0.2
	
	# spawn particles
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 0.2, pull_time/2).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 1, pull_time/2).set_delay(pull_time/2).set_ease(Tween.EASE_IN)
	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	
	update_gas(Ref.game_manager.game_settings["pull_penalty_gas"])
	
	# ugasnem trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false


func _on_SelectorTimer_timeout() -> void:
	
#	feat_selector.modulate.a = feat_selector_alpha
	feat_selector.hide()


func _on_TiltTimer_timeout() -> void:

	tilt_input_timer.stop()
