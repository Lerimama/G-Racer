extends SoundManager


onready var menu_music: AudioStreamPlayer = $Music/NitroMenu

onready var btn_focus: AudioStreamPlayer = $BtnFocus
onready var btn_accept: AudioStreamPlayer = $BtnConfirm
onready var btn_cancel: AudioStreamPlayer = $BtnCancel
onready var screen_transition: AudioStreamPlayer = $ScreenSlide
onready var menu_transition: AudioStreamPlayer = $MenuFade

onready var nitro_intro: AudioStreamPlayer = $Music/NitroIntro
onready var typing_holder: Node2D = $Typing
onready var tutorial_stage_done: AudioStreamPlayer = $TutorialStageDone


func _ready() -> void:

	randomize()

	music_bus_index = AudioServer.get_bus_index("GameMusic")
	sfx_bus_index = AudioServer.get_bus_index("GameSfx")

	# če je bus na štartu setan na mute je mute
	music_set_to_mute = AudioServer.is_bus_mute(music_bus_index)
	sfx_set_to_mute = AudioServer.is_bus_mute(sfx_bus_index)

	if available_music_tracks.empty():
		available_music_tracks = [menu_music]

	# temp, bolje je da iima btns svoje?
	Buts.btn_accept_sound = btn_accept
	Buts.btn_cancel_sound = btn_cancel
	Buts.btn_toggle_on_sound = btn_accept
	Buts.btn_toggle_off_sound = btn_cancel
	Buts.btn_focus_sound = btn_focus


#func set_game_music_volume(value_on_slider: float): # kliče se iz settingsov
#
#	# slajder je omejen med -30 in 10
#	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)
#
#
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
