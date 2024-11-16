extends Node2D
## level scene. handles loading things and game logic.

# -- consts --
## levels directory
var LEVELS_DIR = "res://levels/"
## default level file
var DEFAULT_LEVEL_PATH = "res://levels/default.json"

# -- signals --
signal level_completed
signal cut_made(score: int)
signal open_menu

# -- vars --
## infinite budget flag (for freeplay)
@export var INFINITE_BUDGET: bool = false
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
var cut_mode = CUT_MODES.CIRCLE_CUT
# cut budgets (-1 means infinite)
var circle_cut_budget = -1
var gomory_cut_budget = -1
var split_cut_budget = -1 # both h and v
## score for this level
var score = 0
# - debug -
var debug_cut_direction = Vector2(1, 0)

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var GUIDE_GRID = $guide_grid
@onready var POLYGON = $polygon
@onready var CAMERA = $camera
# @onready var CLICK_VFXS = $vfx/click_vfxs # moved to game scene
# - hud elements -
@onready var HUD = $CanvasLayer/HUD
@onready var NAME_LABEL = $CanvasLayer/HUD/name_label
@onready var BUTTONS_CONTAINER = $CanvasLayer/HUD/cut_buttons
@onready var OPEN_MENU = $CanvasLayer/HUD/open_menu
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/show_hull
@onready var CIRCLE_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/circle
@onready var GOMORY_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/gomory
@onready var H_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/h_split
@onready var V_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/v_split
# - proloaded scenes -
# @onready var CLICK_VFX = preload("res://scenes/click_vfx.tscn") # moved to game scene
# - debug cut button and input -
@onready var DEBUG_CONTAINER = $CanvasLayer/HUD/debug_buttons
@onready var DEBUG_CUT_BUTTON = $CanvasLayer/HUD/debug_buttons/debug_cut
@onready var DEBUG_CUT_INPUT = $CanvasLayer/HUD/debug_buttons/debug_cut_input

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
	# - DATA ASSIGNMENT -
	level_name = parsed_data["name"] if parsed_data.has("name") else "!!! NO NAME !!!"
	NAME_LABEL.text = level_name
	# SET GRID SIZE
	var max_y = parsed_data["max_y"] if parsed_data.has("max_y") else -1
	_set_lattice_grid_parameters(max_y)
	var level_color: Color = Color(parsed_data["poly_color"]) if parsed_data.has("poly_color") else GLOBALS.DEFAULT_COLOR
	var level_vertices : Array[Vector2] = []
	for vert in parsed_data["poly_vertices"]:
		level_vertices.append(Vector2(vert[0], vert[1]))
	# SET POLY DATA
	POLYGON.color = level_color
	POLYGON.initial_vertices = level_vertices
	POLYGON.build_polygon()
	# SET CUT BUDGETS (except for free play, where they're infinite)
	if not INFINITE_BUDGET:
		circle_cut_budget = parsed_data["circle_budget"] if parsed_data.has("circle_budget") else -1
		gomory_cut_budget = parsed_data["gomory_budget"] if parsed_data.has("gomory_budget") else -1
		split_cut_budget = parsed_data["split_budget"] if parsed_data.has("split_budget") else -1
		# update buttons accordingly
		CIRCLE_CUT_BUTTON.budget = circle_cut_budget
		GOMORY_CUT_BUTTON.budget = gomory_cut_budget
		H_SPLIT_CUT_BUTTON.budget = split_cut_budget
		V_SPLIT_CUT_BUTTON.budget = split_cut_budget
	# DEFAULT SELECTED CUT
	CIRCLE_CUT_BUTTON.selected = true
	# ONLY SHOW DEBUG CUT IF DEBUG IS ENABLED!
	DEBUG_CONTAINER.visible = DEBUG_CONTAINER.visible and DEBUG.is_enabled()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_handle_gomory_cut_hover()

# handle inputs here! not in _process!
func _input(event):
	if event.is_action_pressed("esc"):
		_on_open_menu_pressed()
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not is_cutting: # not event.pressed = released
			# ignore UI
			if CIRCLE_CUT_BUTTON.get_global_rect().has_point(event.position):
				return
			if GOMORY_CUT_BUTTON.get_global_rect().has_point(event.position):
				return
			if H_SPLIT_CUT_BUTTON.get_global_rect().has_point(event.position):
				return
			if V_SPLIT_CUT_BUTTON.get_global_rect().has_point(event.position):
				return
			if OPEN_MENU.get_global_rect().has_point(event.position): # consider moving this one to a higher scene
				return
			if DEBUG.is_enabled() and DEBUG_CONTAINER.get_global_rect().has_point(event.position):
				return
			if SHOW_HULL_BUTTON.get_global_rect().has_point(event.position):
				return
			# play click vfx
			# _play_click_vfx(get_global_mouse_position()) # moved to game scene
			# get the clicked lattice position
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			if cut_mode == CUT_MODES.DEBUG_CUT and DEBUG.is_enabled():
				# split the polygon at the given position and at a hard-coded direction
				POLYGON.cut_polygon(clicked_lattice_pos, debug_cut_direction, true)
			# !!! TODO !!! in the demo, cut animations can be cancelled early, with the cut being made at that point
			# should this be implemented as well? or should clicking be disabled during the animation?
			# !!! THINK ABOUT IT !!!
			# these awaits are temporary, until animation cancelling is implemented.
			# once it is, it should await a signal instead of the function call. something like "cut_finished"
			# NOTE: animation cancelling is pretty useless. i'll leave these comments here for now, but i think this feature is better off scrapped
			elif cut_mode == CUT_MODES.CIRCLE_CUT and circle_cut_budget != 0:
				is_cutting = true
				await POLYGON.circle_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.H_SPLIT_CUT and split_cut_budget != 0:
				is_cutting = true
				await POLYGON.h_split_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.V_SPLIT_CUT and split_cut_budget != 0:
				is_cutting = true
				await POLYGON.v_split_cut(clicked_lattice_pos)
				is_cutting = false
			elif cut_mode == CUT_MODES.GOMORY_CUT and gomory_cut_budget != 0: # gomory cut is handled differently
				is_cutting = true
				_handle_gomory_cut_click()
				is_cutting = false
			else: # if somehow, no cut mode is selected
				DEBUG.log("No cut mode selected!")

