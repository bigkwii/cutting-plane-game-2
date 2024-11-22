extends Node2D
## handles the tutorial mode logic and animations

# - signals -
signal quit_gamemode

# - vars -
var level_dicts = [
	{
		"name" : "Tutorial 1/7",
		"max_y": 4,
		"poly_color": "#ff0000",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[2.5, 0.3],
			[3.7, 1.5],
			[2.5, 2.7],
			[1.3, 1.5]
		]
	},
	{},
	{},
	{},
	{},
	{},
	{}
]

## keeps track of the current level index
var current_level_idx: int = 0
## keep track of how many cuts have been made on this level
var cuts_made_on_current_level: int = 0

# - child nodes -
@onready var ANIM_PLAYER = $AnimationPlayer
@onready var LEVEL = null # assigned dynamically
@onready var MENU = $CanvasLayer/HUD/MENU

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(level_dicts[current_level_idx])

func load_level(level_data: Dictionary):
	if LEVEL != null:
		LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.LOAD_FROM_FILE = false
	LEVEL.level_data = level_data
	LEVEL.INFINITE_BUDGET = true
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)
	LEVEL.level_completed.connect(_on_level_completed)
	LEVEL.cut_made.connect(_on_cut_made)
	get_tree().paused = false
	_setup_initial_conditions()

## function to setup the initial conditions for each tutorial level. call after loading a new level
func _setup_initial_conditions():
	match current_level_idx:
		0: # circle cut
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_circle_pressed()
		1: # split pt 1
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL._on_h_split_pressed()
		2: # split pt 2
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_v_split_pressed()
		3: # split and circle
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL._on_h_split_pressed()
		4: # gomory cut pt 1
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()
		5: # gomory cut pt 2
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()
		6: # gomory pt 3
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()

## helper function to disable level click input. to be called on anim player
func disable_level_input():
	LEVEL.can_click = false

## helper function to enable level click input. to be called on anim player
func enable_level_input():
	LEVEL.can_click = true

# - signal callbacks -

func _on_cut_made(_score: int):
	cuts_made_on_current_level += 1
	
func _on_level_completed(_rank: String, _rank_bonus: int, _budget_bonus: int, _remaining_circle: int, _remaining_gomory: int, _remaining_split: int):
	current_level_idx += 1
	cuts_made_on_current_level = 0

# - menu stuff -
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
