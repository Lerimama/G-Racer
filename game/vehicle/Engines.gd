extends Node2D


var engines_on: bool = false

# engine thrusts
onready var front_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR]
onready var rear_thrusts: Array = [$RearEngine/ThrustL, $RearEngine/ThrustR]
onready var all_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR, $RearEngine/ThrustL, $RearEngine/ThrustR] # thrusts so samo vizualna prezentacija headinga
onready var EngineParticlesRear: PackedScene = preload("res://game/vehicle/fx/EngineParticlesRear.tscn")
onready var EngineParticlesFront: PackedScene = preload("res://game/vehicle/fx/EngineParticlesFront.tscn")


func _ready() -> void:
	pass # Replace with function body.

func start_engines():

	$Sounds/EngineStart.play()
	engines_on = true


func stop_engines():

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


func manage_engines(motion_manager: Node2D):

	match motion_manager.motion:

#		motion_manager.MOTION.FWD, motion_manager.MOTION.FWD_LEFT, motion_manager.MOTION.FWD_RIGHT:
		motion_manager.MOTION.FWD:
			for thrust in all_thrusts:
				thrust.start_fx()
		motion_manager.MOTION.FWD_LEFT, motion_manager.MOTION.FWD_RIGHT:
			for thrust in all_thrusts:
				thrust.start_fx()
			for thrust in front_thrusts:
				thrust.rotation = motion_manager.force_rotation # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in rear_thrusts:
				thrust.rotation = - motion_manager.force_rotation

		motion_manager.MOTION.REV:
			for thrust in all_thrusts:
				thrust.start_fx()
			for thrust in front_thrusts:
				thrust.rotation = - motion_manager.force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in rear_thrusts:
				thrust.rotation = motion_manager.force_rotation + deg2rad(180)

		motion_manager.MOTION.REV_LEFT, motion_manager.MOTION.REV_RIGHT:
			for thrust in all_thrusts:
				thrust.start_fx()
			for thrust in front_thrusts:
				thrust.rotation = - motion_manager.force_rotation + deg2rad(180) # za samo zavijanje ne lerpam, ker je lerpano obračanje glavne smeri
			for thrust in rear_thrusts:
				thrust.rotation = motion_manager.force_rotation + deg2rad(180)

		motion_manager.MOTION.IDLE:
			for thrust in all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, 0.1)
				thrust.stop_fx()
			for thrust in all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, motion_manager.engine_rotation_speed)

		motion_manager.MOTION.IDLE_LEFT, motion_manager.MOTION.IDLE_RIGHT:
			var rotate_to_angle:float = deg2rad(motion_manager.max_engine_rotation_deg) #  motion_manager.driving_gear ... # 60 je poseben deg2rad(max_engine_rotation_deg)
			if motion_manager.MOTION.IDLE_LEFT:
				rotate_to_angle *= -1
			for thrust in all_thrusts:
				thrust.start_fx()
			match motion_manager.rotation_motion:
				motion_manager.ROTATION_MOTION.SPIN:
					for thrust in front_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, motion_manager.engine_rotation_speed) # lerpam, ker obrat glavne smeri ni lerpan
					for thrust in rear_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle + deg2rad(180), motion_manager.engine_rotation_speed)
				motion_manager.ROTATION_MOTION.SLIDE: # oba pogona  v smeri premika
					for thrust in all_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, rotate_to_angle, motion_manager.engine_rotation_speed)


func boost_engines():
	pass
