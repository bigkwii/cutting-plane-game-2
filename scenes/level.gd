extends Node2D
## level scene. handles loading things and game logic.

# -- consts --
## levels directory
var LEVELS_DIR = "res://levels/"
## default level file
var DEFAULT_LEVEL_PATH = "res://levels/default.json"

# -- signals --
## emitted when the level is determined to be completed
## [br][br]
## args:
## [br]rank: level rank
## [br]bonus_score: the corresponding bonus score for the rank
## [br]remaining_circle: remaining circle cut budget
## [br]remaining_gomory: remaining gomory cut budget
## [br]remaining_split: remaining split cut budget
signal level_completed(rank: String, rank_bonus: int, budget_bonus: int, remaining_circle: int, remaining_gomory: int, remaining_split: int)
## emitted when a cut is made
## [br][br]
## args:
## [br]score: the score for this level
signal cut_made(score: int)
## emitted when the user wants to open the menu
signal open_menu

# -- vars --
## determines whether to load level from file or from a dictionary
@export var LOAD_FROM_FILE: bool = true
## infinite budget flag (for freeplay)
@export var INFINITE_BUDGET: bool = false
## dimensions of the lattice grid
@export var DIMENSIONS: Vector2 = GLOBALS.DEFAULT_DIMENSIONS
## scaling factor for the lattice points
@export var SCALING: Vector2 = GLOBALS.DEFAULT_SCALING
## offset from the game origin to the grid origin
@export var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET
## selected level, if loading from file
@export_file("*.json") var level_json_path: String = "res://levels/default.json" # so it shows up on editor
## selected level, if loading from a dictionary
@export var level_data: Dictionary = {
	"name": "ERROR!",
	"max_y": 6, 
	"poly_color": "ff0000",
	"circle_budget": -1,
	"gomory_budget": -1,
	"split_budget": -1,
	"poly_vertices": [
		[
			1.7,
			1
		],
		[
			2,
			0.7
		],
		[
			5,
			0.7
		],
		[
			5.3,
			1
		],
		[
			5.3,
			4
		],
		[
			5,
			4.3
		],
		[
			2,
			4.3
		],
		[
			1.7,
			4
		]
	]}
## level name
var level_name: String
## flag to determine if the user is allowed to click
var can_click: bool = true
## flag to determine if the user is currently dragging the camera with mouse1
var is_m1_dragging: bool = false
## need to save the clicked position to differenciate between click and drag
var clicked_pos_at_drag_start: Vector2 = Vector2(0, 0)
## determines if a cut is currently being made
var is_cutting: bool = false
# - cut mode stuff -
enum CUT_MODES { DEBUG_CUT, CIRCLE_CUT, GOMORY_CUT, H_SPLIT_CUT, V_SPLIT_CUT, NONE }
var cut_mode = CUT_MODES.CIRCLE_CUT
# cut budgets (-1 means infinite)
var circle_cut_budget: int = -1
var gomory_cut_budget: int = -1
var split_cut_budget: int = -1 # both h and v
## score for this level
var score: int = 0
## flag to determine if the invalidation timer timed out
var invalidation_timer_timed_out: bool = false
## flag to play the long version of the gomory cut animation (literally only used in level 5 of tutorial)
@export var long_gomory_animation: bool = false:
	set(value):
		long_gomory_animation = value
		if POLYGON != null:
			POLYGON.long_gomory_animation = value
# - debug -
var debug_cut_direction: Vector2 = Vector2(1, 0)

