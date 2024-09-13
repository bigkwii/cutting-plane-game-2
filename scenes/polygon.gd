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
@onready var CUT_VFXS = $vfx/cut_vfxs
@onready var CIRCLE_VFX = $vfx/circle_vfx
@onready var SPLIT_VFX = $vfx/split_vfx
# - cut pieces vfx -
@onready var CUT_PIECES = $cut_pieces

# -- preloaded scenes --
var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")
var CUT_VFX_SCENE = preload("res://scenes/cut_vfx.tscn")
var CUT_PIECE_SCENE = preload("res://scenes/cut_piece.tscn")

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
	calculate_convex_integer_hull(true) # TODO: for testing purposes, remove this `true` later, recalculating the hull is expensive and unnecessary

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
	# debug label
	if DEBUG.is_enabled():
		CENTROID.DEBUG_LABEL.text = str(centroid_lattice_pos)
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
	# snap the intersection to avoid floating point badness
	intersection = snapped( intersection, Vector2(GLOBALS.GEOMETRY_EPSILON, GLOBALS.GEOMETRY_EPSILON) )
	return intersection

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
	# snap the intersection points with epsilons to avoid floating point badness !!! TODO: DOESNT SEEM TO WORK !!!
	for intersection in intersection_points:
		intersection = snapped( intersection, Vector2(GLOBALS.GEOMETRY_EPSILON, GLOBALS.GEOMETRY_EPSILON) )
	return intersection_points

## Determines if a given point is "above" a given line. Above being the line's normal.
## [br][br]
## point: Vector2 the point to check
## line_point, line_dir: point and direction of the line
func is_point_above_line(point: Vector2, line_point: Vector2, line_dir: Vector2) -> bool:
	return (line_dir.x) * (point.y - line_point.y) > (line_dir.y) * (point.x - line_point.x)

## Determines if a given point is ON a given line.
## [br][br]
## point: Vector2 the point to check
## line_point, line_dir: point and direction of the line
func is_point_on_line(point: Vector2, line_point: Vector2, line_dir: Vector2) -> bool:
	var relative_pos = point - line_point
	var cross_prod = relative_pos.cross(line_dir)
	return abs(cross_prod) < GLOBALS.GEOMETRY_EPSILON

## Calculates the UNSIGNED area of a polygon represented by a PackedVector2Array. Works for both CW and CCW winding orders.
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

## Splits a polygon in two halves given a line, and returns BOTH halves' vertices in a Array[PackedVector2Array] (and the intersection points)
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
	if intersection_points.size() < 2:
		DEBUG.log("split_polygon: Invalid number of intersection points: %s" % intersection_points.size())
		return []
	#DEBUG.log("split_polygon: Found %s intersection points: %s" % [intersection_points.size(), intersection_points])
	var added_intersection_1 = false
	var added_intersection_2 = false
	for i in range(polygon.size()):
		var current_point = polygon[i]
		var next_point = polygon[(i + 1) % polygon.size()]

		var current_on_line = is_point_on_line(current_point, line_point, line_dir)
		var next_on_line = is_point_on_line(next_point, line_point, line_dir)

		if current_on_line:
			# If the current point lies on the line, add it to both polygons only once
			if not added_intersection_1:
				new_poly_1.append(current_point)
				new_poly_2.append(current_point)
				added_intersection_1 = true
			elif not added_intersection_2:
				new_poly_1.append(current_point)
				new_poly_2.append(current_point)
				added_intersection_2 = true
			continue
		if is_point_above_line(current_point, line_point, line_dir):
			new_poly_1.append(current_point)
		else:
			new_poly_2.append(current_point)
		if not current_on_line and not next_on_line:
			var intersection_candidate = line_intersects_segment(line_point, line_dir, current_point, next_point)
			if intersection_candidate:
				# Always add the intersection candidate to both polygons
				new_poly_1.append(intersection_candidate)
				new_poly_2.append(intersection_candidate)
	# area check. if any of the new polygons has an area of 0, it's invalid
	if polygon_area(new_poly_1) < GLOBALS.GEOMETRY_EPSILON_SQ or polygon_area(new_poly_2) < GLOBALS.GEOMETRY_EPSILON_SQ:
		DEBUG.log("split_polygon: 0-area polygon detected (%s and %s), invalidated." % [polygon_area(new_poly_1), polygon_area(new_poly_2)])
		return []
	return [new_poly_1, new_poly_2, intersection_points]

