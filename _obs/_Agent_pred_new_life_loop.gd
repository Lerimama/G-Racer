extends RigidBody2D
#class_name Agent


signal activity_changed
signal stat_changed (stats_owner_id, driver_stats) # agent in damage

export var height: float = 0 # na redi potegne iz pro
export var elevation: float = 0
export (NodePath) var engines_path: String  # _temp ... engines
export var group_weapons_by_type: bool = true

var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju

# driver
var driver_index: int
var driver_profile: Dictionary
var driver_stats: Dictionary

# agent
var agent_profile: Dictionary
var agent_type: int
var agent_color: Color = Color.red
var gas_usage: float
var gas_usage_idle: float
var gas_tank_size: float
var agent_camera: Camera2D # spawner
var near_radius: float
var pseudo_stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
var velocity: Vector2 = Vector2.ZERO

# tracking
var ai_target_rank: int
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var body_state: Physics2DDirectBodyState
var tracker: PathFollow2D # napolni se, ko se agent pripiše trackerju

# weapons
var triggering_weapons: Array = []

onready var controller: Node = $AgentController # zamenja se ob spawnu AI/PLAYER
onready var motion_manager: Node = $MotionManager

onready var equip_positions: Node2D = $EquipPositions
onready var weapons: Node2D = $Weapons
onready var equipment: Node2D = $Equipment
onready var shape_poly: Polygon2D = $ShapePoly
onready var engines: Node2D = get_node(engines_path)

onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var revive_timer: Timer = $ReviveTimer
onready var trail_source: Position2D = $TrailSource
onready var front_mass: RigidBody2D = $Mass/Front/FrontMass
onready var rear_mass: RigidBody2D = $Mass/Rear/RearMass
onready var terrain_detect: Area2D = $TerrainDetect
onready var animation_player: AnimationPlayer = $AnimationPlayer

onready var CollisionParticles: PackedScene = preload("res://game/agent/fx/AgentCollisionParticles.tscn")
onready var ExplodingAgent: PackedScene = preload("res://game/agent/fx/ExplodingAgent.tscn")

# debug
onready var direction_line: Line2D = $DirectionLine
var debug_trail_time: float = 0
var debug_trail: Line2D


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"): # idle
		motion_manager.boost_agent()


func _ready() -> void:
#	printt("AGENT", self.name, get_collision_layer_bit(0))

	add_to_group(Rfs.group_agents)

	z_as_relative = false
	z_index = Pfs.z_indexes["agents"]

	equip_positions.hide()

	agent_type = driver_profile["agent_type"]
	ai_target_rank = agent_profile["ai_target_rank"]
	agent_color = driver_profile["driver_color"] # agagentobarva ...
	height = agent_profile["height"]
	elevation = agent_profile["elevation"]
	gas_tank_size = agent_profile["gas_tank_size"]
	gas_usage = agent_profile["gas_usage"]
	gas_usage_idle = agent_profile["gas_usage_idle"]
	near_radius = get_node("NearArea/CollisionShape2D").shape.radius

	_add_controller()
	_add_motion_manager()
	motion_manager._set_default_parameters()

	group_weapons_by_type = true

	# set weapons
	# če je opremljeno na pozicijo
	# če ni uniq tip in bi moralo bit, ga ne dodam v trriggered
	for weapon in weapons.get_children():
		var legit: bool = true
		if equip_positions.positions_equiped.values().has(weapon):
			weapon.setup(self)
			var used_for_triggering: bool = true
			if weapon.weapon_type == weapon.WEAPON_TYPE.MALA: # temp MALA not used for trggering
				used_for_triggering = false
			if group_weapons_by_type:
				for trigg_weapon in triggering_weapons:
					if "weapon_type" in trigg_weapon and trigg_weapon.weapon_type == weapon.weapon_type:
						used_for_triggering = false
			if used_for_triggering:
				if weapon.has_method("_on_weapon_triggered"):
						weapon.connect("weapon_shot", self, "_update_weapon_stat")
						triggering_weapons.append(weapon)
		else:
			weapon.hide()

	# set equipement
	for equip in equipment.get_children():
		if equip_positions.positions_equiped.values().has(equip):
			print ("equipment")
		else:
			print ("hide")
			equip.hide()