# -- child nodes --
@onready var LATTICE_GRID = $lattice_grid
@onready var GUIDE_GRID = $guide_grid
@onready var POLYGON = $polygon
@onready var CAMERA = $camera
# @onready var CLICK_VFXS = $vfx/click_vfxs # moved to game scene
# - hud elements -
@onready var HUD = $CanvasLayer/HUD
@onready var NAME_LABEL = $CanvasLayer/HUD/name_label
@onready var CUT_BUTTONS_CONTAINER = $CanvasLayer/HUD/cut_buttons
@onready var OPEN_MENU = $CanvasLayer/HUD/open_menu
@onready var SHOW_HULL_BUTTON = $CanvasLayer/HUD/show_hull
@onready var CIRCLE_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/circle
@onready var GOMORY_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/gomory
@onready var H_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/h_split
@onready var V_SPLIT_CUT_BUTTON = $CanvasLayer/HUD/cut_buttons/v_split
@onready var SCORE_LABEL = $CanvasLayer/HUD/score_container/score_label
@onready var INVALIDATE_CLICK_TIMER = $invalidate_click_timer
# - proloaded scenes -
# @onready var CLICK_VFX = preload("res://scenes/click_vfx.tscn") # moved to game scene
# - debug cut button and input -
@onready var DEBUG_CONTAINER = $CanvasLayer/HUD/debug_buttons
@onready var DEBUG_CUT_BUTTON = $CanvasLayer/HUD/debug_buttons/debug_cut
@onready var DEBUG_CUT_INPUT = $CanvasLayer/HUD/debug_buttons/debug_cut_input

# Called when the node enters the scene tree for the first time.
func _ready(): # TODO: messy. separate these into functions
	# load level
	var parsed_data
	# if loading from a level file
	if LOAD_FROM_FILE:
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
		parsed_data = JSON.parse_string(file_data.get_as_text())
		if parsed_data == null:
			DEBUG.log("level.gd: Error parsing %s" % level_json_path)
			return
	# if loading from a dictionary
	else:
		parsed_data = level_data	
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
	POLYGON.long_gomory_animation = long_gomory_animation
	POLYGON.build_polygon(true)
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
		# set as disabled if budget is 0
		CIRCLE_CUT_BUTTON.disabled = circle_cut_budget == 0
		GOMORY_CUT_BUTTON.disabled = gomory_cut_budget == 0
		H_SPLIT_CUT_BUTTON.disabled = split_cut_budget == 0
		V_SPLIT_CUT_BUTTON.disabled = split_cut_budget == 0
	# DEFAULT SELECTED CUT
	CIRCLE_CUT_BUTTON.selected = true
	# ONLY SHOW DEBUG CUT IF DEBUG IS ENABLED!
	DEBUG_CONTAINER.visible = DEBUG_CONTAINER.visible and DEBUG.is_enabled()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	_handle_gomory_cut_hover()

