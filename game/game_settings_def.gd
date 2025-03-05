extends Resource


# PER LEVEL STYLE --------------------------------------------------------------------------------------------

export var health_effects_vehicle: bool = true
export (float, 0, 0.05, 0.005) var time_game_heal_rate_factor: float = 0.01 # 0, če nočeš vpliva, 1 je kot da ni damiđa da ma vehicle lahko med 0 in 1
export (float, 0, 0.05, 0.005) var points_game_heal_rate_factor: float = 0 # na ta način, ker lahko obstaja (kot nagrada?)

export var camera_zoom_range: Array = [1, 1.5]
export var start_countdown: bool = true
export var countdown_start_limit: int = 5
export var pickables_count_limit: int = 5
export var pull_gas_penalty: float = -20
export var drifting_mode: bool = true # drift ali tilt?
export var life_as_life_taken: bool = true
export var ranking_cash_rewards: Array = [5000, 3000, 1000]

# daytime params
export var game_shadows_rotation_deg: float = 45
export var game_shadows_color: Color = Color.black # odvisna od višine vira svetlobe
export var game_shadows_length_factor: float = 1 # odvisna od višine vira svetlobe
export var game_shadows_alpha: float = 0.4 # odvisna od moči svetlobe
export var game_shadows_direction: Vector2 = Vector2(800,0) # odvisna od moči svetlobe

