extends RigidBody2D
class_name Bolt


signal bolt_stat_changed (stats_owner_id, driver_stats) # bolt in damage

enum MOTION {ENGINES_OFF, IDLE, FWD, REV, DISARRAY, TILT, FREE_ROTATE, DRIFT, GLIDE} # DIZZY, DYING glede na moč motorja
#enum MOTION {ENGINES_OFF, IDLE, FWD, REV, TILT, FREE_ROTATE, DRIFT, GLIDE, DISARRAY} # DIZZY, DYING glede na moč motorja
var motion: int = MOTION.IDLE setget _change_motion
#var free_motion_type: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke
var free_motion_type: int = MOTION.FREE_ROTATE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.DRIFT # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.GLIDE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = v# presetan motion, ko imaš samo smerne tipke

export var height: float = 0 # PRO
export var elevation: float = 7 # PRO

# seta spawner
var driver_id: int
var driver_profile: Dictionary
var driver_stats: Dictionary
var bolt_profile: Dictionary
# seta ready
var bolt_type: int
var ai_target_rank: int
var bolt_color: Color = Color.red

# bolt
var is_active: bool = false setget _change_activity # predvsem za pošiljanje signala GMju
var bolt_body_state: Physics2DDirectBodyState

onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var revive_timer: Timer = $ReviveTimer
onready var bolt_controller: Node = $BoltController # zamenja se ob spawnu AI/HUMAN

# fx
onready var trail_source: Position2D = $TrailSource
onready var CollisionParticles: PackedScene = preload("res://game/bolt/fx/BoltCollisionParticles.tscn")
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/fx/ExplodingBolt.tscn")

# driving
var rotation_dir = 0
var force_rotation: float = 0 # rotacija v smeri skupne sile motorjev ... določam v _FP (input), apliciram v _IF
var bolt_global_rotation: float
var bolt_global_position: Vector2
var bolt_velocity: Vector2 = Vector2.ZERO
var bolt_shift: int = 1 # -1 = rikverc, +1 = naprej, 0 ne obstaja ... za daptacijo, ker je moč motorja zmeraj pozitivna
var pseudo_stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
onready var drift_power: float = bolt_profile["drift_power"] # 17000
onready var free_rotation_power: float = bolt_profile["free_rotation_power"]
onready var glide_power_front: float = bolt_profile["glide_power_F"] # 46500
onready var glide_power_rear: float = bolt_profile["glide_power_R"] # 50000
onready var gas_usage: float = bolt_profile["gas_usage"]
onready var idle_motion_gas_usage: float = bolt_profile["idle_motion_gas_usage"]
onready var front_mass: RigidBody2D = $Mass/Front/FrontMass
onready var rear_mass: RigidBody2D = $Mass/Rear/RearMass

# engine power
var engine_power = 0
var max_engine_power_adon: float = 0 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
var max_engine_power_factor: float = 1 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
onready var max_engine_power: float = bolt_profile["max_engine_power"]
onready var accelaration_power: float = bolt_profile["accelaration_power"] # delež engine powerja, ki se sešteva
onready var fast_start_engine_power: float = bolt_profile["fast_start_engine_power"] # 500
# engine rotation / direction
var heading_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float = 0.1
onready var max_engine_rotation_deg: float = bolt_profile["max_engine_rotation_deg"]
var max_thrust_rotation_deg: float = 15
export (NodePath) var bolt_engines_path: String  # _temp
onready var engines: Node2D = get_node(bolt_engines_path)

# battle
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var is_shooting: bool = false # način, ki je boljši za efekte

# racing
var bolt_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju
var race_time_on_previous_lap: float = 0

# debug smerna linija
onready var direction_line: Line2D = $DirectionLine

# neu
var using_nitro: bool = false
onready var bolt_hud: Node2D = $BoltHud
onready var available_weapons: Array = [$Turret, $Dropper, $LauncherL, $LauncherR]
onready var chassis: Node2D = $Chassis
onready var terrain_detect: Area2D = $TerrainDetect
onready var animation_player: AnimationPlayer = $AnimationPlayer
#var current_top_suface_type: int = 0 # preverjam spremembo, da ne setam na vsak frejm


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"): # idle
		use_nitro()