# handle inputs here! not in _process!
func _input(event) -> void:
	# handle clicking with mouse 1
	if event is InputEventMouseButton:
		# ignore inputs if paused
		if get_tree().paused:
			return
		# ignore inputs if can_click is false
		if not can_click:
			return
		# ignore UI
		if CUT_BUTTONS_CONTAINER.get_global_rect().has_point(event.position):
			return
		if DEBUG_CONTAINER.visible and DEBUG_CONTAINER.get_global_rect().has_point(event.position):
			return
		if SHOW_HULL_BUTTON.get_global_rect().has_point(event.position):
			return
		if OPEN_MENU.get_global_rect().has_point(event.position):
			return
		# click PRESSED
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_m1_dragging = true
			clicked_pos_at_drag_start = event.position
			# start the invalidation timer
			INVALIDATE_CLICK_TIMER.start()
			invalidation_timer_timed_out = false
			DEBUG.log("Clicked @ " + str(event.position))
		# click RELEASED
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# stop dragging
			is_m1_dragging = false
			# if this happens, it was a drag and not a click (allow for some tolerance)
			if abs(event.position - clicked_pos_at_drag_start) > Vector2(GLOBALS.MOUSE_1_DRAG_EPSILON, GLOBALS.MOUSE_1_DRAG_EPSILON):
				return
			# invalidate click if waiting for a cut to finish
			if is_cutting:
				return
			# invalidate click if using m1 to drag the camera
			if is_m1_dragging:
				return
			# invalidate click if the player took too long to release the click (this is to prevent accidental clicks)
			if invalidation_timer_timed_out:
				invalidation_timer_timed_out = false
				return
			var clicked_lattice_pos = snapped( (get_global_mouse_position() - OFFSET) / SCALING , Vector2(GLOBALS.CLICK_EPSILON, GLOBALS.CLICK_EPSILON) )
			DEBUG.log( "Clicked @ lattice pos: " + str( clicked_lattice_pos ) )
			# - DEBUG CUT -
			if cut_mode == CUT_MODES.DEBUG_CUT and DEBUG.is_enabled():
				# split the polygon at the given position and at a hard-coded direction
				POLYGON.cut_polygon(clicked_lattice_pos, debug_cut_direction, true)
			# - CIRCLE CUT -
			elif cut_mode == CUT_MODES.CIRCLE_CUT and circle_cut_budget != 0:
				is_cutting = true
				var circle_cut_result = await POLYGON.circle_cut(clicked_lattice_pos)
				if circle_cut_result[0] == 0: # no valid cuts
					is_cutting = false
					return
				elif circle_cut_result[0] == 1: # exactly one cut
					score += roundi( circle_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA )
					cut_made.emit(roundi( circle_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA ))
				else: # multiple cut bonus
					score += roundi( circle_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA * SCORE.MULTIPLE_CUT_BONUS_MULTIPLIER)
					cut_made.emit(roundi( circle_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA ))
				circle_cut_budget = circle_cut_budget - 1 if not INFINITE_BUDGET else -1
				SCORE_LABEL.text = str(score)
				CIRCLE_CUT_BUTTON.budget = circle_cut_budget
				# if the polygon becomes integral early, emit the signal
				if POLYGON.is_integral():
					DEBUG.log("Polygon is integral! Rank: " + POLYGON.get_rank())
					var rank_and_bonus = _check_rank()
					var rank = rank_and_bonus[0]
					var rank_bonus = rank_and_bonus[1]
					var budget_bonus = circle_cut_budget * SCORE.CIRCLE_CUT_BONUS + gomory_cut_budget * SCORE.GOMORY_CUT_BONUS + split_cut_budget * SCORE.SPLIT_CUT_BONUS
					score += rank_bonus + budget_bonus
					level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				# if the budget is 0, disable the button and select the next cut mode whose budget is not 0. if all are 0, select none
				if circle_cut_budget == 0:
					CIRCLE_CUT_BUTTON.disabled = true
					if gomory_cut_budget != 0:
						cut_mode = CUT_MODES.GOMORY_CUT
						_unselect_all_cut_buttons()
						GOMORY_CUT_BUTTON.selected = true
						_handle_gomory_cut_selected(true)
					elif split_cut_budget != 0:
						cut_mode = CUT_MODES.H_SPLIT_CUT
						_unselect_all_cut_buttons()
						H_SPLIT_CUT_BUTTON.selected = true
					else:
						cut_mode = CUT_MODES.NONE
						# end level now
						DEBUG.log("Out of cuts! Rank: " + POLYGON.get_rank())
						var rank_and_bonus = _check_rank()
						var rank = rank_and_bonus[0]
						var rank_bonus = rank_and_bonus[1]
						var budget_bonus = 0
						score += rank_bonus + budget_bonus
						level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				is_cutting = false
			# - H SPLIT CUT -
			elif cut_mode == CUT_MODES.H_SPLIT_CUT and split_cut_budget != 0:
				is_cutting = true
				var h_split_cut_result = await POLYGON.h_split_cut(clicked_lattice_pos)
				if h_split_cut_result[0] == 0: # no valid cuts
					is_cutting = false
					return
				elif h_split_cut_result[0] == 1: # exactly one cut
					score += roundi( h_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA )
					cut_made.emit(roundi( h_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA ))
				else: # multiple cut bonus
					score += roundi( h_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA * SCORE.MULTIPLE_CUT_BONUS_MULTIPLIER)
					cut_made.emit(roundi( h_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA ))
				split_cut_budget = split_cut_budget - 1 if not INFINITE_BUDGET else -1
				SCORE_LABEL.text = str(score)
				H_SPLIT_CUT_BUTTON.budget = split_cut_budget # they're shared
				V_SPLIT_CUT_BUTTON.budget = split_cut_budget
				# if the polygon becomes integral early, emit the signal
				if POLYGON.is_integral():
					DEBUG.log("Polygon is integral! Rank: " + POLYGON.get_rank())
					var rank_and_bonus = _check_rank()
					var rank = rank_and_bonus[0]
					var rank_bonus = rank_and_bonus[1]
					var budget_bonus = circle_cut_budget * SCORE.CIRCLE_CUT_BONUS + gomory_cut_budget * SCORE.GOMORY_CUT_BONUS + split_cut_budget * SCORE.SPLIT_CUT_BONUS
					score += rank_bonus + budget_bonus
					level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				# if the budget is 0, disable the button and select the next cut mode whose budget is not 0. if all are 0, select none
				if split_cut_budget == 0:
					H_SPLIT_CUT_BUTTON.disabled = true
					V_SPLIT_CUT_BUTTON.disabled = true
					# select the next cut mode whose budget is not 0. if all are 0, select none
					if circle_cut_budget != 0:
						cut_mode = CUT_MODES.CIRCLE_CUT
						_unselect_all_cut_buttons()
						CIRCLE_CUT_BUTTON.selected = true
					elif gomory_cut_budget != 0:
						cut_mode = CUT_MODES.GOMORY_CUT
						_unselect_all_cut_buttons()
						GOMORY_CUT_BUTTON.selected = true
						_handle_gomory_cut_selected(true)
					else:
						cut_mode = CUT_MODES.NONE
						# end level now
						DEBUG.log("Out of cuts! Rank: " + POLYGON.get_rank())
						var rank_and_bonus = _check_rank()
						var rank = rank_and_bonus[0]
						var rank_bonus = rank_and_bonus[1]
						var budget_bonus = 0
						score += rank_bonus + budget_bonus
						level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				is_cutting = false
			# - V SPLIT CUT -
			elif cut_mode == CUT_MODES.V_SPLIT_CUT and split_cut_budget != 0:
				is_cutting = true
				var v_split_cut_result = await POLYGON.v_split_cut(clicked_lattice_pos)
				if v_split_cut_result[0] == 0: # no valid cuts
					is_cutting = false
					return
				elif v_split_cut_result[0] == 1: # exactly one cut
					score += roundi( v_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA )
					cut_made.emit(roundi( v_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA ))
				else: # multiple cut bonus
					score += roundi( v_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA * SCORE.MULTIPLE_CUT_BONUS_MULTIPLIER)
					cut_made.emit(roundi( v_split_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA * SCORE.MULTIPLE_CUT_BONUS_MULTIPLIER))
				split_cut_budget = split_cut_budget - 1 if not INFINITE_BUDGET else -1
				SCORE_LABEL.text = str(score)
				H_SPLIT_CUT_BUTTON.budget = split_cut_budget # they're shared
				V_SPLIT_CUT_BUTTON.budget = split_cut_budget
				# if the polygon becomes integral early, emit the signal
				if POLYGON.is_integral():
					DEBUG.log("Polygon is integral! Rank: " + POLYGON.get_rank())
					var rank_and_bonus = _check_rank()
					var rank = rank_and_bonus[0]
					var rank_bonus = rank_and_bonus[1]
					var budget_bonus = circle_cut_budget * SCORE.CIRCLE_CUT_BONUS + gomory_cut_budget * SCORE.GOMORY_CUT_BONUS + split_cut_budget * SCORE.SPLIT_CUT_BONUS
					score += rank_bonus + budget_bonus
					level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				# if the budget is 0, disable the button and select the next cut mode whose budget is not 0. if all are 0, select none
				if split_cut_budget == 0:
					H_SPLIT_CUT_BUTTON.disabled = true
					V_SPLIT_CUT_BUTTON.disabled = true
					# select the next cut mode whose budget is not 0. if all are 0, select none
					if circle_cut_budget != 0:
						cut_mode = CUT_MODES.CIRCLE_CUT
						_unselect_all_cut_buttons()
						CIRCLE_CUT_BUTTON.selected = true
					elif gomory_cut_budget != 0:
						cut_mode = CUT_MODES.GOMORY_CUT
						_unselect_all_cut_buttons()
						GOMORY_CUT_BUTTON.selected = true
						_handle_gomory_cut_selected(true)
					else:
						cut_mode = CUT_MODES.NONE
						# end level now
						DEBUG.log("Out of cuts! Rank: " + POLYGON.get_rank())
						var rank_and_bonus = _check_rank()
						var rank = rank_and_bonus[0]
						var rank_bonus = rank_and_bonus[1]
						var budget_bonus = 0
						score += rank_bonus + budget_bonus
						level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				is_cutting = false
			# - GOMORY CUT -
			elif cut_mode == CUT_MODES.GOMORY_CUT and gomory_cut_budget != 0: # gomory cut is handled differently
				is_cutting = true
				var gomory_cut_result = await _handle_gomory_cut_click()
				if gomory_cut_result[0] == 0: # no valid cuts
					is_cutting = false
					return
				elif gomory_cut_result[0] == 1: # exactly one cut (gomory cuts are always 1 cut tops)
					score += roundi(gomory_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA)
					cut_made.emit(roundi(gomory_cut_result[1] * SCORE.SCORE_BY_UNIT_AREA))
				gomory_cut_budget = gomory_cut_budget - 1 if not INFINITE_BUDGET else -1
				SCORE_LABEL.text = str(score)
				GOMORY_CUT_BUTTON.budget = gomory_cut_budget
				# if the polygon becomes integral early, emit the signal
				if POLYGON.is_integral():
					DEBUG.log("Polygon is integral! Rank: " + POLYGON.get_rank())
					var rank_and_bonus = _check_rank()
					var rank = rank_and_bonus[0]
					var rank_bonus = rank_and_bonus[1]
					var budget_bonus = circle_cut_budget * SCORE.CIRCLE_CUT_BONUS + gomory_cut_budget * SCORE.GOMORY_CUT_BONUS + split_cut_budget * SCORE.SPLIT_CUT_BONUS
					score += rank_bonus + budget_bonus
					level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				# if the budget is 0, disable the button and select the next cut mode whose budget is not 0. if all are 0, select none
				if gomory_cut_budget == 0:
					GOMORY_CUT_BUTTON.disabled = true
					_handle_gomory_cut_selected(false)
					# select the next cut mode whose budget is not 0. if all are 0, select none
					if circle_cut_budget != 0:
						cut_mode = CUT_MODES.CIRCLE_CUT
						_unselect_all_cut_buttons()
						CIRCLE_CUT_BUTTON.selected = true
					elif split_cut_budget != 0:
						cut_mode = CUT_MODES.H_SPLIT_CUT
						_unselect_all_cut_buttons()
						H_SPLIT_CUT_BUTTON.selected = true
					else:
						cut_mode = CUT_MODES.NONE
						# end level now
						DEBUG.log("Out of cuts! Rank: " + POLYGON.get_rank())
						var rank_and_bonus = _check_rank()
						var rank = rank_and_bonus[0]
						var rank_bonus = rank_and_bonus[1]
						var budget_bonus = 0
						score += rank_bonus + budget_bonus
						level_completed.emit( rank, rank_bonus, budget_bonus , circle_cut_budget, gomory_cut_budget, split_cut_budget )
				is_cutting = false
			# - FAILSAFE -
			else: # if somehow, no cut mode is selected
				DEBUG.log("No cut mode selected!")

