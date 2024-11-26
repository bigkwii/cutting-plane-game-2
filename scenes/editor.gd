extends Node2D
## editor game mode scene.

# - signals -
signal quit_gamemode

# - vars -
## selected_max_y
@export var max_y: int = 6:
	set(value):
		max_y = clamp(value, 4, 10)
## save verts of level editor in case the player wants to come back
var saved_verts: Array[Vector2] = []

# - child nodes -
@onready var MENU = $CanvasLayer/MENU
@onready var LEVEL_EDITOR = null # assigned dynamically
@onready var LEVEL = null # assigned dynamically

# - preloaded scenes -
var LEVEL_EDITOR_SCENE = preload("res://scenes/level_editor.tscn")
var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level_editor()

func load_level_editor(initial_verts: Array[Vector2] = []) -> void:
	if LEVEL != null:
		LEVEL.queue_free()
	if LEVEL_EDITOR != null:
		LEVEL_EDITOR.queue_free()
	LEVEL_EDITOR = LEVEL_EDITOR_SCENE.instantiate()
	LEVEL_EDITOR.max_y = max_y
	if initial_verts != []:
		LEVEL_EDITOR.initial_verts = initial_verts
	add_child(LEVEL_EDITOR)
	LEVEL_EDITOR.open_menu.connect(_on_level_editor_open_menu)
	LEVEL_EDITOR.play_level.connect(_on_level_editor_play_level)

func load_level(level_data: Dictionary) -> void:
	if LEVEL != null:
		LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.LOAD_FROM_FILE = false
	LEVEL.level_data = level_data
	LEVEL.INFINITE_BUDGET = true
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)
	get_tree().paused = false

# - signal callbacks -

func _on_level_editor_play_level(level_data: Dictionary):
	# save the verts of the level editor for later
	saved_verts = []
	for vert in LEVEL_EDITOR.VERTS.get_children():
		saved_verts.append(vert.lattice_position)
	load_level(level_data)

func _on_level_editor_open_menu():
	get_tree().paused = true
	MENU.visible = true

func _on_level_open_menu():
	get_tree().paused = true
	MENU.visible = true