extends Node2D
## handles the tutorial mode logic and animations

# - signals -
signal quit_gamemode

# - vars -
var level_dicts = [
	{
		"name" : "Tutorial 1/7",
		"max_y": 3,
		"poly_color": "#990000",
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
		"max_y": 3,
		"poly_color": "#009900",
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
		"name" : "Tutorial 3/7",
		"max_y": 3,
		"poly_color": "#000099",
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
		"name" : "Tutorial 4/7",
		"max_y": 3,
		"poly_color": "#ff0000",
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
		"name" : "Tutorial 5/7",
		"max_y": 3,
		"poly_color": "#ff0000",
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
		"name" : "Tutorial 6/7",
		"max_y": 3,
		"poly_color": "#ff0000",
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
		"name" : "Tutorial 7/7",
		"max_y": 3,
		"poly_color": "#ff0000",
		"circle_budget": -1,
		"gomory_budget": 0,
		"split_budget": 0,
		"poly_vertices" : [
			[1.0, 2.0],
			[1.0, 0.5],
			[2.2, 0.8],
			[2.5, 2.0]
		]
	}
]

## keeps track of the current level index
var current_level_idx: int = 0
## keep track of how many cuts have been made on this level
var cuts_made_on_current_level: int = 0

## the content and sizes of the tutorial popups
var tutorial_popups: Dictionary = {
	"0_0" : { # ONLY SHOW ORIGIN
		"size": Vector2(328, 272),
		"position": Vector2(384, 64),
		"text": "<-This dot is the [b]origin[/b], the point (0,0)."
	},
	"0_1" : { # SHOW X AND Y AXIS
		"size": Vector2(672, 344),
		"position": Vector2(448, 200),
		"text": """These are the [color=red]X AXIS[/color] and the [color=green]Y AXIS[/color].
(yes, usually the y axis is "up", but that doesn't matter too much)"""
	},
	"0_2" : { # SHOW THE ENTIRE LATTICE GRID
		"size": Vector2(672, 344),
		"position": Vector2(560, 296),
		"text": """And these are [b]LATTICE POINTS[/b].
They are the points where the x and y coordinates are both whole numebrs."""
	},
	"0_3" : { # PLAY LINE ANIMATION 1
		"size": Vector2(528, 304),
		"position": Vector2(0, 656),
		"text": """This is a [color=red]LINE[/color].
It can be defined as all the points that satisfy an equation like this:
[color=red]Ax + By = C[/color]."""
	},
	"0_4" : { # PLAY LINE ANIMATION 2
		"size": Vector2(728, 304),
		"position": Vector2(0, 656),
		"text": """If we add more lines...
...we will eventually get a [color=red]POLYGON[/color].
The vertices of the polygon are the points where the lines cross each other."""
	},
	"0_5" : { # CONV HULL BUTTON BECOMES VISIBLE AND HULL IS FORCED TO SHOW
		"size": Vector2(384, 584),
		"position": Vector2(1192, 360),
		"text": """Take a look at [color=blue]this[/color]: this polygon encloses some [b]lattice points[/b].
These points also form a polygon. It's called the [color=blue][b]INTEGER CONVEX HULL[/b][/color]."""
	},
	"0_6" : {
		"size": Vector2(384, 384),
		"position": Vector2(1192, 560),
		"text": """In this game, your goal is to get to that [color=blue]convex hull[/color].
How? With [b]the cutting planes[/b]."""
	},
	"0_7" : { # hull hidden, circle cut button visible
		"size": Vector2(600, 280),
		"position": Vector2(1024, 312),
		"text": """Introducting the first cutting plane: [color=red][b]the circle cut[/b][/color]
Select it and then click on the screen."""
	},
	"0_8" : { # after the first successful circle cut
		"size": Vector2(744, 408),
		"position": Vector2(880, 240),
		"text": """It grows a circle until it hits the [b]lattice grid[/b].
Then, if the [b]circle[/b] intersects the [color="red"][b]polygon[/b][/color], it will try to cut it along that line.
Try using it to get to the [color="blue"][b]convex hull[/b][/color]!"""
	},
	"0_9" : { # on level complete
		"size": Vector2(584, 256),
		"position": Vector2(640, 448),
		"text": """Nice job! Circle cuts are simple, but not very efficient..."""
	},
	"1_0" : { # split cut introduction. show only h and v cuts
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """Let's try something more powerful.
Introducing: [color=red]horizontal and vertical split cuts[/color].
Try them out!"""
	},
	"1_1" : { # on level complete
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """That was a lot more efficient, wasn't it?
Note that splits also stop as soon as they hit the lattice grid.
Depending on where you click, the cut won't always be maximal. Be precise!
(By the way, you can zoom in with [color=red]scroll wheel[/color] or by [color=red]pinching the screen[/color].)"""
	},
	"2_0" : { # split cut pt 2
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """Let's see if you can figure this one out."""
	},
	"2_1" : { # on level complete
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """Yup, split cuts can do that!
Also, if you get more than one cut per cutting plane, you'll get [b]bonus points[/b]!"""
	},
	"3_0" : { # split and circle
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """Like circle cuts, split cuts stop as soon as they hit the [b]lattice grid[/b].
A good strategy is to use circle cuts first to trim corners like thar first, and then use split to finish the job."""
	},
	"3_1" : { # on level complete
		"size": Vector2(400, 200),
		"position": Vector2(100, 100),
		"text": """Flawless!"""
	},
	"4_0" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Introducing [color=red][b]Gomory cuts[/b][/color].
Cutting polygons is easy, the tricky part is doing it in such a way that won't get rid of the lattice points inside."""
	},
	"4_1" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """[color=red][b]Gomory cuts[/b][/color] are an efficient way of doing that."""
	},
	"4_2" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """How do they work? The full story is a bit too lengthy to put here, but here's the [b]gist[/b]:"""
	},
	"4_3" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Remember how linescan be written as [color=red]Ax + By = C[/color]?