# -- layout functions --
## called when calculating the lattice grid size. determines the layout constants based on window size and level data
func _set_lattice_grid_parameters(max_y: int) -> void:
	if max_y == -1:
		DEBUG.log("level.gd: max_y not given, defaulting.")
		return
	var window_size = get_viewport_rect().size
	var aspect_ratio = 4.0 / 3.0 # i like 4:3 for the grid, it leaves space for the hud
	# calculate max_x based on max_y and aspect ratio
	var max_x = int( max_y * aspect_ratio )
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
	POLYGON.SCALING = SCALING
	POLYGON.OFFSET = OFFSET

## unselects all cut buttons
func _unselect_all_cut_buttons() -> void:
	CIRCLE_CUT_BUTTON.selected = false
	GOMORY_CUT_BUTTON.selected = false
	H_SPLIT_CUT_BUTTON.selected = false
	V_SPLIT_CUT_BUTTON.selected = false
	DEBUG_CUT_BUTTON.selected = false

# -- button callbacks --
# when the show hull button is HELD, show the convex hull
func _on_show_hull_button_down() -> void:
	POLYGON.CONVEX_INTEGER_HULL.play_show_hull()

func _on_show_hull_button_up() -> void:
	POLYGON.CONVEX_INTEGER_HULL.play_idle()

