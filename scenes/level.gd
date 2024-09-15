extends Node2D
## level scene. handles loading things and game logic.

# -- consts --
## levels directory
var LEVELS_DIR = "res://levels/"
## default level file
var DEFAULT_LEVEL_PATH = "res://levels/default.json"

# -- vars --
## dimensions of the lattice grid
@export var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## scaling factor for the lattice points
@export var SCALING: int = GLOBALS.DEFAULT_SCALING
## offset from the game origin to the grid origin
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## selected level
@export_file("*.json") var level_json_path: String = "res://levels/default.json" # so it shows up on editor
## level name
var level_name: String
## determines if a cut is currently being made
var is_cutting = false
# - cut mode stuff -
enum CUT_MODES { DEBUG_CUT, CIRCLE_CUT, GOMORY_CUT, H_SPLIT_CUT, V_SPLIT_CUT }
var cut_mode = CUT_MODES.DEBUG_CUT
# - debug -
var debug_cut_direction = Vector2(1, 0)

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var POLYGON = $polygon
@onready var CAMERA = $camera
@onready var CLICK_VFXS = $vfx/click_vfxs
# - hud elements -
@onready var HUD = $CanvasLayer/HUD
@onready var BUTTONS_CONTAINER = $CanvasLayer/HUD/buttons
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/buttons/show_hull
@onready var CIRCLE_CUT_BUTTON = $CanvasLayer/HUD/buttons/circle
@onready var GOMORY_CUT_BUTTON = $CanvasLayer/HUD/buttons/gomory
@onready var H_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/buttons/h_split
@onready var V_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/buttons/v_split
# - proloaded scenes -
@onready var CLICK_VFX = preload("res://scenes/click_vfx.tscn")
# - debug cut button and input -
@onready var DEBUG_CUT_BUTTON = $CanvasLayer/HUD/buttons/debug_cut
@onready var DEBUG_CUT_INPUT = $CanvasLayer/HUD/buttons/debug_cut_input

# Called when the node enters the scene tree for the first time.
func _ready(): # TODO: messy. separate these into functions
	# load level
	# if something goes wrong with the given path, load default
	if not FileAccess.file_exists(level_json_path):
		DEBUG.log("Level file not found: '%s', loading default..." % level_json_path)
		level_json_path = DEFAULT_LEVEL_PATH
	# load and parse level data
	var file_data = FileAccess.open(level_json_path, FileAccess.READ)
	if file_data.get_error():
		DEBUG.log("level.gd: Error opening %s" % level_json_path)
		return
	DEBUG.log("level.gd: Opened %s" % level_json_path)
	var parsed_data = JSON.parse_string(file_data.get_as_text())
	# - assign data -
	level_name = parsed_data["name"] if parsed_data.has("name") else "!!! NO NAME !!!"
	# set lattice grid size
	var max_y = parsed_data["max_y"] if parsed_data.has("max_y") else -1
	_set_lattice_grid_parameters(max_y)
	var level_color: Color = Color(parsed_data["poly_color"]) if parsed_data.has("poly_color") else GLOBALS.DEFAULT_COLOR
	var level_vertices : Array[Vector2] = []
	for vert in parsed_data["poly_vertices"]:
		level_vertices.append(Vector2(vert[0], vert[1]))
	POLYGON.color = level_color
	POLYGON.initial_vertices = level_vertices
	POLYGON.build_polygon()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_handle_gomory_cut_hover()

# handle inputs here! not in _process!
func _input(event):
	# reload scene if reset input is pressed
	if event.is_action_pressed("reset"):
		DEBUG.log("Reloading scene...")
		get_tree().reload_current_scene()
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not is_cutting: # not event.pressed = released
			# if on the show hull button, do nothing
			if BUTTONS_CONTAINER.get_global_rect().has_point(event.position): # !!! TODO !!!: this is hacky, i don't like it, figure out a cleaner way
				return
			# play click vfx
			_play_click_vfx(get_global_mouse_position())
			# get the clicked lattice position
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			if cut_mode == CUT_MODES.DEBUG_CUT:
				# split the polygon at the given position and at a hard-coded direction
				POLYGON.cut_polygon(clicked_lattice_pos, debug_cut_direction, true)
			# !!! TODO !!! in the demo, cut animations can be cancelled early, with the cut being made at that point
			# should this be implemented as well? or should clicking be disabled during the animation?
			# !!! THINK ABOUT IT !!!
			# these awaits are temporary, until animation cancelling is implemented.
			# once it is, it should await a signal instead of the function call. something like "cut_finished"
			elif cut_mode == CUT_MODES.CIRCLE_CUT:
				is_cutting = true
				await POLYGON.circle_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.H_SPLIT_CUT:
				is_cutting = true
				await POLYGON.h_split_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.V_SPLIT_CUT:
				is_cutting = true
				await POLYGON.v_split_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.GOMORY_CUT:
				_handle_gomory_cut_click()

