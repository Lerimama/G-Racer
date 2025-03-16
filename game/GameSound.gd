extends SoundManager
# variable so tukaj
# funkcije so v SM

var game_manager: Game # poda GM na ready

# SFX
onready var big_horn: AudioStreamPlayer = $LevelSfx/BigHorn
onready var little_horn: AudioStreamPlayer = $LevelSfx/LittleHorn


# MUSKA
onready var track: AudioStreamPlayer = $Music/Track
onready var track_2: AudioStreamPlayer = $Music/Track_2
onready var track_3: AudioStreamPlayer = $Music/Track_3
onready var track_4: AudioStreamPlayer = $Music/Track_4
# nitro
onready var nitro: AudioStreamPlayer = $Music/Nitro
onready var nitro_menu: AudioStreamPlayer = $Music/NitroMenu
onready var nitro_win: AudioStreamPlayer = $Music/NitroWin
onready var nitro_lose: AudioStreamPlayer = $Music/NitroLose
onready var nitro_intro: AudioStreamPlayer = $Music/NitroIntro
onready var nitro_start: AudioStreamPlayer = $Music/NitroStart

# called vars
onready var game_music: AudioStreamPlayer = nitro
onready var intro_jingle: AudioStreamPlayer = nitro_start
onready var win_jingle: AudioStreamPlayer = nitro_win
onready var lose_jingle: AudioStreamPlayer = nitro_lose
onready var menu_music: AudioStreamPlayer = nitro_menu

onready var btn_focus: AudioStreamPlayer = $GuiSfx/Inputs/BtnFocus
onready var btn_accept: AudioStreamPlayer = $GuiSfx/Inputs/BtnConfirm
onready var btn_cancel: AudioStreamPlayer = $GuiSfx/Inputs/BtnCancel


func _ready() -> void:

	randomize()

	music_bus_index = AudioServer.get_bus_index("GameMusic")
	sfx_bus_index = AudioServer.get_bus_index("GameSfx")

	# če je bus na štartu setan na mute je mute
	music_set_to_mute = AudioServer.is_bus_mute(music_bus_index)
	sfx_set_to_mute = AudioServer.is_bus_mute(sfx_bus_index)

	if available_music_tracks.empty():
		available_music_tracks = [nitro, track, track_2]

	# temp, bolje je da iima btns svoje?
	Buts.btn_accept_sound = btn_accept
	Buts.btn_cancel_sound = btn_cancel
	Buts.btn_toggle_on_sound = btn_accept
	Buts.btn_toggle_off_sound = btn_cancel
	Buts.btn_focus_sound = btn_focus
