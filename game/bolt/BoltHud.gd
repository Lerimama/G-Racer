extends Node2D


var always_visible_mode: bool = true 
var selector_visibily_time: float = 1

var active_weapon_icons: Array
var selected_active_weapon_index: int = 0 setget _on_select_weapon # index znotraj aktivnih orožij
var selected_weapon_index: int # index znotraj vseh orožij

onready var owner_bolt: KinematicBody2D = get_parent()
onready var weapon_selector: Control = $BoltHudLines/WeaponSelector
onready var weapon_icons: Array = $BoltHudLines/WeaponSelector/Weapons.get_children()
onready var energy_bar_line: Polygon2D = $BoltHudLines/EnergyBar/Bar
onready var energy_bar: Control = $BoltHudLines/EnergyBar


func _ready() -> void:

	call_deferred("set_active_icons")
	self.set_deferred("selected_active_weapon_index", 0) # zaporedje je pomembno


func _process(delta: float) -> void:

	# manage positions and rotation
	if visible:
		rotation = -owner_bolt.rotation # negiramo rotacijo bolta, da je pri miru
		global_position = owner_bolt.global_position + Vector2(0, 8)
	
	# manage energy bar
	if energy_bar.visible:
		energy_bar_line.scale.x = owner_bolt.player_stats["energy"] / owner_bolt.max_energy
		if energy_bar_line.scale.x <= 0.5:
			energy_bar_line.color = Ref.color_red
		else:
			energy_bar_line.color = Ref.color_blue

	# manage selector
	if weapon_selector.visible:
		set_active_icons()
		for active_icon in active_weapon_icons:
			active_icon.get_node("Label").text = "%02d" % get_weapon_stat_value(active_icon)
	

func set_active_icons():
	
	# aktiviram in prikažem tiste, ki niso 0 ... in obratno
	for icon in weapon_icons:
		var weapon_stat: float = get_weapon_stat_value(icon)
		# če je stat 0 mora biti skrit in deaktiviran ... in obratno
		if weapon_stat == 0:
			if icon.visible:
				icon.hide()
				self.set_deferred("selected_active_weapon_index", 0)
		else:
			if not icon.visible:
				icon.show() 
				self.set_deferred("selected_active_weapon_index", selected_active_weapon_index)
	
	active_weapon_icons = []
	for icon in weapon_icons:
		if icon.visible:
			active_weapon_icons.append(icon)


func get_weapon_stat_value(weapon_icon: Control):
	
	var weapon_stat: float
	var weapon_icon_index: int = weapon_icons.find(weapon_icon)
	
	match weapon_icon_index:
		0:
			weapon_stat = owner_bolt.player_stats["bullet_count"]
		1:
			weapon_stat = owner_bolt.player_stats["misile_count"]
		2:
			weapon_stat = owner_bolt.player_stats["mina_count"]
		3:
			weapon_stat = owner_bolt.player_stats["shocker_count"]
	
	return weapon_stat		


func _on_select_weapon(new_selected_index: int):
	
	if not active_weapon_icons.empty():
		
		# če še ni prižgan se samo pokaže, izbrana ostane stara ikona
		if not weapon_selector.visible:
			weapon_selector.show()
			selected_active_weapon_index = selected_active_weapon_index
			
		# če je že prižgan, preskočim na naslednjo ikon
		else:
			# loopanje izbire
			if new_selected_index > active_weapon_icons.size() - 1:
				new_selected_index = 0
			elif new_selected_index < 0:
				new_selected_index = active_weapon_icons.size() - 1
#			set_deferred("selected_active_weapon_index", new_selected_index)
			selected_active_weapon_index = new_selected_index
		
		# setam ikone glede na weapon index
		for icon in active_weapon_icons:
			if selected_active_weapon_index == active_weapon_icons.find(icon):
				icon.modulate.a = 1
				icon.get_node("IconEdge").show()
				#				icon.get_node("Label").show()
			else:
				icon.modulate.a = 0.5
				icon.get_node("IconEdge").hide()
				#				icon.get_node("Label").hide()
		
		# konvertam index med aktivnimi orožji v index med vsemi orožji
		var current_selected_weapon_icon: Control = active_weapon_icons[selected_active_weapon_index]
		selected_weapon_index = weapon_icons.find(current_selected_weapon_icon)
			
		# sprožim timer za ugasnit selector			
		$BoltHudLines/WeaponSelector/SelectorTimer.start(selector_visibily_time)


func _on_SelectorTimer_timeout() -> void:
	
	if always_visible_mode:
		pass
	else:
		weapon_selector.hide()