func _ready() -> void:
#	printt("BOLT", self.name, get_collision_layer_bit(0))
	add_to_group(Rfs.group_bolts)

	z_as_relative = false
	z_index = Pfs.z_indexes["bolts"]

	# lnf
	bolt_type = driver_profile["bolt_type"]
	ai_target_rank = bolt_profile["ai_target_rank"]
	bolt_color = driver_profile["driver_color"] # bolt se obarva ...
	chassis.get_node("BoltShape").modulate = bolt_color

	# fizka
	mass = bolt_profile["mass"]
	linear_damp = bolt_profile["drive_lin_damp"]
	angular_damp = bolt_profile["drive_ang_damp"]
	physics_material_override.friction = bolt_profile["friction"]
	physics_material_override.bounce = bolt_profile["bounce"]
	rear_mass.linear_damp = bolt_profile["drive_lin_damp_rear"]

	# weapon settings
	for weapon in available_weapons:
		weapon.set_weapon()

	_add_bolt_controller()

	# debug ... setup panel
	var setup_layer_dict: Dictionary = { # imena so enaka kot samo variable
		"mass": mass,
		"angular_damp": angular_damp,
		"linear_damp": linear_damp,
		"drift_power" : drift_power,
		"free_rotation_power" : free_rotation_power,
		"glide_power_F" : glide_power_front,
		"glide_power_R" : glide_power_rear,
		"elevation" : elevation,
	}
	if driver_id == Pfs.DRIVER.P1:
		Rfs.setup_layer.build_setup_layer(setup_layer_dict, self)
		Rfs.setup_layer.add_new_line_to_setup_layer("back_linear_dump", "linear_damp", rear_mass.linear_damp, rear_mass)
		Rfs.setup_layer.add_new_line_to_setup_layer("engine_power", "max_engine_power", max_engine_power, self)


func _process(delta: float) -> void:

#	printt("max_engine_power", max_engine_power)
	trail_source.update_trail(bolt_velocity.length())

	if not is_active: # resetiram, če ni aktiven
		engine_power = 0
		rotation_dir = 0
	else:
		_motion_state_machine()

		max_engine_power = (bolt_profile["max_engine_power"] + max_engine_power_adon) * max_engine_power_factor
		engine_power = clamp(engine_power, 0, max_engine_power)
		update_stat(Pfs.STATS.GAS_COUNT, gas_usage)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	bolt_body_state = state
	bolt_velocity = state.get_linear_velocity() # tole je bol prej brez stejta
	bolt_global_position = get_global_position() # OPT kje je ta funkcija
	bolt_global_rotation = rotation # a je treba?

	if not is_active:
		pass
	else:
		# sile na neuporabljeno masso se resetirajo ob menjavi motion stanja
		var debug_force: Vector2 # dbueg
		match motion:
			MOTION.IDLE:
				var force: Vector2 = Vector2.RIGHT.rotated(force_rotation) * bolt_shift
				if bolt_shift > 0:
					front_mass.set_applied_force(force)
				else:
					rear_mass.set_applied_force(force)
				debug_force = force
			MOTION.FWD:
				var force: Vector2 = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift
				front_mass.set_applied_force(force)
				debug_force = force
			MOTION.REV:
				var force: Vector2 = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift
				rear_mass.set_applied_force(force)
				debug_force = force
			MOTION.DISARRAY:
				pass
#				front_mass.set_applied_force(Vector2.ZERO)
#				rear_mass.set_applied_force(Vector2.ZERO)
			MOTION.FREE_ROTATE:
				var force: Vector2 = Vector2.UP.rotated(bolt_global_rotation) * free_rotation_power * rotation_dir
				rear_mass.set_applied_force(force)
				front_mass.set_applied_force(- force)
				debug_force = force
			MOTION.DRIFT:
				var force: Vector2 = Vector2.RIGHT.rotated(force_rotation) * 100 * engine_power
#				force = Vector2.RIGHT.rotated(force_rotation) * 100 * engine_power# * bolt_shift
#				engine_power = max_engine_power # poskrbi za bolj "tight" obrat
				front_mass.set_applied_force(force)