## returns if a given line would've cut the convex hull of the polygon
func would_cut_hull(line_point: Vector2, line_dir: Vector2) -> bool:
	var hull = CONVEX_INTEGER_HULL.convex_integer_hull
	var new_polygons = split_polygon(hull, line_point, line_dir)
	if new_polygons.size() == 0:
		DEBUG.log("would_cut_hull: No new polygons found.")
		return false
	return true
	
## Cuts the polygon, given a line, and keeps the half that contains the centroid of the original.
## [br][br]
## This is the function to be called when making a cut.
## [br][br]
## Not to be confused with the split_polygon function, which is used in this function.
## [br][br]
## line_point, line_dir: point and direction of the line
## [br][br]
## returns true if the cut was successful, false otherwise
func cut_polygon(line_point: Vector2, line_dir: Vector2, allow_hull_cutting: bool = false) -> bool:
	var centroid: Vector2 = CENTROID.lattice_position
	var polygon_verts = packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		DEBUG.log("cut_polygon: No new polygons found.")
		return false
	if not allow_hull_cutting and would_cut_hull(line_point, line_dir):
		DEBUG.log("cut_polygon: Hull cutting detected. Aborting.")
		return false
	# play the cut animation
	_play_cut_animation(line_point, line_dir)
	var polygon_to_be_kept_index: int = 0 if Geometry2D.is_point_in_polygon(centroid, new_polygons[0]) else 1
	# run forgiveness checks on the polygon to be kept
	_run_forgiveness_checks(new_polygons[polygon_to_be_kept_index])
	# rebuild the polygon with the polygon to be kept
	rebuild_polygon(new_polygons[polygon_to_be_kept_index])
	# make a cut piece with the polygon to be removed, with an inital speed and direction given by their centroids
	var polygon_to_be_removed_index: int = 1 - polygon_to_be_kept_index
	# get the perpendicular direction to the cut line
	var intersection_points = new_polygons[2]
	var cut_piece_direction = (intersection_points[0] - intersection_points[1]).rotated(-PI/2).normalized()
	# make sure the direction is away from the polygon to be kept
	if cut_piece_direction.dot(centroid - intersection_points[0]) > 0:
		cut_piece_direction = -cut_piece_direction
	_make_cut_piece(new_polygons[polygon_to_be_removed_index], cut_piece_direction)
	return true

## returns true if a cut made with this line WOULD cut the polygon TODO: deprecated?
## [br][br]
## line_point, line_dir: point and direction of the line
func would_cut_polygon(line_point: Vector2, line_dir: Vector2, allow_hull_cutting: bool = false) -> bool:
	var polygon_verts = packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		return false
	if not allow_hull_cutting and would_cut_hull(line_point, line_dir):
		DEBUG.log("cut_polygon: Hull cutting detected. Aborting.")
		return false
	return true

