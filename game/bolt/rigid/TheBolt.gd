extends RigidBody2D


enum EnginesOn {FRONT, BACK, BOTH, NONE}
var current_engines_on: int = EnginesOn.NONE setget _change_engine_on

# player profil
var bolt_id: int # ga seta spawner
onready var player_profile: Dictionary = Pro.player_profiles[bolt_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]

# player stats
onready var player_stats: Dictionary = Pro.default_player_stats.duplicate()
onready var max_energy: float = player_stats["energy"] # zato, da se lahko resetira

# bolt settings
onready var bolt_profile: Dictionary = Pro.bolt_profiles[bolt_type].duplicate()

# bolt controllers
onready var controller_profiles: Dictionary = Pro.controller_profiles
onready var controller_profile_name: int = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

# nodes
onready var bolt_sprite: Sprite = $BoltSprite
onready var bolt_body: RigidBody2D = $PinJoint2D/Body
onready var rigid_back: RigidBody2D = $RearPin/Rear
onready var rigid_front: RigidBody2D = $FrontPin/Front

# driving
var rotation_dir = 0
var engine_hsp = 1
var max_engine_power: float = 50
var current_engine_power: float = 0
var edited_engine: RigidBody2D
var wheels_to_turn: Array
var forward_direction: int = 1 # rikverc ali naprej
var engine_thrust_rotation: float = 0 # wheels 
var thrust_direction_rotation: float 
var rotation_speed: float = 0.03
var max_thrust_rotation_deg: float = 45
var tilt_mode: = false


func _input(event: InputEvent) -> void:

	if Input.is_action_pressed(selector_action):
		tilt_mode = true
	else:
		tilt_mode = false
			
	if Input.is_action_pressed(fwd_action):
		self.current_engines_on = EnginesOn.FRONT

	elif Input.is_action_pressed(rev_action):
		self.current_engines_on = EnginesOn.BACK
	else:		
		self.current_engines_on = EnginesOn.NONE

	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0


var player_name: String # za opredelitev statistike
var bolt_color: Color = Color.red
onready var bolt_sprite_texture: Texture # = Pro.bolt_profiles[bolt_type]["bolt_texture"] 


func _ready() -> void:
	
#	add_to_group(Ref.group_bolts)	
	add_to_group(Ref.group_thebolts)	
	add_to_group(Ref.group_players)	
	
	player_name = player_profile["player_name"]
	
	# bolt
	if bolt_sprite_texture:
		bolt_sprite.texture = bolt_sprite_texture
	bolt_color = player_profile["player_color"] # bolt se obarva ... 	
	bolt_sprite.modulate = bolt_color	
	
#	current_drag = bolt_drag
#	bolt_shadow.shadow_distance = bolt_max_altitude


var velocity
func _process(delta: float) -> void:
	# power
	if current_engines_on == EnginesOn.NONE:
		current_engine_power = 0
	else:
		current_engine_power += engine_hsp
		current_engine_power = clamp(current_engine_power, 0, max_engine_power)
	
	# rotation
	if rotation_dir == 0:
		engine_thrust_rotation = 0
	else:
		engine_thrust_rotation += rotation_dir * rotation_speed
		engine_thrust_rotation = clamp(engine_thrust_rotation, - deg2rad(max_thrust_rotation_deg), deg2rad(max_thrust_rotation_deg))
		
		var bolt_body_rotation: float = get_global_rotation()
		thrust_direction_rotation = engine_thrust_rotation + bolt_body_rotation

	for wheel in wheels_to_turn:
		wheel.rotation = engine_thrust_rotation
#	manage_motion_fx()


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	velocity = get_linear_velocity()
	var force: Vector2 = Vector2.RIGHT.rotated(thrust_direction_rotation) * 100 * current_engine_power  * forward_direction
	
	if edited_engine:
		if not current_engine_power == 0:
			if tilt_mode:
				edited_engine.set_applied_force(Vector2.ZERO)
				rigid_front.set_applied_force(force)
				rigid_back.set_applied_force(force)
			else:
				edited_engine.set_applied_force(force)
		else:
			edited_engine.set_applied_force(Vector2.ZERO)






