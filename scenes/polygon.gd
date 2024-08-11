extends Node2D
## A polygon. Made out of PolyPoint nodes.
## [br][br]
## This scene contains the logic of the polygon, plus utility geometry functions.

# -- vars --
## Scaling factor for the lattice points. To convert from lattice coordinates to screen coordinates.
@export var SCALING: int = GLOBALS.DEFAULT_SCALING
## Offset from the game origin to the grid origin.
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## The color of the polygon. Borders are solid, fill is semi-transparent.
@export var color: Color = Color(1, 0, 0)

## The starting vertices that make up the polygon[br][br]
## Make sure to use Lattice coordinates and to follow a CCW winding order.
@export var initial_vertices: Array[Vector2] = []

## packed version of the vertices array for easy geometry calculations
var packed_vertices: PackedVector2Array = []

# -- child nodes --
@onready var VERTS = $verts
@onready var CENTROID = $centroid
@onready var CONVEX_INTEGER_HULL = $convex_integer_hull
@onready var CUT_VFX = $vfx/cut_vfx

# -- preloaded scenes --
var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if initial_vertices.size() < 3:
		DEBUG.log("polygon._ready: Polygon must have at least 3 vertices! %s given." % initial_vertices.size())
		return
	build_polygon()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _draw():
	if packed_vertices.size() < 3:
		DEBUG.log("polygon._draw: Polygon must have at least 3 vertices! %s given." % packed_vertices.size())
		return
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
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

## Builds the Polygon given vertices on initial_vertices. Does not clear the previous vertices.
## [br][br]
## To be called when first loading a level.
func build_polygon() -> void:
	DEBUG.log("making polygon with vertices: " + str(initial_vertices))
	packed_vertices = PackedVector2Array(initial_vertices)
	for vert in packed_vertices:
		_add_new_vertex(vert)
	calculate_centroid()
	calculate_convex_integer_hull(true) # for testing purposes, remove this `true` later, recalculating the hull is expensive and unnecessary

## Removes all vertex children from the polygon
func _delete_verts() -> void:
	for vert in VERTS.get_children():
		VERTS.remove_child(vert)
		vert.queue_free()

## Deletes itself and all children
func delete_polygon() -> void:
	queue_free()

## Rebuilds the polygon given new vertices in a PackedVector2Array, clearing all previously drawn vertices.
## [br][br]
## To be called when cutting or reloading a level.
func rebuild_polygon(new_vertices: PackedVector2Array) -> void:
	_delete_verts()
	# convert the new vertices to a vector2 array
	initial_vertices = []
	for vert in new_vertices:
		initial_vertices.append(vert)
	# make the new polygon
	build_polygon()
	queue_redraw()
	
## Checks if the polygon is integral. (if all vertices are integers)
func is_integral() -> bool:
	for vert in VERTS.get_children():
		if not vert.is_integral():
			return false
	return true

## Calculates the centroid of the polygon.
## TODO: is it necessary to return the centroid if we save it in the CENTROID node?
func calculate_centroid() -> Vector2:
	var sum: Vector2 = Vector2(0, 0)
	for vert in VERTS.get_children():
		sum += vert.lattice_position
	var centroid_lattice_pos = sum / VERTS.get_child_count()
	# draw centroid
	CENTROID.lattice_position = centroid_lattice_pos
	CENTROID.position = centroid_lattice_pos * SCALING + OFFSET
	CENTROID.color = Color(0, 1, 0)
	return centroid_lattice_pos

