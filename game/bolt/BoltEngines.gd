extends Node2D


var engines_on: bool = false

# engine thrusts
onready var front_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR]
onready var rear_thrusts: Array = [$RearEngine/ThrustL, $RearEngine/ThrustR]
onready var all_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR, $RearEngine/ThrustL, $RearEngine/ThrustR] # thrusts so samo vizualna prezentacija headinga
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/fx/EngineParticlesRear.tscn")
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/fx/EngineParticlesFront.tscn")


func _ready() -> void:
	pass # Replace with function body.


func start_engines():

	$Sounds/EngineStart.play()
	engines_on = true


func shutdown_engines():

	engines_on = false
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


func manage_engines(bolt_motion_manager: Node):

	var MOTION: Dictionary = bolt_motion_manager.MOTION
	var motion: int = bolt_motion_manager.motion
	var ROTATION_MOTION: Dictionary = bolt_motion_manager.ROTATION_MOTION
	var rotation_motion: int = bolt_motion_manager.rotation_motion
	var force_rotation: float = bolt_motion_manager.force_rotation
	var max_engine_rotation_deg: float = bolt_motion_manager.max_engine_rotation_deg
	var driving_gear: int = bolt_motion_manager.driving_gear
	var rotation_dir: int = bolt_motion_manager.rotation_dir
	var engine_rotation_speed: float = bolt_motion_manager.engine_rotation_speed

	match motion:
		MOTION.FWD:
			for thrust in all_thrusts:
				thrust.start_fx()
			for thrust in front_thrusts:
				thrust.rotation = force_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in rear_thrusts:
				thrust.rotation = - force_rotation
		MOTION.REV:
			for thrust in all_thrusts:
				thrust.start_fx()
			for thrust in front_thrusts:
				thrust.rotation = - force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in rear_thrusts:
				thrust.rotation = force_rotation + deg2rad(180)
		MOTION.IDLE:
			#			var rotate_to_angle: float = driving_gear * rotation_dir * deg2rad(max_engine_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)
			var rotate_to_angle: float = rotation_dir * deg2rad(max_engine_rotation_deg) # 60 je poseben deg2rad(max_engine_rotation_deg)
			if rotate_to_angle == 0:
				for thrust in all_thrusts:
					thrust.stop_fx()
				for thrust in all_thrusts:
					thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
			else:
				for thrust in all_thrusts:
					thrust.start_fx()
				match rotation_motion:
					ROTATION_MOTION.FREE: # poravna se v smer vožnje
						for thrust in all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, 0, engine_rotation_speed)
					ROTATION_MOTION.SPIN:
						for thrust in front_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
						for thrust in rear_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), engine_rotation_speed)
					ROTATION_MOTION.SLIDE: # oba pogona  v smeri premika
						for thrust in all_thrusts:
							thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, engine_rotation_speed)


func boost_engines():
	pass
