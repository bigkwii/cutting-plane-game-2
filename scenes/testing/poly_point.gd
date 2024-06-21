extends Node2D
## A vertex of a polygon

## Position of the lattice point relative to the grid (NOT ACTUAL SCREEN / GAME POSITION)
@export var lattice_position = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# draw the vertex as a little red circle
func _draw():
	draw_circle(lattice_position, 5, Color(1, 0, 0))