extends Bolt
class_name Player


export var player_id: String # = "P2" # more bit določen apriorij, ker po imenu določim profil ... ob spawnu dobi pravo ime
var player_name: String
var player_color: Color
var player_profile: Dictionary
#var player_index: int # ga dobi iz game managerja ob kreaciji

var controller_profile_name: String
var controller_profile: Dictionary
var controller_actions: Dictionary

# imena akcij za pripis na evente
var fwd_action # = controller_actions["fwd_action"]
var rev_action # = controller_actions["rev_action"]
var left_action # = controller_actions["left_action"]
var right_action # = controller_actions["right_action"]
var shoot_bullet_action # = controller_actions["shoot_bullet_action"]
var shoot_misile_action # = controller_actions["shoot_misile_action"]
var shoot_shocker_action # = controller_actions["shoot_shocker_action"]

onready var controller_profiles: Dictionary = Pro.default_controller_actions

func _ready() -> void:
	
	# player setup
#	name = player_name _temp off
	player_profile = Pro.default_player_profiles[bolt_owner]
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"]
	bolt_sprite.modulate = bolt_color
	add_to_group(Ref.group_players)
	
	# controller setup
	controller_profile_name = player_profile["controller_profile"]
	controller_actions = controller_profiles[controller_profile_name]
	# controller_profile = Profiles.default_controller_profiles[controller_profile_name]
	
	# asign action names
	fwd_action = controller_actions["fwd_action"]
	rev_action = controller_actions["rev_action"]
	left_action = controller_actions["left_action"]
	right_action = controller_actions["right_action"]
	shoot_bullet_action = controller_actions["shoot_bullet_action"]
	shoot_misile_action = controller_actions["shoot_misile_action"]
	shoot_shocker_action = controller_actions["shoot_shocker_action"]


func _input(event: InputEvent) -> void:
	
	if control_enabled:
		
		# move
		if Input.is_action_pressed(fwd_action):
			engine_power = fwd_engine_power
			# motion state
			fwd_motion = true
			# off
			rev_motion = false
			no_motion = false
		elif Input.is_action_pressed(rev_action):
			engine_power = - rev_engine_power
			# motion state
			rev_motion = true
			#off
			fwd_motion = false
			no_motion = false
		else:			
			engine_power = 0
			# motion state
			no_motion = true
			# off
			rev_motion = false
			fwd_motion = false
		
		# rotation
		rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0	
		
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
	# camera follow
	if camera_follow:
		camera.position = position
		
	
func _physics_process(delta: float) -> void:
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	
	# aplikacija free rotacije
	if not fwd_motion and not rev_motion: 
		rotate(delta * rotation_angle * free_rotation_multiplier)


func reset_bolt():
	pass


func pull_bolt_on_screen(pull_position: Vector2):
	
#	global_position = pull_position	
	set_deferred("bolt_collision.disabled", true) # na priporočilo
	set_deferred("shield_collision", true) # na priporočilo
#	shield_collision.disabled = true
	modulate.a = 0.7
	
	# spawn particles
	
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, 0.15)
	
	
	
	# bolt_to_pull.global_position += vector_to_pull_position			
	
	# posledice
	modulate = Color.red

	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
	
#	var pull_trail: Line2D# = spawn_new_trail()
#	call_deferred("spawn_new_trail")
#	pull_trail.modulate = bolt_color
##	if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
#	if bolt_trail_active and velocity.length() > 0:
#		bolt_trail_active = false
#	new_bolt_trail = BoltTrail.instance()
#	new_bolt_trail.modulate.a = bolt_trail_alpha
#	new_bolt_trail.z_index = z_index + Set.trail_z_index
#	Ref.node_creation_parent.add_child(new_bolt_trail)
#	bolt_trail_active = true 
