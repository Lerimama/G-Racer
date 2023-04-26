extends Bolt


export var analog_input: bool = false

var player_name: String = "P1" # more bit določen apriorij, ker po imenu določim profil ... ob spawnu dobi pravo ime
var player_color: Color
var player_profile: Dictionary
var player_index: int # ga dobi iz game managerja ob kreaciji

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


func _ready() -> void:
	
	# player setup
#	name = player_name _temp off
#	player_profile = Profiles.default_player_profiles[player_name]
#	bolt_color = player_profile["player_color"]
	bolt_color = Profiles.default_player_profiles[player_name]["player_color"]
	bolt_sprite.modulate = bolt_color
	add_to_group(Config.group_players)
	
	# controller setup
	controller_profile_name = Profiles.default_player_profiles[player_name]["controller_profile"]
	controller_actions = Profiles.default_controller_actions[controller_profile_name]
#	controller_profile = Profiles.default_controller_profiles[controller_profile_name]
	
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
		if analog_input: # rezerva
			input_power = Input.get_action_strength(fwd_action) - Input.get_action_strength(rev_action) # +1, -1 ali 0
		else:
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
			.shooting("bullet")
		if Input.is_action_just_released(shoot_misile_action):	
			.shooting("misile")
		if Input.is_action_just_released(shoot_shocker_action):	
			.shooting("shocker")
		if Input.is_action_just_released("pavza"):	
			.shooting("shield")


func _process(delta: float) -> void:
	# camera follow
	if camera_follow:
		camera.position = position
		
	
func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	
	# aplikacija free rotacije
	if not fwd_motion and not rev_motion: 
		rotate(delta * rotation_angle * free_rotation_multiplier)
		