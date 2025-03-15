extends SoundManager


onready var menu_music: AudioStreamPlayer = $Music/NitroMenu

onready var typing_holder: Node2D = $Typing
onready var btn_focus: AudioStreamPlayer = $BtnFocus
onready var btn_confirm: AudioStreamPlayer = $BtnConfirm
onready var btn_cancel: AudioStreamPlayer = $BtnCancel
onready var screen_slide: AudioStreamPlayer = $ScreenSlide
onready var tutorial_stage_done: AudioStreamPlayer = $TutorialStageDone
onready var menu_fade: AudioStreamPlayer = $MenuFade


func _ready() -> void:

	randomize()

	music_bus_index = AudioServer.get_bus_index("GameMusic")
	sfx_bus_index = AudioServer.get_bus_index("GameSfx")

	# če je bus na štartu setan na mute je mute
	music_set_to_mute = AudioServer.is_bus_mute(music_bus_index)
	sfx_set_to_mute = AudioServer.is_bus_mute(sfx_bus_index)

	if available_music_tracks.empty():
		available_music_tracks = [menu_music]



#
#
#var game_sfx_set_to_off: bool = false
#var menu_music_set_to_off: bool = false
#var game_music_set_to_off: bool = false
#
#var currently_playing_track_index: int = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro
#
#onready var game_music: Node2D = $GameMusic
##onready var menu_music: AudioStreamPlayer = $Music/MenuMusic/WarmUpShort
##onready var menu_music_volume_on_node = menu_music.volume_db # za reset po fejdoutu (game over)
#
#
#func _ready() -> void:
#
#	Refs.sound_manager = self
#	randomize()
#
#
## SFX --------------------------------------------------------------------------------------------------------
#
#
#func play_sfx(effect_for: String):
#
#	if game_sfx_set_to_off:
#		return
#
#	match effect_for:
#		"stray_step":
#			$GameSfx/StraySlide.play()
#		"blinking": # GM na strays spawn, ker se bolje sliši
#			$GameSfx/Blinking.get_children().pick_random().play()
#			$GameSfx/BlinkingStatic.get_children().pick_random().play()
#		"thunder_strike": # intro in GM na strays spawn
#			$GameSfx/Burst.play()
#
#
#func play_gui_sfx(effect_for: String):
#
#	match effect_for:
#		# events
#		"start_countdown_a":
#			$GuiSfx/Events/StartCoundownA.play()
#		"start_countdown_b":
#			$GuiSfx/Events/StartCoundownB.play()
#		"game_countdown_a":
#			$GuiSfx/Events/GameCoundownA.play()
#		"game_countdown_b":
#			$GuiSfx/Events/GameCoundownB.play()
#		"win_jingle":
#			$GuiSfx/Events/Win.play()
#		"lose_jingle":
#			$GuiSfx/Events/Loose.play()
##		"record_cheers":
##			$GuiSfx/Events/RecordFanfare.play()
#		"tutorial_stage_done":
#			$GuiSfx/Events/TutorialStageDone.play()
#		# input
#		"typing":
#			$GuiSfx/Inputs/Typing.get_children().pick_random().play()
#		"btn_confirm":
#			$GuiSfx/Inputs/BtnConfirm.play()
#		"btn_cancel":
#			$GuiSfx/Inputs/BtnCancel.play()
#		"btn_focus_change":
##			if Global.allow_gui_sfx:
#				$GuiSfx/Inputs/BtnFocus.play()
#		# menu
#		"menu_fade":
#			$GuiSfx/MenuFade.play()
#		"screen_slide":
#			$GuiSfx/ScreenSlide.play()
#
#
## MUSKA --------------------------------------------------------------------------------------------------------
#
#
#func play_music():
#
#	if game_music_set_to_off:
#		return
#
#	# set track
#	var current_track: AudioStreamPlayer
#
##	if Refs.game_manager.level_profile["level"] == Sets.Levels.NITRO: # get level name drugače
##		var nitro_track: AudioStreamPlayer = $"../Sounds/NitroMusic"
##		current_track = game_music.get_node("Nitro")
##	else:
#	current_track = game_music.get_child(currently_playing_track_index - 1)
#
#	# Mets.sound_play_fade_in(game_music, 0, 2)
#	current_track.play()
#
#
#func stop_music():
##func stop_music(stop_reason: String):
#
#	for music in game_music.get_children():
#		if music.is_playing():
#			_sound_fade_out_and_reset(music, 2)
#
#
#func _sound_fade_out_and_reset(sound: AudioStreamPlayer, fade_time: float):
#	print("sound_fade_out_and_reset je off")
#	return
#	var pre_sound_volume = sound.volume_db
#
#	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	fade_out.tween_property(sound, "volume_db", -80, fade_time)
#	fade_out.tween_callback(sound, "stop")
#	yield(fade_out, "finished")
#
#
#	sound.volume_db = pre_sound_volume
#	emit_signal("fade_out_finished")
##	match stop_reason:
##		"game_music":
##			for music in game_music.get_children():
##				if music.is_playing():
##					music.stop()
##		"game_music_on_gameover":
##			for music in game_music.get_children():
##				if music.is_playing():
##					var current_music_volume = music.volume_db
##					var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
##					fade_out.tween_property(music, "volume_db", -80, 2)
##					fade_out.tween_callback(music, "stop")
##					# volume reset
##					fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti
#
#
#func sound_play_fade_in(sound, new_volume: int, fade_time: float): # uporabljam ?
#
#	var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
#	fade_out.tween_callback(sound, "play")
#	fade_out.tween_property(sound, "volume_db", new_volume, fade_time)
#
#
#
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
