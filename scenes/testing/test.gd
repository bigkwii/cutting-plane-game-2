extends Node2D
## testing scene for various things
## [br][br]
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!! TODO: A LOT OF THIS NEED TO EITHER BE MOVED TO POLYGON, AN AUTOLOAD, OR A NEW "LEVEL" SCENE !!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# -- vars --
## epsilon for snapping to grid
var CLICK_EPSILON = 0.01
## epsilon for geometric calculations
var GEOMETRY_EPSILON = 0.00001
# - cut mode stuff -
enum CUT_MODES { DEBUG_CUT, CIRCLE_CUT, GOMORY_CUT, H_SPLIT_CUT, V_SPLIT_CUT }
var cut_mode = CUT_MODES.DEBUG_CUT
# - debug -
var debug_cut_direction = Vector2(1, 0)

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var POLYGON = $polygon
@onready var CAMERA = $Camera
@onready var CUT_VFX = $vfx/cut_vfx
# - hud elements -
@onready var HUD = $CanvasLayer/HUD
@onready var BUTTONS_CONTAINER = $CanvasLayer/HUD/buttons
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/buttons/show_hull
@onready var CIRCLE_CUT_BUTTON = $CanvasLayer/HUD/buttons/circle
@onready var GOMORY_CUT_BUTTON = $CanvasLayer/HUD/buttons/gomory
@onready var H_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/buttons/h_split
@onready var V_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/buttons/v_split
# - debug cut button and input -
@onready var DEBUG_CUT_BUTTON = $CanvasLayer/HUD/buttons/debug_cut
@onready var DEBUG_CUT_INPUT = $CanvasLayer/HUD/buttons/debug_cut_input

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# TODO: checking for this every frame is ugly. make it event-based later
	if SHOW_HULL_BUTTON.is_pressed():
		POLYGON.CONVEX_INTEGER_HULL.visible = true
	else:
		POLYGON.CONVEX_INTEGER_HULL.visible = false
	if DEBUG_CUT_BUTTON.is_pressed(): # TODO: don't do this like this, make it event-based
		var degrees = float(DEBUG_CUT_INPUT.text)
		if degrees != null:
			debug_cut_direction = Vector2(cos(deg_to_rad(degrees)), -sin(deg_to_rad(degrees)))
		else:
			DEBUG.log("Invalid angle: %s" % degrees)
			DEBUG_CUT_INPUT.text = "0"
			debug_cut_direction = Vector2(1, 0)
		cut_mode = CUT_MODES.DEBUG_CUT
		DEBUG.log("DEBUG_CUT selected")
	if CIRCLE_CUT_BUTTON.is_pressed(): # BAD! don't do this like this
		cut_mode = CUT_MODES.CIRCLE_CUT
		DEBUG.log("CIRCLE_CUT selected")
	if H_SPLIT_CUT_BUTTON.is_pressed(): # AGAIN, BAD!
		cut_mode = CUT_MODES.H_SPLIT_CUT
		DEBUG.log("H_SPLIT_CUT selected")
	if V_SPLIT_CUT_BUTTON.is_pressed(): # AGAIN, BAD!
		cut_mode = CUT_MODES.V_SPLIT_CUT
		DEBUG.log("V_SPLIT_CUT selected")

func _input(event):
	# reload scene if reset input is pressed
	if event.is_action_pressed("reset"):
		DEBUG.log("Reloading scene...")
		get_tree().reload_current_scene()
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed: # not event.pressed = released
			# if on the show hull button, do nothing
			if BUTTONS_CONTAINER.get_global_rect().has_point(event.position): # !!! TODO !!!: this is hacky, i don't like it, figure out a cleaner way
				return
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - DEFAULTS.OFFSET) / DEFAULTS.SCALING , Vector2(CLICK_EPSILON, CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			if cut_mode == CUT_MODES.DEBUG_CUT:
				# split the polygon at the given position and at a hard-coded direction
				cut_polygon(Vector2(clicked_lattice_pos.x, clicked_lattice_pos.y), debug_cut_direction)
			elif cut_mode == CUT_MODES.CIRCLE_CUT:
				circle_cut(clicked_lattice_pos)
			elif cut_mode == CUT_MODES.H_SPLIT_CUT:
				h_split_cut(clicked_lattice_pos)
			elif cut_mode == CUT_MODES.V_SPLIT_CUT:
				v_split_cut(clicked_lattice_pos)
		
## determines if a given point is on a segment
## [br][br]
## point: Vector2 the point to check
## segment_start, segment_end: start and end points of the segment
func is_point_on_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> bool:
	var cross_product = (point.y - segment_start.y) * (segment_end.x - segment_start.x) - (point.x - segment_start.x) * (segment_end.y - segment_start.y)
	if abs(cross_product) > GEOMETRY_EPSILON:
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

## splits a polygon in two halves given a line
## [br][br]
## polygon: PackedVector2Array the polygon to be split
## line_point, line_dir: point and direction of the line
## [br][br]
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!! TODO: this function is kinda ugly and probably does a bunch of unnecesaary stuff.    !!!
## !!! Plus: it should be in the polygon.gd script. Same goes for the cut_polygon function. !!!
## !!! Also, confusing names (split and cut? sounds like the same thing)                    !!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
	if polygon_area(new_poly_1) < GEOMETRY_EPSILON or polygon_area(new_poly_2) < GEOMETRY_EPSILON:
		DEBUG.log("split_polygon: 0-area polygon detected, invalidated.")
		return []
	return [new_poly_1, new_poly_2]
	
## cuts the polygon, given a line, and keeps the half that contains the centroid of the original.
## [br][br]
## line_point, line_dir: point and direction of the line
func cut_polygon(line_point: Vector2, line_dir: Vector2) -> void:
	var centroid: Vector2 = POLYGON.CENTROID.lattice_position
	var polygon_verts = POLYGON.packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_point, line_dir)
	if new_polygons.size() == 0:
		DEBUG.log("cut_polygon: No new polygons found.")
		return
	# move cut_vfx to this position, rotate it to match this direction and hit play
	CUT_VFX.global_position = line_point * DEFAULTS.SCALING + DEFAULTS.OFFSET
	CUT_VFX.rotation = line_dir.angle()
	CUT_VFX.play()
	if Geometry2D.is_point_in_polygon(centroid, new_polygons[0]):
		POLYGON.rebuild_polygon(new_polygons[0])
	else:
		POLYGON.rebuild_polygon(new_polygons[1])

## returns true if a cut made with this line WOULD cut the polygon
## [br][br]
## line_point, line_dir: point and direction of the line
func would_cut_polygon(line_point: Vector2, line_dir: Vector2) -> bool:
	var polygon_verts = POLYGON.packed_vertices
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