# when the debug cut button is PRESSED, set the cut mode to DEBUG_CUT
func _on_debug_cut_pressed() -> void:
	cut_mode = CUT_MODES.DEBUG_CUT
	_unselect_all_cut_buttons()
	DEBUG_CUT_BUTTON.selected = true
	DEBUG.log("DEBUG_CUT selected")
	_handle_gomory_cut_selected(false)

# updates the debug cut angle when the input text changes
func _on_debug_cut_input_text_changed(new_text:String) -> void:
	var degrees = float(new_text) # if the angle is invalid, it will be 0
	debug_cut_direction = Vector2(cos(deg_to_rad(degrees)), -sin(deg_to_rad(degrees)))

# when the circle cut button is PRESSED, set the cut mode to CIRCLE_CUT
func _on_circle_pressed() -> void:
	if is_cutting:
		return
	if circle_cut_budget == 0:
		DEBUG.log("Circle cut budget is 0!")
		return
	cut_mode = CUT_MODES.CIRCLE_CUT
	_unselect_all_cut_buttons()
	CIRCLE_CUT_BUTTON.selected = true
	DEBUG.log("CIRCLE_CUT selected")
	_handle_gomory_cut_selected(false)

# when the gomory cut button is PRESSED, set the cut mode to GOMORY_CUT
func _on_gomory_pressed() -> void:
	if is_cutting:
		return
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
func _on_h_split_pressed() -> void:
	if is_cutting:
		return
	if split_cut_budget == 0:
		DEBUG.log("H/V split cut budget is 0!")
		return
	cut_mode = CUT_MODES.H_SPLIT_CUT
	_unselect_all_cut_buttons()
	H_SPLIT_CUT_BUTTON.selected = true
	DEBUG.log("H_SPLIT_CUT selected")
	_handle_gomory_cut_selected(false)

