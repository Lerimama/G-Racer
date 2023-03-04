extends Node2D


var spawned_by: String

var drop_direction: Vector2 = -transform.x # rikverc na osi x
var drop_speed: float = 32 # regulacija v animaciji
var drop_time: float = 5.0 # opredeli dolžino meta

var activate_time: float = 0.3
var deactivate_time: float = 0.7

var expand_time: float = 0.5 # fps/f tween čas eksplozije uskladi s partikli, da kufri ne bo prezgodaj
var expanded_loop_counter: int = 0 
var max_expanded_loops: int = 5 # lupanje aktiviranega polja

var detect_active_size: Vector2 = Vector2(2.5, 2.5)
var detect_expand_size: Vector2 = Vector2(6.0, 6.0) # doseg partiklov

var shockwave_position: Vector2 # def je 0,0 shader pozicija (spodnji levi kot)
var shockwave_expand_size: float = 0.15
var shockwave_expand_force: float = -0.1

onready var anim_sprite: AnimatedSprite = $MineSprite
onready var collision_area_coll: CollisionShape2D = $CollisionArea/CollisionShape2D
onready var detect_area_coll: CollisionShape2D = $DetectArea/CollisionShape2D
onready var shockwave: ColorRect = $ShockwaveNode/Shockwave
onready var shockwave_node: Node2D = $ShockwaveNode


func _ready() -> void:
	
	add_to_group("Mines")
	
	drop_direction = -transform.x # rikverc na osi x
	
	# disable detect area
	detect_area_coll.scale = Vector2.ZERO
	detect_area_coll.disabled = true # tako se ne zgodi prezgodnja interakcija in poruši vse animacije
	
	# drop mine
	var drop_tween = get_tree().create_tween()
	drop_tween.tween_property(self, "drop_speed", 0.0, drop_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	drop_tween.tween_callback(self, "activate")
	
	# shockwave_setup
	shockwave.material.set_shader_param("center", shockwave_position)
	shockwave.material.set_shader_param("force", 0.0)
	shockwave.material.set_shader_param("size", 0.0)
	shockwave.material.set_shader_param("hole_thickness", 0.0)
#	shockwave.material.set_shader_param("outside_trans", 0.03)
	
	
func _process(delta: float) -> void:
	
	# motion
	global_position += drop_direction * drop_speed * delta
	
	# shockwave - potiskanje v zgornji vogal
	shockwave_node.global_position = Vector2.ZERO
	shockwave_node.global_rotation = 0

	# shockwave - updejtanje centra
	shockwave_position = Vector2(anim_sprite.global_position.x/get_viewport_rect().size.x, 1 - anim_sprite.global_position.y/get_viewport_rect().size.y)
	shockwave.material.set_shader_param("center", shockwave_position)

		 
func activate():
	
	# najprej mino aktiviramo ...
	detect_area_coll.disabled = false
	
	var activate_tween = get_tree().create_tween()
	activate_tween.tween_property(detect_area_coll, "scale", detect_active_size, activate_time).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
#	activate_tween.parallel().tween_property(shockwave, "material:shader_param/force", -0.1, activate_time).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
#	activate_tween.parallel().tween_property(shockwave, "material:shader_param/size", 0.1, activate_time).set_trans(Tween.TRANS_SINE)#.set_ease(Tween.EASE_OUT)
	
	# loopanje
	anim_sprite.play("loop_mini")

	
# kontrola animacij
func _on_BlastSprite_animation_finished() -> void: # prvič klicano iz animacije
	
	match anim_sprite.animation:
		"expand":
			anim_sprite.play("loop_active")
		"loop_active":
			expanded_loop_counter += 1 
			if expanded_loop_counter > max_expanded_loops:
				deactivate()
							
func deactivate():
	
	anim_sprite.play("deactivate")
				
	var deactivate_tween = get_tree().create_tween()
	deactivate_tween.tween_property(detect_area_coll, "scale", Vector2.ZERO, deactivate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	deactivate_tween.parallel().tween_property(shockwave, "material:shader_param/force", 0.0, deactivate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	deactivate_tween.parallel().tween_property(shockwave, "material:shader_param/size", 0.0, deactivate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# KUEFRI
	deactivate_tween.tween_callback(self, "queue_free")
	
			
# aktivacija
func _on_DetectArea_body_entered(body: Node) -> void:
	
	# preverjam metodo ...
	if body.has_method("on_hit_by_blast"): # && body.name != spawned_by:
		
		anim_sprite.play("expand")
		
		var expand_tween = get_tree().create_tween()
		expand_tween.tween_property(shockwave, "material:shader_param/force", shockwave_expand_force, activate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		expand_tween.parallel().tween_property(shockwave, "material:shader_param/size", shockwave_expand_size, activate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		expand_tween.parallel().tween_property(detect_area_coll, "scale", detect_expand_size, activate_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
		# reset counter to 0
		expanded_loop_counter = 0
		
		# disable player
		body.on_hit_by_blast() # na plejerju se izbira ali je motion true ali false


# release plejer
func _on_DetectArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit_by_blast") :#&& body.name != spawned_by:
		body.on_hit_by_blast() # na plejerju se izbira ali je motion true ali false


func _on_CollisionArea_body_entered(body: Node) -> void:
	
	# če ni plejer se ustavi
	if body.name != spawned_by:
		drop_direction = Vector2.ZERO
		print("KONTAKT")