func drive_in(drive_in_time: float):
	pass
#	# da ugotovim, kdaj so vsi zapeljani# bolt.bolt_collision.set_disabled(true) # da ga ne moti morebitna stena
#	var drive_in_finished_position: Vector2 = global_position
#	var drive_in_distance: float = 50
#	global_position -= drive_in_distance * transform.x
#
	modulate.a = 1
#	current_motion_state = MotionStates.FWD # za fx
#	start_engines()
#
#	var intro_drive_tween = get_tree().create_tween()
#	intro_drive_tween.tween_property(self, "global_position", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	
func drive_out():
	pass
#	var drive_out_rotation = Ref.current_level.race_start_node.get_rotation_degrees() - 90
#	var drive_out_vector: Vector2 = Ref.current_level.race_start_node.global_position - Ref.current_level.finish_out_position
#	var drive_out_position: Vector2 = global_position - drive_out_vector
#
#	var drive_out_time: float = 2
#	var drive_out_tween = get_tree().create_tween()
#	drive_out_tween.tween_callback(bolt_collision, "set_disabled", [true])
#	drive_out_tween.tween_property(self, "rotation_degrees", drive_out_rotation, drive_out_time/5)
#	drive_out_tween.parallel().tween_property(self, "global_position", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
#	drive_out_tween.tween_property(self, "modulate:a", 0, drive_out_time) # če je krožna dirka in ne gre iz ekrana
var race_time_on_previous_lap: float = 0
func on_lap_finished(level_lap_limit: int):
	
	# lap time
	var current_race_time: float = Ref.hud.game_timer.game_time_hunds
	var current_lap_time: float = current_race_time - race_time_on_previous_lap # če je slednja 0, je prvi krog
	
	var best_lap_time: float = player_stats["best_lap_time"]
	
	if current_lap_time < best_lap_time or best_lap_time == 0:
		update_stat("best_lap_time", current_lap_time)
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, true)
	else:
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, false)

	update_stat("laps_count", 1)
	
	race_time_on_previous_lap = current_race_time # za naslednji krog
	
	if player_stats["laps_count"] >= level_lap_limit: # trenutno končan krog je že dodan
		Ref.game_manager.bolts_finished.append(self)
		update_stat("level_time", current_race_time)
		self.bolt_active = false # more bit za spremembo statistike
		drive_out()
	
	#	printt ("STAT", player_


onready var front_engine_position_L: Position2D = $FrontEnginePositionL
onready var front_engine_position_R: Position2D = $FrontEnginePositionR
onready var rear_engine_position: Position2D = $RearEnginePosition
onready var trail_position: Position2D = $TrailPosition
onready var gun_position: Position2D = $GunPosition
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D
onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/EngineParticlesRear.tscn") 
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/EngineParticlesFront.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")


	
# trail
var bolt_trail_active: bool = false # aktivna je ravno spawnana, neaktiva je "odklopljena"
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var current_active_trail: Line2D
	
func manage_motion_fx():
	print("pedenam")
	engine_particles_rear.global_position = rear_engine_position.global_position
	engine_particles_rear.global_rotation = rear_engine_position.global_rotation
	engine_particles_front_left.global_position = front_engine_position_L.global_position
	engine_particles_front_left.global_rotation = front_engine_position_L.global_rotation - deg2rad(180)
	engine_particles_front_right.global_position = front_engine_position_R.global_position
	engine_particles_front_right.global_rotation = front_engine_position_R.global_rotation - deg2rad(180)
	
	var velocity_len = get_linear_velocity().length()
	print (velocity_len)
	
	var engine_pitch_tween = get_tree().create_tween()
	if current_engines_on == EnginesOn.FRONT:
#	if current_motion_state == MotionStates.FWD:
		engine_pitch_tween.kill() # more bit
		$Sounds/Engine.pitch_scale = 1 + velocity_len/180
		engine_particles_rear.set_emitting(true)
	if current_engines_on == EnginesOn.BACK:
