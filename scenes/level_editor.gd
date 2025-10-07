extends Node2D
## level editor scene. handles the logic of creation of new polygons. not to be confused with the editor game mode scene.

# - signals -
signal open_menu
signal play_level(data: Dictionary)

# - vars -
## dimensions of the lattice grid
var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## scaling factor for the lattice points
var SCALING: Vector2 = GLOBALS.DEFAULT_SCALING
## offset from the game origin to the grid origin
var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## maximum amount of vertices that can be placed
var MAX_VERTS: int = 50
## maximum amount of equations for creating a level with equations
var MAX_EQS: int = 16
## max_y for the lattice grid. from 4 to 10.
@export var level_max_y: int = 6:
	set(value):
		level_max_y = value
		_set_lattice_grid_parameters(level_max_y)
## max_x for the lattice grid. gets set by _set_lattice_grid_parameters.
var level_max_x: int = -1
## vertices (in lattice coords)
@export var initial_verts: Array[Vector2] = []
## color
@export var color: Color = Color(1, 0, 0)

## the vert currently being dragged
var vert_being_dragged = null
## flag to determine when the player is dragging a vert
var dragging_vert = false:
	set(value):
		dragging_vert = value
		CAMERA.can_drag = not value
## flag to determine if the player is dragging the camera with mouse 1
var is_m1_dragging: bool = false
## need to save the clicked position to differenciate between click and drag
var clicked_pos_at_drag_start: Vector2 = Vector2(0, 0)
## flag to determine if the invalidation timer timed out
var invalidation_timer_timed_out: bool = false
# equation input and validation vars
## global centroid for comparator
var __hpi_centroid = Vector2()
## big number for unbounded results
const HPI_BIG = 1e9

# - child nodes -
@onready var OPEN_MENU = $CanvasLayer/HUD/open_menu
@onready var PLAY_LEVEL_BUTTON = $CanvasLayer/HUD/VBoxContainer/play_level_button
@onready var VERTS = $verts
@onready var LATTICE_GRID = $lattice_grid
@onready var GUIDE_GRID = $guide_grid
@onready var POLYGON_EDITOR = $polygon_editor
@onready var CAMERA = $camera
@onready var INVALIDATE_CLICK_TIMER = $invalidate_click_timer
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/show_hull
@onready var COLOR_PICKER = $CanvasLayer/HUD/color_picker
## since COLOR_PICKER is rotated -90 degs, it's rect got a bit bugged. this container is a hacky way of ignoring the UI on _input
@onready var COLOR_PICKER_HITBOX = $CanvasLayer/HUD/color_picker_hitbox
@onready var VERT_COUNT_CONTAINER = $CanvasLayer/HUD/vert_count_container
@onready var VERT_COUNT_LABEL = $CanvasLayer/HUD/vert_count_container/vert_count_label
# - equation input stuff -
@onready var EQ_MENU = $CanvasLayer/EQ_MENU
@onready var EQ_LIST = $CanvasLayer/EQ_MENU/panel/EQS_CONTAINER/EQ_LIST
@onready var EQ_BUTTON = $CanvasLayer/HUD/VBoxContainer/equations_button
@onready var EQ_ADD_BTN = $CanvasLayer/EQ_MENU/panel/EQS_CONTAINER/EQ_LIST/add_eq_btn
@onready var EQ_ERR_MSG = $CanvasLayer/EQ_MENU/err_message
@onready var EQ_MAKE_LEVEL_BTN = $CanvasLayer/EQ_MENU/panel/make_level_btn

