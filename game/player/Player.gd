extends Bolt
class_name Player


var player_name: String # za opredelitev statistike
#var player_color: Color
var player_profile: Dictionary

var controller_profile_name: String
var controller_profile: Dictionary
var controller_actions: Dictionary

# imena akcij za pripis na evente
var fwd_action: String
var rev_action: String
var left_action: String
var right_action: String
var shoot_bullet_action: String
var shoot_misile_action: String
var shoot_shocker_action: String

onready var controller_profiles: Dictionary = Pro.default_controller_actions


func _ready() -> void:
	
	# player setup
#	name = player_name _temp off
	player_profile = Pro.default_player_profiles[bolt_id]
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"]
	bolt_sprite.modulate = bolt_color
	add_to_group(Ref.group_players)
	
	# controller setup
	controller_profile_name = player_profile["controller_profile"]
	controller_actions = controller_profiles[controller_profile_name]
	
	# asign action names
	fwd_action = controller_actions["fwd_action"]
	rev_action = controller_actions["rev_action"]
	left_action = controller_actions["left_action"]
	right_action = controller_actions["right_action"]
	shoot_bullet_action = controller_actions["shoot_bullet_action"]
	shoot_misile_action = controller_actions["shoot_misile_action"]
	shoot_shocker_action = controller_actions["shoot_shocker_action"]

	
func _input(event: InputEvent) -> void:
	
	if not bolt_active:
		return
	
	# move
	if Input.is_action_pressed(fwd_action):
		engine_power = fwd_engine_power
	elif Input.is_action_pressed(rev_action):
		engine_power = - rev_engine_power
	else:			
		engine_power = 0
	
	# rotation
	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali
	# rotation_angle se računa na inputu ... rotation_dir * deg2rad(turn_angle)
	
	# shooting
	if Input.is_action_just_pressed(shoot_bullet_action):
		shooting("bullet")
	if Input.is_action_just_released(shoot_misile_action):	
		shooting("misile")
	if Input.is_action_just_released(shoot_shocker_action):	
		shooting("shocker")
	if Input.is_action_just_released("pavza"):	
		shield_loops_limit = Pro.bolt_profiles[bolt_type]["shield_loops_limit"] 
		activate_shield()


func _process(delta: float) -> void:
	
#	if camera_follow:
#		camera.position = position
	pass
	
func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	if current_motion_state == MotionStates.IDLE: # aplikacija free rotacije
		rotate(delta * rotation_angle * free_rotation_multiplier)


func pull_bolt_on_screen(pull_position: Vector2):
	
	if not bolt_active:
		return
		
#	bolt_collision.disabled = true
#	shield_collision.disabled = true
	
	var pull_time: float = 0.2
	
	# spawn particles
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 0.2, pull_time/2).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 1, pull_time/2).set_delay(pull_time/2).set_ease(Tween.EASE_IN)
#	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	
	manage_gas(Ref.game_manager.game_settings["pull_penalty_gas"])
	
	# ugasnem trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