#	elif current_motion_state == MotionStates.REV:
		engine_pitch_tween.kill() # more bit
		$Sounds/Engine.pitch_scale = 1 + velocity_len/180
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_right.set_emitting(true)
	if current_engines_on == EnginesOn.NONE:
#	elif current_motion_state == MotionStates.IDLE:
		if $Sounds/Engine.pitch_scale > 1:
			engine_pitch_tween.tween_property($Sounds/Engine, "pitch_scale", 1, 0.2)
		else:
			engine_pitch_tween.kill()
			$Sounds/Engine.pitch_scale = 1
		
	# spawn trail if not active
	if not bolt_trail_active and get_linear_velocity().length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
#	if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		current_active_trail = spawn_new_trail()
	
	# manage trail
	if bolt_trail_active:
		manage_trail()
var stop_speed: float = 15 # hitrost pri kateri ga kar ustavim	
func manage_trail():
	# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
	var velocity_len = get_linear_velocity().length()
	
	if velocity_len > 0:
#	if velocity.length() > 0:
		
		current_active_trail.add_points(global_position)
		current_active_trail.gradient.colors[1] = trail_pseudodecay_color
		
#		if velocity.length() > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
		if velocity_len > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	else:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena

		
func spawn_new_trail():
	
	var new_bolt_trail: Object
	new_bolt_trail = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	bolt_trail_active = true	
	
	return new_bolt_trail		

func activate_nitro(nitro_power: float, nitro_time: float):
	if bolt_active: # če ni aktiven se sam od sebe ustavi
		pass
#		var current_drag_div = drag_div
#		drag_div = Pro.level_areas_profiles[Pro.LevelAreas.AREA_NITRO]["drag_div"]
#		yield(get_tree().create_timer(nitro_time), "timeout")
#		drag_div = current_drag_div
# PRIVAT ------------------------------------------------------------------------------------------------

var bolt_active: bool = false setget _on_bolt_active_changed # predvsem za pošiljanje signala GMju
func _on_bolt_active_changed(bolt_is_active: bool):
	
	bolt_active = bolt_is_active
	# če je aktiven ga upočasnim v trenutni smeri
	#	var deactivate_time: float = 1.5
	#	if bolt_active == false:
	#		rotation_dir = 0
	#		var deactivate_tween = get_tree().create_tween()
	#		deactivate_tween.tween_property(self, "velocity", Vector2.ZERO, deactivate_time) # tajmiram pojemek 
	#		deactivate_tween.parallel().tween_property(self, "engine_power", 0, deactivate_time)
	#		stop_engines()
	#		Ref.game_manager.check_for_level_finished()
		
	printt("bolt_active", bolt_is_active, self)		
func _change_engine_on(new_engine_on: int):
	
	if current_engines_on == new_engine_on:
		return
	
	# resetiram trenutni engine
	if edited_engine:
		edited_engine.set_applied_force(Vector2.ZERO)
	for wheel in wheels_to_turn:
		wheel.rotation = 0
		wheel.get_node("ThrustFx").stop_fx()	
		
	# nastavim nov engine		
	current_engines_on = new_engine_on

	match current_engines_on:
		EnginesOn.FRONT:
			edited_engine = rigid_front
			forward_direction = 1
			wheels_to_turn = [$Wheels/WheelFrontL, $Wheels/WheelFrontR]
			for wheel in wheels_to_turn:
				wheel.get_node("ThrustFx").start_fx()
		EnginesOn.BACK:
			edited_engine = rigid_back
			forward_direction = -1
			wheels_to_turn = [$Wheels/WheelRearL, $Wheels/WheelRearR]
			for wheel in wheels_to_turn:
				wheel.get_node("ThrustFx").start_fx(true)
		EnginesOn.BOTH:
			forward_direction = 1
			wheels_to_turn = [$Wheels/WheelFrontL, $Wheels/WheelFrontR, $Wheels/WheelRearL, $Wheels/WheelRearR]
		EnginesOn.NONE:
			edited_engine = null