## runs "forgiveness" checks on a given polygon, for cleaning up floating point imprecision and quality of life
func _run_forgiveness_checks(polygon: PackedVector2Array):
	# 1) snap to lattice points if close enough
	for i in range(polygon.size()):
		if abs(polygon[i].x - round(polygon[i].x)) < GLOBALS.FORGIVENESS_SNAP_EPSILON and abs(polygon[i].y - round(polygon[i].y)) < GLOBALS.FORGIVENESS_SNAP_EPSILON:
			polygon[i] = snapped( polygon[i], Vector2(GLOBALS.FORGIVENESS_SNAP_EPSILON, GLOBALS.FORGIVENESS_SNAP_EPSILON) )
	# 2) remove vertices that are very close to being colinear with their neighbors
	for i in range(polygon.size()):
		var current_point = polygon[i]
		var prev_point = polygon[(i - 1) % polygon.size()]
		var next_point = polygon[(i + 1) % polygon.size()]
		var dot = (current_point - prev_point).normalized().dot((next_point - current_point).normalized())
		if abs(dot + 1) < GLOBALS.FORGIVENESS_COLINEAR_EPSILON:
			polygon.remove_at(i)
			i -= 1
	# 3) merge vertices that are very close to each other
	for i in range(polygon.size()):
		var current_point = polygon[i] # !!! TODO: CRASHES HERE SOMETIMES (OUT OF RANGE) !!!
		var next_point = polygon[(i + 1) % polygon.size()]
		if current_point.distance_to(next_point) < GLOBALS.FORGIVENESS_MERGE_EPSILON:
			polygon.remove_at(i)
			i -= 1

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
			# snapped to avoid floating point badness
			intersection = snapped( intersection, Vector2(GLOBALS.GEOMETRY_EPSILON, GLOBALS.GEOMETRY_EPSILON) )
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
	# placeholder circle animation. TODO: animation should be interruptible
	_play_circle_animation(circle_center, circle_radius)
	await CIRCLE_VFX.grow_animation_finished

	# make every valid cut possible
	var already_made_cuts = []
	var valid_cuts = 0
	for cut_start in intersection_points:
		for cut_end in intersection_points:
			if cut_start == cut_end:
				continue
			if would_cut_hull(cut_start, cut_end - cut_start):
				continue
			if [cut_start, cut_end] in already_made_cuts or [cut_end, cut_start] in already_made_cuts:
				continue
			var is_valid_cut = cut_polygon(cut_start, cut_end - cut_start)
			valid_cuts += 1 if is_valid_cut else 0
			already_made_cuts.append([cut_start, cut_end])
	if valid_cuts == 0:
		DEBUG.log("circle_cut: No valid cuts found.")
		_play_circle_failure_animation()
	else:
		DEBUG.log("circle_cut: Made %s valid cuts." % valid_cuts)
		_play_circle_success_animation()


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
## [br]
## is_horizontal: bool if the cut is horizontal or vertical
func _base_split_cut(clicked_lattice_pos: Vector2, is_horizontal: bool) -> void:
	var line_point_1: Vector2
	var line_dir_1: Vector2
	var line_point_2: Vector2
	var line_dir_2: Vector2
	var width: float
	if is_horizontal:
		var closest_y = round(clicked_lattice_pos.y)
		var ceil_y = ceil(clicked_lattice_pos.y)
		var floor_y = floor(clicked_lattice_pos.y)
		if abs(closest_y - ceil_y) < abs(closest_y - floor_y):
			line_point_1 = Vector2( clicked_lattice_pos.x, closest_y + 2 * (clicked_lattice_pos.y - closest_y) )
			line_dir_1 = Vector2(1, 0)
			line_point_2 = Vector2( clicked_lattice_pos.x, closest_y )
			line_dir_2 = Vector2(1, 0)
			width = abs(clicked_lattice_pos.y - closest_y)
		else:
			line_point_1 = Vector2( clicked_lattice_pos.x, closest_y )
			line_dir_1 = Vector2(1, 0)
			line_point_2 = Vector2( clicked_lattice_pos.x, closest_y + 2 * (clicked_lattice_pos.y - closest_y ) )
			line_dir_2 = Vector2(1, 0)
			width = abs(clicked_lattice_pos.y - closest_y)
	else:
		var closest_x = round(clicked_lattice_pos.x)
		var ceil_x = ceil(clicked_lattice_pos.x)
		var floor_x = floor(clicked_lattice_pos.x)
		if abs(closest_x - ceil_x) < abs(closest_x - floor_x):
			line_point_1 = Vector2( closest_x + 2 * (clicked_lattice_pos.x - closest_x), clicked_lattice_pos.y )
			line_dir_1 = Vector2(0, 1)
			line_point_2 = Vector2( closest_x, clicked_lattice_pos.y )
			line_dir_2 = Vector2(0, 1)
			width = abs(clicked_lattice_pos.x - closest_x)
		else:
			line_point_1 = Vector2( closest_x, clicked_lattice_pos.y )
			line_dir_1 = Vector2(0, 1)
			line_point_2 = Vector2( closest_x + 2 * (clicked_lattice_pos.x - closest_x ), clicked_lattice_pos.y )
			line_dir_2 = Vector2(0, 1)
			width = abs(clicked_lattice_pos.x - closest_x)
	# !!! PLACEHOLDER SPLIT ANIMATION !!!
	_play_split_animation(clicked_lattice_pos, width, is_horizontal)
	await SPLIT_VFX.grow_animation_finished
	# check if the lines intersect the polygon
	var intersection_points_1 = line_intersects_polygon(packed_vertices, line_point_1, line_dir_1)
	var intersection_points_2 = line_intersects_polygon(packed_vertices, line_point_2, line_dir_2)
	var valid_cuts = 0
	# if only one of the lines intersects the polygon, cut in that direction
	if intersection_points_1.size() > 0 and intersection_points_2.size() == 0:
		var is_valid_cut = cut_polygon(line_point_1, line_dir_1)
		valid_cuts += 1 if is_valid_cut else 0
	elif intersection_points_1.size() == 0 and intersection_points_2.size() > 0:
		var is_valid_cut = cut_polygon(line_point_2, line_dir_2)
		valid_cuts += 1 if is_valid_cut else 0
	# if both lines intersect the polygon, the potential cuts to be made are from the "top" intersection points of lines 1 and 2, and the "bottom" lines
	# TODO: Ugh... ugly ass code. simplify this
	elif intersection_points_1.size() > 0 and intersection_points_2.size() > 0:
		var coord_int = 0 if is_horizontal else 1 # 0: x, 1: y
		var top_intersection_1 = intersection_points_1[0]
		for intersection in intersection_points_1:
			if intersection[coord_int] > top_intersection_1[coord_int]:
				top_intersection_1 = intersection
		var top_intersection_2 = intersection_points_2[0]
		for intersection in intersection_points_2:
			if intersection[coord_int] > top_intersection_2[coord_int]:
				top_intersection_2 = intersection
		var bottom_intersection_1 = intersection_points_1[0]
		for intersection in intersection_points_1:
			if intersection[coord_int] < bottom_intersection_1[coord_int]:
				bottom_intersection_1 = intersection
		var bottom_intersection_2 = intersection_points_2[0]
		for intersection in intersection_points_2:
			if intersection[coord_int] < bottom_intersection_2[coord_int]:
				bottom_intersection_2 = intersection
		# make the cuts
		var is_valid_cut_1 = cut_polygon(top_intersection_1, top_intersection_2 - top_intersection_1)
		var is_valid_cut_2 = cut_polygon(bottom_intersection_1, bottom_intersection_2 - bottom_intersection_1)
		valid_cuts += 1 if is_valid_cut_1 else 0
		valid_cuts += 1 if is_valid_cut_2 else 0
	if valid_cuts == 0:
		DEBUG.log("_split_cut: No valid cuts found.")
		_play_split_failure_animation()
	else:
		DEBUG.log("_split_cut: Made %s valid cuts." % valid_cuts)
		_play_split_success_animation()