# - preloaded scenes -
@onready var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")
@onready var LEVEL_EDITOR_EQUATION_INPUT_SCENE = preload("res://scenes/level_editor_equation_input.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# add the initial verts, if there are any
	if initial_verts != []:
		for vert in initial_verts:
			var poly_point = POLY_POINT_SCENE.instantiate()
			poly_point.lattice_position = vert
			poly_point.editable = true
			poly_point.debug_label_visible = true
			VERTS.add_child(poly_point)
	COLOR_PICKER.color = color
	for vert in VERTS.get_children():
		vert.color = color
	POLYGON_EDITOR.color = color
	# start first eq del btn disabled
	EQ_LIST.get_child(0).disable_delete_btn()
	EQ_LIST.get_child(0).changed_input.connect(_on_eq_changed_input)
	EQ_LIST.get_child(0).eq_deleted.connect(_on_eq_deleted)
	_update_eq_list()

## called every frame
func _process(_delta):
	# mouse moving while dragging
	if dragging_vert:
		var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
		var actual_lattice_pos = clicked_lattice_pos.clamp(Vector2(0, 0), Vector2(level_max_x-1, level_max_y-1))
		vert_being_dragged.lattice_position = actual_lattice_pos
		vert_being_dragged.position = actual_lattice_pos * SCALING + OFFSET
		vert_being_dragged.DEBUG_LABEL.text = str(vert_being_dragged.lattice_position)
	# handle hover
	_handle_hover()
	# update the polygon editor
	update_polygon_editor()
	# update the vert count. it sucks that i have to place this here, but queue_free() isn't fast enough for me to put it inside try_to_drop_vert()
	update_vert_count()
	# update play level button
	update_play_level_button()

func _input(event):
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		# ignore inputs if paused
		if get_tree().paused:
			return
		# ignore UI (unless dragging a vert, then it's harmless)
		if not dragging_vert:
			if OPEN_MENU.get_global_rect().has_point(event.position):
				return
			if PLAY_LEVEL_BUTTON.get_global_rect().has_point(event.position):
				return
			if EQ_BUTTON.get_global_rect().has_point(event.position):
				return
			if SHOW_HULL_BUTTON.get_global_rect().has_point(event.position):
				return
			# commenting this out for now. by all accounts this should work, but the color picker being rotated is messing with the rect
			# if COLOR_PICKER.get_global_rect().has_point(event.position):
			# 	return
			# hacky way to ignore the color picker
			if COLOR_PICKER_HITBOX.get_global_rect().has_point(event.position):
				return
		# click PRESSED
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# - camera stuff -
			is_m1_dragging = true
			clicked_pos_at_drag_start = event.position
			# start the invalidation timer
			INVALIDATE_CLICK_TIMER.start()
			invalidation_timer_timed_out = false
			# - vert stuff -
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			vert_being_dragged = try_to_drag_vert(clicked_lattice_pos)
		# click RELEASED
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# - drop vert stuff -
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			# if the player was dragging a vert, drop it at that position
			if dragging_vert:
				try_to_drop_vert(clicked_lattice_pos)
			# - camera stuff -
			is_m1_dragging = false
			# if this happens, it was a drag and not a click (allow for some tolerance)
			if abs(event.position - clicked_pos_at_drag_start) > Vector2(GLOBALS.MOUSE_1_DRAG_EPSILON, GLOBALS.MOUSE_1_DRAG_EPSILON):
				return
			# invalidate click if using m1 to drag the camera
			if is_m1_dragging:
				return
			# invalidate click if the player took too long to release the click (this is to prevent accidental clicks)
			if invalidation_timer_timed_out:
				invalidation_timer_timed_out = false
				return
			# - add vert stuff -
			# attempt to add a new vert
			else:
				try_to_add_vert(clicked_lattice_pos)
			
## attempts to grab and drag a vert at the clicked lattice position.  
## [br][br]
## If no vert is in range, returns null.
func try_to_drag_vert(clicked_lattice_pos: Vector2):
	# first, look if there's already a vert there, whintin GLOBALS.EDIT_CLICK_RANGE
	for vert in VERTS.get_children():
		if vert.lattice_position.distance_to(clicked_lattice_pos) < GLOBALS.EDIT_CLICK_RANGE:
			dragging_vert = true
			return vert
	dragging_vert = false
	return null

## attempts to add a vert at the clicked lattice position.
## [br][br]
## If there are already MAX_VERTS, returns.
func try_to_add_vert(clicked_lattice_pos: Vector2) -> void:
	# don't add more than MAX_VERTS
	if VERTS.get_child_count() >= MAX_VERTS:
		DEBUG.log("level.gd: too many verts, not adding.")
		return
	# don't place verts too close to each other
	for vert in VERTS.get_children():
		if vert.lattice_position.distance_to(clicked_lattice_pos) < GLOBALS.EDIT_CLICK_RANGE:
			return
	# don't place verts out of bounds
	if clicked_lattice_pos.x < 0 or clicked_lattice_pos.x >= level_max_x-1 or clicked_lattice_pos.y < 0 or clicked_lattice_pos.y >= level_max_y-1:
		return
	var poly_point = POLY_POINT_SCENE.instantiate()
	poly_point.lattice_position = clicked_lattice_pos
	poly_point.SCALING = SCALING
	poly_point.position = clicked_lattice_pos * SCALING + OFFSET
	poly_point.editable = true
	poly_point.color = color
	poly_point.debug_label_visible = true
	VERTS.add_child(poly_point)

## attempts to drop a vert at the clicked lattice position.
func try_to_drop_vert(clicked_lattice_pos: Vector2) -> void:
	var actual_lattice_pos = clicked_lattice_pos.clamp(Vector2(0, 0), Vector2(level_max_x-1, level_max_y-1))
	vert_being_dragged.lattice_position = actual_lattice_pos
	vert_being_dragged.position = actual_lattice_pos * SCALING + OFFSET
	dragging_vert = false
	# if the vert was dropped on top of another vert (i.e: vert_being_dragged.lattice_position within GLOBALS.EDIT_CLICK_RANGE of vert.lattice_position), remove it
	for vert in VERTS.get_children():
		# skip self
		if vert == vert_being_dragged:
			continue
		if vert.lattice_position.distance_to(clicked_lattice_pos) < GLOBALS.EDIT_CLICK_RANGE:
			vert_being_dragged.queue_free()
			break
	return

## removes every vert immediatelly
func clear_verts():
	for vert in VERTS.get_children():
		vert.free()

## updates the vert count
func update_vert_count():
	VERT_COUNT_LABEL.text = str(VERTS.get_child_count()) + "/" + str(MAX_VERTS)

## updates the play level button
func update_play_level_button():
	PLAY_LEVEL_BUTTON.disabled = not POLYGON_EDITOR.validate_level()

## updates the verts such that the one being hovered is highlighted
func _handle_hover():
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING
	for vert in VERTS.get_children():
		if vert.lattice_position.distance_to(mouse_lattice_pos) < GLOBALS.EDIT_CLICK_RANGE:
			vert.hover = true
		else:
			vert.hover = false

func _set_lattice_grid_parameters(max_y: int):
	if max_y == -1:
		DEBUG.log("level.gd: max_y not given, defaulting.")
		return
	var window_size = get_viewport_rect().size
	var aspect_ratio = 4.0 / 3.0 # i like 4:3 for the grid, it leaves space for the hud
	# calculate max_x based on max_y and aspect ratio
	var max_x = int( max_y * aspect_ratio )
	level_max_x = max_x
	DIMENSIONS.y = max_y
	DIMENSIONS.x = max_x
	SCALING = Vector2(int( window_size.y / max_y ), -int( window_size.y / max_y ))
	# set offset such that the grid is centered
	OFFSET.y = int(SCALING.x * (max_y - 0.5))
	# center the grid
	OFFSET.x = int( (window_size.x - SCALING.x * (max_x-1)) * 0.5 )
	# set the lattice grid size
	LATTICE_GRID.DIMENSIONS = DIMENSIONS
	LATTICE_GRID.SCALING = SCALING
	LATTICE_GRID.OFFSET = OFFSET
	LATTICE_GRID.make_lattice_grid()
	# set the guide grid size
	GUIDE_GRID.DIMENSIONS = DIMENSIONS
	GUIDE_GRID.SCALING = SCALING
	GUIDE_GRID.OFFSET = OFFSET
	GUIDE_GRID.update_alpha(0.0)
	# set the polygon grid size
	POLYGON_EDITOR.SCALING = SCALING
	POLYGON_EDITOR.OFFSET = OFFSET
	# if there are verts, update them accordingly
	for vert in VERTS.get_children():
		vert.SCALING = SCALING
		vert.position = vert.lattice_position * SCALING + OFFSET

func update_polygon_editor():
	var packed_vertices = PackedVector2Array()
	for vert in VERTS.get_children():
		packed_vertices.append( vert.lattice_position )
	POLYGON_EDITOR.build_polygon(packed_vertices)
	POLYGON_EDITOR.queue_redraw()

## returns true if a point satisfies A*x + B*y <= C (line represented by [A,B,C])
func _inside(point, line) -> bool:
	var A = line[0]
	var B = line[1]
	var C = line[2]
	return A * point.x + B * point.y <= C + GLOBALS.GEOMETRY_EPSILON

# solve intersection of two infinite lines l1=[A1,B1,C1], l2=[A2,B2,C2]
# returns null if parallel, else Vector2
func _line_intersection_point(l1: Array, l2: Array):
	var A1 = l1[0]; var B1 = l1[1]; var C1 = l1[2]
	var A2 = l2[0]; var B2 = l2[1]; var C2 = l2[2]
	var det = A1 * B2 - A2 * B1
	if abs(det) < GLOBALS.GEOMETRY_EPSILON:
		return null
	var x = (C1 * B2 - C2 * B1) / det
	var y = (A1 * C2 - A2 * C1) / det
	return Vector2(x, y)

# True if point satisfies ALL half-planes (with small epsilon)
func _satisfies_all(point: Vector2, lines: Array) -> bool:
	for line in lines:
		if line.size() < 3:
			continue
		var A = line[0]; var B = line[1]; var C = line[2]
		if A * point.x + B * point.y > C + GLOBALS.GEOMETRY_EPSILON:
			return false
	return true

## deduplicate points by distance threshold
func _dedup_points(points: Array, tol: float) -> Array:
	var uniq: Array = []
	for p in points:
		var found = false
		for q in uniq:
			if p.distance_to(q) < tol:
				found = true
				break
		if not found:
			uniq.append(p)
	return uniq

## comparator for angle sort
func _angle_compare(a, b):
	var ca = atan2(a.y - __hpi_centroid.y, a.x - __hpi_centroid.x)
	var cb = atan2(b.y - __hpi_centroid.y, b.x - __hpi_centroid.x)
	if ca < cb:
		return -1
	elif ca > cb:
		return 1
	return 0

## sort points CCW around centroid
func _sort_ccw(points: Array) -> Array:
	__hpi_centroid = Vector2(0, 0)
	for p in points:
		__hpi_centroid += p
	__hpi_centroid /= float(points.size())
	points.sort_custom(_angle_compare)
	return points

## Compute polygon from lines via pairwise intersections
## [br][br]
## returns [verts: Array[Vector2], err_mgs: String]
func _polygon_from_lines(lines: Array) -> Array:
	if lines == []:
		return [[], "[ERROR] No lines given."]
	# 1) collect all pairwise intersections
	var cand: Array = []
	for i in range(lines.size()):
		for j in range(i + 1, lines.size()):
			var p = _line_intersection_point(lines[i], lines[j])
			if p == null:
				continue
			if abs(p.x) > HPI_BIG or abs(p.y) > HPI_BIG:
				continue
			cand.append(p)
	# 2) filter by all inequalities
	var feasible: Array = []
	for p in cand:
		if _satisfies_all(p, lines):
			feasible.append(p)
	if feasible == []:
		return [[], "[ERROR] No feasable vertices."]
	# 3) dedup
	feasible = _dedup_points(feasible, GLOBALS.EDIT_CLICK_RANGE)
	if feasible.size() < 3:
		return [[], "[ERROR] Polygon has less than 3 vertices (or they may be too close)."]
	# 4) order CCW
	feasible = _sort_ccw(feasible)
	# 5) sanity checks
	for p in feasible:
		if abs(p.x) > HPI_BIG or abs(p.y) > HPI_BIG:
			return [[], "[ERROR] Polygon isn't closed."]
	for i in range(feasible.size()):
		feasible[i] = feasible[i].snapped(Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON))
	return [feasible, ""]