# -- layout functions --
## called when calculating the lattice grid size. determines the layout constants based on window size and level data
func _set_lattice_grid_parameters(max_y: int):
	if max_y == -1:
		DEBUG.log("level.gd: max_y not given, defaulting.")
		return
	var window_size = get_viewport_rect().size
	DEBUG.log("level.gd: window_size: %s" % window_size, 100)
	var aspect_ratio = window_size.x / window_size.y
	DEBUG.log("level.gd: aspect_ratio: %s" % aspect_ratio, 100)
	# calculate max_x based on max_y and aspect ratio
	var max_x = int( max_y * aspect_ratio )
	DIMENSIONS.y = max_y
	DIMENSIONS.x = max_x
	DEBUG.log("level.gd: Calculated lattice grid size: %s" % DIMENSIONS, 100)
	SCALING = int( window_size.y / (max_y) )
	DEBUG.log("level.gd: Calculated scaling: %s" % SCALING, 100)
	# set offset such that the grid is centered
	OFFSET.y = int(SCALING * 0.5)
	# center the grid
	OFFSET.x = int( (window_size.x - (SCALING * max_x)) )
	DEBUG.log("level.gd: Calculated offset: %s" % OFFSET, 100)
	# set the lattice grid size
	LATTICE_GRID.DIMENSIONS = DIMENSIONS
	LATTICE_GRID.SCALING = SCALING
	LATTICE_GRID.OFFSET = OFFSET
	LATTICE_GRID.make_lattice_grid()
	# set the polygon grid size
	POLYGON.SCALING = SCALING
	POLYGON.OFFSET = OFFSET

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down():
	POLYGON.CONVEX_INTEGER_HULL.visible = true

func _on_show_hull_button_up():
	POLYGON.CONVEX_INTEGER_HULL.visible = false

# when the debug cut button is PRESSED, set the cut mode to DEBUG_CUT
func _on_debug_cut_pressed():
	cut_mode = CUT_MODES.DEBUG_CUT
	DEBUG.log("DEBUG_CUT selected")
	_handle_gomory_cut_selected(false)

# updates the debug cut angle when the input text changes
func _on_debug_cut_input_text_changed(new_text:String):
	var degrees = float(new_text) # if the angle is invalid, it will be 0
	debug_cut_direction = Vector2(cos(deg_to_rad(degrees)), -sin(deg_to_rad(degrees)))

# when the circle cut button is PRESSED, set the cut mode to CIRCLE_CUT
func _on_circle_pressed():
	cut_mode = CUT_MODES.CIRCLE_CUT
	DEBUG.log("CIRCLE_CUT selected")
	_handle_gomory_cut_selected(false)

# when the gomory cut button is PRESSED, set the cut mode to GOMORY_CUT
func _on_gomory_pressed():
	# Note: this one has to change the polygon such that the vertices are clickable
	cut_mode = CUT_MODES.GOMORY_CUT
	DEBUG.log("GOMORY_CUT selected")
	_handle_gomory_cut_selected(true)

# when the h split cut button is PRESSED, set the cut mode to H_SPLIT_CUT
func _on_h_split_pressed():
	cut_mode = CUT_MODES.H_SPLIT_CUT
	DEBUG.log("H_SPLIT_CUT selected")
	_handle_gomory_cut_selected(false)

# when the v split cut button is PRESSED, set the cut mode to V_SPLIT_CUT
func _on_v_split_pressed():
	cut_mode = CUT_MODES.V_SPLIT_CUT
	DEBUG.log("V_SPLIT_CUT selected")
	_handle_gomory_cut_selected(false)

# -- gomory cut mode vfx handling --
# TODO: These function names SUCK

## call with true when selecting gomory cut, call with false when any other cut is selected
func _handle_gomory_cut_selected(make_clickable: bool): # TODO: AFTER A CUT, THE EFFECT DISSAPEARS!
	POLYGON.gomory_mode_selected(make_clickable)

## call in process. updates the mouse position for hover vfx
func _handle_gomory_cut_hover():
	if cut_mode != CUT_MODES.GOMORY_CUT:
		return
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING # TODO: these should be read from the level file
	POLYGON.update_verts_hover_vfx(mouse_lattice_pos)

func _handle_gomory_cut_click():
	if cut_mode != CUT_MODES.GOMORY_CUT: # prob unneccesary
		return
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING # TODO: these should be read from the level file
	POLYGON.gomory_cut(mouse_lattice_pos)

# click vfx
func _play_click_vfx(pos: Vector2):
	var click_vfx = CLICK_VFX.instantiate()
	CLICK_VFXS.add_child(click_vfx)
	click_vfx.position = pos
	click_vfx.play_click()
