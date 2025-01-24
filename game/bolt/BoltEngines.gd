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


func _process(delta: float) -> void:
	pass



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