# bolt type profil
onready var ai_target_rank: int = bolt_profile["ai_target_rank"]
onready var reload_ability: float = bolt_profile["reload_ability"]  # reload def gre v weapons
var bolt_position_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju  
	
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var mina_reloaded: bool = true
var mina_released: bool # če je že odvržen v trenutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 1 # poberem jo iz profilov, ali pa kot veleva pickable
onready var BulletScene: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var MisileScene: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var MinaScene: PackedScene = preload("res://game/weapons/Mina.tscn")
			
func shoot(weapon_index: int) -> void:
	
	match weapon_index:
		0: # "bullet":
			if bullet_reloaded:
				if player_stats["bullet_count"] <= 0:
					return
				var new_bullet = BulletScene.instance()
				new_bullet.global_position = gun_position.global_position
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = self # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				new_bullet.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_bullet)
				update_stat("bullet_count", - 1)
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		1: # "misile":
			if misile_reloaded and player_stats["misile_count"] > 0:			
				var new_misile = MisileScene.instance()
				new_misile.global_position = gun_position.global_position
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				update_stat("misile_count", - 1)
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		2: # "mina":
			if mina_reloaded and player_stats["mina_count"] > 0:			
				var new_mina = MinaScene.instance()
				new_mina.global_position = rear_engine_position.global_position
				new_mina.global_rotation = bolt_sprite.global_rotation
				new_mina.spawned_by = self # ime avtorja izstrelka
				new_mina.spawned_by_color = bolt_color
				new_mina.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_mina)
				update_stat("mina_count", - 1)
				mina_reloaded = false
				yield(get_tree().create_timer(new_mina.reload_time / reload_ability), "timeout")
				mina_reloaded = true

	
func on_item_picked(pickable_key: int):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
	
	match pickable_key:
		Pro.Pickables.PICKABLE_BULLET:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["misile_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("bullet_count", pickable_value)
		Pro.Pickables.PICKABLE_MISILE:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("misile_count", pickable_value)
		Pro.Pickables.PICKABLE_MINA:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["misile_count"] = 0
			update_stat("mina_count", pickable_value)
		Pro.Pickables.PICKABLE_SHIELD:
			shield_loops_limit = pickable_value
#			activate_shield()
		Pro.Pickables.PICKABLE_ENERGY:
			player_stats["energy"] = max_energy
		Pro.Pickables.PICKABLE_GAS:
			update_stat("gas_count", pickable_value)
		Pro.Pickables.PICKABLE_LIFE:
			update_stat("life", pickable_value)
		Pro.Pickables.PICKABLE_NITRO:
#			activate_nitro(pickable_value, Pro.pickable_profiles[pickable_key]["duration"])
			pass
		Pro.Pickables.PICKABLE_TRACKING:
#			var default_traction = side_traction
#			side_traction = pickable_value
#			yield(get_tree().create_timer(Pro.pickable_profiles[pickable_key]["duration"]), "timeout")
#			side_traction = default_traction
			pass
		Pro.Pickables.PICKABLE_POINTS:
			update_bolt_points(pickable_value)
		Pro.Pickables.PICKABLE_RANDOM:
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			on_item_picked(random_pickable_key) # pick selected
		

# STATS ------------------------------------------------------------------------------------------------


func update_bolt_points(points_change: int):
	
	update_stat("points", points_change)
	

func update_bolt_rank(new_bolt_rank: int):
	
	update_stat("level_rank", new_bolt_rank)


func update_stat(stat_name: String, change_value: float):
	 
	if not Ref.game_manager.game_on:
		return
			
	if stat_name == "best_lap_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_rank": 
		player_stats[stat_name] = change_value
	else:
		player_stats[stat_name] += change_value # change_value je + ali -
		
	emit_signal("stats_changed", bolt_id, player_stats)



signal stats_changed (stats_owner_id, player_stats) # bolt in damage
