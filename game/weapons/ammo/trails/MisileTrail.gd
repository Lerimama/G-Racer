extends Line2D
# wild trail

export var max_points: int = 50 # kontroliram max dolžino sledi

var in_decay: bool = false
var min_spawn_distance: float = 1

var point_age: Array = [0.0] # v ta array gre za vsako piko nova starost
var chaos_level: float = 0.2
var chaos_speed: float = 1

# tick je dodan za bolj fino kontrolo na obnašanjem linije
var tick: = 0.0 # lastnosti ne dodamo vsaki piki ... kako pogosto je določeno s tikom
var tick_lenght: float = 0.02 # za nadzor hitrosti dodajanja lastnosti na pike ... manjša razdalja med tiki pomeni bolj izrazite lastnosti krivulje

# decay
var lifetime: Array = [2.0, 3.0] # vsaka linija bo imela lajfatjm v tem razponu
var max_width: Array = [130,100]
onready var decay_tween = $DecayTween


func _ready() -> void:

	clear_points()
	randomize()


func _process(delta: float) -> void:

	if tick > tick_lenght:
		tick = 0

		for p in range (get_point_count()):
			point_age[p] += 5 * delta # vsaka pika se stara z delto
			var rand_vector = Vector2(rand_range(-chaos_speed, chaos_speed), rand_range(-chaos_speed, chaos_speed)) # dodam random vektor, ki povzroča kaos
			points[p] += rand_vector * chaos_level * point_age[p] # veča se s frejmi

	else: # če ni večji od prepisane velikosti, ga povečaj
		tick += delta


func start_decay():

	if not in_decay:
		in_decay = true
		var random_lifetime: float = rand_range(lifetime[0], lifetime[1])
		decay_tween.interpolate_property(self ,"modulate", null, Color("#00171a23"), lifetime[0], Tween.TRANS_EXPO, Tween.EASE_OUT )
		decay_tween.interpolate_property(self ,"width", null, rand_range(max_width[0], max_width[1]), random_lifetime, Tween.TRANS_EXPO, Tween.EASE_IN )
		decay_tween.start()


func add_points(current_misile_position, at_pos: =  -1): # same arguments kot v originalni add_point funkciji

	# minimalni razmak med pikami
	# če je razdalja med trenutno piko in eno piko nazaj (-1) manjša od minimalne željene ...
	if get_point_count() > 0 and current_misile_position.distance_to(points[get_point_count() - 1]) < min_spawn_distance:
		return

	# maksimalno število pik
	if get_point_count() > max_points:
		remove_point(0) # odstranimo pravo (tisto, ki je najbolj stara)
		point_age.pop_front() # potem premaknem starosti pik ... ne štekam najbolje
		return

	point_age.append(0.0) # if we add a point we also append a new 0.0 point age array
	add_point(current_misile_position, at_pos)


func _on_Decay_tween_all_completed() -> void:

	queue_free()
