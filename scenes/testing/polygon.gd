extends Node2D
## A polygon. Made out of PolyPoint nodes.

# -- vars --
## Scaling factor for the lattice points. To convert from lattice coordinates to screen coordinates. (Default value chosen to match demo)
@export var SCALING: int = 142
## Offset from the game origin to the grid origin. (Default value chosen to match demo)
@export var OFFSET: Vector2 = Vector2(16, 28)
# TODO: please just make them global variables

## The color of the polygon. Borders are solid, fill is semi-transparent.
@export var color: Color = Color(1, 0, 0)

## The verices that make up the polygon[br][br]
## Make sure to use Lattice coordinates and to follow a CCW winding order.
## [br][br] TODO: THIS VARIABLE NAME IS CONFUSING!!!
@export var vertices: Array[Vector2] = []

# -- child nodes --
@onready var VERTS = $verts

# -- preloaded scenes --
var POLY_POINT_SCENE = preload("res://scenes/testing/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if vertices.size() < 3:
		DEBUG.log("polygon._ready: Polygon must have at least 3 vertices! %s given." % vertices.size())
		return
	_make_polygon()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	if vertices.size() < 3:
		DEBUG.log("polygon._draw: Polygon must have at least 3 vertices! %s given." % vertices.size())
		return
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []
	for vert in VERTS.get_children():
		points.append( vert.position ) # actual position
		colors.append( Color(color, 0.2) ) # semi-transparent fill
	draw_polygon(points, colors)

	points.append(points[0]) # complete round trip
	draw_polyline(points, Color(color, 1), 2) # solid border

## Instantiates a PolyPoint node for a given lattice position.
func _add_new_vertex(lattice_pos: Vector2):
	var new_vert = POLY_POINT_SCENE.instantiate()
	new_vert.lattice_position = lattice_pos
	new_vert.position = lattice_pos * SCALING + OFFSET
	new_vert.color = color
	VERTS.add_child(new_vert)

## Instantiates all PolyPoint nodes for the given vertices.
func _make_polygon():
	DEBUG.log("making polygon with vertices: " + str(vertices))
	for vert in vertices:
		_add_new_vertex(vert)

## deletes itself and all children
func delete_polygon():
	queue_free()

## checks if the polygon is integral. (if all vertices are integers)
func is_integral() -> bool:
	for vert in VERTS.get_children():
		if not vert.is_integral():
			return false
	return true