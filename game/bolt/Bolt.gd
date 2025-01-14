extends RigidBody2D
class_name Bolt


signal stats_changed (stats_owner_id, player_stats) # bolt in damage

enum MOTION {IDLE, FWD, REV, TILT, FREE_ROTATE, DRIFT, GLIDE, DISARRAY} # DIZZY, DYING glede na moč motorja
var current_motion: int = MOTION.IDLE setget _on_motion_change
var free_motion_type: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke

# player and stats
var player_id: int # ga seta spawner
var player_name: String # za opredelitev statistike
var bolt_color: Color = Color.red
onready var player_profile: Dictionary = Pros.player_profiles[player_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]
onready var player_stats: Dictionary = Pros.default_player_stats.duplicate()
onready var max_health: float = player_stats["health"] # zato, da se lahko resetira

# bolt
var is_active: bool = false setget _on_bolt_activity_change # predvsem za pošiljanje signala GMju
var bolt_body_state: Physics2DDirectBodyState
onready var bolt_profile: Dictionary = Pros.bolt_profiles[bolt_type].duplicate()
onready var ai_target_rank: int = bolt_profile["ai_target_rank"]
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var revive_timer: Timer = $ReviveTimer
onready var bolt_controller: Node = $BoltController # zamenja se ob spawnu AI/HUMAN

# fx
onready var trail_position: Position2D = $TrailPosition
onready var CollisionParticles: PackedScene = preload("res://game/bolt/fx/BoltCollisionParticles.tscn")
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/fx/EngineParticlesRear.tscn")
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/fx/EngineParticlesFront.tscn")
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

# engines
var engines_on: bool = false # lahko deluje tudi ko ni igre in je neaktiven
var heading_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_power = 0
var engine_rotation_speed: float = 0.1
onready var max_engine_power: float = bolt_profile["max_engine_power"]
onready var engine_hsp: float = bolt_profile["engine_hsp"]
onready var power_burst_hsp: float = bolt_profile["power_burst_hsp"]
onready var max_engine_rotation_deg: float = bolt_profile["max_engine_rotation_deg"]
var all_thrusts: Array # thrusts so samo vizualna prezentacija headinga
var max_thrust_rotation_deg: float = 15
onready var front_thrusts: Array = [
	$Chassis/DriveTrain/FrontEngine/ThrustL,
	$Chassis/DriveTrain/FrontEngine/ThrustR,
	$ShadowViewport/Chassis/DriveTrain/FrontEngine/ThrustL,
	$ShadowViewport/Chassis/DriveTrain/FrontEngine/ThrustR
	]
onready var rear_thrusts: Array = [
	$Chassis/DriveTrain/RearEngine/ThrustL,
	$Chassis/DriveTrain/RearEngine/ThrustR,
	$ShadowViewport/Chassis/DriveTrain/RearEngine/ThrustL,
	$ShadowViewport/Chassis/DriveTrain/RearEngine/ThrustR
	]

# battle
var revive_time: float = 2
var is_shielded: bool = false # OPT ... ne rabiš, shield naj deluje s fiziko ... ne rabiš
var is_shooting: bool = false # način, ki je boljši za efekte

# racing
var bolt_position_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju
var race_time_on_previous_lap: float = 0

# trail
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var active_trail: Line2D

# debug smerna linija
onready var direction_line: Line2D = $DirectionLine

# neu
var height: float = 0 # PRO
var elevation: float = 7 # PRO
onready var bolt_hud: Node2D = $BoltHud
onready var available_weapons: Array = [$Turret, $Dropper, $LauncherL, $LauncherR]
onready var bolt_sprite: Sprite = $Chassis/BoltSprite
#onready var bolt_poly: Polygon2D = $Chassis/Polygon2D
onready var bolt_poly: Polygon2D = $Chassis/BoltShape
onready var terrain_detect: Area2D = $TerrainDetect
#var current_top_suface: Area2D = null # preverjam spremembo, da ne setam na vsak frejm
var current_top_suface_type: int = 0 # preverjam spremembo, da ne setam na vsak frejm
onready var animation_player: AnimationPlayer = $AnimationPlayer
# breaker
#export var height: float = 50 setget _change_shape_height
#export var elevation: float = 0
export var transparency: float = 1

