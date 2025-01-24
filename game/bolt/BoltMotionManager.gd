extends Node
## na driving vplivam z:
## 	maso in porazdelitvijo F/R
##	#	front mass ... potiska
##	#	# 	nižja masa pomeni večji vpliv sile na njo
##	#	# 	večja ... vozilo bolje drži smer
##	#	rear mass ... sledi
##	#	# 	nižja masa pomeni hitrejši vpliv sile, ki jo vleče
##	#	# 	večja ... rit je vedno bolj statična ... na koncu se samo še front vrti okrog riti
##	#	# 	nižja ... rit odnaša
##	F/R linear damp ... predenje drsenje, drift
##	angular_damp ... ostrina zavijanja
##	max_engine_rotation ... ostrina zavijanja,drift
##
## picajzelj adaptacija na zgornje spremembe
##	engine_power, ker vpliva linear damp
##	accelaration, ker vpliva linear damp
## 	max_engine_rotation, ker na več powerja zavija bolj ostro
##
## lahko uporabim, ampak raje ne ...
##	masa
##	lin_damp = 0
##	ang_damp_rear = 0
##	ang_damp_front = 0


onready var bolt = get_parent()

enum MOTION {ENGINES_OFF, IDLE, FWD, REV, DISARRAY, TILT, FREE_ROTATE, DRIFT, GLIDE} # DIZZY, DYING glede na moč motorja
var motion: int = MOTION.IDLE setget _change_motion
var floating_motion: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke
#var floating_motion: int = MOTION.FREE_ROTATE # presetan motion, ko imaš samo smerne tipke
#var floating_motion: int = MOTION.DRIFT # presetan motion, ko imaš samo smerne tipke
#var floating_motion: int = MOTION.GLIDE # presetan motion, ko imaš samo smerne tipke
#var floating_motion: int = v# presetan motion, ko imaš samo smerne tipke


enum DRIVING_MODE {DEFAULT, NAKED, ORIG, AGILE, TRACKING, DRIFTING, BOOSTED}
var driving_mode: int = 0 setget _change_driving_mode

# engine
var engine_power = 0
var max_engine_power# = 500000 setget _change_max_engine_power
var def_max_engine_power = 500#000 # 1 - 500 konjev
var max_engine_power_adon: float = 0 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
var max_engine_power_factor: float = 1 # tole spremija samo kar koli vpliva na moč med igro, ovinek?
var accelaration_power = 0# 5000  # delta seštevanje moči motorja do največje moči
var bolt_shift: int = 1 # -1 = rikverc, +1 = naprej, 0 ne obstaja ... za daptacijo, ker je moč motorja zmeraj pozitivna
onready var free_rotation_power: float = bolt.bolt_profile["free_rotation_power"]
onready var fast_start_engine_power: float = bolt.bolt_profile["fast_start_engine_power"] # 500

# direction
var force_rotation: float = 0 # rotacija v smeri skupne sile motorjev ... določam v _FP (input), apliciram v _IF
var rotation_dir = 0
var heading_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float = 0.1
onready var max_engine_rotation_deg: float = bolt.bolt_profile["max_engine_rotation_deg"]

# adapt to driving mode
var lin_damp_engine_power_adapt: float = 0.2 # 0.5 težišče je na sredini
var lin_damp_acc_adapt: float = 0.2 # 0.5 težišče je na sredini


func _process(delta: float) -> void:

	if not bolt.is_active: # resetiram, če ni aktiven
		engine_power = 0
		rotation_dir = 0
	else:
		bolt.force = _motion_machine()
		max_engine_power = (def_max_engine_power + max_engine_power_adon) * max_engine_power_factor

		max_engine_power *= Rfs.game_manager.game_settings["reality_engine_power_factor"]

		# debug
		if not bolt.force == Vector2.ZERO:
			var vector_to_target = bolt.force.normalized() * 100
			vector_to_target = vector_to_target.rotated(- bolt.global_rotation)# - get_global_rotation()
			bolt.direction_line.set_point_position(1, vector_to_target)


