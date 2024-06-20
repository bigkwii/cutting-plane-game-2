extends Node2D

# a vertex represents a point in 2D space, and will be used to define a polygon

# -- vars --
@export var pos = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# draw the vertex as a little red circle
func _draw():
	draw_circle(pos, 5, Color(1, 0, 0))