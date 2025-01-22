extends Node

enum MOTION {ENGINES_OFF, IDLE, FWD, REV, DISARRAY, TILT, FREE_ROTATE, DRIFT, GLIDE} # DIZZY, DYING glede na moč motorja
#enum MOTION {ENGINES_OFF, IDLE, FWD, REV, TILT, FREE_ROTATE, DRIFT, GLIDE, DISARRAY} # DIZZY, DYING glede na moč motorja
var motion: int = MOTION.IDLE setget _change_motion
#var free_motion_type: int = MOTION.IDLE # presetan motion, ko imaš samo smerne tipke
var free_motion_type: int = MOTION.FREE_ROTATE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.DRIFT # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.GLIDE # presetan motion, ko imaš samo smerne tipke
#var free_motion_type: int = MOTION.TILT # presetan motion, ko imaš samo smerne tipke

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass



func _motion_machine():
	pass
#
#
#	heading_rotation = lerp_angle(heading_rotation, rotation_dir * deg2rad(max_engine_rotation_deg) * bolt_shift, engine_rotation_speed)
#	var max_free_thrust_rotation_deg: float = 90 # PRO
#	var rotate_to_angle: float = rotation_dir * deg2rad(max_free_thrust_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)
#
#	# force global rotation ... premaknjena na kotrolerje
#	#	force_rotation = heading_rotation + get_global_rotation() # da ne striže (_FP!!) prestavljeno v kontrolerja
#
#	match motion:
#		MOTION.IDLE:
#			engine_power = 0
#			for thrust in engines.all_thrusts:
#				thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
#		MOTION.FWD:
#			engine_power += accelaration_power
#			if Rfs.game_manager.fast_start_window:
#				engine_power += fast_start_engine_power
#			for thrust in engines.front_thrusts:
#				thrust.rotation = heading_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
#			for thrust in engines.rear_thrusts:
#				thrust.rotation = - heading_rotation
#		MOTION.REV:
#			engine_power += accelaration_power
#			for thrust in engines.front_thrusts:
#				thrust.rotation = - heading_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
#			for thrust in engines.rear_thrusts:
#				thrust.rotation = heading_rotation + deg2rad(180)
#			# OPT obrat pogona v rikverc ... smooth rotacija ... dela ok dokler ne vozim naokoli, potem se smeri vrtenja podrejo
#			#				for thrust in engines.all_thrusts:
#			#					var rotation_direction: int = 1
#			#					if thrust.position_on_bolt == thrust.POSITION.LEFT:
#			#						rotation_direction = -1
#			#					var rotate_to: float = (heading_rotation + deg2rad(180)) * rotation_direction
#			#					thrust.rotation = lerp_angle(thrust.rotation, rotate_to, engine_rotation_speed)
#		MOTION.FREE_ROTATE:
#			engine_power = 0
#			for thrust in engines.front_thrusts:
#				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
#			for thrust in engines.rear_thrusts:
#				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
#		MOTION.DRIFT: # zadnji pogon v smeri zavoja
#			engine_power = lerp(engine_power, 0, 0.01)
#		MOTION.GLIDE: # oba pogona  v smeri premika
#			engine_power = 0
#			for thrust in engines.all_thrusts:
#				thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)
#
#
#
func _change_motion(new_motion: int):
	pass
#
#	# nastavim nov engine
#	if not new_motion == motion:
#		motion = new_motion
#		match motion:
#			MOTION.IDLE:
#				if bolt_shift > 0:
#					rear_mass.set_applied_force(Vector2.ZERO)
#				else:
#					front_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = bolt_profile["idle_lin_damp"]
#				angular_damp = bolt_profile["idle_ang_damp"]
#				for thrust in engines.all_thrusts:
#					thrust.stop_fx()
#			MOTION.FWD:
#				rear_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = bolt_profile["drive_lin_damp"]
#				angular_damp = bolt_profile["drive_ang_damp"]
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()
#			MOTION.REV:
#				front_mass.set_applied_force(Vector2.ZERO)
#				linear_damp = bolt_profile["drive_lin_damp"]
#				angular_damp = bolt_profile["drive_ang_damp"]
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()
#			MOTION.FREE_ROTATE:
#				linear_damp = bolt_profile["idle_lin_damp"]
#				angular_damp = bolt_profile["idle_ang_damp"] # če tega ni moraš prekinit tipko, da se preklopi preko IDLE stanja
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()
#			MOTION.DRIFT: # ni zrihtano
#				linear_damp = bolt_profile["idle_lin_damp"]
#				#			linear_damp = bolt_profile["drive_lin_damp"]
#				#			angular_damp = bolt_profile["idle_ang_damp"]
#				engine_power = max_engine_power # poskrbi za bolj "tight" obrat
#				for thrust in engines.front_thrusts:
#					thrust.stop_fx()
#				for thrust in engines.rear_thrusts:
#					thrust.start_fx()
#			MOTION.GLIDE:
#				linear_damp = bolt_profile["idle_lin_damp"] # da ne izgubi hitrosti
#				angular_damp = bolt_profile["glide_ang_damp"] # da se ne vrti, če zavija
#				for thrust in engines.all_thrusts:
#					thrust.start_fx()
#			MOTION.DISARRAY:
#				pass
