extends Node2D
## A polygon. Made out of PolyPoint nodes.

# -- vars --
## The color of the polygon. Borders are solid, fill is semi-transparent.
@export var color: Color = Color(1, 0, 0)

# -- child nodes --
@onready var verts = $verts

# -- preloaded scenes --
var _poly_point_scene = preload("res://scenes/testing/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# test vertices
	for i in range(3):
		var v = _poly_point_scene.instantiate()
		v.pos = Vector2(100 * i, 100 * i)
		verts.add_child(v)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# function to instanciate a new vertex
func _add_new_vertex(pos: Vector2):
	var v = _poly_point_scene.instantiate()
	v.pos = pos
	verts.add_child(v)

# function to remove a vertex
func _remove_vertex(v: Node):
	verts.remove_child(v)
	v.queue_free()