#				rear_mass.set_applied_force(Vector2.UP.rotated(bolt_global_rotation) * 1000 * rotation_dir)
				debug_force = force
			MOTION.GLIDE:
				var force: Vector2 = Vector2.DOWN.rotated(bolt_global_rotation) * rotation_dir
				front_mass.set_applied_force(force * glide_power_front)
				rear_mass.set_applied_force(force * glide_power_rear)
				debug_force = force

		# debug
		if not debug_force == Vector2.ZERO:
			var vector_to_target = debug_force.normalized() * 100
			vector_to_target = vector_to_target.rotated(- get_global_rotation())# - get_global_rotation())
			direction_line.set_point_position(1, vector_to_target)

		# printt("rot power", front_mass.get_applied_force().length(), rear_mass.get_applied_force().length())
		# print("power %s / " % engine_power, "force %s" % force)


func _motion_state_machine():


	heading_rotation = lerp_angle(heading_rotation, rotation_dir * deg2rad(max_engine_rotation_deg) * bolt_shift, engine_rotation_speed)
	# printt("heading", rad2deg(heading_rotation))
	var max_free_thrust_rotation_deg: float = 90 # PRO
	var rotate_to_angle: float = rotation_dir * deg2rad(max_free_thrust_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)

	# force global rotation ... premaknjena na kotrolerje
	#	force_rotation = heading_rotation + get_global_rotation() # da ne striže (_FP!!) prestavljeno v kontrolerja

	match motion:
		MOTION.IDLE:
			engine_power = 0
			for thrust in engines.all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
		MOTION.FWD:
			engine_power += accelaration_power
			if Rfs.game_manager.fast_start_window:
				engine_power += fast_start_engine_power
			for thrust in engines.front_thrusts:
				thrust.rotation = heading_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in engines.rear_thrusts:
				thrust.rotation = - heading_rotation
		MOTION.REV:
			engine_power += accelaration_power
			for thrust in engines.front_thrusts:
				thrust.rotation = - heading_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in engines.rear_thrusts:
				thrust.rotation = heading_rotation + deg2rad(180)
			# OPT obrat pogona v rikverc ... smooth rotacija ... dela ok dokler ne vozim naokoli, potem se smeri vrtenja podrejo
			#				for thrust in engines.all_thrusts:
			#					var rotation_direction: int = 1
			#					if thrust.position_on_bolt == thrust.POSITION.LEFT:
			#						rotation_direction = -1
			#					var rotate_to: float = (heading_rotation + deg2rad(180)) * rotation_direction
			#					thrust.rotation = lerp_angle(thrust.rotation, rotate_to, engine_rotation_speed)
		MOTION.FREE_ROTATE:
			engine_power = 0
			for thrust in engines.front_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
			for thrust in engines.rear_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
		MOTION.DRIFT: # zadnji pogon v smeri zavoja
			engine_power = lerp(engine_power, 0, 0.01)
		MOTION.GLIDE: # oba pogona  v smeri premika
			engine_power = 0
			for thrust in engines.all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)


func _change_motion(new_motion: int):

	# nastavim nov engine
	if not new_motion == motion:
		motion = new_motion
		match motion:
			MOTION.IDLE:
				if bolt_shift > 0:
					rear_mass.set_applied_force(Vector2.ZERO)
				else:
					front_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["idle_lin_damp"]
				angular_damp = bolt_profile["idle_ang_damp"]
				for thrust in engines.all_thrusts:
					thrust.stop_fx()
			MOTION.FWD:
				rear_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["drive_lin_damp"]
				angular_damp = bolt_profile["drive_ang_damp"]
				for thrust in engines.all_thrusts:
					thrust.start_fx()
			MOTION.REV:
				front_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["drive_lin_damp"]
				angular_damp = bolt_profile["drive_ang_damp"]
				for thrust in engines.all_thrusts:
					thrust.start_fx()
			MOTION.FREE_ROTATE:
				linear_damp = bolt_profile["idle_lin_damp"]
				angular_damp = bolt_profile["idle_ang_damp"] # če tega ni moraš prekinit tipko, da se preklopi preko IDLE stanja
				for thrust in engines.all_thrusts:
					thrust.start_fx()
			MOTION.DRIFT: # ni zrihtano
				linear_damp = bolt_profile["idle_lin_damp"]
				#			linear_damp = bolt_profile["drive_lin_damp"]
				#			angular_damp = bolt_profile["idle_ang_damp"]
				engine_power = max_engine_power # poskrbi za bolj "tight" obrat
				for thrust in engines.front_thrusts:
					thrust.stop_fx()
				for thrust in engines.rear_thrusts:
					thrust.start_fx()
			MOTION.GLIDE:
				linear_damp = bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				angular_damp = bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
				for thrust in engines.all_thrusts:
					thrust.start_fx()
			MOTION.DISARRAY:
				pass


