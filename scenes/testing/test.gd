extends Node2D

# -- vars --
var EPSILON = 0.01

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var POLYGON = $polygon

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _input(event):
	# reload scene if reset input is pressed
	if event.is_action_pressed("reset"):
		DEBUG.log("Reloading scene...")
		get_tree().reload_current_scene()
	# print click position
	if event.is_action_pressed("mouse1"):
		if event.pressed:
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - DEFAULTS.OFFSET) / DEFAULTS.SCALING , Vector2(EPSILON, EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
