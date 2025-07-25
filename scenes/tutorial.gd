extends Node2D
## handles the tutorial mode logic and vfx

# - signals -
signal quit_gamemode

# - vars -
var level_dicts = [
	{
		"name" : "Tutorial 1/7",
		"max_y": 3,
		"poly_color": "#880000",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[1.0, 2.0],
			[1.0, 0.5],
			[2.2, 0.8],
			[2.5, 2.0]
		]
	},
	{
		"name" : "Tutorial 2/7",
		"max_y": 4,
		"poly_color": "#008800",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[1.3, 0.3],
			[3.7, 0.3],
			[3.7, 2.7],
			[1.3, 2.7]
		]
	},
	{
		"name" : "Tutorial 3/7",
		"max_y": 4,
		"poly_color": "#000088",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[2.0, 1.0],
			[2.5, 0.5],
			[3.0, 1.0],
			[3.0, 2.0],
			[2.5, 2.5],
			[2.0, 2.0]
		]
	},
	{
		"name" : "Tutorial 4/7",
		"max_y": 4,
		"poly_color": "#888800",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[1.8, 0.7],
			[2.5, 0.0],
			[3.2, 0.7],
			[3.2, 2.3],
			[2.5, 3.0],
			[1.8, 2.3]
		]
	},
	{
		"name" : "Tutorial 5/7",
		"max_y": 4,
		"poly_color": "#880088",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[2.0, 1.0],
			[2.5, 0.5],
			[3.3, 0.0],
			[3.7, 0.7],
			[3.7, 1.3],
			[3.3, 2.0],
			[2.0, 2.0]
		]
	},
	{
		"name" : "Tutorial 6/7",
		"max_y": 4,
		"poly_color": "#008888",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[0.7, 0.7],
			[3.3, 0.7],
			[3.5, 1.5],
			[3.3, 2.3],
			[0.7, 2.3],
			[0.5, 1.5]
		]
	},
	{
		"name" : "Tutorial 7/7",
		"max_y": 5,
		"poly_color": "#888888",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[3.0, 1.0],
			[4.0, 1.0],
			[4.0, 2.0],
			[2.0, 4.0],
			[1.0, 4.0],
			[1.0, 3.0],
			[1.2, 1.9]
		]
	}
]

## keeps track of the current level index
var current_level_idx: int = 0
## keep track of how many cuts have been made on this level
var cuts_made_on_current_level: int = 0
## keeps track of the current tutorial popup index
var current_tutorial_popup_idx: int = 0

