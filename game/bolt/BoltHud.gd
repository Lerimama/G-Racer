extends Node2D


var available_features_keys: Array # = [Pfs.AMMO.BULLET, Pfs.AMMO.MISILE, Pfs.AMMO.MINA]
var active_features_indexes: Array = [] # array indexov med available_featuresi
var selected_feature_index: int = 0 setget _change_selected_weapon # index znotraj aktivnih orožij

# lnf
var y_position_offset: float # določi se na glede na pozicijo huda ob ready
var unselected_feature_alpha: float = 0.32

var always_visible_mode: bool = true # če ni uporabljam timer, ki ugasne zadevo po selectanju
var selector_visibily_time: float = 1

onready var owner_node: Node2D = get_parent()
onready var selector: Control = $BoltHudLines/Selector
onready var selector_timer: Timer = $BoltHudLines/SelectorTimer
onready var health_bar: Control = $BoltHudLines/HealthBar
onready var health_bar_line: ColorRect = $BoltHudLines/HealthBar/Bar
onready var rotation_label: Label = $BoltHudLines/RotationLabel


func _ready() -> void:

	y_position_offset = position.y

	yield(owner_node, "ready")

	# dodam opremo na voljo (malo bolj zapleteno, da se ne podvaja)
	var unique_feature_nodes: Array = []
	for feat_node in owner_node.available_weapons:
		var first_3_letters: String = feat_node.name.left(3)
		var duplicated: bool = false
		for uniq in unique_feature_nodes:
			if uniq.name.left(3) == first_3_letters:
				duplicated = true
		if not duplicated:
			unique_feature_nodes.append(feat_node)
	for uniq_feat in unique_feature_nodes:
		if uniq_feat.weapon_is_set:
			available_features_keys.append(uniq_feat.weapon_ammo)

	_add_features_to_selector()

	for key in available_features_keys:
		var feat_count_key: int = Pfs.ammo_profiles[key]["stat_key"]
		var feat_count: float = owner_node.driver_stats[feat_count_key]
		var feat_index: int = available_features_keys.find(key)
		_update_feature(feat_index, feat_count)

	self.selected_feature_index = 0


func _process(delta: float) -> void:

	# manage positions and rotation
	if visible: # določi bolt
		global_rotation = 0 # negiramo rotacijo bolta, da je pri miru
		global_position = owner_node.global_position + Vector2(0, y_position_offset)

	# manage health bar
	if health_bar.visible:
		health_bar_line.rect_scale.x = owner.driver_stats[Pfs.STATS.HEALTH]
		if health_bar_line.rect_scale.x <= 0.5:
			health_bar_line.color = Rfs.color_red
		else:
			health_bar_line.color = Rfs.color_blue

	# manage selector
	if selector.visible:
		for key in available_features_keys:
			var feat_count: float = owner_node.driver_stats[Pfs.ammo_profiles[key]["stat_key"]]
			var feat_index: int = available_features_keys.find(key)
			_update_feature(feat_index, feat_count)


func _add_features_to_selector():

	for key in available_features_keys:
		var new_feature_box = selector.get_child(0).duplicate()
		selector.add_child(new_feature_box)
		new_feature_box.get_node("Icon").texture = Pfs.ammo_profiles[key]["icon"]

	# zbrišem template
	selector.get_child(0).queue_free()


func _update_feature(feature_index: int, new_value):

	var feature_node: Control = selector.get_child(feature_index)
	feature_node.get_node("CountLabel").text = "%02d" % new_value

	# (de)aktiviram
	if new_value <= 0:
		feature_node.hide()
		active_features_indexes.erase(feature_index)
		self.set_deferred("selected_feature_index", 0)
	else:
		feature_node.show()
		if not active_features_indexes.has(feature_node):
			active_features_indexes.append(feature_index)
		self.set_deferred("selected_feature_index", selected_feature_index)


func _change_selected_weapon(new_feat_key: int):
#	print(selected_weapon_key)

	if not available_features_keys.size() > 1:
		selected_feature_index = 0
	else:
#	if not new_feat_key == selected_feature_index:

		# če še ni prižgan se samo pokaže, izbrana ostane stara ikona
		if not selector.visible:
			selector.show()
			selected_feature_index = selected_feature_index

		# če je že prižgan, preskočim na naslednjo ikono
		else:
			# loopanje izbire
			if new_feat_key > available_features_keys.size() - 1:
				new_feat_key = 0
			elif new_feat_key < 0:
				new_feat_key = available_features_keys.size() - 1
			selected_feature_index = new_feat_key

		# setam ikone glede na weapon index
		for key in available_features_keys:
			var feature_node: Control = selector.get_child(key)
			if selected_feature_index == available_features_keys.find(key):
				feature_node.modulate.a = 1
			else:
				feature_node.modulate.a = unselected_feature_alpha
		# old v
		#		for node_index in selector.get_children().size():
		#			var feature_node: Control = selector.get_children()[node_index]
		##			if selected_feature_index == active_features_indexes.find(node_index):
		#			if selected_feature_index == available_features_keys.find(node_index):
		#				feature_node.modulate.a = 1
		#			else:
		#				feature_node.modulate.a = unselected_weapon_alpha

		# sprožim timer za ugasnit selector
		selector_timer.start(selector_visibily_time)


func _on_SelectorTimer_timeout() -> void:

	if always_visible_mode: # zazih
		pass
	else:
		selector.hide()