# when the v split cut button is PRESSED, set the cut mode to V_SPLIT_CUT
func _on_v_split_pressed() -> void:
	if is_cutting:
		return
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
func _handle_gomory_cut_selected(make_clickable: bool) -> void: # TODO: AFTER A CUT, THE EFFECT DISSAPEARS! (solved in a hacky way)
	POLYGON.gomory_mode_selected(make_clickable)

## call in process. updates the mouse position for hover vfx
func _handle_gomory_cut_hover() -> void:
	if cut_mode != CUT_MODES.GOMORY_CUT:
		return
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING
	POLYGON.update_verts_hover_vfx(mouse_lattice_pos)

## function to handle the gomory cut click interaction. the polygon scene is responsible of validating this click
func _handle_gomory_cut_click() -> Array:
	if cut_mode != CUT_MODES.GOMORY_CUT: # prob unneccesary
		return [0, 0.0]
	var mouse_lattice_pos = (get_global_mouse_position() - OFFSET) / SCALING
	return await POLYGON.gomory_cut(mouse_lattice_pos)

# click vfx
# func _play_click_vfx(pos: Vector2):
# 	var click_vfx = CLICK_VFX.instantiate()
# 	CLICK_VFXS.add_child(click_vfx)
# 	click_vfx.position = pos
# 	click_vfx.play_click()

func _on_open_menu_pressed() -> void:
	open_menu.emit()

func _on_camera_zoom_level_changed(zoom_level:float) -> void:
	GUIDE_GRID.update_alpha(zoom_level - 0.05) # -0.5 so the grid doesn't show up too early

## function called after a cut is made to check the current status of the rank.
## [br][br]
## returns the rank and it's respective bonus score on an array, like so: [rank: String, bonus_score: int]
func _check_rank() -> Array:
	var rank = POLYGON.get_rank()
	var bonus_score = 0
	if rank == "-":
		bonus_score = SCORE.NO_RANK
	elif rank == "D":
		bonus_score = SCORE.D_RANK
	elif rank == "C":
		bonus_score = SCORE.C_RANK
	elif rank == "B":
		bonus_score = SCORE.B_RANK
	elif rank == "A":
		bonus_score = SCORE.A_RANK
	elif rank == "S":
		bonus_score = SCORE.S_RANK
	return [rank, bonus_score]

## when the timer times out, it means click was held for too long to count, and should be invalidated
func _on_invalidate_click_timer_timeout():
	invalidation_timer_timed_out = true
	DEBUG.log("Invalidation timer timed out!")