## the content and sizes of the tutorial popups
var tutorial_popups: Dictionary = {
	"0_0" : { # ONLY SHOW ORIGIN
		"size": Vector2(460, 312),
		"position": Vector2(424, 64),
		"text": "<-This little dot is [color=red][b]the origin[/b][/color], the point at coordinates (0,0)."
	},
	"0_1" : { # SHOW X AND Y AXIS
		"size": Vector2(751, 352),
		"position": Vector2(408, 152),
		"text": """These are the [color=red][b]X AXIS[/b][/color] and the [color=blue][b]Y AXIS[/b][/color].

(yes, usually the y axis is "up", not "down", but that doesn't matter too much)"""
	},
	"0_2" : { # SHOW THE ENTIRE LATTICE GRID
		"size": Vector2(792, 372),
		"position": Vector2(408, 152),
		"text": """And these are [b]LATTICE POINTS[/b].

They are the points where the x and y coordinates are [color=red][b]both whole numbers[/b][/color]."""
	},
	"0_3" : { # SHOW LINE 1
		"size": Vector2(704, 444),
		"position": Vector2(64, 388),
		"text": """This is a [color=red][b]LINE[/b][/color].

It can be defined as all the points that satisfy an equation of this type:

[color=red][b]Ax + By = C[/b][/color]."""
	},
	"0_4" : { # SHOW ALL LINES AND DUMMY POLYGON
		"size": Vector2(704, 524),
		"position": Vector2(0, 436),
		"text": """If we add more lines...

...we will eventually get a [color=red][b]POLYGON[/b][/color].

The vertices of the polygon are the points where the lines cross each other."""
	},
	"0_5" : { # SHOW HULL BUTTON BECOMES VISIBLE AND HULL IS FORCED TO SHOW
		"size": Vector2(447, 562),
		"position": Vector2(1144, 348),
		"text": """Take a look at [color=blue][b]this[/b][/color]: this polygon encloses some [b]lattice points[/b].

These points also form a polygon. It's called the [color=blue][b]INTEGER CONVEX HULL[/b][/color]."""
	},
	"0_6" : { # FORCE HIDE HULL
		"size": Vector2(447, 454),
		"position": Vector2(1144, 376),
		"text": """In this game, your goal is to get to that [color=blue][b]convex hull[/b][/color].

How? With [b]cutting planes[/b]."""
	},
	"0_7" : { # SHOW CIRCLE CUT BUTTON
		"size": Vector2(391, 560),
		"position": Vector2(1248, 200),
		"text": """Introducting the first cutting plane: [color=red][b]the circle cut[/b][/color]

It belongs to the family of [color=red][b]intersection cuts[/b][/color]."""
	},
	"0_8" : {
		"size": Vector2(650, 750),
		"position": Vector2(989, 180),
		"text": """If you click the screen, a circle will grow until it hits the [b]lattice[/b].

Then, it will try to [color=red][b]make a cut along the intersection of the circle and the polygon[/b][/color].

Try using it to get to the [color="blue"][b]convex hull[/b][/color]!

[color=red][b]Select it[/b][/color] and then [color=red][b]click on the screen[/b][/color]."""
	},
	"0_9" : { # on level complete
		"size": Vector2(448, 300),
		"position": Vector2(64, 476),
		"text": """Nice job! Circle cuts are simple, but not very efficient..."""
	},
	"1_0" : { # split cut introduction. show only h and v cuts
		"size": Vector2(448, 650), 
		"position": Vector2(1192, 150),
		"text": """Let's try something more powerful.

Introducing: [color=red][b]horizontal and vertical split cuts[/b][/color], another type of [color=red][b]intersection cut[/b][/color].

Try them out!"""
	},
	"1_1" : { # on level complete
		"size": Vector2(976, 598),
		"position": Vector2(65, 284),
		"text": """That was a lot more efficient, wasn't it?

Note that [color=red][b]splits[/b][/color] also stop as soon as they hit the [b]lattice[/b].

Depending on where you click, the cut [color=red][b]won't always be maximal[/b][/color]. Be precise!

(By the way, you can zoom in with [color=red][b]scroll wheel[/b][/color] or by [color=red][b]pinching the screen[/b][/color].)"""
	},
	"2_0" : { # split cut pt 2
		"size": Vector2(352, 300),
		"position": Vector2(480, 350),
		"text": """Let's see if you can figure this one out."""
	},
	"2_1" : { # on level complete
		"size": Vector2(767, 350),
		"position": Vector2(65, 470),
		"text": """Yup! Split cuts can do that!

Also, if you get [color=red][b]more than one cut[/b][/color] with one cutting plane, you'll get [color=red][b]bonus points[/b][/color]!"""
	},
	"3_0" : { # split and circle
		"size": Vector2(767, 460),
		"position": Vector2(64, 340),
		"text": """Like circle cuts, split cuts [color=red][b]stop as soon as they hit the lattice[/b][/color].

A good strategy is to use a [color=red][b]circle cut[/b][/color] to [color=red][b]trim a corner[/b][/color] split cuts can't get to, and then use a [color=red][b]split cut[/b][/color] to [color=red][b]finish the job[/b][/color]."""
	},
	"3_1" : { # on level complete
		"size": Vector2(320, 265),
		"position": Vector2(64, 576),
		"text": """Excellent!"""
	},
	"4_0" : { # gomory cut pt 1
		"size": Vector2(550, 550),
		"position": Vector2(1192, 200),
		"text" : """Introducing [color=red][b]Gomory cuts[/b][/color].

Cutting polygons isn't hard, the [color=red][b]tricky part[/b][/color] is doing it in such a way that [color=red][b]won't get rid of the lattice points inside[/b][/color]."""
	},
	"4_1" : { # gomory cut pt 1
		"size": Vector2(376, 500),
		"position": Vector2(1262, 180),
		"text" : """[color=red][b]Gomory cuts[/b][/color] are an efficient way of doing that.

This type of cut is a bit more [color=red][b]algebraic[/b][/color]."""
	},
	"4_2" : { # gomory cut pt 1
		"size": Vector2(640, 288),
		"position": Vector2(64, 544),
		"text" : """How do they work? The full story is a bit too lengthy to put here, but here's the [b]gist[/b]:"""
	},
	"4_3" : { # gomory cut pt 1
		"size": Vector2(950, 800),
		"position": Vector2(64, 100),
		"text" : """Remember how lines can be written as
[color=red][b]Ax + By = C[/b][/color]?

Say that you have 2 lines:
[color=red][b]A1x + B1y = C1[/b][/color]
and
[color=blue][b]A2x + B2y = C2[/b][/color]

And let's say that you did some math, and found the point where they cross. Let's call it [b](x',y')[/b]

But whoops! [b]x'[/b] and [b]y'[/b] are [b]decimals[/b]! And you want [b]whole numbers[/b]!"""
	},
	"4_4" : { # gomory cut pt 1
		"size": Vector2(1120, 750),
		"position": Vector2(64, 100),
		"text" : """The [color=red][b]Gomory cut method[/b][/color] says:

First, write out [b]x'[/b] algebraically in a special way, using the equations of the two lines.

Since it's a decimal value, it will end up looking something like:

[color=red][b]x' = (some whole number) + (some decimal)[/b][/color]

That decimal part can be [color=red][b]rounded[/b][/color] to generate a [color=red][b]new line[/b][/color] that, when used to cut the polygon, will [color=red][b]nudge you closer to whole number values[/b][/color]!"""
	},
	"4_5" : { # gomory cut pt 1
		"size": Vector2(950, 500),
		"position": Vector2(64, 310),
		"text" : """You can repeat this process with [b]y'[/b] to get a second line.

Both of these lines are [color=red][b]Gomory cuts[/b][/color]!

As to which one of these 2 cuts will get chosen here: [color=red][b]the game will automatically pick the one that cuts the most[/b][/color]."""
	},
	"4_6" : { # gomory cut pt 1
		"size": Vector2(576, 350),
		"position": Vector2(64, 444),
		"text" : """Give it a shot!

[color=red][b]Select a vertex[/b][/color], and watch the [color=red][b]Gomory cut[/b][/color] work it's magic!"""
	},
	"4_7" : { # on level complete
		"size": Vector2(320, 256),
		"position": Vector2(64, 576),
		"text" : """Nice job!"""
	},
	"5_0" : { # gomory cut pt 2
		"size": Vector2(576, 350),
		"position": Vector2(64, 350),
		"text" : """[color=red][b]Gomory cuts[/b][/color] can be hard to predict visually.

Take some time to get a feel for them."""
	},
	"5_1" : { # on level complete
		"size": Vector2(256, 256),
		"position": Vector2(64, 576),
		"text" : """Good!"""
	},
	"6_0" : { # gomory cut pt 3
		"size": Vector2(384, 256),
		"position": Vector2(64, 576),
		"text" : """Here's an interesting case..."""
	},
	"6_1" : { # after 4 cuts
		"size": Vector2(450, 288),
		"position": Vector2(64, 544),
		"text" : """Seems like this will go on forever...

doesn't it?"""
	},
	"6_2" : { # after 4 cuts
		"size": Vector2(768, 200),
		"position": Vector2(64, 442),
		"text" : """[color=red][b]Gomory cuts[/b][/color] are usually efficient, but may not always converge quickly."""
	},
	"6_3" : { # after 4 cuts
		"size": Vector2(760, 360),
		"position": Vector2(64, 470),
		"text" : """Don't worry, in this game, [color=red][b]close enough is good enough[/b][/color]!

If you get [color=red][b]close enough[/b][/color] to the hull, the polygon will [color=red][b]correct itself[/b][/color]."""
	},
	"6_4" : {
		"size": Vector2(256, 256),
		"position": Vector2(64, 576),
		"text" : """There you go!"""
	}
}