## returns [valid: bool, error_msg: String, verts: Array[Vector2]]
func validate_eqs() -> Array:
	var verts: Array = []
	# check for invalid line eqs
	for idx in range(EQ_LIST.get_child_count() - 1):
		var eq = EQ_LIST.get_child(idx)
		# ignore eqs that were queue_free'd (they are going to be deleted at the and of this frame)
		if eq.is_queued_for_deletion():
			continue
		if eq.A == 0.0 and eq.B == 0.0 and eq.C == 0.0:
			return [false, "[WARNING] @ equation %s: A, B and C can't all be zero." % [idx + 1], []]
		if eq.A == 0.0 and eq.B == 0.0:
			return [false, "[WARNING] @ equation %s: A and B can't both be zero." % [idx + 1], []]
	# get line eqs
	var eqs: Array[Array] = []
	for idx in range(EQ_LIST.get_child_count() - 1):
		var eq = EQ_LIST.get_child(idx)
		# ignore eqs that were queue_free'd (they are going to be deleted at the and of this frame)
		if eq.is_queued_for_deletion():
			continue
		eqs.append([eq.A, eq.B, eq.C])
	# try to make polygon from lines
	var poly_res = _polygon_from_lines(eqs)
	verts = poly_res[0]
	var err_mgs = poly_res[1]
	if verts == []:
		return [false, err_mgs, verts]
	# don't go over MAX_VERTS
	if len(verts) + VERTS.get_child_count() > MAX_VERTS:
		return [false, "[ERROR] Adding this many vertices: %s would go over the maximum." % [len(verts)], verts]
	# check for out of bound verts
	for vert in verts:
		var out_of_bound_verts = []
		if vert.x < 0 or vert.x >= level_max_x-1 or vert.y < 0 or vert.y >= level_max_y-1:
			out_of_bound_verts.append(vert)
		if out_of_bound_verts != []:
			return [false, "[ERROR] Out of bound vertices: %s (Maybe try resizing the editor?)" % [out_of_bound_verts], verts]
	return [true, "", verts]

