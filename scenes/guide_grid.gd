extends Node2D
## guide grid that aids with precision when cutting

# -- vars --
## dimensions of the grid
@export var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## scaling factor for the grid
@export var SCALING: Vector2 = GLOBALS.DEFAULT_SCALING
## offset from the game origin to the grid origin
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## transparency of the grid
@export var alpha: float = 0.5

func _draw():
	## draw a grid of lines
	for x in range(DIMENSIONS.x * 2 - 1):
		draw_line(Vector2(x * SCALING.x * 0.5, 0) + OFFSET, Vector2(x * SCALING.x * 0.5, (DIMENSIONS.y - 1) * SCALING.y) + OFFSET, Color(1, 1, 1, alpha), 0.25, true)
	for y in range(DIMENSIONS.y * 2 - 1):
		draw_line(Vector2(0, y * SCALING.y * 0.5) + OFFSET, Vector2( (DIMENSIONS.x - 1) * SCALING.x, y * SCALING.y * 0.5) + OFFSET, Color(1, 1, 1, alpha), 0.25, true)

## called when the alpha value is changed
func update_alpha(new_alpha: float):
	alpha = new_alpha
	queue_redraw()
