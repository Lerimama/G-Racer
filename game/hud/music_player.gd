extends Label


onready var on_icon: TextureRect = $OnIcon
onready var off_icon: TextureRect = $OffIcon


func _input(event: InputEvent) -> void:
	
	if Global.game_manager.game_on and visible == true: # visible je, da deluje samo na enem plejerju
		if Input.is_action_just_pressed("n") and visible == true: 
			if not AudioServer.is_bus_mute(2):
				Global.sound_manager.skip_track()
		
		if Input.is_action_just_pressed("m") and visible == true:
			AudioServer.set_bus_mute(2, not AudioServer.is_bus_mute(2))
	

func _process(delta: float) -> void:
	
	text = "%02d" % Global.sound_manager.currently_playing_track_index
	
	if AudioServer.is_bus_mute(2) or Global.sound_manager.game_music_set_to_off:
		on_icon.visible = false
		off_icon.visible = true
	else:
		on_icon.visible = true
		off_icon.visible = false
