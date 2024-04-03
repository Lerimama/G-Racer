extends Node


var sfx_set_to_mute: bool = false
#var menu_music_set_to_off: bool = false
var music_set_to_mute: bool = false

var currently_playing_track_index: int = 1 # ga ne resetiraš, da ostane v spominu skozi celo igro

onready var game_music: Node2D = $GameMusic
#onready var menu_music: AudioStreamPlayer = $Music/MenuMusic/WarmUpShort
#onready var menu_music_volume_on_node = menu_music.volume_db # za reset po fejdoutu (game over)



func _input(event: InputEvent) -> void:
	
	# un/mute
	if Input.is_action_just_pressed("m"):
		var bus_index: int = AudioServer.get_bus_index("GameMusic")
		var is_bus_mute: bool = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not is_bus_mute)
		music_set_to_mute = not is_bus_mute

	if Input.is_action_just_pressed("f"):	
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		var is_bus_mute: bool = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not is_bus_mute)
		sfx_set_to_mute = not is_bus_mute	
	
			
func _ready() -> void:
	
	Ref.sound_manager = self
	randomize()

	
# SFX --------------------------------------------------------------------------------------------------------
	
#onready var sfx: Node = $Sfx
onready var music: Node = $Music
	
		
func play_sfx(effect_for: String):
	
	match effect_for:
		"bolt_explode": $Sfx/BoltExplode.play()
		"bullet_shoot": $Sfx/BulletShoot.play()
		"bullet_hit": $Sfx/BulletHit.play()
		"misile_explode": 
			$Sfx/MisileExplode.play()
			# ustavim, če se pleja ...
#			$Sfx/MisileFlight.set_volume_db(-80)
#			$Sfx/MisileShoot.set_volume_db(-80)
#			$Sfx/MisileFlight.stop()
#			$Sfx/MisileShoot.stop()
		"misile_dissarm": 
			$Sfx/MisileDissarm.play()
#			$Sfx/MisileFlight.set_volume_db(-80)
#			$Sfx/MisileShoot.set_volume_db(-80)
#			$Sfx/MisileFlight.stop()
#			$Sfx/MisileShoot.stop()
		"mina_explode": 
			$Sfx/MisileExplode.play()
			# ustavim, če se pleja ...
			$Sfx/MisileFlight.set_volume_db(-80)
			$Sfx/MisileShoot.set_volume_db(-80)
			$Sfx/MisileFlight.stop()
			$Sfx/MisileShoot.stop()
		"shocker_effect": $Sfx/ShockerEffect.play()
		"pickable": $Sfx/Pickable.play()
		"pickable_weapon": $Sfx/PickableWeapon.play()
		"pickable_nitro": $Sfx/PickableNitro.play()
		# events
		"finish_horn": $Sfx/FinishHorn.play()


func stop_sfx(effect_for: String):
	
	match effect_for:
		"shocker_effect":
			$Sfx/ShockerEffect.stop()
#			if $Sfx/ShockerEffect.is_playing():
#				 $Sfx/ShockerEffect.stop()
		"bolt_engine": 
			pass
			if $Sfx/BoltEngine.is_playing():
				$Sfx/BoltEngine.stop()
	
			
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
			Met.get_random_member($GuiSfx/Inputs/Typing).play()
		"btn_confirm":
			$GuiSfx/Inputs/BtnConfirm.play()
		"btn_cancel":
			$GuiSfx/Inputs/BtnCancel.play()
		"btn_focus_change":
#			if Global.allow_focus_sfx:
				$GuiSfx/Inputs/BtnFocus.play()
		# menu
		"menu_fade":
			$GuiSfx/MenuFade.play()
		"screen_slide":
			$GuiSfx/ScreenSlide.play()
		

# MUSKA --------------------------------------------------------------------------------------------------------
		

func play_music():
	
	# set track
	var current_track: AudioStreamPlayer
	if Ref.game_manager.level_settings["level"] == Set.Levels.RACE_NITRO:
		var nitro_track: AudioStreamPlayer = $"GameMusic/Nitro"
		current_track = game_music.get_node("Nitro")
	else:
		currently_playing_track_index = 2 # ga ne resetiraš, da ostane v spominu skozi celo igro
		current_track = game_music.get_child(currently_playing_track_index - 1)
	
	printt("muza", current_track)
	if not music_set_to_mute:	
		current_track.play()	


func stop_music():
	
	for music in game_music.get_children():
		if music.is_playing():
			Met.sound_stop_fade_out(music, 2)
			

func set_game_music_volume(value_on_slider: float): # kliče se iz settingsov
	
	# slajder je omejen med -30 in 10
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameMusic"), value_on_slider)
		
		
func skip_track():
	
	currently_playing_track_index += 1
	
	if currently_playing_track_index > game_music.get_child_count():
		currently_playing_track_index = 1
	
	for music in game_music.get_children():
		if music.is_playing():
			var current_music_volume = music.volume_db
			var fade_out = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)	
			fade_out.tween_property(music, "volume_db", -80, 0.5)
			fade_out.tween_callback(music, "stop")
			fade_out.tween_callback(music, "set_volume_db", [current_music_volume]) # reset glasnosti
			fade_out.tween_callback(self, "play_music", ["game_music"])
