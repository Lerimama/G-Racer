extends Node2D


var engines_on: bool = false

# sound
onready var engine_start_sound: AudioStreamPlayer = $Sounds/EngineStart
onready var engine_revup_sound: AudioStreamPlayer = $Sounds/EngineRevup
onready var engine_drive_sound: AudioStreamPlayer = $Sounds/Engine
onready var engine_boost_sound: AudioStreamPlayer = $Sounds/EngineBoost
# ... ni še
onready var engine_stop_sound: AudioStreamPlayer = $Sounds/EngineStart

# thrusts
onready var left_thrusts: Array = [$FrontEngine/ThrustL, $RearEngine/ThrustL]
onready var right_thrusts: Array = [$FrontEngine/ThrustR, $RearEngine/ThrustR]
onready var front_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR]
onready var rear_thrusts: Array = [$RearEngine/ThrustL, $RearEngine/ThrustR]
onready var all_thrusts: Array = [$FrontEngine/ThrustL, $FrontEngine/ThrustR, $RearEngine/ThrustL, $RearEngine/ThrustR] # thrusts so samo vizualna prezentacija headinga
onready var EngineParticlesRear: PackedScene = preload("res://game/vehicle/fx/EngineParticlesRear.tscn")
onready var EngineParticlesFront: PackedScene = preload("res://game/vehicle/fx/EngineParticlesFront.tscn")


func _ready() -> void:

	for thrust in all_thrusts:
		thrust.thrust_owner = get_parent()

	engine_start_sound.connect("finished", self, "_on_engines_start_finished")


func start_engines():

	engine_start_sound.play()
	engines_on = true


func stop_engines():

	engines_on = false
	if engine_drive_sound.is_playing():
		var current_engine_volume: float = engine_drive_sound.get_volume_db()
		var engine_stop_tween = get_tree().create_tween()
		engine_stop_tween.tween_property(engine_drive_sound, "pitch_scale", 0.5, 2)
		engine_stop_tween.tween_property(engine_drive_sound, "volume_db", -80, 2)
		yield(engine_stop_tween, "finished")
		engine_drive_sound.stop()
		engine_drive_sound.volume_db = current_engine_volume

	engine_revup_sound.stop()
	engine_start_sound.stop()


func revup():

	engine_revup_sound.play()
	for thrust in all_thrusts:
		thrust.start_fx(true)

func manage_engines(motion_manager: Node2D):

	for thrust in all_thrusts:
		thrust.start_fx()

	var to_idle_rotation_factor: float =  motion_manager.engine_rotation_speed * 2
	var to_force_rotation_factor: float = 0.5 # _temp ...rotacija thrusta je počasna
	_manage_engine_sound(motion_manager.current_engine_power, motion_manager.max_engine_power, motion_manager.rotation_dir != 0)

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
				thrust.stop_fx()
			for thrust in left_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, deg2rad(0.001), to_idle_rotation_factor)
				if thrust.rotation < deg2rad(1):
					thrust.rotation = 0
			# rotacijo v drugo smer naredi z približanjem ciljnega kota
			for thrust in right_thrusts:
				thrust.rotation = lerp_angle(thrust.rotation, deg2rad(359.999), to_force_rotation_factor)
				# ko je skoraj 0 = 0
				if thrust.rotation > deg2rad(359):
					thrust.rotation = 0


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


func _manage_engine_sound(current_value: float, max_value: float, is_rotating: bool = false):

	var rotating_pitch_delta: float = 0.045
	var pitch_range: Array = [1, 2]
	if engine_drive_sound.is_playing():
		var value_percent: float = current_value / max_value
#		var new_pitch: float = pitch_range[0] + (pitch_range[1] - pitch_range[0]) * pow(value_percent, 2)
		var new_pitch: float = pitch_range[0] + (pitch_range[1] - pitch_range[0]) * value_percent
		if is_rotating:
			new_pitch += rotating_pitch_delta
		else:
			new_pitch -= rotating_pitch_delta

		engine_drive_sound.pitch_scale = new_pitch


func _on_engines_start_finished():

	engine_drive_sound.play()


func boost_engines(turn_on: bool = true):

	if turn_on: # ne uporabljam ... itak (še) ni loopan
		engine_boost_sound.play()
	else:
		engine_boost_sound.stop()