# - child nodes -
@onready var LEVEL = null # assigned dynamically
@onready var MENU = $CanvasLayer/HUD/MENU
@onready var TUTORIAL_POPUP = $CanvasLayer/HUD/TUTORIAL/tutorial_popup
@onready var TUTORIAL_TEXT = $CanvasLayer/HUD/TUTORIAL/tutorial_popup/tutorial_text
@onready var TUTORIAL_NEXT_BUTTON = $CanvasLayer/HUD/TUTORIAL/tutorial_popup/tutorial_next
@onready var TUTORIAL_MODE_FINISH = $CanvasLayer/HUD/TUTORIAL_FINISH
# dummy elements for vfxs
@onready var LINES = $vfx/lines
@onready var LINE1 = $vfx/lines/line1
@onready var LINE2 = $vfx/lines/line2
@onready var LINE3 = $vfx/lines/line3
@onready var LINE4 = $vfx/lines/line4
@onready var EQ1 = $vfx/lines/eq1
@onready var EQ2 = $vfx/lines/eq2
@onready var EQ3 = $vfx/lines/eq3
@onready var EQ4 = $vfx/lines/eq4
@onready var AXES = $vfx/axes
@onready var DUMMY_ORIGIN = $vfx/dummy_origin
@onready var DUMMY_LATTICE_GRID = $vfx/dummy_lattice_grid
@onready var DUMMY_POLYGON = $vfx/dummy_polygon

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# load the level
	load_level(level_dicts[current_level_idx])
	# open the first tutorial popup
	open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
	# disable inputs for the LEVEL scene
	disable_level_input()
	# setup the vfx elements for the tutorial
	# level originally hidden
	LEVEL.visible = false
	LEVEL.SHOW_HULL_BUTTON.visible = false
	LEVEL.CIRCLE_CUT_BUTTON.visible = false
	# make the dummy lattice grid
	DUMMY_LATTICE_GRID.DIMENSIONS = LEVEL.DIMENSIONS
	DUMMY_LATTICE_GRID.SCALING = LEVEL.SCALING
	DUMMY_LATTICE_GRID.OFFSET = LEVEL.OFFSET
	DUMMY_LATTICE_GRID.make_lattice_grid()
	DUMMY_LATTICE_GRID.visible = false
	# the axes
	AXES.position = LEVEL.OFFSET
	AXES.visible = false
	# and the little origin dot (visible from the beginning)
	DUMMY_ORIGIN.position = LEVEL.OFFSET
	DUMMY_ORIGIN.visible = true
	# set up the lines and eqs
	# dummy polygon mimics the polygon in the level
	DUMMY_POLYGON.polygon = PackedVector2Array([
		Vector2(1.0, 0.5) * LEVEL.SCALING + LEVEL.OFFSET,
		Vector2(2.2, 0.8) * LEVEL.SCALING + LEVEL.OFFSET,
		Vector2(2.5, 2.0) * LEVEL.SCALING + LEVEL.OFFSET,
		Vector2(1.0, 2.0) * LEVEL.SCALING + LEVEL.OFFSET
	])
	DUMMY_POLYGON.visible = false
	# set up the lines and eqs describing it
	LINE1.position = LEVEL.OFFSET + (Vector2(1.0, 0.5) + Vector2(2.2, 0.8)) * 0.5 * LEVEL.SCALING
	LINE1.rotation = (Vector2(2.2, 0.8) - Vector2(1.0, 0.5)).angle()
	LINE1.visible = false
	EQ1.position = LINE1.position
	EQ1.visible = false
	# line 2
	LINE2.position = LEVEL.OFFSET + (Vector2(2.2, 0.8) + Vector2(2.5, 2.0)) * 0.5 * LEVEL.SCALING
	LINE2.rotation = (Vector2(2.5, 2.0) - Vector2(2.2, 0.8)).angle()
	LINE2.visible = false
	EQ2.position = LINE2.position
	EQ2.visible = false
	# line 3
	LINE3.position = LEVEL.OFFSET + (Vector2(2.5, 2.0) + Vector2(1.0, 2.0)) * 0.5 * LEVEL.SCALING
	LINE3.rotation = (Vector2(1.0, 2.0) - Vector2(2.5, 2.0)).angle()
	LINE3.visible = false
	EQ3.position = LINE3.position
	EQ3.visible = false
	# line 4
	LINE4.position = LEVEL.OFFSET + (Vector2(1.0, 2.0) + Vector2(1.0, 0.5)) * 0.5 * LEVEL.SCALING
	LINE4.rotation = (Vector2(1.0, 0.5) - Vector2(1.0, 2.0)).angle()
	LINE4.visible = false
	EQ4.visible = false
	EQ4.position = LINE4.position