func _change_activity(new_is_active: bool):

	if not new_is_active == is_active:
		is_active = new_is_active
		match is_active:
			true:
				bolt_controller.set_process_input(true)
				call_deferred("set_physics_process", true)
				call_deferred("set_process", true)
			false: # ga upočasnim v trenutni smeri
				reset_bolt()
				bolt_controller.set_process_input(false)
				# nočeš ga skos slišat, če je multiplejer
				engines.shutdown_engines()
				Rfs.game_manager.check_for_level_finished()
				call_deferred("set_physics_process", false)
				call_deferred("set_process", false)


func _add_bolt_controller():

	 # zbrišem placeholder
	bolt_controller.queue_free()

	# opredelim controller sceno
	var drivers_controller_profile: Dictionary = Pfs.controller_profiles[driver_profile["controller_type"]]
	var BoltController: PackedScene = drivers_controller_profile["controller_scene"]

	# spawn na vrh boltovega drevesa
	bolt_controller = BoltController.instance()
	bolt_controller.controlled_bolt = self
	bolt_controller.controller_type = driver_profile["controller_type"]
	call_deferred("add_child", bolt_controller)
	call_deferred("move_child", bolt_controller, 0)


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
		Rfs.game_camera.shake_camera(Rfs.game_camera.bullet_hit_shake)

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
		Rfs.game_camera.shake_camera(Rfs.game_camera.misile_hit_shake)
		Rfs.sound_manager.play_sfx("bolt_explode")
		_explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa

	elif hit_by.is_in_group(Rfs.group_mine):
		var inertia_factor: float = 400000
		var hit_by_power: float = inertia_factor
		apply_torque_impulse(hit_by_power)
		Rfs.game_camera.shake_camera(Rfs.game_camera.misile_hit_shake)


func _destroy_bolt():

	_explode()
	motion = MOTION.ENGINES_OFF
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
	bolt_controller.set_process_input(false)
	set_physics_process(false)
	# resetira na revive

	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = bolt_global_position
	new_exploding_bolt.global_rotation = chassis.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = bolt_velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawner_color = bolt_color
	new_exploding_bolt.z_index = z_index + 1
	Rfs.node_creation_parent.add_child(new_exploding_bolt)

	Rfs.game_camera.shake_camera(Rfs.game_camera.bolt_explosion_shake)


func _revive_bolt():

	# reset pred prikazom
	collision_shape.set_deferred("disabled", false)
	#	collision_shape.disabled = false

	self.is_active = true
	bolt_controller.set_process_input(true)
	set_physics_process(true)
	visible = true

	# reset energije
	update_stat(Pfs.STATS.HEALTH, 1)


# UTILITI ------------------------------------------------------------------------------------------------


func reset_bolt():
	# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v bolt "v igri"

	motion = MOTION.IDLE
	front_mass.set_applied_force(Vector2.ZERO)
	front_mass.set_applied_torque(0)
	rear_mass.set_applied_force(Vector2.ZERO)
	rear_mass.set_applied_torque(0)
	rotation_dir = 0
	engine_power = 0
	for thrust in engines.all_thrusts:
		thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
		thrust.stop_fx()


func drive_in(drive_in_time: float = 2):

	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	motion = MOTION.IDLE
	engines.start_engines()

	#	var drive_in_time: float = 2
	var drive_in_finished_position: Vector2 = bolt_global_position
	var drive_in_vector: Vector2 = Rfs.current_level.drive_in_position.rotated(Rfs.current_level.level_start.global_rotation)
	var drive_in_start_position: Vector2 = bolt_global_position + drive_in_vector
	# premaknem ga nazaj in zapeljem do linije
	bolt_body_state.transform.origin = drive_in_start_position
	var drive_in_tween = get_tree().create_tween()
	drive_in_tween.tween_property(bolt_body_state, "transform:origin", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yield(drive_in_tween, "finished")

	collision_shape.set_deferred("disabled", false)
	self.is_active = true


func drive_out():

	collision_shape.set_deferred("disabled", true)
	self.is_active = false

	var drive_out_time: float = 2
	var drive_out_vector: Vector2 = Rfs.current_level.drive_out_position.rotated(Rfs.current_level.level_finish.global_rotation)
	var drive_out_position: Vector2 = bolt_global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)
	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(bolt_body_state, "transform:rotated", angle_to_vector, drive_out_time/5)
	drive_out_tween.tween_property(bolt_body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	engines.shutdown_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), bolt_controller.ai_target)
	#	set_physics_process(false)
	#	motion = MOTION.IDLE


