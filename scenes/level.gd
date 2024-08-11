extends Node2D
## level scene. handles loading things and game logic.

# -- vars --
## selected level
@export var level_json_filename: String
## level name
var level_name: String
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
	# if no level is given, load the default level
	if level_json_filename == "":
		level_json_filename = GLOBALS.DEFAULT_LEVEL
	var level_json_path = GLOBALS.LEVELS_DIR + level_json_filename + ".json"
	# if there's a problem with the level file, return
	if not FileAccess.file_exists(level_json_path):
		DEBUG.log("Level file not found: %s" % level_json_path)
		return
	# load and parse level data
	var file_data = FileAccess.open(level_json_path, FileAccess.READ)
	var parsed_data = JSON.parse_string(file_data.get_as_text())
	# assign data
	level_name = parsed_data["name"]
	var level_color: Color = Color(parsed_data["poly_color"])
	var level_vertices : Array[Vector2] = []
	for vert in parsed_data["poly_vertices"]:
		level_vertices.append(Vector2(vert[0], vert[1]))
	POLYGON.color = level_color
	POLYGON.initial_vertices = level_vertices
	POLYGON.build_polygon()
	
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
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - GLOBALS.DEFAULT_OFFSET) / GLOBALS.DEFAULT_SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			if cut_mode == CUT_MODES.DEBUG_CUT:
				# split the polygon at the given position and at a hard-coded direction
				POLYGON.cut_polygon(clicked_lattice_pos, debug_cut_direction)
			elif cut_mode == CUT_MODES.CIRCLE_CUT:
				POLYGON.circle_cut(clicked_lattice_pos)
			elif cut_mode == CUT_MODES.H_SPLIT_CUT:
				POLYGON.h_split_cut(clicked_lattice_pos)
			elif cut_mode == CUT_MODES.V_SPLIT_CUT:
				POLYGON.v_split_cut(clicked_lattice_pos)
		
