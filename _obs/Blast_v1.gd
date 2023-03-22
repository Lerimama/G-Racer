extends Node2D


### ------------------------------------------------------------------------------
###
### štarta z intro animacijo in tween_on 
### ko area zazna drugega pejerja se sproži tween_off
### tween_off na koncu kliče "expand" animacijo in "trail decay"
### "expand" animacija po koncu kliče "activated" loop
### "activated" loop se ponovi n-krat in potem
###- tweens > intro, outro, explode
### TRAIL
### širina traila se poveča z intro animacijo
### ko se izvaja "trail decay"
###
### ZAZNAVANJE OBJEKTOV
### - zaznavanja lastnika rešim tako, da se area
### - zaznavanje zadnje stene rešim tako, da se area od štarta poveča
### - proti koncu se area zmanjša, da lahko spet zajamem oškodovance
### - area se poveča ročno usklajeno s partikli (tween)
###
### ------------------------------------------------------------------------------

#signal Get_hit (hit_location, misile_velocity, misile_owner)

var spawned_by: String

var speed: float = 0 # regulacija v animaciji
var max_speed: float = 1000 # regulacija v animaciji
var direction: Vector2

export var flight_intro_time: float = 0.2
export var flight_outro_time: float = 0.05

var detect_size: Vector2 = Vector2.ZERO
var detect_max_size: Vector2 = Vector2(8, 8) # max velikost ob letu
var detect_explode_size: Vector2 = Vector2(17.5, 17.5) # doseg partiklov

var explode_time: float = 1.8 # tween čas eksplozije uskladi s partikli (da ne bo kufri prezgodaj

var tween_name: String
var new_blast_trail: Object

onready var explosion_particles: Particles2D = $ExplosionParticles
onready var blast_sprite: AnimatedSprite = $BlastSprite
onready var tween: Tween = $Tween
onready var detect_area: Area2D = $DetectArea
onready var BlastTrail: PackedScene = preload("res://scenes/weapons/BlastTrail.tscn") 

var decay_started: bool

func _ready() -> void:
	
	add_to_group("Blasts")
	blast_sprite.play("intro")
	direction = transform.x # rotacija smeri ob štartu
	detect_area.scale = detect_size
	
	# spawn trail
	new_blast_trail = BlastTrail.instance()
	new_blast_trail.position = $TrailPosition.position
	Global.effects_creation_parent.add_child(new_blast_trail)
	new_blast_trail.set_as_toplevel(true)
	
	# speed up
	tween_name = "intro_tween"
	tween.interpolate_property(self ,"speed", null, max_speed, flight_intro_time, Tween.TRANS_QUAD, Tween.EASE_IN )
	tween.interpolate_property(self ,"detect_size", null, detect_max_size, flight_intro_time, Tween.TRANS_EXPO, Tween.EASE_IN )
	tween.start() # ob koncu kliče "speed down"
	
	
func _process(delta: float) -> void:
	
	print(tween_name)
	# scale detect
	detect_area.scale = detect_size
	
	# add points
	if speed > 5: # tako konča že dovolj zgodaj, da ne daje točk v null objekt
		new_blast_trail.add_points(global_position)
		pass
	
	# accelaration
	position += direction * speed * delta


func explode(): 
	
	explosion_particles.emitting = true
	
	# povečanje detect area
	tween_name = "explode_tween"
	tween.interpolate_property(self ,"detect_size", null, detect_explode_size, explode_time, Tween.TRANS_EXPO, Tween.EASE_OUT )
	tween.start()

	blast_sprite.visible = false
	
	
# po expand animaciji
func _on_BlastSprite_animation_finished() -> void: # prvič klicano iz animacije
	
	# katera animacija je končana
	if blast_sprite.animation == "expand":
		explode()


# detect other obj and speed down
func _on_DetectArea_body_entered(body: Node) -> void:
	
	# preverjam, da vtor ni lastnik
	if body.name != spawned_by: # objekt ni lastnik
		tween_name = "outro_tween" # pseudo ime twina
		tween.interpolate_property(self ,"speed", null, 0, flight_outro_time, Tween.TRANS_QUAD, Tween.EASE_OUT )
		tween.interpolate_property(self ,"detect_size", detect_max_size, Vector2.ZERO, flight_intro_time, Tween.TRANS_LINEAR, Tween.EASE_OUT )
		tween.start()
		

# ko se ustavi
func _on_Tween_tween_completed(object: Object, key: NodePath) -> void:
	
	# preverjamo ime tweena
	if tween_name == "outro_tween" || decay_started != true:
		
		tween_name = "trivial_tween" # sam da ni isto kot zgoraj ... izločim signale ostalih tweenov
		
		new_blast_trail.start_decay()
		decay_started = true
		
		blast_sprite.play("expand")


# ko se explozija konča
func _on_Tween_tween_all_completed() -> void:

	# preverjamo ime tweena
	if tween_name == "explode_tween":
		print("KUFRI - Blast")
		queue_free()
