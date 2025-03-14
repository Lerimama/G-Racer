extends HBoxContainer


func _ready() -> void:

	var level_btn_template: Button = Mets.remove_chidren_and_get_template(get_children())

	for level_index in Pros.LEVELS.values():

		var new_level_btn: Button = level_btn_template.duplicate()
		new_level_btn.title = Pros.level_profiles[level_index]["level_name"]
		new_level_btn.thumb_texture = Pros.level_profiles[level_index]["level_thumb"]
		new_level_btn.description = Pros.level_profiles[level_index]["level_desc"]
		add_child(new_level_btn)

		new_level_btn.connect("pressed", self, "_on_level_btn_pressed", [new_level_btn])

		# pressed
		var btn_index: int = get_children().find(new_level_btn)
		if btn_index in Sets.game_levels:
			new_level_btn.is_activated = true
		else:
			new_level_btn.is_activated = false

	yield(get_tree(), "idle_frame")
	# fokus za ciklanje ... ne dela
	var first_btn: Button = get_children().front()
	var last_btn: Button = get_children().back()
	first_btn.focus_neighbour_left = get_path_to(last_btn)
	first_btn.set_focus_neighbour(MARGIN_LEFT, get_path_to(last_btn))
	last_btn.set_focus_neighbour(MARGIN_RIGHT, get_path_to(first_btn))


func _on_level_btn_pressed(btn: Button):

	var btn_index: int = get_children().find(btn)

	# _temp select one level only
	Sets.game_levels = [btn_index]
	for other_btn in get_children():
		if other_btn == btn:
			other_btn.is_activated = true
		else:
			other_btn.is_activated = false

	# turnir mode
	#	other_btn.is_activated = not other_btn.is_activated

	#	if btn_index in Sets.game_levels:
	#		Sets.game_levels.erase(btn_index)
	#	else:
	#		Sets.game_levels.append(btn_index)
