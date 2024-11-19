@tool
extends Button
## button for selecting cut types

## all cut types
@export_enum("debug", "circle", "gomory", "h_split", "v_split") var cut_type: String = "debug":
	set(value):
		_update_cut_type_icon(value)
		cut_type = value

## true if this is the selected cut type
@export var selected: bool = false:
	set(value):
		if value and budget != 0:
			_set_font_color(Color(1.0, 0.0, 0.0))
		else:
			_set_font_color(Color(1.0, 1.0, 1.0))
		selected = value
		queue_redraw()

## determines if the budget should be displayed on the button
@export var visible_budget: bool = true:
	set(value):
		visible_budget = value
		queue_redraw()

## budget to be displayed on the button. -1 is infinite
@export var budget: int = -1:
	set(value):
		_update_budget_label(value)
		budget = value

## radius of the background circle for budget display
@export var budget_circle_radius = 30
## color of the background circle for budget display
var budget_circle_color = Color(1.0, 1.0, 1.0)

## where to draw the budget circle
var _budget_circle_position = Vector2(0, 0)

## flag to determine when to draw the circle cut icon
var _draw_circle_cut_icon: bool = false

## flag to determine when to draw the v split cut icon
var _draw_v_split_cut_icon: bool = false

## flag to determine when to draw the h split cut icon
var _draw_h_split_cut_icon: bool = false

## color of the icons
var icon_color = Color(1.0, 1.0, 1.0)

# - child nodes -
@onready var BUDGET_LEFT_LABEL = $budget_left_label

# TODO: make the actual icons for the cut types (Circle for circle, parallel lines for splits)
func _draw():
	# draw a solid red circle behind the budget text
	if not BUDGET_LEFT_LABEL: # <- TODO: ugh...
		return
	if visible_budget:
		BUDGET_LEFT_LABEL.visible = true
		draw_circle(_budget_circle_position, budget_circle_radius, budget_circle_color)
	else:
		BUDGET_LEFT_LABEL.visible = false
	# draw the cut type icon
	# NOTE: THIS IS A TERRIBLE WAY TO DO THIS. I'M SORRYYYYYYYYYYYYY
	if _draw_circle_cut_icon:
		# get exact center of the button
		var center = size / 2
		# draw a circle
		if disabled:
			draw_circle(center, 25, Color(0.87, 0.87, 0.87, 0.19), false, 4.0)
		else:
			draw_circle(center, 25, icon_color, false, 4.0)
	if _draw_v_split_cut_icon:
		# get exact center of the button
		var center = size / 2
		# draw 2 vertical lines
		if disabled:
			draw_line(Vector2(center.x - 10, center.y - 25), Vector2(center.x - 10, center.y + 25), Color(0.87, 0.87, 0.87, 0.19), 4.0)
			draw_line(Vector2(center.x + 10, center.y - 25), Vector2(center.x + 10, center.y + 25), Color(0.87, 0.87, 0.87, 0.19), 4.0)
		else:
			draw_line(Vector2(center.x - 10, center.y - 25), Vector2(center.x - 10, center.y + 25), icon_color, 4.0)
			draw_line(Vector2(center.x + 10, center.y - 25), Vector2(center.x + 10, center.y + 25), icon_color, 4.0)
	if _draw_h_split_cut_icon:
		# get exact center of the button
		var center = size / 2
		# draw 2 horizontal lines
		if disabled:
			draw_line(Vector2(center.x - 25, center.y - 10), Vector2(center.x + 25, center.y - 10), Color(0.87, 0.87, 0.87, 0.19), 4.0)
			draw_line(Vector2(center.x - 25, center.y + 10), Vector2(center.x + 25, center.y + 10), Color(0.87, 0.87, 0.87, 0.19), 4.0)
		else:
			draw_line(Vector2(center.x - 25, center.y - 10), Vector2(center.x + 25, center.y - 10), icon_color, 4.0)
			draw_line(Vector2(center.x - 25, center.y + 10), Vector2(center.x + 25, center.y + 10), icon_color, 4.0)

func _ready():
	_budget_circle_position = BUDGET_LEFT_LABEL.position + BUDGET_LEFT_LABEL.size / 2
	queue_redraw()

func _update_cut_type_icon(value: String): # NOTE: terrible way to do this
	if value == "gomory":
		text = "G"
		_draw_circle_cut_icon = false
		_draw_v_split_cut_icon = false
		_draw_h_split_cut_icon = false
	elif value == "circle":
		text = ""
		_draw_circle_cut_icon = true
		_draw_v_split_cut_icon = false
		_draw_h_split_cut_icon = false
	elif value == "h_split":
		text = ""
		_draw_circle_cut_icon = false
		_draw_v_split_cut_icon = false
		_draw_h_split_cut_icon = true
	elif value == "v_split":
		text = ""
		_draw_circle_cut_icon = false
		_draw_v_split_cut_icon = true
		_draw_h_split_cut_icon = false
	elif value == "debug":
		text = "D"
		_draw_circle_cut_icon = false
		_draw_v_split_cut_icon = false
		_draw_h_split_cut_icon = false
	queue_redraw()

## updates the budget label. called as part of the setter.
## [br]
## TODO: this is ugly as hell, but the setter was getting called before the onready var was set and crashing.
func _update_budget_label(value: int):
	if value == 0:
		budget_circle_color = Color(0.4, 0.4, 0.4)
	elif value > 0:
		budget_circle_color = Color(1.0, 0.0, 0.0)
	else:
		budget_circle_color = Color(1.0, 1.0, 1.0)
	if not BUDGET_LEFT_LABEL: # <- TODO: ugh...
		queue_redraw()
		return
	if value == -1:
		BUDGET_LEFT_LABEL.text = "INF"
	else:
		BUDGET_LEFT_LABEL.text = str(value)
	queue_redraw()

## sets the font color
func _set_font_color(color: Color):
	icon_color = color
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_focus_color", color)
	queue_redraw()
