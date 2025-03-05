extends Node2D


var engines_on: bool = false

# engine thrusts
onready var front_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR]
onready var rear_thrusts: Array = [$RearEngine/ThrustL, $RearEngine/ThrustR]
onready var all_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR, $RearEngine/ThrustL, $RearEngine/ThrustR] # thrusts so samo vizualna prezentacija headinga
onready var EngineParticlesRear: PackedScene = preload("res://game/vehicle/fx/EngineParticlesRear.tscn")
onready var EngineParticlesFront: PackedScene = preload("res://game/vehicle/fx/EngineParticlesFront.tscn")


func _ready() -> void:

	for thrust in all_thrusts:
		thrust.thrust_owner = get_parent()

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

	for thrust in all_thrusts:
		thrust.start_fx()

	var to_idle_rotation_factor: float =  motion_manager.engine_rotation_speed * 2
	var to_force_rotation_factor: float = 0.5 # _temp ...rotacija thrusta je počasna

	match motion_manager.motion:

		motion_manager.MOTION.FWD,motion_manager.MOTION.FWD_LEFT, motion_manager.MOTION.FWD_RIGHT:
			for thrust in front_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation,  motion_manager.force_rotation, 1)
			for thrust in rear_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, to_force_rotation_factor)

		motion_manager.MOTION.REV, motion_manager.MOTION.REV_LEFT, motion_manager.MOTION.REV_RIGHT:
			for thrust in front_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, - deg2rad(180), to_idle_rotation_factor)
			for thrust in rear_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation,  motion_manager.force_rotation + deg2rad(180), to_force_rotation_factor)

		motion_manager.MOTION.IDLE:
			for thrust in all_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, 0, to_idle_rotation_factor)
				thrust.stop_fx()

		motion_manager.MOTION.IDLE_RIGHT, motion_manager.MOTION.IDLE_LEFT:

			var idle_dir: int = 1
			if motion_manager.motion == motion_manager.MOTION.IDLE_LEFT:
				idle_dir = -1

			match motion_manager.rotation_motion:

				motion_manager.ROTATION_MOTION.SPIN:
					for thrust in front_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, deg2rad(90) * idle_dir, to_idle_rotation_factor) # lerpam, ker obrat glavne smeri ni lerpan
					for thrust in rear_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, - deg2rad(90) * idle_dir, to_idle_rotation_factor)

				motion_manager.ROTATION_MOTION.SLIDE:
					for thrust in front_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, deg2rad(90) * idle_dir, to_idle_rotation_factor) # lerpam, ker obrat glavne smeri ni lerpan
					for thrust in rear_thrusts:
						thrust.rotation = lerp_angle(thrust.rotation, deg2rad(90) * idle_dir, to_idle_rotation_factor)



func boost_engines():
	pass
