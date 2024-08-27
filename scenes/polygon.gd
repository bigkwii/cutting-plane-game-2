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
# - vfx -
@onready var CUT_VFX = $vfx/cut_vfx
@onready var CIRCLE_VFX = $vfx/circle_vfx

# -- preloaded scenes --
var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# build_polygon() # commenting this out because the level scene will handle the creation of the polygon
	pass

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
	if initial_vertices.size() < 3:
		DEBUG.log("polygon._ready: Polygon must have at least 3 vertices! %s given." % initial_vertices.size())
		return
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

## Calculates the area of a polygon represented by a PackedVector2Array. Works for both CW and CCW winding orders.
## [br][br]
## polygon: PackedVector2Array the polygon to calculate the area of
func polygon_area(polygon: PackedVector2Array) -> float:
	var area = 0.0
	for i in range(polygon.size()):
		var current_point = polygon[i]
		var next_point = polygon[(i + 1) % polygon.size()]
		area += (current_point.x * next_point.y - next_point.x * current_point.y)
	area /= 2
	return abs(area)

## Splits a polygon in two halves given a line, and returns BOTH halves' vertices in a Array[PackedVector2Array]
## [br][br]
## If something goes wrong, returns an empty array.
## [br][br]
## Not to be confused with the cut_polygon function, which keeps the half that contains the centroid.
## [br][br]
## polygon: PackedVector2Array the polygon to be split
## line_point, line_dir: point and direction of the line
## [br][br]
func split_polygon(polygon: PackedVector2Array, line_point: Vector2, line_dir: Vector2) -> Array[PackedVector2Array]:
	var new_poly_1 = PackedVector2Array()
	var new_poly_2 = PackedVector2Array()
	var intersection_points = line_intersects_polygon(polygon, line_point, line_dir)
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
	if polygon_area(new_poly_1) < GLOBALS.GEOMETRY_EPSILON_SQ or polygon_area(new_poly_2) < GLOBALS.GEOMETRY_EPSILON_SQ:
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
## [br][br]
## returns true if the cut was successful, false otherwise
func cut_polygon(line_point: Vector2, line_dir: Vector2) -> bool:
	var centroid: Vector2 = CENTROID.lattice_position
	var polygon_verts = packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		DEBUG.log("cut_polygon: No new polygons found.")
		return false
	# play the cut animation
	_play_cut_animation(line_point, line_dir)
	if Geometry2D.is_point_in_polygon(centroid, new_polygons[0]):
		rebuild_polygon(new_polygons[0])
	else:
		rebuild_polygon(new_polygons[1])
	return true

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
		if intersection and not intersection in intersection_points:
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
		var intersection_parameter = Geometry2D.segment_intersects_circle(start_point, end_point, circle_center, circle_radius)
		# intersection_parameter is a value between 0 and 1. convert to the actual position of the intersection
		if intersection_parameter != -1:
			var intersection = start_point + intersection_parameter * (end_point - start_point)
			intersection_points.append(intersection)
	return intersection_points

# -- the cut functions --
# these are the functions to be called when clicking on the screen with the respective cut mode selected on the level scene

## grows a circle until it intersects a lattice point. once it does, it checks if it intersects the polygon on 2 points.
## [br][br]
## if it intersects, cuts in the direction described by the intersection points.
## [br][br]
## clicked_lattice_pos: Vector2 the lattice position where the click happened
func circle_cut(clicked_lattice_pos: Vector2) -> void:
	var circle_center = clicked_lattice_pos
	# get the closest point with integer coordinates to the circle center
	# !!! TODO: optimize this !!!
	var candidates: Array[Vector2] = []
	candidates.append(Vector2(floor(circle_center.x), floor(circle_center.y)))
	candidates.append(Vector2(floor(circle_center.x), ceil(circle_center.y)))
	candidates.append(Vector2(ceil(circle_center.x), floor(circle_center.y)))
	candidates.append(Vector2(ceil(circle_center.x), ceil(circle_center.y)))
	var closest_lattice_point = candidates[0]
	for candidate in candidates:
		if (candidate - circle_center).length_squared() < (closest_lattice_point - circle_center).length_squared():
			closest_lattice_point = candidate
	# the radius of the circle will be the distance to the closest lattice point
	var circle_radius = (closest_lattice_point - circle_center).length()
	var intersection_points = circle_intersects_polygon(packed_vertices, circle_center, circle_radius)
	#if intersection_points.size() < 2:
	#	DEBUG.log("circle_cut: Invalid number of intersection points: %s" % intersection_points.size())
	#	return
	var is_cut_successful = intersection_points.size() >= 2 # TODO: check with would_cut_polygon ?

	# placeholder circle animation. TODO: when the real animations are done, this function should AWAIT the grow animation to finish
	_play_circle_animation(circle_center, circle_radius, is_cut_successful) # TODO: The success of the cut should be determined AFTER cut_polygon
	# wait for the animation to finish
	# !!! TODO !!! await is probably not the best here.
	# the function should really end here and there should be another function that gets triggered by the signal that performs the cut
	await CIRCLE_VFX.animation_finished

	if !is_cut_successful:
		return

	var line_point = intersection_points[0]
	var line_dir = intersection_points[1] - intersection_points[0]
	cut_polygon(line_point, line_dir)

