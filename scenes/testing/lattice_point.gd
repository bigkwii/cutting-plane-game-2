# one of the points from the lattice integer grid
extends Node2D

# pos relative to game units, not actual pixels
@export var pos: Vector2 = Vector2(0, 0)
@export var radius: float = 3
@export var color: Color = Color(1, 1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _draw():
	# little white circle
	draw_circle(pos, radius, color)

