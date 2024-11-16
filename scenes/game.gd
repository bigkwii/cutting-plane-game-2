extends Node2D
## main game scene. handles gamemode selection and level loading

# - preloaded scenes - 
var TEST_MENU_SCENE = preload("res://scenes/testing/test_menu.tscn")
var TUTORIAL_SCENE = preload("res://scenes/tutorial.tscn")
var ARCADE_SCENE = preload("res://scenes/arcade.tscn")
var FREE_PLAY_SCENE = preload("res://scenes/free_play.tscn")
var EDITOR_SCENE = preload("res://scenes/editor.tscn")
# var SPEEDRUN_SCENE = preload("res://scenes/speedrun.tscn")

var CLICK_VFX = preload("res://scenes/click_vfx.tscn")

# - child nodes -
@onready var SELECTED_GAMEMODE = $selected_gamemode
@onready var CLICK_VFXS = $vfx/click_vfxs

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_play_click_vfx(get_global_mouse_position())

# - vfx -
func _play_click_vfx(pos: Vector2):
	var click_vfx = CLICK_VFX.instantiate()
	CLICK_VFXS.add_child(click_vfx)
	click_vfx.position = pos
	click_vfx.play_click()

# - signal callbacks -

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


