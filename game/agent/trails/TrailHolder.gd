extends Position2D


var agent_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var active_trail: Line2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func spawn_new_trail():

	var AgentTrail: PackedScene = preload("res://game/agent/trails/AgentTrail.tscn")
	var new_agent_trail: Line2D = AgentTrail.instance()
	new_agent_trail.modulate.a = agent_trail_alpha
	new_agent_trail.z_index = z_index
	new_agent_trail.width = 20
	Rfs.node_creation_parent.add_child(new_agent_trail)

	# signal za deaktivacijo, če ni bila že prej
	new_agent_trail.connect("trail_exiting", self, "_on_trail_exiting")

	return new_agent_trail


func decay():
	if active_trail and not active_trail.in_decay:
		active_trail.start_decay() # trail decay tween start


func update_trail(moving_speed: float = 0, stop_speed_threshold: float = 0.5):

	# spawn trail if not active
	if not active_trail and moving_speed > stop_speed_threshold: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and moving_speed > stop_speed_threshold:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if moving_speed > stop_speed_threshold and active_trail.modulate.a < agent_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", agent_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova
	elif active_trail and moving_speed <= stop_speed_threshold:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func _on_trail_exiting(exiting_trail: Line2D):

	if exiting_trail == active_trail:
		active_trail = null
