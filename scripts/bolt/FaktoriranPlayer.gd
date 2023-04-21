extends Bolt


var player_index: int # ga dobi iz game managerja ob kreaciji

var controller_profile_name: String
var controller_profile: Dictionary
var controller_actions: Dictionary

onready var health_bar: Polygon2D = $EnergyPoly

# plejer stats
onready var player_stats: Dictionary = Profiles.default_player_stats
onready var health: float = Profiles.default_player_stats["health"] # tale se sreminja z igro
onready var health_max: float = Profiles.default_player_stats["health"] # tole je konstanta da se lahko vrne
onready var life: int = Profiles.default_player_stats["life"]
onready var bullet_count = Profiles.default_player_stats["bullet_count"]
onready var misile_count = Profiles.default_player_stats["misile_count"]
onready var shocker_count = Profiles.default_player_stats["shocker_count"]

var fwd_action # = controller_actions["fwd_action"]
var rev_action # = controller_actions["rev_action"]
var left_action # = controller_actions["left_action"]
var right_action # = controller_actions["right_action"]
var shoot_bullet_action # = controller_actions["shoot_bullet_action"]
var shoot_misile_action # = controller_actions["shoot_misile_action"]
var shoot_shocker_action # = controller_actions["shoot_shocker_action"]

var player_name: String = "P1"
var player_profile: Dictionary
var player_color: Color
	
	
func _ready() -> void:
		
	# player setup
#	name = player_name _temp off
	player_profile = Profiles.default_player_profiles[player_name]
	bolt_color = player_profile["player_color"]
	bolt_sprite.modulate = bolt_color
	add_to_group(Config.group_players)
	
	# controller setup
	controller_profile_name = player_profile["controller_profile"]
#	controller_profile = Profiles.default_controller_profiles[controller_profile_name]
	controller_actions = Profiles.default_controller_actions[controller_profile_name]
	
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
		input_power = Input.get_action_strength(fwd_action) - Input.get_action_strength(rev_action) # +1, -1 ali 0
		rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0	

		if Input.is_action_just_pressed(shoot_bullet_action):
			print("bullet")
			.shooting("bullet")
		if Input.is_action_just_released(shoot_misile_action):	
			.shooting("misile")
		if Input.is_action_just_released(shoot_shocker_action):	
			.shooting("shocker")
	

func state_machine(delta):
	
	#motion states
	if input_power > 0 and control_enabled:
		power_fwd = true
		power_rev = false
		no_power = false
	elif input_power < 0 and control_enabled:
		power_fwd = false
		power_rev = true
		no_power = false
	elif input_power == 0 or not control_enabled:
		power_fwd = false
		power_rev = false
		no_power = true
	

func _process(delta: float) -> void:
	
	# camera follow
	if camera_follow:
		camera.position = position
		
	
func _physics_process(delta: float) -> void:
	
#	print(input_power)
	state_machine(delta)
	
	health_bar.rotation = -(rotation) # negiramo rotacijo bolta, da je pri miru
	health_bar.global_position = global_position + Vector2(-3.5, 8) # negiramo rotacijo bolta, da je pri miru
	
	health_bar.scale.x = health / health_max
	if health_bar.scale.x < 0.5:
		health_bar.color = Color.indianred
	else:
		health_bar.color = Color.aquamarine


func manage_player_stats(stat_changed: String, change_value: float):

#	health -= damage
#	health_bar.scale.x = health/10
#	if health <= 0:
#		die()
	pass
	
func shooting(weapons) -> void:
#	match weapons:
#		"Bullet":	
#			if bullet_reloaded:
#				var new_bullet = Bullet.instance()
##				new_bullet.global_position = bolt_sprite.global_position# + gun_pos
#				new_bullet.global_position = to_global(gun_pos)
#				new_bullet.global_rotation = bolt_sprite.global_rotation
#				new_bullet.spawned_by = name # ime avtorja izstrelka
#				new_bullet.spawned_by_color = player_color
#				Global.node_creation_parent.add_child(new_bullet)
#
#				bullet_reloaded = false
#				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
#				bullet_reloaded= true
#
#		"Misile":
#			if misile_reloaded and misile_count > 0:			
#				var new_misile = Misile.instance()
#				new_misile.global_position = to_global(gun_pos)
#				new_misile.global_rotation = bolt_sprite.global_rotation
#				new_misile.spawned_by = name # ime avtorja izstrelka
#				new_misile.spawned_by_color = player_color
#				new_misile.spawned_by_speed = velocity.length()
#				Global.node_creation_parent.add_child(new_misile)
#				misile_count -= 1
#
#				misile_reloaded = false
#				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
#				misile_reloaded= true
#
#				# reload, ko je uničena				
#				# Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
#				# misile_reloaded = false
#
#		"Shocker":
#			if shocker_reloaded and shocker_count > 0:			
#				var new_shocker = Shocker.instance()
#				new_shocker.global_position = to_global(shocker_pos)
#				new_shocker.global_rotation = bolt_sprite.global_rotation
#				new_shocker.spawned_by = name # ime avtorja izstrelka
#				new_shocker.spawned_by_color = player_color
#				Global.node_creation_parent.add_child(new_shocker)
#				shocker_count -= 1
#
#				shocker_reloaded = false
#				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
#				shocker_reloaded= true
#
#		"Shield":		
#			if shields_on == false:
#				shield.modulate.a = 1
#				animation_player.play("shield_on")
#				shields_on = true
#				bolt_collision.disabled = true
#				shield_collision.disabled = false
#			else:
#				animation_player.play_backwards("shield_on")
#				# shields_on = false # premaknjeno dol na konec animacije
#				# collisions setup premaknjeno dol na konec animacije
#				shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja
	pass

			
#func die():
#
##	# shake camera
##	camera.add_trauma(camera.bolt_explosion_shake)
##
##	# najprej explodiraj 
##	# potem ugasni sprite in coll 
##	# potem ugasni motor in štartaj trail decay
##	# explozijo izključi ko grejo partikli ven
##	var new_exploding_bolt = ExplodingBolt.instance()
##	new_exploding_bolt.global_position = global_position
##	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
##	new_exploding_bolt.modulate = modulate
##	new_exploding_bolt.modulate.a = 1
##	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
##	Global.node_creation_parent.add_child(new_exploding_bolt)
##
##	queue_free()		
#	pass