func _ready() -> void:
#	printt("BOLT", self.name)

	all_thrusts = front_thrusts
	all_thrusts.append_array(rear_thrusts)

	add_to_group(Refs.group_bolts)
	player_name = player_profile["player_name"]
	# bolt
	bolt_color = player_profile["player_color"] # bolt se obarva ...
	bolt_sprite.modulate = bolt_color
	bolt_poly.modulate = bolt_color

	# bolt settings
	mass = bolt_profile["mass"]
	linear_damp = bolt_profile["drive_lin_damp"]
	angular_damp = bolt_profile["drive_ang_damp"]
	physics_material_override.friction = bolt_profile["friction"]
	physics_material_override.bounce = bolt_profile["bounce"]
	rear_mass.linear_damp = bolt_profile["drive_lin_damp_rear"]

	# weapon settings
	for weapon in available_weapons:
		weapon.set_weapon()

	spawn_bolt_controller()

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
	if player_id == Pros.PLAYER.P1:
		Refs.setup_layer.build_setup_layer(setup_layer_dict, self)
		Refs.setup_layer.add_new_line_to_setup_layer("back_linear_dump", "linear_damp", rear_mass.linear_damp, rear_mass)
		Refs.setup_layer.add_new_line_to_setup_layer("engine_power", "max_engine_power", max_engine_power, self)


func _process(delta: float) -> void:

	get_surfaces()
	update_trail()

	if not is_active: # resetiram, če ni aktiven
		engine_power = 0
		rotation_dir = 0
	else:
		heading_rotation = lerp_angle(heading_rotation, rotation_dir * deg2rad(max_engine_rotation_deg) * bolt_shift, engine_rotation_speed)
		# printt("heading", rad2deg(heading_rotation))
		var max_free_thrust_rotation_deg: float = 90 # PRO
		var rotate_to_angle: float = rotation_dir * deg2rad(max_free_thrust_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)

		# force global rotation ... premaknjena na kotrolerje
		#	force_rotation = heading_rotation + get_global_rotation() # da ne striže (_FP!!) prestavljeno v kontrolerja

		match current_motion:
			MOTION.IDLE:
				engine_power = 0
				for thrust in all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			MOTION.FWD:
				engine_power += engine_hsp
				if Refs.game_manager.fast_start_window:
					engine_power += power_burst_hsp
				for thrust in front_thrusts:
					thrust.rotation = heading_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
				for thrust in rear_thrusts:
					thrust.rotation = - heading_rotation
			MOTION.REV:
				engine_power += engine_hsp
				for thrust in front_thrusts:
					thrust.rotation = - heading_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
				for thrust in rear_thrusts:
					thrust.rotation = heading_rotation + deg2rad(180)
				# OPT obrat pogona v rikverc ... smooth rotacija ... dela ok dokler ne vozim naokoli, potem se smeri vrtenja podrejo
				#				for thrust in all_thrusts:
				#					var rotation_direction: int = 1
				#					if thrust.position_on_bolt == thrust.POSITION.LEFT:
				#						rotation_direction = -1
				#					var rotate_to: float = (heading_rotation + deg2rad(180)) * rotation_direction
				#					thrust.rotation = lerp_angle(thrust.rotation, rotate_to, engine_rotation_speed)
			MOTION.FREE_ROTATE:
				engine_power = 0
				for thrust in front_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
				for thrust in rear_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
			MOTION.DRIFT: # zadnji pogon v smeri zavoja
				engine_power = lerp(engine_power, 0, 0.01)
			MOTION.GLIDE: # oba pogona  v smeri premika
				engine_power = 0
				for thrust in all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)

		engine_power = clamp(engine_power, 0, max_engine_power) # zazih
		update_gas(gas_usage)


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
		match current_motion:
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


# BATTLE ----------------------------------------------------------------------------

#func on_hit(hitting_node: Node2D, hit_global_position: Vector2):
func on_hit(hit_by: Node2D, hit_global_position: Vector2):