func h_split_cut(clicked_lattice_pos: Vector2) -> void:
	_base_split_cut(clicked_lattice_pos, true)

func v_split_cut(clicked_lattice_pos: Vector2) -> void:
	_base_split_cut(clicked_lattice_pos, false)

func gomory_cut(clicked_lattice_pos: Vector2) -> void:
	# vertex selection
	var selected_index: int = -1
	var closest_distance: float = INF
	for i in range(packed_vertices.size()):
		if packed_vertices[i].x == int(packed_vertices[i].x) and packed_vertices[i].y == int(packed_vertices[i].y):
			continue
		var distance = packed_vertices[i].distance_to(clicked_lattice_pos)
		if distance < GLOBALS.GOMORY_CUT_CLICK_RANGE and distance < closest_distance:
			closest_distance = distance
			selected_index = i
	if selected_index == -1:
		DEBUG.log("gomory_cut: No vertex in range")
		return
	DEBUG.log("gomory_cut: selected vertex: %s" % packed_vertices[selected_index])
	
	# gomory mixed integer cut algorithm (logic ripped straight from the demo)
	var selected_vertex = packed_vertices[selected_index]
	var neigh_before = packed_vertices[(selected_index - 1 + packed_vertices.size()) % packed_vertices.size()]
	var neigh_after = packed_vertices[(selected_index + 1) % packed_vertices.size()]
	var a1 = Vector2(-(selected_vertex - neigh_before).y, (selected_vertex - neigh_before).x)
	var b1 = a1.dot(neigh_before)
	if a1.dot(neigh_after) > b1:
		a1 = -a1
		b1 = -b1
	var a2 = Vector2(-(selected_vertex - neigh_after).y, (selected_vertex - neigh_after).x)
	var b2 = a2.dot(neigh_after)
	if a2.dot(neigh_before) > b2:
		a2 = -a2
		b2 = -b2
	var inverse_basis_rows = compute_inverse_basis_rows(a1.x, a1.y, a2.x, a2.y)
	# First GMI cut
	var aLattice1 = Vector2(1, 0)
	var aSlack1 = inverse_basis_rows[0]
	var b = inverse_basis_rows[0].x * b1 + inverse_basis_rows[0].y * b2
	var result1 = get_gmi(aLattice1, aSlack1, b, inverse_basis_rows)
	var violation1: float = 0.0
	var GMIaLattice1: Vector2 = result1[0]
	var GMIaSlack1: Vector2 = result1[1]
	var GMIb1: float = result1[2]
	var status = 0
	if (abs(selected_vertex.x - round(selected_vertex.x)) < GLOBALS.GEOMETRY_EPSILON):
		status = 1
	if status == 0:
		GMIb1 -= (GMIaSlack1.x * b1 + GMIaSlack1.y * b2)
		GMIaLattice1 -= Vector2(GMIaSlack1.x * a1.x + GMIaSlack1.y * a2.x, GMIaSlack1.x * a1.y + GMIaSlack1.y * a2.y)
		violation1 = (GMIaLattice1.dot(selected_vertex) - GMIb1) / GMIaLattice1.length()
	# Second GMI cut
	var aLattice2 = Vector2(0, 1)
	var aSlack2 = inverse_basis_rows[1]
	b = inverse_basis_rows[1].x * b1 + inverse_basis_rows[1].y * b2
	var result2 = get_gmi(aLattice2, aSlack2, b, inverse_basis_rows)
	var violation2: float = 0.0
	var GMIaLattice2: Vector2 = result2[0]
	var GMIaSlack2: Vector2 = result2[1]
	var GMIb2: float = result2[2]
	status = 0
	if (abs(selected_vertex.y - round(selected_vertex.y)) < GLOBALS.GEOMETRY_EPSILON):
		status = 1
	if status == 0:
		GMIb2 -= (GMIaSlack2.x * b1 + GMIaSlack2.y * b2)
		GMIaLattice2 -= Vector2(GMIaSlack2.x * a1.x + GMIaSlack2.y * a2.x, GMIaSlack2.x * a1.y + GMIaSlack2.y * a2.y)
		violation2 = (GMIaLattice2.dot(selected_vertex) - GMIb2) / GMIaLattice2.length()
	# Determine which GMI cut to apply based on the violation
	var GMIaLattice: Vector2
	var _GMIaSlack: Vector2
	var GMIb: float
	if violation1 < violation2:
		GMIaLattice = GMIaLattice1
		_GMIaSlack = GMIaSlack1
		GMIb = GMIb1
	else:
		GMIaLattice = GMIaLattice2
		_GMIaSlack = GMIaSlack2
		GMIb = GMIb2
	# get the points for the cut
	var point1: Vector2
	var point2: Vector2
	if ( GMIaLattice.x != 0 and GMIaLattice.y != 0 ):
		point1.x = GMIb / GMIaLattice.x
		point1.y = 0
		point2.x = 0
		point2.y = GMIb / GMIaLattice.y
	elif ( GMIaLattice.x == 0 ):
		point1.x = 0
		point1.y = GMIb / GMIaLattice.y
		point2.x = 1
		point2.y = GMIb / GMIaLattice.y
	else:
		point1.x = GMIb / GMIaLattice.x
		point1.y = 0
		point2.x = GMIb / GMIaLattice.x
		point2.y = 1
	# turn the points into a line
	var line_point = point1
	var line_dir = point2 - point1
	# Perform the cut on the polygon
	cut_polygon(line_point, line_dir)
	# this is to update the hover vfx on the verts. i know, it's a bit hacky.
	gomory_mode_selected(true)

