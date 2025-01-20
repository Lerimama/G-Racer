extends Node2D


var always_visible_mode: bool = true
var selector_visibily_time: float = 1
var available_weapons_icons: Array
var actived_weapon_key: int = 0 setget _on_activate_selected_weapon # index znotraj aktivnih orožij
var unselected_weapon_alpha: float = 0.32
var y_position_offset: float # določi se na glede na pozicijo huda ob ready

onready var weapon_selector: Control = $BoltHudLines/WeaponSelector
onready var weapon_icons: Array = $BoltHudLines/WeaponSelector.get_children()
onready var health_bar: Control = $BoltHudLines/HealthBar
onready var selector_timer: Timer = $BoltHudLines/WeaponSelector/SelectorTimer
onready var health_bar_line: ColorRect = $BoltHudLines/HealthBar/Bar


func _ready() -> void:

	y_position_offset = position.y
	weapon_icons.erase(selector_timer) # timer ni ikona
	call_deferred("set_active_icons")
	self.set_deferred("actived_weapon_key", 0) # zaporedje je pomembno


func _process(delta: float) -> void:

	# manage positions and rotation
	if visible: # določi bolt
		rotation = -owner.rotation # negiramo rotacijo bolta, da je pri miru
		global_position = owner.global_position + Vector2(0, y_position_offset)
	#	test_hud.rect_global_position = (owner.global_position + Vector2(0, 8))*4 + Vector2(640, 360)# + Vector2(2560, 1440)*0.5

	# manage health bar
	if health_bar.visible:
		health_bar_line.rect_scale.x = owner.driver_stats["health"]
		if health_bar_line.rect_scale.x <= 0.5:
			health_bar_line.color = Rfs.color_red
		else:
			health_bar_line.color = Rfs.color_blue

	# manage selector
	if weapon_selector.visible:
		set_active_icons()
		for active_icon in available_weapons_icons:
			active_icon.get_node("CountLabel").text = "%02d" % get_weapon_stat_value(active_icon)


func set_active_icons():

	# aktiviram in prikažem tiste, ki niso 0 ... in obratno
	for icon in weapon_icons:
		var weapon_stat: float = get_weapon_stat_value(icon)
		# če je stat 0 mora biti skrit in deaktiviran ... in obratno
		if weapon_stat == 0:
			if icon.visible:
				icon.hide()
				self.set_deferred("actived_weapon_key", 0)
		else:
			if not icon.visible:
				icon.show()
				self.set_deferred("actived_weapon_key", actived_weapon_key)

	available_weapons_icons = []
	for icon in weapon_icons:
		if icon.visible:
			available_weapons_icons.append(icon)


func get_weapon_stat_value(weapon_icon: Control):

	var weapon_stat: float
	var weapon_icon_index: int = weapon_icons.find(weapon_icon)

	match weapon_icon_index:
		0:
			weapon_stat = owner.driver_stats["bullet_count"]
		1:
			weapon_stat = owner.driver_stats["misile_count"]
		2:
			weapon_stat = owner.driver_stats["mina_count"]
	return weapon_stat


func _on_activate_selected_weapon(selected_weapon_key: int):

	if not available_weapons_icons.empty():

		# če še ni prižgan se samo pokaže, izbrana ostane stara ikona
		if not weapon_selector.visible:
			weapon_selector.show()
			actived_weapon_key = actived_weapon_key

		# če je že prižgan, preskočim na naslednjo ikono
		else:
			# loopanje izbire
			if selected_weapon_key > available_weapons_icons.size() - 1:
				selected_weapon_key = 0
			elif selected_weapon_key < 0:
				selected_weapon_key = available_weapons_icons.size() - 1
#			set_deferred("actived_weapon_key", selected_weapon_key)
			actived_weapon_key = selected_weapon_key

		# setam ikone glede na weapon index
		for icon in available_weapons_icons:
			if actived_weapon_key == available_weapons_icons.find(icon):
				icon.modulate.a = 1
				icon.get_node("IconEdge").show()
			else:
				icon.modulate.a = unselected_weapon_alpha
				icon.get_node("IconEdge").hide()

		# konvertam index med aktivnimi orožji v index med vsemi orožji
		var current_selected_weapon_icon: Control = available_weapons_icons[actived_weapon_key]
		var selected_weapon_index: int = weapon_icons.find(current_selected_weapon_icon)

		# sprožim timer za ugasnit selector
		selector_timer.start(selector_visibily_time)


func _on_SelectorTimer_timeout() -> void:

	if always_visible_mode:
		pass
	else:
		weapon_selector.hide()
