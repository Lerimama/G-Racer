extends Resource

export (float, 0, 10) var add_trauma: float = 0.5
export var trauma_time: float = 0.1 # decay delay
export(float, 0, 1) var decay_factor: float = 0.5
export var max_horizontal: float = 150
export var max_vertical: float = 150
export var max_rotation: float = 25
export (float, 0, 300, 0.5)var time_scale: float = 150
export var max_trauma: float = 1