func _process(delta: float) -> void:

	# debug trail
	if Input.is_action_pressed("T"):
		if not debug_trail:
			debug_trail = Line2D.new()
			debug_trail.z_index = 1000
			Rfs.node_creation_parent.add_child(debug_trail)
		else:
			debug_trail_time += delta
			if debug_trail_time > 0.1:
				debug_trail.add_point(global_position)
				debug_trail_time = 0
	if Input.is_action_just_released("T"):
		debug_trail_time = 0
		debug_trail = null

	trail_source.update_trail(velocity.length())

	if engines.engines_on: # poraba
		update_stat(Pfs.STATS.GAS, gas_usage)


func _integrate_forces(state: Physics2DDirectBodyState) -> void: # get state in set forces
	# print("power %s / " % motion_manager.current_engine_power, "force %s" % force)

	body_state = state
	velocity = state.get_linear_velocity() # tole je bol prej brez stejta

	if is_active:
		set_applied_torque(motion_manager.torque_on_agent)
		match motion_manager.motion:
			motion_manager.MOTION.IDLE:
				# sila je 0 samo, če ni idle rotacije ali pa ja ROTATION, ker rotiram s torqu
				front_mass.set_applied_force(motion_manager.force_on_agent)
				rear_mass.set_applied_force(-motion_manager.force_on_agent)
			motion_manager.MOTION.FWD:
				front_mass.set_applied_force(motion_manager.force_on_agent)
				rear_mass.set_applied_force(Vector2.ZERO)
			motion_manager.MOTION.REV:
				front_mass.set_applied_force(Vector2.ZERO)
				rear_mass.set_applied_force(motion_manager.force_on_agent)


# LAJF ----------------------------------------------------------------------------


func on_hit(hit_by: Node2D, hit_global_position: Vector2):

	if is_shielded:
		return

	update_stat(Pfs.STATS.HEALTH, - hit_by.hit_damage)

	if hit_by.is_in_group(Rfs.group_bullets):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia)
		if agent_camera:
			agent_camera.shake_camera(agent_camera.bullet_hit_shake)

	elif hit_by.is_in_group(Rfs.group_misiles):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		#		apply_central_impulse(hit_by_inertia)
		# get_contact_collider_position(contact_idx: int) # ... Returns the contact position in the collider.
		# get_contact_collider_velocity_at_position(contact_idx: int) # Returns the linear velocity vector at the collider's contact point.
		# get_contact_impulse(contact_idx: int) # Impulse created by the contact. Only implemented for Bullet physics.
		#		var hit_position: Vector2 =
		#		var global_hit_position: Vector2 = to_global(hit_position)
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia) # OPT misile impulse knockback ... ne deluje?
		if agent_camera:
			agent_camera.shake_camera(agent_camera.misile_hit_shake)
		Rfs.sound_manager.play_sfx("agent_explode")
		_explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa

	elif hit_by.is_in_group(Rfs.group_mine):
		var inertia_factor: float = 400000
		var hit_by_power: float = inertia_factor
		apply_torque_impulse(hit_by_power)
		if agent_camera:
			agent_camera.shake_camera(agent_camera.misile_hit_shake)

	#	if inertIJA > jadajasdasd >>>> to dissaray


func _destroy():

	_explode()
	motion_manager.motion = motion_manager.MOTION.IDLE
	engines.shutdown_engines()
	self.is_active = false
	update_stat(Pfs.STATS.LIFE, - 1)

	if driver_stats[Pfs.STATS.LIFE] > 0:
		revive_timer.start(revive_time)
	else:
		queue_free()


func _explode():

	# disable staf
	collision_shape.set_deferred("disabled", true)
	#	collision_shape.disabled = true

	trail_source.decay()

	visible = false
	controller.set_process_input(false)
	set_physics_process(false)
	# resetira na revive

	# spawn eksplozije
	var new_exploding_agent = ExplodingAgent.instance()
	new_exploding_agent.global_position = global_position
	new_exploding_agent.global_rotation = global_rotation
	new_exploding_agent.modulate.a = 1
	new_exploding_agent.velocity = velocity # podamo hitrost, da se premika s hitrostjo agenta
	new_exploding_agent.spawner_color = agent_color
	new_exploding_agent.z_index = z_index + 1
	Rfs.node_creation_parent.add_child(new_exploding_agent)

	if agent_camera:
		agent_camera.shake_camera(agent_camera.agent_explosion_shake)
	queue_free()


