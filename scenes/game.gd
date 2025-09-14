extends Node2D
## main game scene. handles gamemode selection and level loading

# - preloaded scenes - 
var TEST_MENU_SCENE = preload("res://scenes/testing/test_menu.tscn")
var TUTORIAL_SCENE = preload("res://scenes/tutorial.tscn")
var ARCADE_SCENE = preload("res://scenes/arcade.tscn")
var FREE_PLAY_SCENE = preload("res://scenes/free_play.tscn")
var EDITOR_SCENE = preload("res://scenes/editor.tscn")
var SPEEDRUN_SCENE = preload("res://scenes/speedrun.tscn")

var CLICK_VFX = preload("res://scenes/click_vfx.tscn")

# - child nodes -
@onready var SELECTED_GAMEMODE = $selected_gamemode
@onready var CLICK_VFXS = $vfx/click_vfxs

# - vars -
const MAX_CLICK_VFXS = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	# if OS.get_name() in ["Android", "iOS", "Web"]: # hidden by default on mobile and web
	# 	CRT.visible = false
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed: # play on press
			_play_click_vfx(get_global_mouse_position(), true)
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: # play on release
			_play_click_vfx(get_global_mouse_position())

# - fps check -
func _on_fps_timer_timeout():
	var avg_fps := Engine.get_frames_per_second()
	if avg_fps < 30 and CRT.visible:
		DEBUG.log("FPS too low (%s). CRT Shader OFF." % [avg_fps])
		CRT.visible = false
	else:
		DEBUG.log("FPS good enough (%s). CRT Shader ON." % [avg_fps])

# - vfx -
func _play_click_vfx(pos: Vector2, backwards: bool = false):
	if CLICK_VFXS.get_child_count() > MAX_CLICK_VFXS:
		return
	var click_vfx = CLICK_VFX.instantiate()
	CLICK_VFXS.add_child(click_vfx)
	click_vfx.position = pos
	click_vfx.play_click(backwards)

# - signal callbacks -

# - free play -

func _on_test_menu_start_free_play(level_path: String):
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var FREE_PLAY = FREE_PLAY_SCENE.instantiate()
	FREE_PLAY.level_json_path = level_path
	SELECTED_GAMEMODE.add_child(FREE_PLAY)
	FREE_PLAY.quit_gamemode.connect(_on_free_play_quit_gamemode)

func _on_free_play_quit_gamemode():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TEST_MENU = TEST_MENU_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TEST_MENU)
	TEST_MENU.start_free_play.connect(_on_test_menu_start_free_play)
	TEST_MENU.start_arcade.connect(_on_test_menu_start_arcade)
	TEST_MENU.start_tutorial.connect(_on_test_menu_start_tutorial)
	TEST_MENU.start_editor.connect(_on_test_menu_start_editor)
	TEST_MENU.start_speedrun.connect(_on_test_menu_start_speedrun)

# - arcade -

func _on_test_menu_start_arcade():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var ARCADE = ARCADE_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(ARCADE)
	ARCADE.quit_gamemode.connect(_on_arcade_quit_gamemode)

func _on_arcade_quit_gamemode():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TEST_MENU = TEST_MENU_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TEST_MENU)
	TEST_MENU.start_free_play.connect(_on_test_menu_start_free_play)
	TEST_MENU.start_arcade.connect(_on_test_menu_start_arcade)
	TEST_MENU.start_tutorial.connect(_on_test_menu_start_tutorial)
	TEST_MENU.start_editor.connect(_on_test_menu_start_editor)
	TEST_MENU.start_speedrun.connect(_on_test_menu_start_speedrun)

# - tutorial -

func _on_test_menu_start_tutorial():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TUTORIAL = TUTORIAL_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TUTORIAL)
	TUTORIAL.quit_gamemode.connect(_on_tutorial_quit_gamemode)

func _on_tutorial_quit_gamemode():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TEST_MENU = TEST_MENU_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TEST_MENU)
	TEST_MENU.start_free_play.connect(_on_test_menu_start_free_play)
	TEST_MENU.start_arcade.connect(_on_test_menu_start_arcade)
	TEST_MENU.start_tutorial.connect(_on_test_menu_start_tutorial)
	TEST_MENU.start_editor.connect(_on_test_menu_start_editor)
	TEST_MENU.start_speedrun.connect(_on_test_menu_start_speedrun)

# - editor -

func _on_test_menu_start_editor():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var EDITOR = EDITOR_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(EDITOR)
	EDITOR.quit_gamemode.connect(_on_editor_quit_gamemode)

func _on_editor_quit_gamemode():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TEST_MENU = TEST_MENU_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TEST_MENU)
	TEST_MENU.start_free_play.connect(_on_test_menu_start_free_play)
	TEST_MENU.start_arcade.connect(_on_test_menu_start_arcade)
	TEST_MENU.start_tutorial.connect(_on_test_menu_start_tutorial)
	TEST_MENU.start_editor.connect(_on_test_menu_start_editor)
	TEST_MENU.start_speedrun.connect(_on_test_menu_start_speedrun)

# - speedrun -

func _on_test_menu_start_speedrun():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var SPEEDRUN = SPEEDRUN_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(SPEEDRUN)
	SPEEDRUN.quit_gamemode.connect(_on_speedrun_quit_gamemode)

func _on_speedrun_quit_gamemode():
	SELECTED_GAMEMODE.get_child(0).queue_free()
	var TEST_MENU = TEST_MENU_SCENE.instantiate()
	SELECTED_GAMEMODE.add_child(TEST_MENU)
	TEST_MENU.start_free_play.connect(_on_test_menu_start_free_play)
	TEST_MENU.start_arcade.connect(_on_test_menu_start_arcade)
	TEST_MENU.start_tutorial.connect(_on_test_menu_start_tutorial)
	TEST_MENU.start_editor.connect(_on_test_menu_start_editor)
	TEST_MENU.start_speedrun.connect(_on_test_menu_start_speedrun)
