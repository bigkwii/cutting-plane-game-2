extends Node2D
## Represents a lattice point (that is, an intiger point) on the grid

## Position of the lattice point relative to the grid (NOT ACTUAL SCREEN / GAME POSITION)
@export var lattice_position: Vector2 = Vector2(0, 0)
## Radius of the lattice point to be drawn
@export var radius: float = 3
## Color of the lattice point
@export var color: Color = Color(1, 1, 1, .9)

# Called when the node enters the scene tree for the first time.
func _ready():
	z_index = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _draw() -> void:
	# little white circle on top of itself
	draw_circle(Vector2.ZERO, radius, color, true)

## Changes the color of the lattice point
func change_color(new_color: Color) -> void:
	color = new_color
	queue_redraw()
