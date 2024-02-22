extends KinematicBody2D
class_name Stray

enum States {IDLE, MOVING, STATIC, DYING, WALL} # static, unmovable ... ko je GO ali pa je poden
var current_state = States.IDLE # ni vready, da lahko setam že ob spawnu

var stray_color: Color
var step_attempt: int = 1 # če nima prostora, proba v drugo smer (največ 4krat)
var visible_on_screen: bool = false

onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var collision_shape_ext: CollisionShape2D = $CollisionShapeExt
onready var vision_rays: Array = [$Vision/VisionRay1, $Vision/VisionRay2, $Vision/VisionRay3]
onready var vision: Node2D = $Vision
onready var color_poly: Polygon2D = $ColorPoly
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var count_label: Label = $CountLabel # debug
onready var position_indicator: Node2D = $PositionIndicator
onready var visibility_notifier_2d: VisibilityNotifier2D = $VisibilityNotifier2D
onready var cell_size_x: int = Global.current_tilemap.cell_size.x
#onready var step_time: float = Global.game_manager.game_settings["stray_step_time"]


func _ready() -> void:
	
	add_to_group(Global.group_strays)

	randomize() # za random die animacije
	
	color_poly.modulate = stray_color
	modulate.a = 0
	position_indicator.get_node("PositionPoly").color = stray_color
	count_label.text = name
	position_indicator.visible = false


func _process(delta: float) -> void:
	
	if Global.game_manager.show_position_indicators:
		position_indicator.visible = true
	else:
		position_indicator.visible = false
	
	if position_indicator.visible:
		get_position_indicator_position(get_viewport().get_node("PlayerCamera"))
	
	
func show_stray(): # kliče GM
	
	# žrebam animacijo
	var random_animation_index = randi() % 3 + 1
	var random_animation_name: String = "glitch_%s" % random_animation_index
	animation_player.play(random_animation_name)


func die(stray_in_stack_index: int, strays_in_stack_count: int):
	
	current_state = States.DYING
	global_position = Global.snap_to_nearest_grid(global_position) 
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# animacije
	if strays_in_stack_count <= 3: # žrebam
		var random_animation_index = randi() % 5 + 1
		var random_animation_name: String = "die_stray_%s" % random_animation_index
		animation_player.play(random_animation_name) 
	else: # ne žrebam
		animation_player.play("die_stray")

	position_indicator.modulate.a = 0	
	collision_shape.disabled = true
	collision_shape_ext.disabled = true
	
	# color vanish
	var vanish_time = animation_player.get_current_animation_length()
	var vanish: SceneTreeTween = get_tree().create_tween()
	vanish.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	
	# KVEFRI je v animaciji


# MOVEMENT ------------------------------------------------------------------------------------------------------
	
	
func step(step_direction: Vector2):
	
	if not current_state == States.IDLE:
	# if current_state.STATIC:
		return
		
	var current_collider = detect_collision_in_direction(step_direction)
	
	if current_collider:
#		if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
#			return
#		else: # če kolajda izbrani smeri gibanja zarotira smer za 90 in poskusi znova
		step_attempt += 1
		if step_attempt < 5:
			var new_direction = step_direction.rotated(deg2rad(90))
			step(new_direction)
			step_attempt = 1
		return
	
	current_state = States.MOVING
	
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika
	
	var step_time: float = 0.2
	
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")


