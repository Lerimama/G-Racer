extends Node
class_name SoundManager


var sfx_set_to_mute: bool = false
var music_set_to_mute: bool = false

var available_music_tracks: Array = []
var playing_track_index: int = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro

onready var music_holder: Node2D = $Music
onready var music_bus_index: int# = AudioServer.get_bus_index("GameMusic")
onready var sfx_bus_index: int# = AudioServer.get_bus_index("GameSfx")


func _input(event: InputEvent) -> void:

	# un/mute
	if Input.is_action_just_pressed("mute"):
		var is_bus_mute: bool = AudioServer.is_bus_mute(music_bus_index)
		AudioServer.set_bus_mute(music_bus_index, not is_bus_mute)
		music_set_to_mute = not is_bus_mute

	if Input.is_action_just_pressed("skip_track"):
		pass


func _ready() -> void:

	randomize()

	# če je bus na štartu setan na mute je mute
	music_set_to_mute = AudioServer.is_bus_mute(music_bus_index)
	sfx_set_to_mute = AudioServer.is_bus_mute(sfx_bus_index)


# MUSKA --------------------------------------------------------------------------------------------------------


func fade_sounds(sound_1: AudioStreamPlayer, sound_2: AudioStreamPlayer = null, pause_instead: bool = false, in_parallel: bool = false, fade_time: float = 1):

	var sound_1_def_volume: float = sound_1.volume_db
	printt ("fading", sound_1, sound_2, sound_1_def_volume)
	var fade_tween = get_tree().create_tween()

	# out
	if not sound_2:
		fade_tween.tween_property(sound_1, "volume_db", -80.0, fade_time).set_ease(Tween.EASE_IN)
		if pause_instead:
			fade_tween.tween_callback(sound_1, "set_stream_paused", true)
		else:
			fade_tween.tween_callback(sound_1, "stop")
	# in
	elif not sound_1:
		if sound_2.stream_paused:
			fade_tween.tween_callback(sound_2, "set_stream_paused", false)
		else:
			fade_tween.tween_callback(sound_2, "play")
		fade_tween.parallel().tween_property(sound_2, "volume_db", sound_2.volume_db, fade_time).from(-80.0).set_ease(Tween.EASE_IN)
	# out/in
	else:
		fade_tween.tween_property(sound_1, "volume_db", -80.0, fade_time/2).set_ease(Tween.EASE_IN)
		if pause_instead:
			fade_tween.tween_callback(sound_1, "set_stream_paused", true)
		else:
			fade_tween.tween_callback(sound_1, "stop")
		if sound_2.stream_paused:
			fade_tween.parallel().tween_callback(sound_1, "set_stream_paused", false)
			fade_tween.parallel().tween_property(sound_2, "volume_db", sound_2.volumew_db, fade_time/2).from(-80.0).set_ease(Tween.EASE_IN)
		else:
			fade_tween.parallel().tween_callback(sound_2, "play")
	yield(fade_tween, "finished")
	sound_1.volume_db = sound_1_def_volume



#func set_music_volume(value_on_slider: float): # kliče se iz settingsov
#
#	# slajder je omejen med -30 in 10
#	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)

#func skip_track():
#
#	currently_playing_track_index += 1
#
#	if currently_playing_track_index > game_music.get_child_count():
#		currently_playing_track_index = 1
#
#	for music in game_music.get_children():
#		if music.is_playing():
#			var current_music_volume = music.volume_db
#			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
#			fade_out.tween_property(music, "volume_db", -80, 0.5)
#			fade_out.tween_callback(music, "stop")
#			fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti
#			fade_out.tween_callback(self, "play_music", ["game_music"])
