extends Resource


enum DAMAGE_TYPE {EXPLODE, CUT, HIT, TRAVEL} # enako kot breaker
export (DAMAGE_TYPE) var damage_type = DAMAGE_TYPE.EXPLODE

export var height: float = 0
export var elevation: float = 0 # elevation se doda elevationu objektu spawnanja
export var masa: float = 1 # fejk, ker je konematic, on_hit pa preverja .mass
export var lifetime: float = 1 # 0 = večno
export var hit_damage: float = 0.1
export var hit_inertia: float = 100 # fejk, ker je konematic, on_hit pa preverja .mass
export var start_thrust_power: float = 10
export var max_thrust_power: float = 100
export var direction_start_range: Vector2 = Vector2.ZERO

export var trail: PackedScene
export (Array, PackedScene) var shoot_fx: Array
export (Array, PackedScene) var hit_fx: Array
export (Array, PackedScene) var dissarm_fx: Array

export var homming_mode: bool = false # sledilka mode (ko zagleda tarčo v dometu)
export var use_vision: bool = false