## Function to compute inverse basis rows (ripped straight from the demo)
func compute_inverse_basis_rows(a: float, b: float, c: float, d: float) -> Array[Vector2]:
	var out_rows: Array[Vector2] = []
	var determinant = a * d - b * c
	if determinant == 0:
		DEBUG.log("compute_inverse_basis_rows: Error: Determinant is zero!")
		return []
	out_rows.append(Vector2(d / determinant, -b / determinant))
	out_rows.append(Vector2(-c / determinant, a / determinant))
	return out_rows

## Function to compute GMI cut (ripped straight from the demo)
func get_gmi(a_lattice: Vector2, a_slack: Vector2, b: float, inverse_basis_rows: Array) -> Array:
	var GMIaLattice: Vector2 = Vector2()
	var GMIaSlack: Vector2 = Vector2()
	var GMIb: float = 0.0
	var aprime = Vector2(a_lattice.dot(Vector2(1, 0)), a_lattice.dot(Vector2(0,1)))
	var f0 = b - floor(b)
	var f1 = aprime.x - floor(aprime.x)
	var f2 = aprime.y - floor(aprime.y)
	if f0 == 0.0:
		return [1, GMIaLattice, GMIaSlack, GMIb]  # No GMI cut possible
	var gmiLattice = Vector2()
	gmiLattice.x = f1 / f0 if f1 <= f0 else (1.0 - f1) / (1.0 - f0)
	gmiLattice.y = f2 / f0 if f2 <= f0 else (1.0 - f2) / (1.0 - f0)
	GMIaSlack.x = a_slack.x / f0 if a_slack.x > 0.0 else -a_slack.x / (1.0 - f0)
	GMIaSlack.y = a_slack.y / f0 if a_slack.y > 0.0 else -a_slack.y / (1.0 - f0)
	GMIb = 1.0
	GMIaLattice.x = gmiLattice.x * inverse_basis_rows[0].x + gmiLattice.y * inverse_basis_rows[1].x
	GMIaLattice.y = gmiLattice.x * inverse_basis_rows[0].y + gmiLattice.y * inverse_basis_rows[1].y
	return [GMIaLattice, GMIaSlack, GMIb]  # GMI cut successful

