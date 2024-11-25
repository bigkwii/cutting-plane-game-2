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
## max_y for the lattice grid. from 4 to 10.
@export var level_max_y: int = 6:
	set(value):
		level_max_y = clamp(value, 4, 10)
		_set_lattice_grid_parameters(level_max_y)
## vertices (in lattice coords)
@export var verts: Array[Vector2] = []
## color
@export var color: Color = Color(1, 1, 1)

## the vert currently being dragged
var vert_being_dragged = null
## flag to determine when the player is dragging a vert
var dragging_vert = false
## flag to determine if the invalidation timer timed out
var invalidation_timer_timed_out: bool = false

# - child nodes -
@onready var VERTS = $verts
@onready var LATTICE_GRID = $lattice_grid
@onready var GUIDE_GRID = $guide_grid
@onready var POLYGON_EDITOR = $polygon_editor
@onready var CAMERA = $camera
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

func _process(_delta):
	# mouse moving while dragging
	if dragging_vert:
		var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
		vert_being_dragged.lattice_position = clicked_lattice_pos
		vert_being_dragged.position = clicked_lattice_pos * SCALING + OFFSET
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
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			DEBUG.log("level.gd: clicked @ lattice position %s" % clicked_lattice_pos)
			vert_being_dragged = try_to_add_point(clicked_lattice_pos)
			dragging_vert = vert_being_dragged != null
		# click RELEASED
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# if the player was dragging a vert, drop it at that position
			if dragging_vert:
				var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
				vert_being_dragged.lattice_position = clicked_lattice_pos
				vert_being_dragged.position = clicked_lattice_pos * SCALING + OFFSET
				vert_being_dragged = null
				dragging_vert = false
				return
			
## attempts to add a point at the clicked lattice position.  
## [br][br]
## If there's already a point there, it won't add a new one, and will instead return the existing point.
func try_to_add_point(clicked_lattice_pos: Vector2):
	# first, look if there's already a point there, whintin GLOBALS.EDIT_CLICK_RANGE
	for vert in VERTS.get_children():
		if vert.lattice_position.distance_to(clicked_lattice_pos) < GLOBALS.EDIT_CLICK_RANGE:
			DEBUG.log("level.gd: clicked on existing point, not adding.")
			return vert
	var poly_point = POLY_POINT_SCENE.instantiate()
	poly_point.lattice_position = clicked_lattice_pos
	poly_point.position = clicked_lattice_pos * SCALING + OFFSET
	poly_point.editable = true
	VERTS.add_child(poly_point)

func _set_lattice_grid_parameters(max_y: int):
	if max_y == -1:
		DEBUG.log("level.gd: max_y not given, defaulting.")
		return
	var window_size = get_viewport_rect().size
	var aspect_ratio = 4.0 / 3.0 # i like 4:3 for the grid, it leaves space for the hud
	# calculate max_x based on max_y and aspect ratio
	var max_x = int( max_y * aspect_ratio )
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
	DEBUG.log("Invalidation timer timed out!")

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_show_hull()

func _on_show_hull_button_up() -> void:
	POLYGON_EDITOR.CONVEX_INTEGER_HULL.play_idle()