func _update_eq_list():
	var validation_result = validate_eqs()
	EQ_ERR_MSG.text = validation_result[1]
	if validation_result[0]:
		EQ_MAKE_LEVEL_BTN.disabled = false
	else:
		EQ_MAKE_LEVEL_BTN.disabled = true

# - signal callbacks -

func _on_invalidate_click_timer_timeout():
	invalidation_timer_timed_out = true

func _on_eq_changed_input():
	var eq_count: int = EQ_LIST.get_child_count() - 1
	if eq_count > 1:
		EQ_LIST.get_child(0).enable_delete_btn()
	if eq_count > MAX_EQS - 1:
		EQ_ADD_BTN.disabled = true
	else:
		EQ_ADD_BTN.disabled = false
	_update_eq_list()

func _on_eq_deleted():
	DEBUG.log("level_editor.on_eq_deleted: eq deleted, updating...")
	var eq_count: int = EQ_LIST.get_child_count() - 1
	if eq_count == 2:
		EQ_LIST.get_child(0).disable_delete_btn()
		EQ_LIST.get_child(1).disable_delete_btn()
	else:
		EQ_LIST.get_child(0).enable_delete_btn()
		EQ_LIST.get_child(1).enable_delete_btn()
	if eq_count > MAX_EQS:
		EQ_ADD_BTN.disabled = true
	else:
		EQ_ADD_BTN.disabled = false
	_update_eq_list()

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_show_hull()