#	$BreakerLite.on_hit(hit_by, hit_global_position) # debug
#	return

	if is_shielded:
		return

	#	if Refs.current_level.level_type == Refs.current_level.LEVEL_TYPE.BATTLE:
	update_stat("health", - hit_by.hit_damage)

	if hit_by.is_in_group(Refs.group_bullets):
		var inertia_factor: float = 100
		var hit_by_inertia: Vector2 = hit_by.velocity * hit_by.mass * inertia_factor
		var global_hit_position: Vector2 = hit_by.global_position
		var local_hit_position: Vector2 = global_hit_position - position
		apply_impulse(local_hit_position, hit_by_inertia)
		Refs.current_camera.shake_camera(Refs.current_camera.bullet_hit_shake)

	elif hit_by.is_in_group(Refs.group_misiles):
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
		#		apply_impulse( to_global(Vector2.RIGHT * bolt_sprite.texture.get_size().x/2), hit_by_inertia) # debug
		Refs.current_camera.shake_camera(Refs.current_camera.misile_hit_shake)
		Refs.sound_manager.play_sfx("bolt_explode")
		#		if Refs.current_level.level_type == Refs.current_level.LEVEL_TYPE.BATTLE:
		explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa

	elif hit_by.is_in_group(Refs.group_mine):
		var inertia_factor: float = 400000
		var hit_by_power: float = inertia_factor
		apply_torque_impulse(hit_by_power)
		Refs.current_camera.shake_camera(Refs.current_camera.misile_hit_shake)

	# health management
	if player_stats["health"] <= 0:
		lose_life()


func lose_life():

	explode()
	shutdown_engines()
	self.is_active = false
	update_stat("life", - 1)

	if player_stats["life"] > 0:
		revive_timer.start(revive_time)
	else:
		queue_free()


func explode():

	# disable staf
	collision_shape.set_deferred("disabled", true)
	#	collision_shape.disabled = true
	if active_trail: # ugasni tejl
		active_trail.start_decay() # trail decay tween start
	visible = false
	bolt_controller.set_process_input(false)
	set_physics_process(false)
	# resetira na revive

	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = bolt_global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = bolt_velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawner_color = bolt_color
	new_exploding_bolt.z_index = z_index + 1
	Refs.node_creation_parent.add_child(new_exploding_bolt)

	Refs.current_camera.shake_camera(Refs.current_camera.bolt_explosion_shake)


func revive_bolt():

	# reset pred prikazom
	collision_shape.set_deferred("disabled", false)
	#	collision_shape.disabled = false

	self.is_active = true
	bolt_controller.set_process_input(true)
	set_physics_process(true)
	visible = true

	# reset energije
	var difference_to_max_health: float = max_health - player_stats["health"] # na tak način, ker energijo stats prištevajo
	update_stat("health", difference_to_max_health)


# UTILITY ----------------------------------------------------------------------------


func shutdown_engines():

	engines_on = false
	engine_power = 0 # zazih
	if $Sounds/Engine.is_playing():
		var current_engine_volume: float = $Sounds/Engine.get_volume_db()
		var engine_stop_tween = get_tree().create_tween()
		engine_stop_tween.tween_property($Sounds/Engine, "pitch_scale", 0.5, 2)
		engine_stop_tween.tween_property($Sounds/Engine, "volume_db", -80, 2)
		yield(engine_stop_tween, "finished")
		$Sounds/Engine.stop()
		$Sounds/Engine.volume_db = current_engine_volume
	$Sounds/EngineRevup.stop()
	$Sounds/EngineStart.stop()


func start_engines():

	engines_on = true
	$Sounds/EngineStart.play()



func update_gas(used_amount: float):

	update_stat("gas_count", used_amount)

	if player_stats["gas_count"] <= 0: # če zmanjka bencina je deaktiviran
		player_stats["gas_count"] = 0
		self.is_active = false


func update_bolt_points(points_change: int):

	update_stat("points", points_change)


func update_bolt_rank(new_bolt_rank: int):

	update_stat("level_rank", new_bolt_rank)


func update_stat(stat_name: String, change_value: float):

	if not Refs.game_manager.game_on:
		return

	if stat_name == "best_lap_time":
		player_stats[stat_name] = change_value
	elif stat_name == "level_time":
		player_stats[stat_name] = change_value
	elif stat_name == "level_rank":
		player_stats[stat_name] = change_value
	else:
		player_stats[stat_name] += change_value # change_value je + ali -

	emit_signal("stats_changed", player_id, player_stats)