# -- layout functions --
## called when calculating the lattice grid size. determines the layout constants based on window size and level data
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
	POLYGON.SCALING = SCALING
	POLYGON.OFFSET = OFFSET

## unselects all cut buttons
func _unselect_all_cut_buttons():
	CIRCLE_CUT_BUTTON.selected = false
	GOMORY_CUT_BUTTON.selected = false
	H_SPLIT_CUT_BUTTON.selected = false
	V_SPLIT_CUT_BUTTON.selected = false
	DEBUG_CUT_BUTTON.selected = false

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down():
	POLYGON.CONVEX_INTEGER_HULL.play_show_hull()

func _on_show_hull_button_up():
	POLYGON.CONVEX_INTEGER_HULL.play_idle()

# when the debug cut button is PRESSED, set the cut mode to DEBUG_CUT
func _on_debug_cut_pressed():
	cut_mode = CUT_MODES.DEBUG_CUT
	_unselect_all_cut_buttons()
	DEBUG_CUT_BUTTON.selected = true
	DEBUG.log("DEBUG_CUT selected")
	_handle_gomory_cut_selected(false)

# updates the debug cut angle when the input text changes
func _on_debug_cut_input_text_changed(new_text:String):
	var degrees = float(new_text) # if the angle is invalid, it will be 0
	debug_cut_direction = Vector2(cos(deg_to_rad(degrees)), -sin(deg_to_rad(degrees)))

# when the circle cut button is PRESSED, set the cut mode to CIRCLE_CUT
func _on_circle_pressed():
	if circle_cut_budget == 0:
		DEBUG.log("Circle cut budget is 0!")
		return
	cut_mode = CUT_MODES.CIRCLE_CUT
	_unselect_all_cut_buttons()
	CIRCLE_CUT_BUTTON.selected = true
	DEBUG.log("CIRCLE_CUT selected")
	_handle_gomory_cut_selected(false)

# when the gomory cut button is PRESSED, set the cut mode to GOMORY_CUT
func _on_gomory_pressed():
	if gomory_cut_budget == 0:
		DEBUG.log("Gomory cut budget is 0!")
		return
	# Note: this one has to change the polygon such that the vertices are clickable
	cut_mode = CUT_MODES.GOMORY_CUT
	_unselect_all_cut_buttons()
	GOMORY_CUT_BUTTON.selected = true
	DEBUG.log("GOMORY_CUT selected")
	_handle_gomory_cut_selected(true)

# when the h split cut button is PRESSED, set the cut mode to H_SPLIT_CUT
func _on_h_split_pressed():
	if split_cut_budget == 0:
		DEBUG.log("H/V split cut budget is 0!")
		return
	cut_mode = CUT_MODES.H_SPLIT_CUT
	_unselect_all_cut_buttons()
	H_SPLIT_CUT_BUTTON.selected = true
	DEBUG.log("H_SPLIT_CUT selected")
	_handle_gomory_cut_selected(false)

# when the v split cut button is PRESSED, set the cut mode to V_SPLIT_CUT
func _on_v_split_pressed():
	if split_cut_budget == 0:
		DEBUG.log("H/V split cut budget is 0!")
		return
	cut_mode = CUT_MODES.V_SPLIT_CUT
	_unselect_all_cut_buttons()
	V_SPLIT_CUT_BUTTON.selected = true
	DEBUG.log("V_SPLIT_CUT selected")
	_handle_gomory_cut_selected(false)

# -- gomory cut mode vfx handling --
# TODO: These function names SUCK

## call with true when selecting gomory cut, call with false when any other cut is selected
func _handle_gomory_cut_selected(make_clickable: bool): # TODO: AFTER A CUT, THE EFFECT DISSAPEARS! (solved in a hacky way)
	POLYGON.gomory_mode_selected(make_clickable)

## call in process. updates the mouse position for hover vfx
func _handle_gomory_cut_hover():
	if cut_mode != CUT_MODES.GOMORY_CUT:
		return
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING
	POLYGON.update_verts_hover_vfx(mouse_lattice_pos)

## function to handle the gomory cut click interaction. the polygon scene is responsible of validating this click
func _handle_gomory_cut_click():
	if cut_mode != CUT_MODES.GOMORY_CUT: # prob unneccesary
		return
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING
	await POLYGON.gomory_cut(mouse_lattice_pos)

# click vfx
# func _play_click_vfx(pos: Vector2):
# 	var click_vfx = CLICK_VFX.instantiate()
# 	CLICK_VFXS.add_child(click_vfx)
# 	click_vfx.position = pos
# 	click_vfx.play_click()

func _on_open_menu_pressed():
	open_menu.emit()

func _on_camera_zoom_level_changed(zoom_level:float):
	GUIDE_GRID.update_alpha(zoom_level - 0.25) # -0.25 so the grid doesn't show up too early
