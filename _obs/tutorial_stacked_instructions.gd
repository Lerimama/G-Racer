extends Control


enum TutorialStage {MISSION = 1, TRAVELING, BURSTING, SKILLING, STACKING, WINLOSE}
var current_tutorial_stage: int

var tutorial_finished: bool = false

# za beleženje vmesnih rezultatov
var traveling_directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var all_skills: Array = ["push", "pull", "teleport"]
var xtra_separation: HSeparator # dodatek za razmak pod odprtim tutorial tekstom

# min heights
var xtra_separation_height: int = 14
var stage_height_traveling: int = 234
var stage_height_bursting: int = 394
var stage_height_skilling: int = 394
var stage_height_stacking: int = 346
var stage_height_winlose: int = 300

onready var animation_player: AnimationPlayer = $AnimationPlayer
# xtra separation
onready var travel_sepa: HSeparator = $Checkpoints/TravelSepa
onready var bursting_sepa: HSeparator = $Checkpoints/BurstingSepa
onready var skilling_sepa: HSeparator = $Checkpoints/SkillingSepa
onready var stacking_sepa: HSeparator = $Checkpoints/StackingSepa
onready var win_lose_sepa: HSeparator = $Checkpoints/WinLoseSepa # ne rabim, ampak more zaradi standardizirane metode
# stages
onready var mission_panel: Control = $MissionPanel
onready var hud_guide: Control = $HudGuide
onready var traveling_content: Control = $Checkpoints/TravelingContent
onready var bursting_content: Control = $Checkpoints/BurstingContent
onready var skilling_content: Control = $Checkpoints/SkillingContent
onready var stacking_content: Control = $Checkpoints/StackingContent
onready var winlose_content: Control = $Checkpoints/WinLoseContent
# labels
onready var traveling_label: Label = $Checkpoints/Traveling
onready var bursting_label: Label = $Checkpoints/Bursting
onready var skilling_label: Label = $Checkpoints/Skilling
onready var stacking_label: Label = $Checkpoints/Stacking
onready var winlose_label: Label = $Checkpoints/WinLose


func _input(event: InputEvent) -> void:
	
	if current_tutorial_stage == TutorialStage.MISSION: # namesto menija
		if Input.is_action_just_pressed("ui_accept"):
			Global.sound_manager.play_gui_sfx("btn_confirm")
			animation_player.play("tutorial_start")
			current_tutorial_stage = 0 # anti dablklik
			Global.sound_manager.play_music("game_music")
			Global.sound_manager.skip_track() # skipa prvi komad in zapleja drugega
			
	elif current_tutorial_stage == TutorialStage.TRAVELING:
		if Input.is_action_pressed("ui_up"):
			traveling_directions.erase(Vector2.UP)
		elif Input.is_action_pressed("ui_down"):
			traveling_directions.erase(Vector2.DOWN)
		elif Input.is_action_pressed("ui_left"):
			traveling_directions.erase(Vector2.LEFT)
		elif Input.is_action_pressed("ui_right"):
			traveling_directions.erase(Vector2.RIGHT)
		
		if traveling_directions.empty():
			finish_traveling()	
			
	
func _ready() -> void:
	
	Global.tutorial_gui = self # za statse iz GMja
	visible = false
	
	mission_panel.visible = true
	hud_guide.visible = true
	hud_guide.modulate.a = 0
		
	traveling_content.visible = true
	traveling_content.rect_min_size.y = 0
	travel_sepa.visible = false
	
	bursting_content.visible = true
	bursting_content.rect_min_size.y = 0
	bursting_sepa.visible = false
	
	skilling_content.visible = true
	skilling_content.rect_min_size.y = 0
	skilling_sepa.visible = false
	
	stacking_content.visible = true
	stacking_content.rect_min_size.y = 0
	stacking_sepa.visible = false
	
	winlose_content.visible = true
	winlose_content.rect_min_size.y = 0
	win_lose_sepa.visible = false