func load_level(level_data: Dictionary):
	if LEVEL != null:
		LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.LOAD_FROM_FILE = false
	LEVEL.level_data = level_data
	LEVEL.INFINITE_BUDGET = true
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)
	LEVEL.level_completed.connect(_on_level_completed)
	LEVEL.cut_made.connect(_on_cut_made)
	get_tree().paused = false
	_setup_initial_conditions()

## function to setup the initial conditions for each tutorial level. call after loading a new level
func _setup_initial_conditions():
	match current_level_idx:
		0: # circle cut
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_circle_pressed()
		1: # split pt 1
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL._on_h_split_pressed()
		2: # split pt 2
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_v_split_pressed()
		3: # split and circle
			LEVEL.GOMORY_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_h_split_pressed()
		4: # gomory cut pt 1
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()
		5: # gomory cut pt 2
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()
		6: # gomory pt 3
			LEVEL.CIRCLE_CUT_BUTTON.visible = false
			LEVEL.H_SPLIT_CUT_BUTTON.visible = false
			LEVEL.V_SPLIT_CUT_BUTTON.visible = false
			LEVEL._on_gomory_pressed()

## helper function to disable level click input.
func disable_level_input():
	LEVEL.can_click = false

## helper function to enable level click input.
func enable_level_input():
	LEVEL.can_click = true

