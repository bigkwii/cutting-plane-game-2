extends Node2D
## The grid of lattice (integer) points. They define the coordinates of the in-game polygons and points.
## [br][br]
## [color=yellow]NOTE: THESE COORDINATES DO NOT CORRESPOND TO THE PIXELS ON THE SCREEN.[/color]

# -- vars --
## Dimensions of the grid. How many rows and columns of lattice points.
@export var DIMENTIONS: Vector2 = Vector2(8, 6)
## Scaling factor for the lattice points. To convert from lattice coordinates to screen coordinates. (Default value chosen to match demo)
@export var SCALING: int = 142
## Offset from the game origin to the grid origin. (Default value chosen to match demo)
@export var OFFSET: Vector2 = Vector2(16, 28)
# TODO: MAYBE MAKE THESE VARIABLES GLOBAL? AN AUTOLOAD SCRIPT WITH THE VARS AND FUNCTIONS TO CONVERT BETWEEN LATTICE AND SCREEN COORDINATES?

# -- preloaded scenes --
@onready var LATTICE_POINT_SCENE = preload("res://scenes/testing/lattice_point.tscn")

# -- nodes --
@onready var LATTICE_POINTS = $lattice_points

# Called when the node enters the scene tree for the first time.
func _ready():
	_make_lattice_grid()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Adds a new lattice point at a given position (relative to grid origin)
func _add_new_lattice_point(lattice_pos: Vector2) -> void:
	var new_lattice_point = LATTICE_POINT_SCENE.instantiate()
	new_lattice_point.lattice_position = lattice_pos # save the position ralative to the grid origin
	new_lattice_point.position = lattice_pos * SCALING + OFFSET # scaling and offset from the game origin
	LATTICE_POINTS.add_child(new_lattice_point)

## Makes the grid
func _make_lattice_grid() -> void:
	for x in range(DIMENTIONS.x):
		for y in range(DIMENTIONS.y):
			_add_new_lattice_point(Vector2(x, y))
	DEBUG.log("Lattice grid created:\nDIMENTIONS: %s\nSCALING: %s\nOFFSET: %s"
			  % [DIMENTIONS, SCALING, OFFSET])

