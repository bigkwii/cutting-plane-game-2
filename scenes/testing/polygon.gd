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

## The starting vertices that make up the polygon[br][br]
## Make sure to use Lattice coordinates and to follow a CCW winding order.
@export var initial_vertices: Array[Vector2] = []

## packed version of the vertices array for easy geometry calculations
var packed_vertices: PackedVector2Array = []

## convex integer hull inside the polygon
var convex_integer_hull: PackedVector2Array = []

# -- child nodes --
@onready var VERTS = $verts

# -- preloaded scenes --
var POLY_POINT_SCENE = preload("res://scenes/testing/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if initial_vertices.size() < 3:
		DEBUG.log("polygon._ready: Polygon must have at least 3 vertices! %s given." % initial_vertices.size())
		return
	_make_polygon()
	if DEBUG.is_enabled():
		# draw centroid
		var centroid_coords = centroid()
		var centroid_node = POLY_POINT_SCENE.instantiate()
		centroid_node.lattice_position = centroid_coords
		centroid_node.position = centroid_coords * SCALING + OFFSET
		centroid_node.color = Color(0, 1, 0)
		centroid_node.name = "centroid"
		add_child(centroid_node)
	calculate_convex_integer_hull()
	DEBUG.log("convex integer hull: " + str(convex_integer_hull), 10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	if packed_vertices.size() < 3:
		DEBUG.log("polygon._draw: Polygon must have at least 3 vertices! %s given." % packed_vertices.size())
		return
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []
	for vert in VERTS.get_children():
		points.append( vert.position ) # actual position
		colors.append( Color(color, 0.2) ) # semi-transparent fill
	draw_polygon(points, colors)

	points.append(points[0]) # complete round trip
	draw_polyline(points, Color(color, 1), 2) # solid border

	# draw convex integer hull
	if convex_integer_hull.size() > 2:
		points = []
		for vert in convex_integer_hull:
			points.append( vert * SCALING + OFFSET ) # this is why we need to go from packed -> array -> packed
		draw_polyline(points, Color(0, 0, 1), 2) # solid border

## Instantiates a PolyPoint node for a given lattice position.
func _add_new_vertex(lattice_pos: Vector2):
	var new_vert = POLY_POINT_SCENE.instantiate()
	new_vert.lattice_position = lattice_pos
	new_vert.position = lattice_pos * SCALING + OFFSET
	new_vert.color = color
	VERTS.add_child(new_vert)

## Instantiates all PolyPoint nodes for the given vertices.
func _make_polygon() -> void:
	DEBUG.log("making polygon with vertices: " + str(initial_vertices))
	for vert in initial_vertices:
		_add_new_vertex(vert)
	packed_vertices = PackedVector2Array(initial_vertices)

## Deletes itself and all children
func delete_polygon() -> void:
	queue_free()

## Checks if the polygon is integral. (if all vertices are integers)
func is_integral() -> bool:
	for vert in VERTS.get_children():
		if not vert.is_integral():
			return false
	return true

## Calculates the centroid of the polygon.
func centroid() -> Vector2:
	var sum: Vector2 = Vector2(0, 0)
	for vert in VERTS.get_children():
		sum += vert.lattice_position
	return sum / VERTS.get_child_count()

## Gets all the integer lattice points inside the polygon.
func calculate_convex_integer_hull() -> void:
	var hull: PackedVector2Array = []
	# PackedVector2Array doesn't support reduce, sadly.
	var min_x: float = packed_vertices[0].x
	var max_x: float = packed_vertices[0].x
	var min_y: float = packed_vertices[0].y
	var max_y: float = packed_vertices[0].y
	for vert in packed_vertices:
		min_x = min(min_x, vert.x)
		max_x = max(max_x, vert.x)
		min_y = min(min_y, vert.y)
		max_y = max(max_y, vert.y)
	# find all lattice points inside the bounding box
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), packed_vertices): # we need to use the packed version for this
				hull.append(Vector2(x, y))
	# get the convex hull of the points
	hull = Geometry2D.convex_hull(hull)
	convex_integer_hull = PackedVector2Array(hull)