func _revive():

	# reset pred prikazom
	collision_shape.set_deferred("disabled", false)
	#	collision_shape.disabled = false

	self.is_active = true
	controller.set_process_input(true)
	set_physics_process(true)
	visible = true

	# reset energije
	update_stat(Pfs.STATS.HEALTH, 1)


func _reset_motion():
	# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v agent "v igri"

	motion_manager.motion = motion_manager.MOTION.IDLE
	front_mass.set_applied_force(Vector2.ZERO)
	front_mass.set_applied_torque(0)
	rear_mass.set_applied_force(Vector2.ZERO)
	rear_mass.set_applied_torque(0)
	motion_manager.rotation_dir = 0
	for thrust in engines.all_thrusts:
		thrust.rotation = lerp_angle(thrust.rotation, 0, 0.1)
		thrust.stop_fx()


# UTILITI ------------------------------------------------------------------------------------------------


func drive_in(drive_in_vector: Vector2 = Vector2.ZERO, drive_in_time: float = 1):

	self.is_active = true

	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	motion_manager.motion = motion_manager.MOTION.IDLE
	engines.start_engines()

	var drive_in_finished_position: Vector2 = global_position
	var drive_in_start_position: Vector2 = global_position + drive_in_vector
	# premaknem ga nazaj in zapeljem do linije
	body_state.transform.origin = drive_in_start_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(body_state, "transform:origin", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")

	collision_shape.set_deferred("disabled", false)


func drive_out(drive_out_vector: Vector2 = Vector2.ZERO, drive_out_time: float = 1):

	collision_shape.set_deferred("disabled", true)
	self.is_active = false

	var drive_out_position: Vector2 = global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)

	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(body_state, "transform:rotated", angle_to_vector, drive_out_time/5)
	drive_out_tween.tween_property(body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	engines.shutdown_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), controller.ai_target)
	#	set_physics_process(false)
	#	motion_manager.motion = motion_manager.MOTION.IDLE


func revup():

	$Sounds/EngineRevup.play()
	for thrust in engines.all_thrusts:
		thrust.start_fx(true)


func _spawn_shield():

	var ShieldScene: PackedScene = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = global_position
	new_shield.spawner = self # ime avtorja izstrelka
	new_shield.scale = Vector2.ONE
	new_shield.shield_time = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["time"]

	Rfs.node_creation_parent.add_child(new_shield)


func pull_on_screen(pull_position: Vector2): # kliče GM

	# disejblam koližne
	controller.set_process_input(false)
	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	controller.set_process_input(true)

	update_stat(Pfs.STATS.GAS, Sts.pull_gas_penalty)


func screen_wrap(): # ne uporabljam

	# kopirano iz tutoriala ---> https://www.youtube.com/watch?v=xsAyx2r1bQU
	var xform = body_state.get_transform()
	var screensize: Vector2 = get_viewport_rect().size
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	elif xform.origin.x < 0:
		xform.origin.x = screensize.x
	elif xform.origin.y > screensize.y:
		xform.origin.y = 0
	elif xform.origin.y < 0:
		xform.origin.y = screensize.y
	if not is_active:
		return
	body_state.set_transform(xform)


func _change_activity(new_is_active: bool):

	if not new_is_active == is_active:
		is_active = new_is_active
		if is_active == true:
			controller.set_process_input(true)
			call_deferred("set_physics_process", true)
			call_deferred("set_process", true)
		else: # ga upočasnim v trenutni smeri
			_reset_motion()
			controller.set_process_input(false)
			# nočeš ga skos slišat, če je multiplejer
			engines.shutdown_engines()
			call_deferred("set_physics_process", false)
			call_deferred("set_process", false)

		emit_signal("activity_changed", self)


func _add_controller():

	 # zbrišem placeholder
	controller.queue_free()

	var AgentController: PackedScene# = drivers_controller_profile["controller_scene"]
	if driver_profile["driver_type"] == Pfs.DRIVER_TYPE.AI:
