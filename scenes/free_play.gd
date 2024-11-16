extends Node2D
## scene for free play mode

# - signals -
signal quit_gamemode

# - vars -
## loaded level path
@export_file("*.json") var level_json_path = ""

# - child nodes -
@onready var MENU = $CanvasLayer/MENU
@onready var LEVEL_SELECTOR = $CanvasLayer/LEVEL_SELECTOR
@onready var LEVEL = null # assigned dynamically

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.level_json_path = level_json_path
	LEVEL.INFINITE_BUDGET = true
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _input(event):
	# reload scene if reset input is pressed
	if event.is_action_pressed("reset"):
		DEBUG.log("Reloading level...")
		reload_level()

func reload_level():
	LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.level_json_path = level_json_path
	LEVEL.INFINITE_BUDGET = true
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)

func _on_level_open_menu():
	get_tree().paused = true
	MENU.visible = true

func _on_x_pressed():
	get_tree().paused = false
	MENU.visible = false

func _on_exit_pressed():
	get_tree().paused = false
	quit_gamemode.emit()
	queue_free()

func _on_reload_pressed():
	get_tree().paused = false
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_selector_pressed():
	LEVEL_SELECTOR.visible = true

func _on_selector_x_btn_pressed():
	LEVEL_SELECTOR.visible = false

func _on_lvl_1_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/1.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_2_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/2.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_3_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/3.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_4_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/4.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_5_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/5.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_6_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/6.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_7_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/7.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_8_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/8.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false

func _on_lvl_9_btn_pressed():
	get_tree().paused = false
	level_json_path = "res://levels/demo/9.json"
	reload_level()
	MENU.visible = false
	LEVEL_SELECTOR.visible = false