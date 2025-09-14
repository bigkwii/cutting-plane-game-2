#@tool

extends Node2D
## A vertex of a polygon

## Position of the poly point relative to the grid (NOT ACTUAL SCREEN / GAME POSITION)
@export var lattice_position: Vector2 = Vector2(0, 0)
## Radius of the poly point to be drawn
@export var radius: float = 3
## Color of the poly point
@export var color = Color(1, 0, 0)
## Clickable attribute
@export var clickable = false
## if hovering over with mouse
@export var hover: bool = false
## scaling
@export var SCALING: Vector2 = GLOBALS.DEFAULT_SCALING
## flag to show debug label
@export var debug_label_visible: bool = false
## editable attribute
@export var editable: bool = false

@onready var DEBUG_LABEL = $debug_label

## flag that determines if it's an integer point
var is_integer: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	DEBUG_LABEL.text = str(lattice_position)
	DEBUG_LABEL.visible = debug_label_visible
	if is_integral():
		clickable = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

# draw the vertex as a little red circle
func _draw():
	draw_circle(Vector2.ZERO, radius, color)
	if clickable:
		draw_circle(Vector2.ZERO, GLOBALS.GOMORY_CUT_CLICK_RANGE * SCALING.x, Color(1, 0, 0, 0.5), false, 1.5)
	if hover and not editable:
		draw_circle(Vector2.ZERO, radius, Color.RED, false, 2)
	if is_integral():
		draw_circle(Vector2.ZERO, radius, Color.GREEN, false, 2)
	if editable:
		draw_circle(Vector2.ZERO, GLOBALS.EDIT_CLICK_RANGE * SCALING.x, Color(0, 0, 1, 0.8), false, 1.5)
	if hover and editable:
		draw_circle(Vector2.ZERO, radius, Color.BLUE, false, 2)

## deletes itself
func delete_poly_point():
	queue_free()

## checks if the poly point is integral (i.e. lattice position is an integer)
## [br][br]
## Note: does NOT account for floating point imprecision. Make sure that's handled and corrected by the cutting functions.
func is_integral() -> bool:
	return lattice_position.x == int(lattice_position.x) and lattice_position.y == int(lattice_position.y)