Say that you have 2 lines:
[color=red]A1x + B1y = C1[/color] and
[color=red]A2x + B2y = C2[/color]
And let's say that you did some math, and found the point where they cross. let's call it [b](xi,yi)[/b]
But whoops! [b]xi[/b] and [b]yi[/b] are [b]decimals[/b]! And you want [b]whole numbers[/b]!"""
	},
	"4_4" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """The [color=red][b]Gomory cut[/b][/color] says:
First, write out [b]xi[/b] in a certain way. In the end it will look like:
[color=red]xi = (some whole number) + (some decimal)[/color]
That decimal part can be used to generate a [color=red][b]new line[/b][/color] that will [b]nudge you closer to a whole number![/b]"""
	},
	"4_5" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """You can repeat this process with [b]yi[/b] to get a second line.
Both of these lines are [color=red][b]Gomory cuts[/b][/color]! And they're mathematically guaranteed to converge to the [b]convex hull[/b]!
As to which one of these 2 will get chosen here: the game will automatically pick the most optimal one."""
	},
	"4_6" : { # gomory cut pt 1
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Give it a shot!
[color=red][b]Select a vertex[/b][/color], and watch the [color=red][b]Gomory cut[/b][/color] work it's magic!"""
	},
	"4_7" : { # on level complete
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Nice job!"""
	},
	"5_0" : { # gomory cut pt 2
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """[color=red][b]Gomory cuts[/b][/color] can be hard to predict visually.
Take some time to get a feel for them."""
	},
	"5_1" : { # on level complete
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Good!"""
	},
	"6_0" : { # gomory cut pt 3
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Here's an interesting case..."""
	},
	"6_1" : { # after a bunch of cuts
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Seems like this will go on forever... doesn't it?"""
	},
	"6_2" : { # after a bunch of cuts
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """[color=red][b]Gomory cuts[/b][/color] Are efficient, but they're not perfect.
They're guaranteed to converge, but not necessarily in a reasonable amount of time. They can get stuck like this."""
	},
	"6_3" : { # after a bunch of cuts
		"size" : Vector2(400, 200),
		"position" : Vector2(100, 100),
		"text" : """Don't worry, in this game, [b]close enough is good enough[/b]!
If you get [b]close enough[/b] to a solution, the polygon will [b]correct itself[/b]."""
	}
}

# - child nodes -
@onready var ANIM_PLAYER = $AnimationPlayer
@onready var LEVEL = null # assigned dynamically
@onready var MENU = $CanvasLayer/HUD/MENU
@onready var TUTORIAL_POPUP = $CanvasLayer/HUD/TUTORIAL/tutorial_popup
@onready var TUTORIAL_TEXT = $CanvasLayer/HUD/TUTORIAL/tutorial_popup/tutorial_text
@onready var TUTORIAL_NEXT_BUTTON = $CanvasLayer/HUD/TUTORIAL/tutorial_popup/tutorial_next

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_level(level_dicts[current_level_idx])

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
	# LEVEL._on_show_hull_button_down() # show hull
	# LEVEL._on_show_hull_button_up() # hide hull

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
	
func _on_level_completed(_rank: String, _rank_bonus: int, _budget_bonus: int, _remaining_circle: int, _remaining_gomory: int, _remaining_split: int):
	current_level_idx += 1
	cuts_made_on_current_level = 0
	# TESTING
	if current_level_idx < level_dicts.size():
		load_level(level_dicts[current_level_idx])
	else:
		get_tree().paused = false
		quit_gamemode.emit()
		queue_free()

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