# -- placeholder cut animations --
# TODO: make circle and split animations interruplible (?)

func _play_cut_animation(line_point: Vector2, line_dir: Vector2) -> void:
	var new_cut_vfx = CUT_VFX_SCENE.instantiate()
	CUT_VFXS.add_child(new_cut_vfx)
	new_cut_vfx.global_position = line_point * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	new_cut_vfx.rotation = line_dir.angle()
	new_cut_vfx.play()

func _play_circle_animation(circle_center: Vector2, circle_radius: float) -> void:
	CIRCLE_VFX.global_position = circle_center * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	CIRCLE_VFX.radius = circle_radius * GLOBALS.DEFAULT_SCALING
	CIRCLE_VFX.play_grow()

func _play_circle_success_animation() -> void:
	CIRCLE_VFX.play_success()

func _play_circle_failure_animation() -> void:
	CIRCLE_VFX.play_failure()

func _play_split_animation(origin: Vector2, width: float, is_horizontal: bool) -> void:
	SPLIT_VFX.global_position = origin * GLOBALS.DEFAULT_SCALING + GLOBALS.DEFAULT_OFFSET
	SPLIT_VFX.width = width * GLOBALS.DEFAULT_SCALING
	SPLIT_VFX.is_horizontal = is_horizontal
	SPLIT_VFX.play_grow()

func _play_split_success_animation() -> void:
	SPLIT_VFX.play_success()

func _play_split_failure_animation() -> void:
	SPLIT_VFX.play_failure()

# -- gomory cut mode vfx handling --
func gomory_mode_selected(make_clickable: bool):
	for vert in VERTS.get_children():
		if vert.is_integral():
			continue
		if not make_clickable:
			vert.hover = false # just in case
		vert.clickable = make_clickable

func update_verts_hover_vfx(mouse_lattice_pos):
	var closest_distance = INF
	var selected_vert = null
	for vert in VERTS.get_children():
		if vert.is_integral():
			continue
		vert.hover = false
		var distance = vert.lattice_position.distance_to(mouse_lattice_pos)
		if distance < 0.1 and distance < closest_distance: # TODO: same!
			closest_distance = distance
			if closest_distance < INF:
				selected_vert = vert
	if selected_vert:
		selected_vert.hover = true

# -- cut piece creation --
func _make_cut_piece(lattice_verts: PackedVector2Array, initial_velocity_dir: Vector2 = Vector2(0, 0)) -> void:
	var new_cut_piece = CUT_PIECE_SCENE.instantiate()
	new_cut_piece.packed_vertices = lattice_verts
	new_cut_piece.SCALING = SCALING
	new_cut_piece.OFFSET = OFFSET
	new_cut_piece.color = color
	new_cut_piece.initial_velocity_dir = initial_velocity_dir
	CUT_PIECES.add_child(new_cut_piece)
