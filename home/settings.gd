extends Control


onready var intro: Node2D = $"%Intro"
onready var colors_container: HBoxContainer = $ColorSchemeOptions/Colors


func _ready() -> void:
	
	
	# menu music state
	if Global.sound_manager.menu_music_set_to_off:
		$MenuMusicBtn.pressed = false
	else:
		$MenuMusicBtn.pressed = true
	
	# game music state
	if Global.sound_manager.game_music_set_to_off:
		$GameMusicBtn.pressed = false
	else:
		$GameMusicBtn.pressed = true
	$GameMusicSlider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameMusic")) # da je slajder v settingsih in pavzi poenoten

	# game sfx state
	if Global.sound_manager.game_sfx_set_to_off:
		$GameSfxBtn.pressed = false
	else:
		$GameSfxBtn.pressed = true
	
	# cam shake state
	if Global.main_node.camera_shake_on:
		$CameraShakeBtn.pressed = true
	else:
		$CameraShakeBtn.pressed = false

	# pregame screen
	if Profiles.default_game_settings["game_instructions_popup"] == true:
		$InstructionsBtn.pressed = true
	else:
		$InstructionsBtn.pressed = false
		
	# color scheme selector state
	for color_btn in colors_container.get_children(): # deselect all
		color_btn.set_pressed_no_signal(false)
		color_btn.get_node("SelectedIcon").visible = false
		
	
	if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]: 
		$ColorSchemeOptions/Colors/ColorBtn.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_2"]: 
		$ColorSchemeOptions/Colors/ColorBtn2.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_3"]: 
		$ColorSchemeOptions/Colors/ColorBtn3.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_4"]: 
		$ColorSchemeOptions/Colors/ColorBtn4.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_5"]: 
		$ColorSchemeOptions/Colors/ColorBtn5.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_6"]: 
		$ColorSchemeOptions/Colors/ColorBtn6.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_7"]: 
		$ColorSchemeOptions/Colors/ColorBtn7.set_pressed_no_signal(true)
	elif Profiles.current_color_scheme == Profiles.game_color_schemes["color_scheme_8"]: 
		$ColorSchemeOptions/Colors/ColorBtn8.set_pressed_no_signal(true)
	
	for color_btn in colors_container.get_children(): # pressed btn efekt
		if color_btn.is_pressed():
			color_btn.set_disabled(true)
			color_btn.get_node("SelectedIcon").visible = true


func _process(delta: float) -> void:
	
	# barvanje color schemes gumba / titla
	for child in $ColorSchemeOptions/Colors.get_children():
		if child.has_focus():
			$ColorSchemeOptions.modulate = Color.white
			break
		$ColorSchemeOptions.modulate = Global.color_gui_gray
		
	
func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("settings")
	get_viewport().set_disable_input(true)
	
		
func _on_MenuMusicBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.menu_music_set_to_off = false
		Global.sound_manager.play_music("menu_music")
	else:
		Global.sound_manager.stop_music("menu_music")
		Global.sound_manager.menu_music_set_to_off = true


func _on_GameMusicBtn_toggled(button_pressed: bool) -> void:
	
	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_music_set_to_off = false
	else:
		Global.sound_manager.game_music_set_to_off = true


func _on_MusicHSlider_value_changed(value: float) -> void:
	
	Global.sound_manager.set_game_music_volume(value)


func _on_GameSfxBtn_toggled(button_pressed: bool) -> void:

	# ker muzika še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
	else:
		Global.sound_manager.game_sfx_set_to_off = true


func _on_CameraShakeBtn_toggled(button_pressed: bool) -> void:
	
	# ker igra še ni naloudana samo setam željeno stanje ob nalaganju
	if button_pressed:
		Global.main_node.camera_shake_on = true
	else:
		Global.main_node.camera_shake_on = false


func _on_InstructionsBtn_toggled(button_pressed: bool) -> void:
	
	if button_pressed:
		Global.sound_manager.game_sfx_set_to_off = false
		Profiles.default_game_settings["game_instructions_popup"] = true
	else:
		Profiles.default_game_settings["game_instructions_popup"] = false
		
		
# COLOR SCHEMES ----------------------------------------------------------------------------------------------------------------

		
func color_scheme_selector(pressed_btn_name: String):
	
	for color_btn in colors_container.get_children():
		if not color_btn.name == pressed_btn_name: # deselect all other
			color_btn.set_pressed_no_signal(false)
			color_btn.set_disabled(false)
			color_btn.get_node("SelectedIcon").visible = false
		if color_btn.name == pressed_btn_name: # zaščita pred ponovnim klikom
			color_btn.set_disabled(true)
			color_btn.get_node("SelectedIcon").visible = true


func _on_ColorBtn_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["default_color_scheme"]
	color_scheme_selector("ColorBtn")
	intro.respawn_strays()
	
	
func _on_ColorBtn2_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_2"]
	color_scheme_selector("ColorBtn2")
	intro.respawn_strays()


func _on_ColorBtn3_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_3"]
	color_scheme_selector("ColorBtn3")
	intro.respawn_strays()


func _on_ColorBtn4_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_4"]
	color_scheme_selector("ColorBtn4")
	intro.respawn_strays()


func _on_ColorBtn5_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_5"]
	color_scheme_selector("ColorBtn5")
	intro.respawn_strays()


func _on_ColorBtn6_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_6"]
	color_scheme_selector("ColorBtn6")
	intro.respawn_strays()


func _on_ColorBtn7_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_7"]
	color_scheme_selector("ColorBtn7")
	intro.respawn_strays()


func _on_ColorBtn8_toggled(button_pressed: bool) -> void:
	
	Profiles.current_color_scheme = Profiles.game_color_schemes["color_scheme_8"]
	color_scheme_selector("ColorBtn8")
	intro.respawn_strays()
