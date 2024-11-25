extends Node2D
## stripped down version of a polygon to be used in the editor.

# -- vars --
## Scaling factor for the lattice points. To convert from lattice coordinates to screen coordinates.
@export var SCALING: int = GLOBALS.DEFAULT_SCALING
## Offset from the game origin to the grid origin.
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## The color of the polygon. Borders are solid, fill is semi-transparent.
@export var color: Color = Color(1, 0, 0)

## being edited flag
@export var being_edited: bool = true

## convex hull of the vertices. NOT TO BE CONFUSED WITH THE CONVEX INTEGER HULL. What will get drawn.
@export var convex_hull: PackedVector2Array = PackedVector2Array()

# - child nodes -
@onready var CONVEX_INTEGER_HULL = $convex_integer_hull

# - preloaded scenes -
@onready var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")

func _process(_delta):
	pass

func _draw():
	var alpha = 0.6 if being_edited else 1.0 # might deprecate this
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	for vert in convex_hull:
		points.append( vert * SCALING + OFFSET ) # this is why we need to go from packed -> array -> packed
		colors.append( Color(color, 0.2 * alpha) )
	if points.size() < 3:
		return
	draw_polygon(points, colors) # semi-transparent fill
	if convex_hull.size() > 0:
		points.append( convex_hull[0] * SCALING + OFFSET ) # close the loop
		draw_polyline(points, Color(color, alpha), 2) # solid border

## Determines if a given point is inside a given polygon, given its position.
func is_point_inside_polygon(lattice_position: Vector2, packed_vertices: PackedVector2Array) -> bool:
	# Geometry2D.is_point_in_polygon is BUGGED! LOL!
	return (lattice_position in packed_vertices) or Geometry2D.is_point_in_polygon(lattice_position, packed_vertices)

## Calculates the convex integer hull of the polygon and stores it in the CONVEX_INTEGER_HULL node for drawing.
func calculate_convex_integer_hull(packed_vertices: PackedVector2Array) -> void:
	if packed_vertices.size() < 1:
		return
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
			if is_point_inside_polygon(Vector2(x, y), packed_vertices):
				hull.append(Vector2(x, y))
	# get the convex hull of the points
	hull = Geometry2D.convex_hull(hull)
	if hull.size() < 1:
		return
	hull.remove_at(hull.size() - 1) # remove the last point, as it's the same as the first
	CONVEX_INTEGER_HULL.convex_integer_hull = PackedVector2Array(hull)
	CONVEX_INTEGER_HULL.SCALING = SCALING
	CONVEX_INTEGER_HULL.OFFSET = OFFSET

## Calculates the centroid of the convex integer hull of the polygon.
func calculate_hull_centroid() -> Vector2:
	if CONVEX_INTEGER_HULL.convex_integer_hull.size() < 1:
		CONVEX_INTEGER_HULL.CENTROID.visible = false
		return Vector2()
	CONVEX_INTEGER_HULL.CENTROID.visible = true
	var hull_centroid_lattice_pos: Vector2 = Vector2()
	var area: float = 0.0
	var centroid_x: float = 0.0
	var centroid_y: float = 0.0
	for i in range(CONVEX_INTEGER_HULL.convex_integer_hull.size()):
		var current_point = CONVEX_INTEGER_HULL.convex_integer_hull[i]
		var next_point = CONVEX_INTEGER_HULL.convex_integer_hull[(i + 1) % CONVEX_INTEGER_HULL.convex_integer_hull.size()]
		var cross_product = (current_point.x * next_point.y - next_point.x * current_point.y)
		area += cross_product
		centroid_x += (current_point.x + next_point.x) * cross_product
		centroid_y += (current_point.y + next_point.y) * cross_product
	area /= 2.0
	centroid_x /= 6.0 * area
	centroid_y /= 6.0 * area
	hull_centroid_lattice_pos = Vector2(centroid_x, centroid_y)
	# draw centroid
	CONVEX_INTEGER_HULL.CENTROID.lattice_position = hull_centroid_lattice_pos
	CONVEX_INTEGER_HULL.CENTROID.position = hull_centroid_lattice_pos * SCALING + OFFSET
	CONVEX_INTEGER_HULL.CENTROID.color = Color(0, 0, 1)
	# debug label
	if DEBUG.is_enabled():
		CONVEX_INTEGER_HULL.CENTROID.DEBUG_LABEL.text = str(hull_centroid_lattice_pos)
	return hull_centroid_lattice_pos

## Given a set of vertices, calculates the convex hull of them, and also the convex integer hull of that polygon.
## [br][br]
## Returns the convex hull of the vertices in a PackedVector2Array.
func build_polygon(packed_vertices: PackedVector2Array) -> PackedVector2Array:
	convex_hull = Geometry2D.convex_hull(packed_vertices)
	calculate_convex_integer_hull(convex_hull)
	calculate_hull_centroid()
	return convex_hull

## returns the area of a polygon given its vertices
func get_polygon_area(packed_vertices: PackedVector2Array) -> float:
	if packed_vertices.size() < 3:
		return 0.0
	var area: float = 0.0
	for i in range(packed_vertices.size()):
		var current_point = packed_vertices[i]
		var next_point = packed_vertices[(i + 1) % packed_vertices.size()]
		area += (current_point.x * next_point.y - next_point.x * current_point.y)
	return area / 2.0

## validates that the convex hull could be made into a level
func validate_level() -> bool:
	return convex_hull.size() > 2 \
		and CONVEX_INTEGER_HULL.convex_integer_hull.size() > 2 \
		and get_polygon_area(convex_hull) > GLOBALS.GEOMETRY_EPSILON_AREA \
		and get_polygon_area(CONVEX_INTEGER_HULL.convex_integer_hull) > GLOBALS.GEOMETRY_EPSILON_AREA