func _change_motion(new_motion: int):

	# nastavim nov engine
	if not new_motion == motion:
		motion = new_motion
		match motion:
			MOTION.IDLE:
				if bolt_shift > 0:
					bolt.rear_mass.set_applied_force(Vector2.ZERO)
				else:
					bolt.front_mass.set_applied_force(Vector2.ZERO)
				bolt.linear_damp = bolt.bolt_profile["idle_lin_damp"]
				bolt.angular_damp = bolt.bolt_profile["idle_ang_damp"]
				for thrust in bolt.engines.all_thrusts:
					thrust.stop_fx()
			MOTION.FWD:
				bolt.rear_mass.set_applied_force(Vector2.ZERO)
				bolt.linear_damp = bolt.bolt_profile["drive_lin_damp"]
				bolt.angular_damp = bolt.bolt_profile["drive_ang_damp"]
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.REV:
				bolt.front_mass.set_applied_force(Vector2.ZERO)
				bolt.linear_damp = bolt.bolt_profile["drive_lin_damp"]
				bolt.angular_damp = bolt.bolt_profile["drive_ang_damp"]
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.FREE_ROTATE:
				bolt.linear_damp = bolt.bolt_profile["idle_lin_damp"]
				bolt.angular_damp = bolt.bolt_profile["idle_ang_damp"] # če tega ni moraš prekinit tipko, da se preklopi preko IDLE stanja
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.DRIFT: # ni zrihtano
				bolt.linear_damp = bolt.bolt_profile["idle_lin_damp"]
				#			linear_damp = bolt_profile["drive_lin_damp"]
				#			angular_damp = bolt_profile["idle_ang_damp"]
				engine_power = max_engine_power # poskrbi za bolj "tight" obrat
				for thrust in bolt.engines.front_thrusts:
					thrust.stop_fx()
				for thrust in bolt.engines.rear_thrusts:
					thrust.start_fx()
			MOTION.GLIDE:
				bolt.force = Vector2.DOWN.rotated(bolt.rotation) * rotation_dir
				bolt.linear_damp = bolt.bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
				bolt.angular_damp = bolt.bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
				for thrust in bolt.engines.all_thrusts:
					thrust.start_fx()
			MOTION.DISARRAY:
				pass


func _motion_machine():

	heading_rotation = lerp_angle(heading_rotation, rotation_dir * deg2rad(max_engine_rotation_deg) * bolt_shift, engine_rotation_speed)

	var max_free_thrust_rotation_deg: float = bolt.bolt_profile["max_free_thrust_rotation_deg"]
	var rotate_to_angle: float = rotation_dir * deg2rad(max_free_thrust_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)

	# force global rotation ... premaknjena na kotrolerje
	#	force_rotation = heading_rotation + get_global_rotation() # da ne striže (_FP!!) prestavljeno v kontrolerja

	var force_on_bolt = Vector2.ZERO
	match motion:
		MOTION.IDLE:
			force_on_bolt = Vector2.ZERO
			engine_power = 0
			for thrust in bolt.engines.all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
		MOTION.FWD:
			force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift

#			var test = get_tree().create_tween()
#			test.tween_property(bolt, "engine_power", max_engine_power * 2, 1).set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_BOUNCE)
#				acc_tween = test

			engine_power = lerp(engine_power, max_engine_power * 2, 0.1)
#			engine_power += accelaration_power
			if Rfs.game_manager.fast_start_window:
				engine_power += fast_start_engine_power
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = heading_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = - heading_rotation
		MOTION.REV:
			force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * engine_power * bolt_shift

#			engine_power += accelaration_power
			engine_power = lerp(engine_power, max_engine_power * 2, 0.1)

			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = - heading_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = heading_rotation + deg2rad(180)
			# OPT obrat pogona v rikverc ... smooth rotacija ... dela ok dokler ne vozim naokoli, potem se smeri vrtenja podrejo
			#				for thrust in engines.all_thrusts:
			#					var rotation_direction: int = 1
			#					if thrust.position_on_bolt == thrust.POSITION.LEFT:
			#						rotation_direction = -1
			#					var rotate_to: float = (heading_rotation + deg2rad(180)) * rotation_direction
			#					thrust.rotation = lerp_angle(thrust.rotation, rotate_to, engine_rotation_speed)
		MOTION.FREE_ROTATE:
			force_on_bolt = Vector2.UP.rotated(bolt.rotation) * free_rotation_power * rotation_dir
			engine_power = 0
			for thrust in bolt.engines.front_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
			for thrust in bolt.engines.rear_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
		MOTION.DRIFT: # zadnji pogon v smeri zavoja
			force_on_bolt = Vector2.RIGHT.rotated(force_rotation) * 100 * engine_power
			engine_power = lerp(engine_power, 0, 0.01)
		MOTION.GLIDE: # oba pogona  v smeri premika
			engine_power = 0
			for thrust in bolt.bolt.engines.all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, bolt.rotate_to_angle, engine_rotation_speed)

	return force_on_bolt


