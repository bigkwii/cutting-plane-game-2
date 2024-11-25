extends Node2D
## level editor scene. handles the logic of creation of new polygons. not to be confused with the editor game mode scene.

# - signals -
var open_menu

# - vars -
## dimensions of the lattice grid
var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## scaling factor for the lattice points
var SCALING: int = GLOBALS.DEFAULT_SCALING
## offset from the game origin to the grid origin
var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## maximum amount of vertices that can be placed
var MAX_VERTS: int = 50
## max_y for the lattice grid. from 4 to 10.
@export var level_max_y: int = 6:
	set(value):
		level_max_y = clamp(value, 4, 10)
		_set_lattice_grid_parameters(level_max_y)
## max_x for the lattice grid. gets set by _set_lattice_grid_parameters.
var level_max_x: int = -1
## vertices (in lattice coords)
@export var verts: Array[Vector2] = []
## color
@export var color: Color = Color(1, 1, 1)

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

# - child nodes -
@onready var VERTS = $verts
@onready var LATTICE_GRID = $lattice_grid
@onready var GUIDE_GRID = $guide_grid
@onready var POLYGON_EDITOR = $polygon_editor
@onready var CAMERA = $camera
@onready var INVALIDATE_CLICK_TIMER = $invalidate_click_timer
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/show_hull

# - preloaded scenes -
@onready var POLY_POINT_SCENE = preload("res://scenes/poly_point.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	if verts != []:
		for vert in verts:
			var poly_point = POLY_POINT_SCENE.instantiate()
			poly_point.position = vert * SCALING + OFFSET
			VERTS.add_child(poly_point)
		verts = []
		# open the menu
	_set_lattice_grid_parameters(level_max_y)

## called every frame
func _process(_delta):
	# mouse moving while dragging
	if dragging_vert:
		var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
		var actual_lattice_pos = clicked_lattice_pos.clamp(Vector2(0, 0), Vector2(level_max_x-1, level_max_y-1))
		vert_being_dragged.lattice_position = actual_lattice_pos
		vert_being_dragged.position = actual_lattice_pos * SCALING + OFFSET
	# handle hover
	_handle_hover()
	# update the polygon editor
	update_polygon_editor()

func _input(event):
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		# ignore inputs if paused
		if get_tree().paused:
			return
		# ignore UI
		if SHOW_HULL_BUTTON.get_global_rect().has_point(event.position):
			return
		# !!! add more !!!
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
	if clicked_lattice_pos.x < 0 or clicked_lattice_pos.x >= level_max_x or clicked_lattice_pos.y < 0 or clicked_lattice_pos.y >= level_max_y:
		return
	var poly_point = POLY_POINT_SCENE.instantiate()
	poly_point.lattice_position = clicked_lattice_pos
	poly_point.position = clicked_lattice_pos * SCALING + OFFSET
	poly_point.editable = true
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
	SCALING = int( window_size.y / max_y )
	# set offset such that the grid is centered
	OFFSET.y = int(SCALING * 0.5)
	# center the grid
	OFFSET.x = int( (window_size.x - SCALING * (max_x-1)) * 0.5 )
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

func update_polygon_editor():
	var packed_vertices = PackedVector2Array()
	for vert in VERTS.get_children():
		packed_vertices.append( vert.lattice_position )
	POLYGON_EDITOR.build_polygon(packed_vertices)
	POLYGON_EDITOR.queue_redraw()

# - signal callbacks -

func _on_invalidate_click_timer_timeout():
	invalidation_timer_timed_out = true

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_show_hull()

func _on_show_hull_button_up() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_idle()

func _on_camera_zoom_level_changed(zoom_level:float):
	GUIDE_GRID.update_alpha(zoom_level - 0.05) # -0.5 so the grid doesn't show up too early