func _process(delta: float) -> void:
	
	if Global.game_manager.strays_in_game_count == 0 and not tutorial_finished:
		if current_tutorial_stage > 3 and current_tutorial_stage < 6: # spucano v skilling or stacking 
			tutorial_finished = true
			Global.game_manager.game_over(Global.game_manager.GameoverReason.CLEANED)
		elif current_tutorial_stage == 6: # spucano v winlose
			tutorial_finished = true
			finish_tutorial()


func open_tutorial(): # kliče se z GM
	
	visible = true
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	animation_player.play("mission_in")
	
	
func start_tutorial():

	current_tutorial_stage = TutorialStage.TRAVELING
	
	Global.hud.game_timer.start_timer()
	Global.game_manager.game_on = true
	
	get_tree().call_group(Global.group_players, "set_physics_process", true)
	

# STAGES ------------------------------------------------------------------------------------------------------------------	


func finish_traveling():
	if not current_tutorial_stage == TutorialStage.TRAVELING:
		return	
	traveling_label.modulate = Global.color_green
	change_stage(traveling_content, bursting_content, stage_height_bursting, bursting_sepa, TutorialStage.BURSTING)
	
	yield(get_tree().create_timer(1), "timeout")
	Global.game_manager.set_strays()
	
	
func finish_bursting():
	if not current_tutorial_stage == TutorialStage.BURSTING:
		return
	bursting_label.modulate = Global.color_green
	change_stage(bursting_content, skilling_content, stage_height_skilling, skilling_sepa, TutorialStage.SKILLING)		


func finish_skilling():
	
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return
	skilling_label.modulate = Global.color_green
	change_stage(skilling_content, stacking_content, stage_height_stacking, stacking_sepa, TutorialStage.STACKING)		
	
	
func finish_stacking():
	
	if not current_tutorial_stage == TutorialStage.STACKING:
		return
	stacking_label.modulate = Global.color_green
	change_stage(stacking_content, winlose_content, stage_height_winlose, win_lose_sepa, TutorialStage.WINLOSE)		

	
func finish_tutorial():
	
	if not current_tutorial_stage == TutorialStage.WINLOSE:
		return
	winlose_label.modulate = Global.color_green
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	
	var close_final_stage = get_tree().create_tween()
	close_final_stage.tween_property(winlose_content, "rect_min_size:y", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	close_final_stage.tween_callback(Global.game_manager, "game_over", [Global.game_manager.GameoverReason.CLEANED])


# UTILITI ------------------------------------------------------------------------------------------------------------------	


func change_stage(stage_to_hide: Control, next_stage: Control, next_stage_height: int, separation_adon: Control, next_stage_enum: int):
	
	Global.sound_manager.play_gui_sfx("tutorial_stage_done")
	current_tutorial_stage = next_stage_enum
	
	var close_stage = get_tree().create_tween()
	close_stage.tween_property(stage_to_hide, "rect_min_size:y", 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(0.5)
	close_stage.parallel().tween_property(xtra_separation, "rect_min_size:y", 0, 0.5).set_delay(0.5)
	close_stage.parallel().tween_callback(xtra_separation, "hide").set_delay(1)
	close_stage.tween_callback(self, "open_stage", [next_stage, next_stage_height, separation_adon])
	

func open_stage(stage_to_show: Control, stage_height: int, next_separation_adon: Control):
	
	xtra_separation = next_separation_adon
	
	var open_stage = get_tree().create_tween()
	open_stage.tween_property(stage_to_show, "rect_min_size:y", stage_height, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	open_stage.parallel().tween_callback(xtra_separation, "show").set_delay(0.5)
	open_stage.parallel().tween_property(xtra_separation, "rect_min_size:y", xtra_separation_height, 0.3).set_delay(0.5)


func skill_done(skill: String):
	
	if not current_tutorial_stage == TutorialStage.SKILLING:
		return	
	
	all_skills.erase(skill)
	if all_skills.empty():
		finish_skilling()
		
		
# SIGNALS ------------------------------------------------------------------------------------------------------------------	

	
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"mission_in":
			current_tutorial_stage = TutorialStage.MISSION
		"tutorial_start":
			var show_player = get_tree().create_tween()
			show_player.tween_callback(self, "open_stage", [traveling_content, stage_height_traveling, travel_sepa]).set_delay(0.5)
			show_player.tween_callback(self, "start_tutorial").set_delay(1)
