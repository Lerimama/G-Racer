extends Node2D


#signal Get_hit (hit_location, misile_velocity, misile_owner)

var spawned_by: String

var speed: float = -32 # regulacija v animaciji
var direction: Vector2

var flight_time: float = 0.8

var detect_size: Vector2 = Vector2.ZERO
var detect_max_size: Vector2 = Vector2(5, 5) # max velikost ob letu
var detect_explode_size: Vector2 = Vector2(7.5, 7.5) # doseg partiklov

var explosion_time: float = 0.5 # fps/f tween čas eksplozije uskladi s partikli (da ne bo kufri prezgodaj

# animacije
var tween_name: String
var animation_loop_counter: int = 0 
var max_explosion_loop: int = 3 # kolk cajta je igralec zaklenjen

#onready var explosion_particles: Particles2D = $ExplosionParticles
onready var blast_sprite: AnimatedSprite = $BlastSprite
onready var tween: Tween = $Tween
onready var detect_area_poly: CollisionPolygon2D = $DetectArea/CollisionPolygon2D


func _ready() -> void:
	
	add_to_group("Blasts")
	
	direction = transform.x # rotacija smeri ob štartu
	
	# scale detect area
	detect_area_poly.scale = detect_size
	
	# relase
	tween_name = "flight_tween"
	tween.interpolate_property(self ,"speed", null, 0, flight_time, Tween.TRANS_LINEAR, Tween.EASE_OUT )
	tween.start()
	
	detect_area_poly.disabled = true # tako se ne zgodi prezgodnja interakcij in poruši vse animacije
	
	
func _process(delta: float) -> void:
	
	# scale detect area
	detect_area_poly.scale = detect_size
	
	# motion
	position += direction * speed * delta
	 

# kontrola animacij
func _on_BlastSprite_animation_finished() -> void: # prvič klicano iz animacije
	
	# po določeni animaciji naredi ...
	match blast_sprite.animation:
		
		"expand":
			blast_sprite.play("warning")
			# povečanje detect area
			tween.interpolate_property(self ,"detect_size", null, detect_max_size, explosion_time, Tween.TRANS_LINEAR, Tween.EASE_OUT )
			tween.start()
		"warning":
			detect_area_poly.disabled = false
		"explosion": # kličem iz area signala
			blast_sprite.play("explosion_loop")
		"explosion_loop":
			animation_loop_counter += 1 
			if animation_loop_counter > max_explosion_loop:
				blast_sprite.play("close")
				
				# pomanjšanje detect area
				tween_name = "close_tween"
				tween.interpolate_property(self ,"detect_size", null, Vector2.ZERO, explosion_time, Tween.TRANS_QUAD, Tween.EASE_IN )
				tween.start()	
							
		"close":
			detect_area_poly.disabled = true # tako se ne zgodi prezgodnja interakcij in poruši vse animacije
			animation_loop_counter = 0
#			print("KUFRI - Blast")
			queue_free()	
		

# ko se ustavi po flight
func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
	
	# preverjamo ime tweena
	if tween_name == "flight_tween":
		tween_name = "nn_tween" # sam da ni isto kot zgoraj ... izločim signale ostalih tweenov
		blast_sprite.play("expand")


# detect in aktivacija
func _on_DetectArea_body_entered(body: Node) -> void:
	
	# preverjam, da ni avtor in ima metodo ...
	if body.has_method("on_hit_by_blast"): # && body.name != spawned_by:
		
		blast_sprite.play("explosion")
		# povečanje detect area
		tween.interpolate_property(self ,"detect_size", null, detect_explode_size, explosion_time, Tween.TRANS_LINEAR, Tween.EASE_OUT )
		tween.start()
		# reset counter to 0
		animation_loop_counter = 0

		body.on_hit_by_blast() # na plejerju se izbira ali je motion true ali false


# release prisoner
func _on_DetectArea_body_exited(body: Node) -> void:
		# preverjam, da ni avtor in ima metodo ...
	if body.has_method("on_hit_by_blast") :#&& body.name != spawned_by:
		
		body.on_hit_by_blast() # na plejerju se izbira ali je motion true ali false
