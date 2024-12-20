extends Node2D
## The grid of lattice (integer) points. They define the coordinates of the in-game polygons and points.
## [br][br]
## [color=yellow]NOTE: THESE COORDINATES DO NOT CORRESPOND TO THE PIXELS ON THE SCREEN.[/color]

# -- vars --
## Dimensions of the grid. How many rows and columns of lattice points.
@export var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## Scaling factor for the lattice points. To convert from lattice coordinates to screen coordinates.
@export var SCALING: int = GLOBALS.DEFAULT_SCALING
## Offset from the game origin to the grid origin.
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET

# -- preloaded scenes --
@onready var LATTICE_POINT_SCENE = preload("res://scenes/lattice_point.tscn")

# -- nodes --
@onready var LATTICE_POINTS = $lattice_points

# Called when the node enters the scene tree for the first time.
func _ready():
	# make_lattice_grid() # gets handled by level scene now
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

## Adds a new lattice point at a given position (relative to grid origin)
func _add_new_lattice_point(lattice_pos: Vector2) -> void:
	var new_lattice_point = LATTICE_POINT_SCENE.instantiate()
	new_lattice_point.lattice_position = lattice_pos # save the position relative to the grid origin
	new_lattice_point.position = lattice_pos * SCALING + OFFSET # scaling and offset from the game origin
	LATTICE_POINTS.add_child(new_lattice_point)

## removes all lattice points
func _remove_all_lattice_points() -> void:
	for lattice_point in LATTICE_POINTS.get_children():
		lattice_point.queue_free()

## Makes the grid
func make_lattice_grid() -> void:
	if LATTICE_POINTS.get_child_count() > 0:
		_remove_all_lattice_points()
	for x in range(DIMENSIONS.x):
		for y in range(DIMENSIONS.y):
			_add_new_lattice_point(Vector2(x, y))
	DEBUG.log("Lattice grid created:\nDIMENSIONS: %s\nSCALING: %s\nOFFSET: %s"
			  % [DIMENSIONS, SCALING, OFFSET])