## Determines if a given points is inside the polygon, given its lattice position.
func is_point_inside_polygon(lattice_pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(lattice_pos, packed_vertices)

## Calculates the convex integer hull of the polygon and stores it in the CONVEX_INTEGER_HULL node for drawing.
func calculate_convex_integer_hull(redraw: bool = false) -> void:
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
			if is_point_inside_polygon(Vector2(x, y)): # we need to use the packed version for this
				hull.append(Vector2(x, y))
	# get the convex hull of the points
	hull = Geometry2D.convex_hull(hull)
	CONVEX_INTEGER_HULL.convex_integer_hull = PackedVector2Array(hull)
	# if a redraw was requested, queue it
	if redraw:
		CONVEX_INTEGER_HULL.queue_redraw()

## determines if a given point is on a segment
## [br][br]
## point: Vector2 the point to check
## segment_start, segment_end: start and end points of the segment
func is_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> bool:
	var cross_product = (point.y - segment_start.y) * (segment_end.x - segment_start.x) - (point.x - segment_start.x) * (segment_end.y - segment_start.y)
	if abs(cross_product) > GLOBALS.GEOMETRY_EPSILON:
		return false
	var dot_product = (point.x - segment_start.x) * (segment_end.x - segment_start.x) + (point.y - segment_start.y) * (segment_end.y - segment_start.y)
	if dot_product < 0:
		return false
	var squared_length = (segment_end - segment_start).length_squared()
	if dot_product > squared_length:
		return false
	return true

## Combination of line_intersects_line and segment_intersects_segment. Returns null if the intersection point is not on the segment
## [br][br]
## line_point: Vector2 point that defines the line
## line_direction: Vector2 direction of the line
## segment_start, segment_end: start and end points of the segment
func line_intersects_segment(line_point: Vector2, line_direction: Vector2, segment_start: Vector2, segment_end: Vector2):
	var segment_direction = segment_end - segment_start
	var intersection = Geometry2D.line_intersects_line(line_point, line_direction, segment_start, segment_direction)
	if not intersection:
		return null
	if not is_point_on_segment(intersection, segment_start, segment_end):
		return null
	return intersection

## Determines if a given point is "above" a given line segment. Really just used to determine which half of a polygon the centroid is in.
## [br][br]
## point: Vector2 the point to check
## line_point, line_dir: point and direction of the line
func is_point_above_line(point: Vector2, line_point: Vector2, line_dir: Vector2) -> bool:
	return (line_dir.x) * (point.y - line_point.y) > (line_dir.y) * (point.x - line_point.x)

## Calculates the area of a polygon represented by a PackedVector2Array
## [br][br]
## polygon: PackedVector2Array the polygon to calculate the area of
func polygon_area(polygon: PackedVector2Array) -> float:
	var area = 0.0
	for i in range(polygon.size()):
		var current_point = polygon[i]
		var next_point = polygon[(i + 1) % polygon.size()]
		area += current_point.x * next_point.y - next_point.x * current_point.y
	return area / 2

## Splits a polygon in two halves given a line, and returns BOTH halves' vertices in a Array[PackedVector2Array]
## [br][br]
## Not to be confused with the cut_polygon function, which keeps the half that contains the centroid.
## [br][br]
## polygon: PackedVector2Array the polygon to be split
## line_point, line_dir: point and direction of the line
## [br][br]
func split_polygon(polygon: PackedVector2Array, line_point: Vector2, line_dir: Vector2) -> Array[PackedVector2Array]:
	var new_poly_1 = PackedVector2Array()
	var new_poly_2 = PackedVector2Array()
	var intersection_points = []
	for i in range(polygon.size()):
		var start_point = polygon[i]
		var end_point = polygon[(i + 1) % polygon.size()]
		var intersection = line_intersects_segment(line_point, line_dir, start_point, end_point)
		if intersection:
			intersection_points.append(intersection)
	if intersection_points.size() < 2: # TODO: does this make sense? idk, think about it harder some other time.
		DEBUG.log("split_polygon: Invalid number of intersection points: %s" % intersection_points.size())
		return []
	DEBUG.log("split_polygon: Found %s intersection points: %s" % [intersection_points.size(), intersection_points])
	var is_upper = is_point_above_line(polygon[0], line_point, line_dir)
	var added_intersection_1 = false
	var added_intersection_2 = false
	for i in range(polygon.size()):
		var current_point = polygon[i]
		if is_point_above_line(current_point, line_point, line_dir):
			new_poly_1.append(current_point)
		else:
			new_poly_2.append(current_point)
		var next_point = polygon[(i + 1) % polygon.size()]
		if line_intersects_segment(line_point, line_dir, current_point, next_point):
			var intersection = intersection_points.pop_front()
			if not added_intersection_1:
				new_poly_1.append(intersection)
				new_poly_2.append(intersection)
				added_intersection_1 = true
			elif not added_intersection_2:
				new_poly_1.append(intersection)
				new_poly_2.append(intersection)
				added_intersection_2 = true
			is_upper = not is_upper
	# area check. if any of the new polygons has an area of 0, it's invalid
	if polygon_area(new_poly_1) < GLOBALS.GEOMETRY_EPSILON or polygon_area(new_poly_2) < GLOBALS.GEOMETRY_EPSILON:
		DEBUG.log("split_polygon: 0-area polygon detected, invalidated.")
		return []
	return [new_poly_1, new_poly_2]
	
## Cuts the polygon, given a line, and keeps the half that contains the centroid of the original.
## [br][br]
## This is the function to be called when making a cut.
## [br][br]
## Not to be confused with the split_polygon function, which is used in this function.
## [br][br]
## line_point, line_dir: point and direction of the line
func cut_polygon(line_point: Vector2, line_dir: Vector2) -> void:
	var centroid: Vector2 = CENTROID.lattice_position
	var polygon_verts = packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		DEBUG.log("cut_polygon: No new polygons found.")
		return
	# move cut_vfx to this position, rotate it to match this direction and hit play
	CUT_VFX.global_position = line_point * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	CUT_VFX.rotation = line_dir.angle()
	CUT_VFX.play()
	if Geometry2D.is_point_in_polygon(centroid, new_polygons[0]):
		rebuild_polygon(new_polygons[0])
	else:
		rebuild_polygon(new_polygons[1])

## returns true if a cut made with this line WOULD cut the polygon
## [br][br]
## line_point, line_dir: point and direction of the line
func would_cut_polygon(line_point: Vector2, line_dir: Vector2) -> bool:
	var polygon_verts = packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		return false
	return true

## returns all the intersection points of a line with a polygon
## [br][br]
## polygon: PackedVector2Array the polygon to check
## line_point, line_dir: point and direction of the line
func line_intersects_polygon(polygon: PackedVector2Array, line_point: Vector2, line_dir: Vector2):
	var intersection_points = []
	for i in range(polygon.size()):
		var start_point = polygon[i]
		var end_point = polygon[(i + 1) % polygon.size()]
		var intersection = line_intersects_segment(line_point, line_dir, start_point, end_point)
		if intersection:
			intersection_points.append(intersection)
	return intersection_points

## returns all the intersection points of a circle with a polygon
## [br][br]
## polygon: PackedVector2Array the polygon to check
## circle_center: center of the circle
## circle_radius: radius of the circle
func circle_intersects_polygon(polygon: PackedVector2Array, circle_center: Vector2, circle_radius: float):
	var intersection_points = []
	for i in range(polygon.size()):
		var start_point = polygon[i]
		var end_point = polygon[(i + 1) % polygon.size()]
		var intersection = Geometry2D.segment_intersects_circle(start_point, end_point, circle_center, circle_radius)
		if intersection:
			intersection_points.append(intersection)
	return intersection_points

## the circle cut. makes the biggest circle that fits inside the lattice square where the click happened, and if that circle intersects the polygon in 2 points, cuts it.
## [br][br]
## clicked_lattice_pos: Vector2 the lattice position where the click happened
func circle_cut(clicked_lattice_pos: Vector2) -> void:
	DEBUG.log("Circle cut not implemented yet.")

func h_split_cut(clicked_lattice_pos: Vector2) -> void:
	DEBUG.log("H split cut not implemented yet.")

func v_split_cut(clicked_lattice_pos: Vector2) -> void:
	DEBUG.log("V split cut not implemented yet.")

func gomory_cut(clicked_lattice_pos: Vector2) -> void:
	DEBUG.log("Gomory cut not implemented yet.")