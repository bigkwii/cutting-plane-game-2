extends Node2D
## A vertex of a polygon

## Position of the poly point relative to the grid (NOT ACTUAL SCREEN / GAME POSITION)
@export var lattice_position = Vector2(0, 0)
## Radius of the poly point to be drawn
@export var radius: float = 3
## Color of the poly point
@export var color = Color(1, 0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# draw the vertex as a little red circle
func _draw():
	draw_circle(Vector2.ZERO, radius, color)

## deletes itself
func delete_poly_point():
	queue_free()

## checks if the poly point is integral (i.e. lattice position is an integer)
## [br][br]
## TODO: WATCH OUT FOR FLOATING POINT ERRORS! MAKE SURE THE CUTTING PROCESS HAS SOME TOLERANCE AND CAN CORRECT SUCH IMPRECISIONS
func is_integral() -> bool:
	return lattice_position.x == int(lattice_position.x) and lattice_position.y == int(lattice_position.y)
