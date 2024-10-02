extends Node2D

enum POSITIONS {LEFT, RIGHT, FRONT, REAR}
export (POSITIONS) var position_on_bolt: int = 0
#export var owner_node_path: String = 
onready var owner_node: Node2D = owner.owner

var thrust_active: bool = false
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var pseudo_stop_speed: = 15.0
var active_trail: Line2D

# particles
var thrust_particles_name: String = "ThrustParticles"
var thrust_over_particles_name: String = "ThrustOverParticles"
var smoke_particles_name: String = "SmokeParticles"
onready var side_left: Node2D = $SideLeft
onready var side_right: Node2D = $SideRight
var current_side_node: Node2D


func _ready() -> void:
	
#	print ("P", owner)
##	var owner_node_path
#	if owner_node_path:
#		owner_node = get_node(owner_node_path)
#	print ("N", owner)
	
	match position_on_bolt:
		POSITIONS.LEFT:
			current_side_node = side_left
			side_right.queue_free()
			
		POSITIONS.RIGHT:
			current_side_node = side_right
			side_left.queue_free()

	# vse na off, potem prižgem
	for side in [side_left, side_right]:
		side.get_node(thrust_particles_name).emitting = false
		side.get_node(thrust_over_particles_name).emitting = false
		side.get_node(smoke_particles_name).emitting = false
#		side_left.hide()
#		side_right.hide()
	current_side_node.show()


func _process(delta: float) -> void:
	
	if owner_node:
		update_trail()
	pass
	
# particles
	
func start_fx(reverse_direction: bool = false):
	
	if not thrust_active:
		thrust_active = true
		current_side_node.get_node(thrust_particles_name).emitting = true
		current_side_node.get_node(thrust_over_particles_name).emitting = true
		current_side_node.get_node(smoke_particles_name).emitting = true
#		if reverse_direction:
#			smoke_particles.get_process_material().direction.x = 1
#			thrust_particles.get_process_material().direction.x = 1
#		else:
#			smoke_particles.get_process_material().direction.x = -1
#			thrust_particles.get_process_material().direction.x = -1


func stop_fx():
	
	if thrust_active:
		thrust_active = false
		current_side_node.get_node(thrust_particles_name).emitting = false
		current_side_node.get_node(thrust_over_particles_name).emitting = false
		current_side_node.get_node(smoke_particles_name).emitting = false
		

# trail	
	
func spawn_new_trail():
	
	var BoltTrail: PackedScene = preload("res://game/bolt/fx/ThrustTrail.tscn")
	var new_trail: Line2D = BoltTrail.instance()
	# na poziciji partiklov na trenutno izbrani strani
	new_trail.global_position = current_side_node.get_node(thrust_particles_name).global_position
	new_trail.modulate.a = bolt_trail_alpha
	new_trail.width = 5
	Ref.node_creation_parent.add_child(new_trail)
	
	# signal za deaktivacijo, če ni bila že prej
	new_trail.connect("trail_is_exiting", self, "_on_trail_exiting")
	
	return new_trail		
	
	
func update_trail():
	
	# spawn trail if not active
	if not active_trail and owner_node.bolt_velocity.length() > pseudo_stop_speed: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and owner_node.bolt_velocity.length() > pseudo_stop_speed:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if owner_node.bolt_velocity.length() > pseudo_stop_speed and active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	elif active_trail and owner_node.bolt_velocity.length() <= pseudo_stop_speed:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func _on_trail_exiting(exiting_trail: Line2D):
	
	if exiting_trail == active_trail:
		active_trail = null