func _change_driving_mode(new_driving_mode: int = DRIVING_MODE.DEFAULT):

#	if not new_driving_mode == driving_mode:
	driving_mode = new_driving_mode
#	driving_mode = DRIVING_MODE.DRIFTING
	driving_mode = DRIVING_MODE.TRACKING
#	driving_mode = DRIVING_MODE.NAKED
#	driving_mode = DRIVING_MODE.AGILE
#	driving_mode = DRIVING_MODE.ORIG

#	printt ("driving", DRIVING_MODE.keys()[driving_mode])
	bolt.mass = bolt.bolt_profile["mass"]

	var new_front_mass_bias: float
	match driving_mode:

		DRIVING_MODE.DEFAULT:
			engine_rotation_speed = bolt.bolt_profile["engine_rotation_speed"]
			max_engine_rotation_deg = bolt.bolt_profile["max_engine_rotation_deg"]
			accelaration_power = bolt.bolt_profile["accelaration_power"]
			def_max_engine_power = bolt.bolt_profile["max_engine_power"]
			#
			new_front_mass_bias = bolt.bolt_profile["front_mass_bias"]
			bolt.angular_damp = bolt.bolt_profile["ang_damp"]
			bolt.front_mass.linear_damp = bolt.bolt_profile["lin_damp_front"]
			bolt.rear_mass.linear_damp = bolt.bolt_profile["lin_damp_rear"]

		DRIVING_MODE.ORIG:
			engine_rotation_speed = 0.1
			max_engine_rotation_deg = 90
			accelaration_power = 5000
			def_max_engine_power = 500#000
			bolt.mass = 80 # 800 kil, front in rear teža se uporablja bolj za razmerje
			bolt.angular_damp = 16 # regulacija ostrine zavijanja ... tudi driftanja
			bolt.linear_damp = 2 # imam ga za omejitev slajdanja prvega kolesa
			bolt.rear_mass.mass = 1
			bolt.rear_mass.linear_damp = 3 # regulacija driftanja
			bolt.rear_mass.angular_damp = -1 # 0 proj def
			bolt.front_mass.mass = 1
			bolt.front_mass.linear_damp = -1 # 0 proj def
			bolt.front_mass.angular_damp = -1 # 0 proj def

		DRIVING_MODE.NAKED:
			bolt.mass = 0 # 800 kil, front in rear teža se uporablja bolj za razmerje
			new_front_mass_bias = 0.5
			bolt.angular_damp = 0
			bolt.linear_damp = 0 # imam ga za omejitev slajdanja prvega kolesa
			bolt.front_mass.linear_damp = 0
			bolt.rear_mass.linear_damp = 0

		DRIVING_MODE.AGILE: # hitro vijuganje, nežno driftanje
			accelaration_power = 32000
			def_max_engine_power = 700#000
			new_front_mass_bias = 0.5
			bolt.angular_damp = 18
			bolt.front_mass.linear_damp = 2
			bolt.rear_mass.linear_damp = 5

		DRIVING_MODE.TRACKING: # dolgo zavijanje, no drift
			engine_rotation_speed = 0.5
			accelaration_power = 32000
			def_max_engine_power = 800#000
			new_front_mass_bias = 0.5
			bolt.angular_damp = 50
			bolt.front_mass.linear_damp = 3
			bolt.rear_mass.linear_damp = 5
			max_engine_rotation_deg = 32

		DRIVING_MODE.DRIFTING: # krajše zavijanje + drift
			accelaration_power = 32000
			def_max_engine_power = 600#000
			new_front_mass_bias = 0.2
			bolt.angular_damp = 50
			bolt.front_mass.linear_damp = 4
			bolt.rear_mass.linear_damp = 0.1
			max_engine_rotation_deg = 32

	var front_rear_mass: float = bolt.front_mass.mass + bolt.rear_mass.mass
	bolt.front_mass.mass = front_rear_mass * new_front_mass_bias
	bolt.rear_mass.mass = front_rear_mass * (1 - new_front_mass_bias)