func _on_show_hull_button_up() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_idle()

func _on_camera_zoom_level_changed(zoom_level:float):
	GUIDE_GRID.update_alpha(zoom_level - 0.05) # -0.5 so the grid doesn't show up too early

func _on_open_menu_pressed():
	open_menu.emit()

func _on_color_picker_color_changed(new_color: Color):
	color = new_color
	for vert in VERTS.get_children():
		vert.color = color
	POLYGON_EDITOR.color = color

func _on_play_level_button_pressed():
	if POLYGON_EDITOR.validate_level() == false:
		DEBUG.log("level.gd: level is invalid, not playing.")
		return
	var packed_vertices: PackedVector2Array = POLYGON_EDITOR.convex_hull
	var initial_vertices: Array[Array] = []
	for vert in packed_vertices: # need to convert to an array of arrays
		initial_vertices.append( [vert.x, vert.y] )
	var data: Dictionary = {
		"name": "Playing Level",
		"max_y": level_max_y,
		"poly_color": "#" + color.to_html(false),
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : initial_vertices
	}
	play_level.emit(data)

func _on_equations_button_pressed():
	EQ_MENU.visible = true
	get_tree().paused = true
	_update_eq_list()

func _on_eq_x_pressed():
	EQ_MENU.visible = false
	get_tree().paused = false

func _on_add_eq_btn_pressed():
	var new_eq = LEVEL_EDITOR_EQUATION_INPUT_SCENE.instantiate()
	EQ_LIST.add_child(new_eq)
	EQ_LIST.move_child(new_eq, EQ_LIST.get_child_count() - 2) # ...why can't i add a child at a given index?
	new_eq.changed_input.connect(_on_eq_changed_input)
	new_eq.eq_deleted.connect(_on_eq_deleted)
	_on_eq_changed_input()

func _on_make_level_btn_pressed():
	var verts = []
	var validation_results = validate_eqs()
	if validation_results[0]:
		verts = validation_results[2]
		for vert in verts:
			try_to_add_vert(vert)
	EQ_MENU.visible = false
	get_tree().paused = false
