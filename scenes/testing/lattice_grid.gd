# the lattice grid of integer points.

extends Node2D

# -- vars --
# dimensions of the grid
@export var dimensions: Vector2 = Vector2(8, 6)
# scaling factor for the lattice points
@export var scaling: int = 32
# offset for the lattice points from the origin
@export var offset: Vector2 = Vector2(16, 16)

# -- preloaded scenes --
@onready var lattice_point_scene = preload("res://scenes/testing/lattice_point.tscn")

# -- nodes --
@onready var lattice_points = $lattice_points

# Called when the node enters the scene tree for the first time.
func _ready():
	_make_lattice_grid()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_update_lattice_grid()

func _add_new_lattice_point(pos: Vector2):
	var new_lattice_point = lattice_point_scene.instantiate()
	new_lattice_point.pos = pos
	new_lattice_point.position = pos * scaling + offset # scaling and padding
	lattice_points.add_child(new_lattice_point)

func _make_lattice_grid():
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			_add_new_lattice_point(Vector2(x, y))

func _update_lattice_grid():
	for lattice_point in lattice_points.get_children():
		lattice_point.queue_free()
	_make_lattice_grid()
