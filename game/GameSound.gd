extends Node


var game_manager: Game # poda GM na ready
var sfx_set_to_mute: bool = false
var music_set_to_mute: bool = false

var available_music_tracks: Array = []
var playing_track_index: int = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro

onready var game_music_holder: Node2D = $GameMusic
onready var music_bus_index: int = AudioServer.get_bus_index("GameMusic")
onready var sfx_bus_index: int = AudioServer.get_bus_index("GameSfx")

onready var big_horn: AudioStreamPlayer = $LevelSfx/BigHorn
onready var little_horn: AudioStreamPlayer = $LevelSfx/LittleHorn

# nitro
onready var nitro: AudioStreamPlayer = $GameMusic/Nitro
onready var nitro_menu: AudioStreamPlayer = $GameMusic/NitroMenu
onready var nitro_win: AudioStreamPlayer = $GameMusic/NitroWin
onready var nitro_lose: AudioStreamPlayer = $GameMusic/NitroLose
onready var nitro_intro: AudioStreamPlayer = $GameMusic/NitroIntro

# muska
onready var track: AudioStreamPlayer = $GameMusic/Track
onready var track_2: AudioStreamPlayer = $GameMusic/Track_2
onready var track_3: AudioStreamPlayer = $GameMusic/Track_3
onready var track_4: AudioStreamPlayer = $GameMusic/Track_4

onready var game_music: AudioStreamPlayer = nitro
onready var intro_jingle: AudioStreamPlayer = nitro_intro
onready var win_jingle: AudioStreamPlayer = nitro_win
onready var lose_jingle: AudioStreamPlayer = nitro_lose
onready var menu_music: AudioStreamPlayer = nitro_menu


func _input(event: InputEvent) -> void:

	# un/mute
	if Input.is_action_just_pressed("mute_track"):
		var is_bus_mute: bool = AudioServer.is_bus_mute(music_bus_index)
		AudioServer.set_bus_mute(music_bus_index, not is_bus_mute)
		music_set_to_mute = not is_bus_mute

	if Input.is_action_just_pressed("skip_track"):
		var is_bus_mute: bool = AudioServer.is_bus_mute(sfx_bus_index)
		AudioServer.set_bus_mute(sfx_bus_index, not is_bus_mute)
		sfx_set_to_mute = not is_bus_mute


func _ready() -> void:

	randomize()

	# če je bus na štartu setan na mute je mute
	music_set_to_mute = AudioServer.is_bus_mute(music_bus_index)
	sfx_set_to_mute = AudioServer.is_bus_mute(sfx_bus_index)

	if available_music_tracks.empty():
		available_music_tracks = [nitro, track, track_2]


func play_level_sfx(effect_for: String):
	pass


func play_gui_sfx(effect_for: String):

	match effect_for:
		# events
		"start_countdown_a":
			$GuiSfx/Events/StartCoundownA.play()
		"start_countdown_b":
			$GuiSfx/Events/StartCoundownB.play()
		"game_countdown_a":
			$GuiSfx/Events/GameCoundownA.play()
		"game_countdown_b":
			$GuiSfx/Events/GameCoundownB.play()
		"win_jingle":
			$GuiSfx/Events/Win.play()
		"lose_jingle":
			$GuiSfx/Events/Loose.play()
#		"record_cheers":
#			$GuiSfx/Events/RecordFanfare.play()
		"tutorial_stage_done":
			$GuiSfx/Events/TutorialStageDone.play()
		# input
		"typing":
			$GuiSfx/Inputs/Typing.get_children().pick_random().play()
		"btn_confirm":
			$GuiSfx/Inputs/BtnConfirm.play()
		"btn_cancel":
			$GuiSfx/Inputs/BtnCancel.play()
		"btn_focus_change":
#			if Global.allow_gui_sfx:
				$GuiSfx/Inputs/BtnFocus.play()
		# menu
		"menu_fade":
			$GuiSfx/MenuFade.play()
		"screen_slide":
			$GuiSfx/ScreenSlide.play()


# MUSKA --------------------------------------------------------------------------------------------------------


func fade_sounds(sound_1: AudioStreamPlayer, sound_2: AudioStreamPlayer = null, pause_instead: bool = false, in_parallel: bool = false, fade_time: float = 1):

	var sound_1_def_volume: float = sound_1.volume_db
	printt ("fading", sound_1, sound_2, sound_1_def_volume)
	var fade_tween = get_tree().create_tween()

	# out
	if not sound_2:
		fade_tween.tween_property(sound_1, "volume_db", -80.0, fade_time)
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
		fade_tween.parallel().tween_property(sound_2, "volume_db", sound_2.volume_db, fade_time).from(-80.0)
	# out/in
	else:
		fade_tween.tween_property(sound_1, "volume_db", -80.0, fade_time/2)
		if pause_instead:
			fade_tween.tween_callback(sound_1, "set_stream_paused", true)
		else:
			fade_tween.tween_callback(sound_1, "stop")
		if sound_2.stream_paused:
			fade_tween.parallel().tween_callback(sound_1, "set_stream_paused", false)
			fade_tween.parallel().tween_property(sound_2, "volume_db", sound_2.volumew_db, fade_time/2).from(-80.0)
		else:
			fade_tween.parallel().tween_callback(sound_2, "play")
	yield(fade_tween, "finished")
	sound_1.volume_db = sound_1_def_volume


func fade_in_sound(sound: AudioStreamPlayer, fade_time: float = 1):

	var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
	if sound.stream_paused:
			fade_tween.tween_callback(sound, "set_stream_paused", false)
	else:
		fade_tween.tween_callback(sound, "play")
	fade_tween.tween_property(sound, "volume_db", sound.volume_db, fade_time).from(-80)


func set_game_music_volume(value_on_slider: float): # kliče se iz settingsov

	# slajder je omejen med -30 in 10
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)


#func skip_track():
#
#	currently_playing_track_index += 1
#
#	if currently_playing_track_index > game_music_holder.get_child_count():
#		currently_playing_track_index = 1
#
#	for music_track in game_music_holder.get_children():
#		if music_track.is_playing():
#			#			var current_music_volume = music_track.volume_db
#			#			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
#			#			fade_out.tween_property(music_track, "volume_db", -80, 0.5)
#			#			fade_out.tween_callback(music_track, "stop")
#			#			fade_out.tween_callback(music_track, "set_volume_db", [current_music_volume]) # reset glasnosti
#			#			fade_out.tween_callback(self, "play_music", ["game_music_holder"])
#			yield(Mts.sound_fade_out_and_reset("music", 2), "fadeout_finished")
