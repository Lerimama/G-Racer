extends BoxContainer


#func _ready() -> void:
#func set_levels_menu() -> void: # tole gre na starša
#
#	var level_btn_template: Button = Mets.remove_chidren_and_get_template(get_children())
#
#	for level_index in Pros.LEVELS.values():
#
#		var new_level_btn: Button = level_btn_template.duplicate()
#		new_level_btn.title = Pros.level_profiles[level_index]["level_name"]
#		new_level_btn.thumb_texture = Pros.level_profiles[level_index]["level_thumb"]
#		new_level_btn.description = Pros.level_profiles[level_index]["level_desc"]
#		add_child(new_level_btn)
#
#		new_level_btn.connect("pressed", get_parent(), "_on_level_btn_pressed", [new_level_btn])
#		new_level_btn.connect("focus_entered", get_parent(), "_on_level_btn_focused", [new_level_btn])
#
#		# pressed
#		var btn_index: int = get_children().find(new_level_btn)
#		if btn_index in Sets.game_levels:
#			new_level_btn.is_selected = true
#		else:
#			new_level_btn.is_selected = false
#
#	yield(get_tree(), "idle_frame")
#	# fokus za ciklanje ... ne dela
#	var first_btn: Button = get_children().front()
#	var last_btn: Button = get_children().back()
#	first_btn.focus_neighbour_left = get_path_to(last_btn)
#	first_btn.set_focus_neighbour(MARGIN_LEFT, get_path_to(last_btn))
#	last_btn.set_focus_neighbour(MARGIN_RIGHT, get_path_to(first_btn))


#var selected_level_btns: Array = []
#func _on_level_btn_pressed(btn: Button):
#
#	if btn in selected_level_btns:
#		selected_level_btns.erase(btn)
#		btn.is_selected = false
#	else:
#		selected_level_btns.append(btn)
#		btn.is_selected = true
#
#			# single level mode
#		#	var btn_index: int = get_children().find(btn)
#		#
#		#	# _temp select one level only
#		#	Sets.game_levels = [btn_index]
#		#	for other_btn in get_children():
#		#		if other_btn == btn:
#		#			other_btn.is_selected = true
#		#		else:
#		#			other_btn.is_selected = false
#
#
#var focused_level_btn_index: int = 0 # da vem levo/desno
#func _on_level_btn_focused(btn: Button):
#
#	btn.focused_display.show()
#
#	# levo/desno
#	var slide_direction: int = 1
#	var new_focused_btn_index: int = get_children().find(btn)
#	if focused_level_btn_index < new_focused_btn_index:
#		slide_direction = -1
#	elif focused_level_btn_index == new_focused_btn_index:
#		slide_direction = 0
#	focused_level_btn_index = new_focused_btn_index
#
#	var slide_distance: float = btn.rect_size.x + get_constant("hseparation")
#	var slide_tween = get_tree().create_tween()
#	slide_tween.tween_property(self, "rect_position:x", slide_distance * slide_direction, 0.2).as_relative()