#		controller.controller_type = -1
		AgentController = Pfs.ai_profile["controller_scene"]
	else:
		var drivers_controller_profile: Dictionary = Pfs.controller_profiles[driver_profile["controller_type"]]
		AgentController = drivers_controller_profile["controller_scene"]

	# spawn na vrh agentovega drevesa
	controller = AgentController.instance()
	controller.controlled_agent = self
	controller.agent_manager = motion_manager
	if not driver_profile["driver_type"] == Pfs.DRIVER_TYPE.AI:
		controller.controller_type = driver_profile["controller_type"]

	call_deferred("add_child", controller)
	call_deferred("move_child", controller, 0)


func _add_motion_manager():

	var agent_profile: Dictionary = Pfs.agent_profiles[driver_profile["agent_type"]]
	var motion_manager_path = agent_profile["motion_manager_path"]
	motion_manager.set_script(motion_manager_path)
	motion_manager.managed_agent = self
#	motion_manager.set_process(false)
#	yield(motion_manager, "ready")
	motion_manager.set_deferred("set_process", true)


func on_item_picked(pickable_key: int):

	match pickable_key:
		Pfs.PICKABLE.PICKABLE_SHIELD:
			_spawn_shield()
		Pfs.PICKABLE.PICKABLE_NITRO:
			motion_manager.boost_agent()
		_:
			# če spreminja statistiko
			if Pfs.pickable_profiles[pickable_key].keys().has("driver_stat"):
				var change_value: float = Pfs.pickable_profiles[pickable_key]["value"]
				var change_stat_key: int = Pfs.pickable_profiles[pickable_key]["driver_stat"]
				update_stat(change_stat_key, change_value)


func _update_weapon_stat(stat_key: int, change_value):

	driver_stats[stat_key] += change_value # change_value je + ali -
	#	update_stat(stat_key, change_value)
	emit_signal("stat_changed", driver_index, stat_key, driver_stats[stat_key])


func update_stat(stat_key: int, change_value):

#	if not motion_manager.game_is_on: # _temp neodločen sem
#		return

	var curr_stat_name: String
	driver_stats[stat_key] += change_value # change_value je + ali -

	# health
	if stat_key == Pfs.STATS.HEALTH:
		driver_stats[Pfs.STATS.HEALTH] = clamp(driver_stats[Pfs.STATS.HEALTH], 0, 1) # more bigt , ker max heath zmeri dodam 1
		if driver_stats[Pfs.STATS.HEALTH] == 0:
			_destroy()
		return # poštima ga agent hud

	# gas
	# če zmanjka bencina je deaktiviran
	if driver_stats[Pfs.STATS.GAS] <= 0:
		driver_stats[Pfs.STATS.GAS] = 0
		self.is_active = false

	# če ga je več kot max, povečam max (max je zaradi hud gas bar
	elif driver_stats[Pfs.STATS.GAS] > gas_tank_size:
		gas_tank_size = driver_stats[Pfs.STATS.GAS]

	emit_signal("stat_changed", driver_index, stat_key, driver_stats[stat_key])


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_ReviveTimer_timeout() -> void:

	_revive()


func _on_Agent_body_entered(body: Node2D) -> void:

	if not $Sounds/HitWall2.is_playing():
		$Sounds/HitWall.play()
		$Sounds/HitWall2.play()

	# odbojni partikli
	if velocity.length() > pseudo_stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = body_state.get_contact_local_position(0)
		new_collision_particles.rotation = body_state.get_contact_local_normal(0).angle() # rotacija partiklov glede na normalo površine
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič
		new_collision_particles.color = agent_color
		new_collision_particles.set_emitting(true)
		Rfs.node_creation_parent.add_child(new_collision_particles)

	trail_source.decay()


func _exit_tree() -> void:
	# pospravljanje morebitnih smeti

	#	for sound in sounds.get_children():
	#		sound.stop()
	#	if engine_particles_rear:
	#		engine_particles_rear.queue_free()
	#	if engine_particles_front_left:
	#		engine_particles_front_left.queue_free()
	#	if engine_particles_front_right:
	#		engine_particles_front_right.queue_free()
	##	active_trail.start_decay() # trail decay tween start

	self.is_active = false # zazih
	if agent_camera:
		if agent_camera.follow_target == self:
			agent_camera.follow_target = null
	trail_source.decay()


