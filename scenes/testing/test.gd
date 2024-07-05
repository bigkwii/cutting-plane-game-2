extends Node2D

# -- vars --
## epsilon for snapping to grid
var CLICK_EPSILON = 0.01
## epsilon for geometric calculations
var GEOMETRY_EPSILON = 0.00001

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var POLYGON = $polygon
@onready var CAMERA = $Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _input(event):
	# reload scene if reset input is pressed
	if event.is_action_pressed("reset"):
		DEBUG.log("Reloading scene...")
		get_tree().reload_current_scene()
	if event.is_action_pressed("mouse1"):
		if event.pressed:
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - DEFAULTS.OFFSET) / DEFAULTS.SCALING , Vector2(CLICK_EPSILON, CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			# split the polygon at the given position and at a hard-coded direction
			cut_polygon(Vector2(clicked_lattice_pos.x, clicked_lattice_pos.y), Vector2(1,1))
		
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
## line_start, line_end: start and end points of the line segment
func is_point_above_line(point: Vector2, line_point: Vector2, line_dir: Vector2) -> bool:
	return (line_dir.x) * (point.y - line_point.y) > (line_dir.y) * (point.x - line_point.x)

## splits a polygon in two halves given a line
## [br][br]
## polygon: PackedVector2Array the polygon to be split
## line_start, line_end: start and end points of the line
## [br][br]
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!! TODO: this function is kinda ugly and probably does a bunch of unnecesaary stuff.    !!!
## !!! Plus: it should be in the polygon.gd script. Same goes for the cut_polygon function. !!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
func split_polygon(polygon: PackedVector2Array, line_point: Vector2, line_dir: Vector2) -> Array:
	var new_poly_1 = PackedVector2Array()
	var new_poly_2 = PackedVector2Array()
	var intersection_points = []
	for i in range(polygon.size()):
		var start_point = polygon[i]
		var end_point = polygon[(i + 1) % polygon.size()]
		var intersection = line_intersects_segment(line_point, line_dir, start_point, end_point)
		if intersection:
			intersection_points.append(intersection)
	if intersection_points.size() == 0 or intersection_points.size() % 2 != 0: # TODO: not sure about the 2nd condition
		DEBUG.log("split_polygon: Invalid number of intersection points: %s" % intersection_points.size())
		return []
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
	return [new_poly_1, new_poly_2]
	
## cuts the polygon, given a line, and keeps the half that contains the centroid of the original.
## [br][br]
## line_start, line_end: start and end points of the line
func cut_polygon(line_start: Vector2, line_end: Vector2) -> void:
	var centroid: Vector2 = POLYGON.CENTROID.lattice_position
	var polygon_verts = POLYGON.packed_vertices
	var new_polygons = split_polygon(polygon_verts, line_start, line_end)
	if new_polygons.size() == 0:
		DEBUG.log("cut_polygon: No new polygons found.")
		return
	if Geometry2D.is_point_in_polygon(centroid, new_polygons[0]):
		POLYGON.rebuild_polygon(new_polygons[0])
	else:
		POLYGON.rebuild_polygon(new_polygons[1])


# -- camera stuff --