## function to open the tutorial popup with the given level id and popup id
## [br][br]
## also handles the effects that happen during that part of the tutorial
func open_tutorial_popup(level_id: int, popup_id: int):
	var key = str(level_id) + "_" + str(popup_id)
	TUTORIAL_POPUP.visible = true
	TUTORIAL_POPUP.size = tutorial_popups[key]["size"]
	TUTORIAL_POPUP.position = tutorial_popups[key]["position"]
	TUTORIAL_TEXT.text = tutorial_popups[key]["text"]

## function to close the tutorial popup
func close_tutorial_popup():
	TUTORIAL_POPUP.visible = false

# - signal callbacks -

func _on_cut_made(_score: int):
	cuts_made_on_current_level += 1
	if current_level_idx == 6 and cuts_made_on_current_level == 4:
		disable_level_input()
		open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
	
func _on_level_completed(_rank: String, _rank_bonus: int, _budget_bonus: int, _remaining_circle: int, _remaining_gomory: int, _remaining_split: int):
	disable_level_input()
	open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)

# - menu stuff -
func _on_level_open_menu():
	get_tree().paused = true
	MENU.visible = true

func _on_x_pressed():
	get_tree().paused = false
	MENU.visible = false

func _on_exit_pressed():
	get_tree().paused = false
	quit_gamemode.emit()
	queue_free()

# - tutorial stuff -

## main function to handle the tutorial logic, popups, and vfx
func _on_tutorial_next_pressed():
	match current_level_idx:
		0:
			match current_tutorial_popup_idx:
				9: # start level 1
					close_tutorial_popup()
					current_level_idx = 1
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				8: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
				7:
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				6: # show circle cut button
					LEVEL.CIRCLE_CUT_BUTTON.visible = true
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				5: # force the hull to be hidden
					LEVEL._on_show_hull_button_up()
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				4: # hide lines, hide dummy poly show level, hull btn, and force the hull to be shown
					DUMMY_POLYGON.visible = false
					LINE1.visible = false
					EQ1.visible = false
					LINE2.visible = false
					EQ2.visible = false
					LINE3.visible = false
					EQ3.visible = false
					LINE4.visible = false
					EQ4.visible = false
					DUMMY_LATTICE_GRID.visible = false
					LEVEL.visible = true
					# how hull button
					LEVEL.SHOW_HULL_BUTTON.visible = true
					# force the hull to be shown
					LEVEL._on_show_hull_button_down()
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				3: # show all lines and dummy poly
					DUMMY_POLYGON.visible = true
					LINE2.visible = true
					EQ2.visible = true
					LINE3.visible = true
					EQ3.visible = true
					LINE4.visible = true
					EQ4.visible = true
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				2: # show line 1
					LINE1.visible = true
					EQ1.visible = true
					AXES.visible = false
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				1: # show the lattice grid
					DUMMY_ORIGIN.visible = false
					DUMMY_LATTICE_GRID.visible = true
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				0: # show the axes
					AXES.visible = true
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
		1:
			match current_tutorial_popup_idx:
				1: # start level 2
					close_tutorial_popup()
					current_level_idx = 2
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				0: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
		2:
			match current_tutorial_popup_idx:
				1: # start level 3
					close_tutorial_popup()
					current_level_idx = 3
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				0: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
		3:
			match current_tutorial_popup_idx:
				1: # start level 4
					close_tutorial_popup()
					current_level_idx = 4
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					# this level and only this level has the long gomory cut animation
					LEVEL.long_gomory_animation = true
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				0: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
		4:
			match current_tutorial_popup_idx:
				7: # start level 5
					close_tutorial_popup()
					current_level_idx = 5
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				6: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
				_:
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
		5:
			match current_tutorial_popup_idx:
				1: # start level 6
					close_tutorial_popup()
					current_level_idx = 6
					cuts_made_on_current_level = 0
					current_tutorial_popup_idx = 0
					load_level(level_dicts[current_level_idx])
					disable_level_input()
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				0: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
		6:
			match current_tutorial_popup_idx:
				4: # end of tutorial
					close_tutorial_popup()
					TUTORIAL_MODE_FINISH.visible = true
					get_tree().paused = true
				3: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
				0: # gameplay starts here
					current_tutorial_popup_idx += 1
					close_tutorial_popup()
					enable_level_input()
				_:
					close_tutorial_popup()
					current_tutorial_popup_idx += 1
					open_tutorial_popup(current_level_idx, current_tutorial_popup_idx)
				