func update_trail():

	# spawn trail if not active
	if not active_trail and bolt_velocity.length() > pseudo_stop_speed: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and bolt_velocity.length() > pseudo_stop_speed:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(bolt_global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if bolt_velocity.length() > pseudo_stop_speed and active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova
	elif active_trail and bolt_velocity.length() <= pseudo_stop_speed:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func lap_finished(level_lap_limit: int):

	# lap time
	var current_race_time: float = Refs.hud.game_timer.game_time_hunds
	var current_lap_time: float = current_race_time - race_time_on_previous_lap # če je slednja 0, je prvi krog
	var best_lap_time: float = player_stats["best_lap_time"]
	if current_lap_time < best_lap_time or best_lap_time == 0:
		update_stat("best_lap_time", current_lap_time)
		Refs.hud.spawn_bolt_floating_tag(self, current_lap_time, true)
	else:
		Refs.hud.spawn_bolt_floating_tag(self, current_lap_time, false)

	update_stat("laps_count", 1)

	race_time_on_previous_lap = current_race_time # za naslednji krog

	if player_stats["laps_count"] >= level_lap_limit: # trenutno končan krog je že dodan
		Refs.game_manager.bolts_finished.append(self)
		update_stat("level_time", current_race_time)
		drive_out()


func pull_bolt_on_screen(pull_position: Vector2, current_leader: RigidBody2D):

	# disejblam koližne
	bolt_controller.set_process_input(false)
	collision_shape.set_deferred("disabled", true)

	# reštartam trail
	if active_trail:
		active_trail.start_decay() # trail decay tween start

	var pull_time: float = 0.2
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(bolt_body_state, "transform:origin", pull_position, pull_time)#.set_ease(Tween.EASE_OUT)
	yield(pull_tween, "finished")
	collision_shape.set_deferred("disabled", false)
	bolt_controller.set_process_input(true)

	# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
	if player_stats["laps_count"] < current_leader.player_stats["laps_count"]:
		var laps_finished_difference: int = current_leader.player_stats["laps_count"] - player_stats["laps_count"]
		update_stat("laps_count", laps_finished_difference)

	# če preskoči checkpoint, ga dodaj, če ga leader ima
	var all_checked_bolts: Array = Refs.game_manager.bolts_checked
	if all_checked_bolts.has(current_leader):
		all_checked_bolts.append(self)

	# ne dela
	#	if Refs.game_manager.current_pull_positions.has(pull_position):
	#		Refs.game_manager.current_pull_positions.erase(pull_position)

	update_gas(Refs.game_manager.game_settings["pull_gas_penalty"])


func screen_wrap():

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


func drive_in(drive_in_time: float = 2):

	collision_shape.set_deferred("disabled", true)
	modulate.a = 1
	start_engines()

	#	var drive_in_time: float = 2
	var drive_in_finished_position: Vector2 = bolt_global_position
	var drive_in_vector: Vector2 = Refs.current_level.drive_in_position.rotated(Refs.current_level.level_start.global_rotation)
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
	var drive_out_vector: Vector2 = Refs.current_level.drive_out_position.rotated(Refs.current_level.level_finish.global_rotation)
	var drive_out_position: Vector2 = bolt_global_position + drive_out_vector
	var angle_to_vector: float = get_angle_to(drive_out_position)
	var drive_out_tween = get_tree().create_tween()
	# obrnem ga proti cilju in zapeljem do linije
	#	drive_out_tween.tween_property(bolt_body_state, "transform:rotated", angle_to_vector, drive_out_time/5)
	drive_out_tween.tween_property(bolt_body_state, "transform:origin", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	yield(drive_out_tween, "finished")

	shutdown_engines()
	modulate.a = 0
	#	set_sleeping(true)
	#	printt("drive out", is_sleeping(), bolt_controller.ai_target)
	#	set_physics_process(false)
	#	current_motion = MOTION.IDLE


func revup():

	$Sounds/EngineRevup.play()
	for thrust in all_thrusts:
		thrust.start_fx(true)


func item_picked(pickable_key: int):

	var pickable_value: float = Pros.pickable_profiles[pickable_key]["value"]
	var pickable_time: float = Pros.pickable_profiles[pickable_key]["time"]

	match pickable_key:
		Pros.PICKABLE.PICKABLE_BULLET:
			#			if not Refs.current_level.level_type == Refs.current_level.LEVEL_TYPE.BATTLE:
			#				player_stats["misile_count"] = 0
			#				player_stats["mina_count"] = 0
			update_stat("bullet_count", pickable_value)
		Pros.PICKABLE.PICKABLE_MISILE:
			#			if not Refs.current_level.level_type == Refs.current_level.LEVEL_TYPE.BATTLE:
			#				player_stats["bullet_count"] = 0
			#				player_stats["mina_count"] = 0
			update_stat("misile_count", pickable_value)
		Pros.PICKABLE.PICKABLE_MINA:
			#			if not Refs.current_level.level_type == Refs.current_level.LEVEL_TYPE.BATTLE:
			#				player_stats["bullet_count"] = 0
			#				player_stats["misile_count"] = 0
			update_stat("mina_count", pickable_value)
		Pros.PICKABLE.PICKABLE_SHIELD:
			spawn_shield(pickable_value, pickable_time)
		Pros.PICKABLE.PICKABLE_HEALTH:
			player_stats["health"] = max_health
		Pros.PICKABLE.PICKABLE_GAS:
			update_stat("gas_count", pickable_value)
		Pros.PICKABLE.PICKABLE_LIFE:
			update_stat("life", pickable_value)
		Pros.PICKABLE.PICKABLE_NITRO:
			max_engine_power = max_engine_power * pickable_value
			yield(get_tree().create_timer(pickable_time), "timeout")
			max_engine_power = bolt_profile["max_engine_power"]
		Pros.PICKABLE.PICKABLE_POINTS:
			update_bolt_points(pickable_value)
		Pros.PICKABLE.PICKABLE_CASH:
			update_stat("cash_count", pickable_value)
		Pros.PICKABLE.PICKABLE_RANDOM:
			var random_range: int = Pros.pickable_profiles.keys().size() - 1 # izloči random
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pros.pickable_profiles.keys()[random_pickable_index]
			item_picked(random_pickable_key) # pick selected


func spawn_new_trail():

	var BoltTrail: PackedScene = preload("res://game/bolt/fx/BoltTrail.tscn")
	var new_bolt_trail: Line2D = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = trail_position.z_index
	new_bolt_trail.width = 20
	Refs.node_creation_parent.add_child(new_bolt_trail)

	# signal za deaktivacijo, če ni bila že prej
	new_bolt_trail.connect("trail_is_exiting", self, "_on_trail_exiting")

	return new_bolt_trail


func spawn_shield(shield_duration: float, shield_time: float):

	var ShieldScene: PackedScene = Pros.ammo_profiles[Pros.AMMO.SHIELD]["scene"]
	var new_shield = ShieldScene.instance()
	new_shield.global_position = bolt_global_position
	new_shield.spawner = self # ime avtorja izstrelka
	new_shield.scale = Vector2.ONE
	new_shield.shield_time = shield_duration

	Refs.node_creation_parent.add_child(new_shield)


func spawn_bolt_controller():

	 # zbrišem placeholder
	bolt_controller.queue_free()

	# opredelim controller sceno
	var players_controller_profile: Dictionary = Pros.controller_profiles[player_profile["controller_type"]]
	var BoltController: PackedScene = players_controller_profile["controller_scene"]

	# spawn na vrh boltovega drevesa
	bolt_controller = BoltController.instance()
	bolt_controller.controlled_bolt = self
	bolt_controller.controller_type = player_profile["controller_type"]
	call_deferred("add_child", bolt_controller)
	call_deferred("move_child", bolt_controller, 0)


func reset_bolt():
	# naj bo kar "totalni" reset, ki se ga ne kliče med tem, ko je v bolt "v igri"

	current_motion = MOTION.IDLE
	front_mass.set_applied_force(Vector2.ZERO)
	front_mass.set_applied_torque(0)
	rear_mass.set_applied_force(Vector2.ZERO)
	rear_mass.set_applied_torque(0)
	rotation_dir = 0
	engine_power = 0
	for thrust in all_thrusts:
		thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
		thrust.stop_fx()


func get_surfaces():

	# naberem vse areje pod boltom in opredelim tiste, ki štejejo za podlago
	var all_areas_under_bolt: Array = terrain_detect.get_overlapping_areas()
	var surfaces_under_bolt: Array = []
	for area in all_areas_under_bolt:
		if "surface_type" in area:
			surfaces_under_bolt.append(area)

	# če ni arej, ki so podlaga, določim gravel tip
	if surfaces_under_bolt.empty():
		current_top_suface_type = Pros.SURFACE.NONE
	# če so, preverim istost nove podlage
	else:
		var new_top_surface: Area2D = surfaces_under_bolt[surfaces_under_bolt.size() - 1]
		if not current_top_suface_type == new_top_surface.surface_type:
			current_top_suface_type = new_top_surface.surface_type

	# gravelšejk
	#	match current_top_suface_type:
	#		Pros.SURFACE.GRAVEL:
	#			animation_player.play("gravel_shake")
	#		_:
	#			animation_player.stop()
#	printt ("SURF", Pros.SURFACE.keys()[current_top_suface_type])

	var new_engine_power_factor: float = Pros.surface_type_profiles[current_top_suface_type]["engine_power_factor"]
	max_engine_power = bolt_profile["max_engine_power"] * new_engine_power_factor


# PRIVAT ------------------------------------------------------------------------------------------------


func _on_bolt_activity_change(bolt_is_active: bool):

	is_active = bolt_is_active

	# če je aktiven ga upočasnim v trenutni smeri
	var deactivate_time: float = 1.5

	match is_active:
		false:
			reset_bolt()
			bolt_controller.set_process_input(false)
			shutdown_engines() # nočeš ga skos slišat, če je multiplejer
			Refs.game_manager.check_for_level_finished()
		true:
			bolt_controller.set_process_input(true)


func _on_motion_change(new_motion: int):

	# nastavim nov engine
	if not new_motion == current_motion:
		current_motion = new_motion
		match current_motion:
			MOTION.IDLE:
				if bolt_shift > 0:
					rear_mass.set_applied_force(Vector2.ZERO)
				else:
					front_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["idle_lin_damp"]
				angular_damp = bolt_profile["idle_ang_damp"]
				for thrust in all_thrusts:
					thrust.stop_fx()
			MOTION.FWD:
				rear_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["drive_lin_damp"]
				angular_damp = bolt_profile["drive_ang_damp"]
				for thrust in all_thrusts:
					thrust.start_fx()
			MOTION.REV:
				front_mass.set_applied_force(Vector2.ZERO)
				linear_damp = bolt_profile["drive_lin_damp"]
				angular_damp = bolt_profile["drive_ang_damp"]
				for thrust in all_thrusts:
					thrust.start_fx()
			MOTION.FREE_ROTATE:
				linear_damp = bolt_profile["idle_lin_damp"]
				angular_damp = bolt_profile["idle_ang_damp"] # če tega ni moraš prekinit tipko, da se preklopi preko IDLE stanja
				for thrust in all_thrusts:
					thrust.start_fx()
			MOTION.DRIFT: # ni zrihtano
				linear_damp = bolt_profile["idle_lin_damp"]
				#			linear_damp = bolt_profile["drive_lin_damp"]
				#			angular_damp = bolt_profile["idle_ang_damp"]
				engine_power = max_engine_power # poskrbi za bolj "tight" obrat
				for thrust in front_thrusts:
					thrust.stop_fx()
				for thrust in rear_thrusts:
					thrust.start_fx()
			MOTION.GLIDE:
				linear_damp = bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				angular_damp = bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
				for thrust in all_thrusts:
					thrust.start_fx()
			MOTION.DISARRAY:
				pass


func _on_trail_exiting(exiting_trail: Line2D):

	if exiting_trail == active_trail:
		active_trail = null


func _on_ReviveTimer_timeout() -> void:

	revive_bolt()


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
		Refs.node_creation_parent.add_child(new_collision_particles)

	if active_trail:
		active_trail.start_decay() # trail decay tween start


func _exit_tree() -> void: # pospravljanje morebitnih smeti

	# da ne pušča smeti za sabo

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
	if Refs.current_camera.follow_target == self:
		Refs.current_camera.follow_target = null
	if active_trail and not active_trail.in_decay:
		active_trail.start_decay()