func use_nitro():
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	if not using_nitro:
		printt ("pred ", max_engine_power_adon, max_engine_power, "-----------------")
		Rfs.sound_manager.play_sfx("pickable_nitro")
		max_engine_power_adon = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
		engine_power += Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_adon"]
		printt ("med ", max_engine_power_adon, max_engine_power,"-----------------")
		yield(get_tree().create_timer(Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]),"timeout")
		max_engine_power_adon = 0
		using_nitro = false
		printt ("po ", max_engine_power_adon, max_engine_power,"-----------------")


func revup():

	$Sounds/EngineRevup.play()
	for thrust in engines.all_thrusts:
		thrust.start_fx(true)


func _spawn_shield():

	var ShieldScene: PackedScene = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = bolt_global_position
	new_shield.spawner = self # ime avtorja izstrelka
	new_shield.scale = Vector2.ONE
	new_shield.shield_time = Pfs.equipment_profiles[Pfs.EQUIPMENT.SHIELD]["time"]

	Rfs.node_creation_parent.add_child(new_shield)


func pull_bolt_on_screen(pull_position: Vector2): # kliče GM

	# disejblam koližne
	bolt_controller.set_process_input(false)
	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	trail_source.decay()

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(bolt_body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	bolt_controller.set_process_input(true)

	update_stat(Pfs.STATS.GAS_COUNT, Rfs.game_manager.game_settings["pull_gas_penalty"])


func screen_wrap(): # ne uporabljam

	# kopirano iz tutoriala ---> https://www.youtube.com/watch?v=xsAyx2r1bQU
	var xform = bolt_body_state.get_transform()
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
	bolt_body_state.set_transform(xform)


func on_item_picked(pickable_key: int):

	match pickable_key:
		Pfs.PICKABLE.PICKABLE_SHIELD:
			_spawn_shield()
		Pfs.PICKABLE.PICKABLE_NITRO:
			use_nitro()
		_:
			# če spreminja statistiko
			if Pfs.pickable_profiles[pickable_key].keys().has("driver_stat"):
				var change_value: float = Pfs.pickable_profiles[pickable_key]["value"]
				var change_stat_key: int = Pfs.pickable_profiles[pickable_key]["driver_stat"]
				update_stat(change_stat_key, change_value)


func update_stat(stat_key: int, change_value):

	if not Rfs.game_manager.game_on:
		return

	var curr_stat_name: String
	driver_stats[stat_key] += change_value # change_value je + ali -

	# health management
	if stat_key == Pfs.STATS.HEALTH:
		driver_stats[Pfs.STATS.HEALTH] = clamp(driver_stats[Pfs.STATS.HEALTH], 0, 1) # more bigt , ker max heath zmeri dodam 1
		if driver_stats[Pfs.STATS.HEALTH] == 0:
			_destroy_bolt()
		return # poštima ga bolt hud

	# gas management
	if driver_stats[Pfs.STATS.GAS_COUNT] <= 0: # če zmanjka bencina je deaktiviran
		driver_stats[Pfs.STATS.GAS_COUNT] = 0
		self.is_active = false

	emit_signal("bolt_stat_changed", driver_id, stat_key, driver_stats[stat_key])


# SIGNALI ------------------------------------------------------------------------------------------------


func _on_ReviveTimer_timeout() -> void:

	_revive_bolt()


func _on_Bolt_body_entered(body: Node2D) -> void:

	if not $Sounds/HitWall2.is_playing():
		$Sounds/HitWall.play()
		$Sounds/HitWall2.play()

	# odbojni partikli
	if bolt_velocity.length() > pseudo_stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = bolt_body_state.get_contact_local_position(0)
		new_collision_particles.rotation = bolt_body_state.get_contact_local_normal(0).angle() # rotacija partiklov glede na normalo površine
		new_collision_particles.amount = (bolt_velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič
		new_collision_particles.color = bolt_color
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
	if Rfs.game_camera.follow_target == self:
		Rfs.game_camera.follow_target = null
	trail_source.decay()