func push_stray(push_direction: Vector2, push_cock_time: float, push_time: float):
	
	current_state = States.MOVING
	var stray_move_time: float = 0.08
	var heavier_hit_delay: float = 0.05  # z delayom je porinek bolj pristen in "težak"
	
	var push_tween = get_tree().create_tween()
	# napnem
	push_tween.tween_property(collision_shape_ext, "position", - push_direction * cell_size_x, push_cock_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # animiram simultano s premikom plejerja
#	# spustim
	push_tween.tween_property(collision_shape_ext, "position", Vector2.ZERO, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN) # vrnem jo na 0 pozicijo
	push_tween.tween_callback(collision_shape_ext, "set_position", [push_direction * cell_size_x]) # potem jo takoj vržem pred straja, da zaščiti premik naprej
	push_tween.tween_property(self, "position", global_position + push_direction * cell_size_x, stray_move_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(heavier_hit_delay)
	push_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, stray_move_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(heavier_hit_delay)
	push_tween.tween_callback(self, "end_move")
	
	
func pull_stray(pull_direction: Vector2, pull_cock_time: float, pull_time: float):
	
	current_state = States.MOVING

	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pull_tween.tween_property(collision_shape_ext, "position", pull_direction * cell_size_x, pull_cock_time) # collision_ext v smer premika (animiram s premikom plejerja)
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x, pull_time)#.set_delay(pull_time)
	pull_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, pull_time) # stray ext shape
	pull_tween.tween_callback(self, "end_move")


func end_move():
	
	if current_state == States.MOVING: # da se stanje resetira samo če ni STATIC al pa DYING al pa WALL
		current_state = States.IDLE
		# modulate = Color.red
	global_position = Global.snap_to_nearest_grid(global_position) 
	
		
# UTILITI ------------------------------------------------------------------------------------------------------


func get_position_indicator_position(current_camera: Camera2D):
	
	var viewport_position = get_viewport_rect().position
	var viewport_size = get_viewport_rect().end
	var current_camera_position = current_camera.get_camera_screen_center()
	
	var camera_edge_clamp_down_x = current_camera_position.x - viewport_size.x/2 + cell_size_x/2 # polovička vp-ja na vsako stran centra kamere
	var camera_edge_clamp_up_x = current_camera_position.x + viewport_size.x/2 - cell_size_x/2
	var camera_edge_clamp_down_y = current_camera_position.y - viewport_size.y/2 + cell_size_x/2 # polovička vp-ja na vsako stran centra kamere
	var camera_edge_clamp_up_y = current_camera_position.y + viewport_size.y/2 - cell_size_x/2
		
	position_indicator.global_position = global_position
	position_indicator.global_position.x = clamp(position_indicator.global_position.x, camera_edge_clamp_down_x, camera_edge_clamp_up_x)
	position_indicator.global_position.y = clamp(position_indicator.global_position.y, camera_edge_clamp_down_y, camera_edge_clamp_up_y)
	

func play_sound(effect_for: String):
	
	if Global.sound_manager.game_sfx_set_to_off:
		return
		
	match effect_for:
		"turning_color":
			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
		"blinking":
			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
			$Sounds/BlinkingStatic.get_child(random_static_index).play()
		"stepping":
			var random_step_index = randi() % $Sounds/Stepping.get_child_count()
			var selected_step_sound = $Sounds/Stepping.get_child(random_step_index).play()


func get_neighbor_strays_on_hit(): # kliče player on hit
	
	var directions_to_check: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var current_cell_neighbors: Array
	
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			if not neighbor.current_state == neighbor.States.DYING and not neighbor.current_state == neighbor.States.WALL: # če je vstanju umiranja se ne šteje za soseda
				current_cell_neighbors.append(neighbor)
				
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov

	
func detect_collision_in_direction(direction_to_check):
	
	# obrnem vision grupo v smeri...
	vision.look_at(global_position + direction_to_check)
	
	# vsi ray gledajo naravnost
	for ray in vision_rays:
		ray.cast_to = Vector2(45, 0) # en pixel manj kot 48, da ne seže preko celice
	
	# grebanje kolajderja	
	var first_collider: Node2D
	for ray in vision_rays:
		ray.add_exception(self)
		ray.force_raycast_update()
		if ray.is_colliding():
			first_collider = ray.get_collider()
			break # ko je kolajder neham čekirat
	
	return first_collider


# SIGNALI ------------------------------------------------------------------------------------------------------


func _on_VisibilityNotifier2D_viewport_entered(viewport: Viewport) -> void:
	
	Global.strays_on_screen.append(self)
	visible_on_screen = true

func _on_VisibilityNotifier2D_viewport_exited(viewport: Viewport) -> void:
	
	Global.strays_on_screen.erase(self)
	visible_on_screen = false