## extends 2 parallel lines from the clicked lattice position until one of the hits the lattice grid.
## [br][br]
## once it does, check if the lines intersect the polygon.
## [br][br]
## if only one of the lines intersects the polygon, cut in that direction.
## [br][br]
## if both lines intersect the polygon, cut in the direction as position described by the intersection of the polygon with the first line and the intersection with the other line.
## [br][br]
## note: there may be 2 of these. In which case, make both cuts and award bonus points.
## [br][br]
## clicked_lattice_pos: Vector2 the lattice position where the click happened
## is_horizontal: bool if the cut is horizontal or vertical
func _base_split_cut(clicked_lattice_pos: Vector2, is_horizontal: bool) -> void:
	# temporary way to find the closest lattice point
	var line_point_1: Vector2
	var line_dir_1: Vector2
	var line_point_2: Vector2
	var line_dir_2: Vector2
	if is_horizontal:
		var closest_y = round(clicked_lattice_pos.y)
		var ceil_y = ceil(clicked_lattice_pos.y)
		var floor_y = floor(clicked_lattice_pos.y)
		if abs(closest_y - ceil_y) < abs(closest_y - floor_y):
			line_point_1 = Vector2( clicked_lattice_pos.x, closest_y + 2 * (clicked_lattice_pos.y - closest_y) )
			line_dir_1 = Vector2(1, 0)
			line_point_2 = Vector2( clicked_lattice_pos.x, closest_y )
			line_dir_2 = Vector2(1, 0)
		else:
			line_point_1 = Vector2( clicked_lattice_pos.x, closest_y )
			line_dir_1 = Vector2(1, 0)
			line_point_2 = Vector2( clicked_lattice_pos.x, closest_y + 2 * (clicked_lattice_pos.y - closest_y ) )
			line_dir_2 = Vector2(1, 0)
			

		# line_point_1 = Vector2( clicked_lattice_pos.x, floor(clicked_lattice_pos.y) )
		# line_dir_1 = Vector2(1, 0)
		# line_point_2 = Vector2( clicked_lattice_pos.x, ceil(clicked_lattice_pos.y) )
		# line_dir_2 = Vector2(1, 0)
	else:
		var closest_x = round(clicked_lattice_pos.x)
		var ceil_x = ceil(clicked_lattice_pos.x)
		var floor_x = floor(clicked_lattice_pos.x)
		if abs(closest_x - ceil_x) < abs(closest_x - floor_x):
			line_point_1 = Vector2( closest_x + 2 * (clicked_lattice_pos.x - closest_x), clicked_lattice_pos.y )
			line_dir_1 = Vector2(0, 1)
			line_point_2 = Vector2( closest_x, clicked_lattice_pos.y )
			line_dir_2 = Vector2(0, 1)
		else:
			line_point_1 = Vector2( closest_x, clicked_lattice_pos.y )
			line_dir_1 = Vector2(0, 1)
			line_point_2 = Vector2( closest_x + 2 * (clicked_lattice_pos.x - closest_x ), clicked_lattice_pos.y )
			line_dir_2 = Vector2(0, 1)

		# line_point_1 = Vector2( floor(clicked_lattice_pos.x), clicked_lattice_pos.y )
		# line_dir_1 = Vector2(0, 1)
		# line_point_2 = Vector2( ceil(clicked_lattice_pos.x), clicked_lattice_pos.y )
		# line_dir_2 = Vector2(0, 1)

	# check if the lines intersect the polygon
	var intersection_points_1 = line_intersects_polygon(packed_vertices, line_point_1, line_dir_1)
	var intersection_points_2 = line_intersects_polygon(packed_vertices, line_point_2, line_dir_2)

	# if only line 1 intersects the polygon, cut in the direction of line 1
	if intersection_points_1.size() > 0 and intersection_points_2.size() == 0:
		cut_polygon(line_point_1, line_dir_1)
		return
	# if only line 2 intersects the polygon, cut in the direction of line 2
	if intersection_points_1.size() == 0 and intersection_points_2.size() > 0:
		cut_polygon(line_point_2, line_dir_2)
		return
	# if both lines intersect the polygon, cut in the direction described by the intersection points
	if intersection_points_1.size() > 0 and intersection_points_2.size() > 0: # TODO! THIS DOESN'T WORK, HANDLE MULTIPLE INTERSECTIONS
		DEBUG.log("_base_split_cut: Cutting in the direction described by both lines' intersections.", 100)
		DEBUG.log("_base_split_cut: Intersection points 1: %s" % [intersection_points_1], 100)
		DEBUG.log("_base_split_cut: Intersection points 2: %s" % [intersection_points_2], 100)
		# at most, there should be 2 intersection points per line (if there are more, something went terribly wrong).
		# moreover, cuts cannot be done across the convex hull.
		# we can check for this by checking if the points are "behind" or "in front" of the centroid.
		# this, at most we'll have 2 cuts:
		# 1. from the intersection from line 1 to the intersection from line 2, if both are behind the centroid
		# 2. from the intersection from line 1 to the intersection from line 2, if both are in front of the centroid
		var intersection_point_from_line_1_behind_centroid: Vector2
		var intersection_point_from_line_2_behind_centroid: Vector2
		var intersection_point_from_line_1_ahead_centroid: Vector2
		var intersection_point_from_line_2_ahead_centroid: Vector2
		if is_horizontal:
			var centroid_x = CENTROID.lattice_position.x
			for intersection_point in intersection_points_1:
				if intersection_point.x < centroid_x:
					intersection_point_from_line_1_behind_centroid = intersection_point
				else:
					intersection_point_from_line_1_ahead_centroid = intersection_point
			for intersection_point in intersection_points_2:
				if intersection_point.x < centroid_x:
					intersection_point_from_line_2_behind_centroid = intersection_point
				else:
					intersection_point_from_line_2_ahead_centroid = intersection_point
		else:
			var centroid_y = CENTROID.lattice_position.y
			for intersection_point in intersection_points_1:
				if intersection_point.y < centroid_y:
					intersection_point_from_line_1_behind_centroid = intersection_point
				else:
					intersection_point_from_line_1_ahead_centroid = intersection_point
			for intersection_point in intersection_points_2:
				if intersection_point.y < centroid_y:
					intersection_point_from_line_2_behind_centroid = intersection_point
				else:
					intersection_point_from_line_2_ahead_centroid = intersection_point
		# check if the points are valid
		if intersection_point_from_line_1_behind_centroid and intersection_point_from_line_2_behind_centroid:
			cut_polygon(intersection_point_from_line_1_behind_centroid, intersection_point_from_line_2_behind_centroid - intersection_point_from_line_1_behind_centroid)
		if intersection_point_from_line_1_ahead_centroid and intersection_point_from_line_2_ahead_centroid:
			cut_polygon(intersection_point_from_line_1_ahead_centroid, intersection_point_from_line_2_ahead_centroid - intersection_point_from_line_1_ahead_centroid)
		return
	# if neither line intersects the polygon, do nothing
	DEBUG.log("_base_split_cut: No intersection points found.")
	return


func h_split_cut(clicked_lattice_pos: Vector2) -> void:
	_base_split_cut(clicked_lattice_pos, true)

func v_split_cut(clicked_lattice_pos: Vector2) -> void:
	_base_split_cut(clicked_lattice_pos, false)

func gomory_cut(clicked_lattice_pos: Vector2) -> void: # Note: this one doesn't depend on the clicked lattice position, of course
	DEBUG.log("Gomory cut not implemented yet.")

# -- placeholder cut animations --
# TODO: make real animations

func _play_cut_animation(line_point: Vector2, line_dir: Vector2) -> void:
	CUT_VFX.global_position = line_point * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	CUT_VFX.rotation = line_dir.angle()
	CUT_VFX.play()

func _play_circle_animation(circle_center: Vector2, circle_radius: float, success: bool) -> void:
	CIRCLE_VFX.global_position = circle_center * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	CIRCLE_VFX.radius = circle_radius * GLOBALS.DEFAULT_SCALING
	CIRCLE_VFX.successful_cut = success
	CIRCLE_VFX.play_grow()
