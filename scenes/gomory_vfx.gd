@tool
extends Node2D

signal animation_finished

# the data for the vfx
@export var data: Dictionary = {}

@onready var ANIM_PLAYER = $AnimationPlayer

# - child nodes -
@onready var EQ1 = $short/VBoxContainer/eq1
@onready var EQ2 = $short/VBoxContainer/eq2
@onready var EQ3 = $short/VBoxContainer/eq3
@onready var EQ4 = $short/VBoxContainer/eq4
@onready var LINE1 = $line1
@onready var LINE2 = $line2
@onready var LINE3 = $line3
@onready var LINE4 = $line4

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func play_short():
	# set origin on clicked vertex
	global_position = data["selected_vertex"] * data["scaling"] + data["offset"]
	# fill in the equation labels
	var eq1_y_sign = " + " if data["A1y"] >= 0 else " - "
	var eq2_y_sign = " + " if data["A2y"] >= 0 else " - "
	var eq3_y_sign = " + " if data["GMIaLatticey"] >= 0 else " - "
	EQ1.text = str(snapped(data["A1x"], 0.001)) + "x" + eq1_y_sign + str(abs(snapped(data["A1y"], 0.001))) + "y" + " = " + str(snapped(data["B1"], 0.001))
	EQ2.text = str(snapped(data["A2x"], 0.001)) + "x" + eq2_y_sign + str(abs(snapped(data["A2y"], 0.001))) + "y" + " = " + str(snapped(data["B2"], 0.001))
	EQ3.text = str(snapped(data["badGMIaLatticex"], 0.001)) + "x" + eq3_y_sign + str(abs(snapped(data["badGMIaLatticey"], 0.001))) + "y" + " = " + str(snapped(data["badGMIb"], 0.001))
	EQ4.text = str(snapped(data["GMIaLatticex"], 0.001)) + "x" + eq3_y_sign + str(abs(snapped(data["GMIaLatticey"], 0.001))) + "y" + " = " + str(snapped(data["GMIb"], 0.001))
	# make the lines
	# line 1 goes from data["neigh_before"] to data["selected_vertex"]
	LINE1.global_position = data["neigh_before"] * data["scaling"] + data["offset"]
	LINE1.rotation = (data["selected_vertex"] - data["neigh_before"]).angle()
	# line 2 goes from data["neigh_after"] to data["selected_vertex"]
	LINE2.global_position = data["neigh_after"] * data["scaling"] + data["offset"]
	LINE2.rotation = (data["selected_vertex"] - data["neigh_after"]).angle()
	# line 3 goes from data["bad_point1"] to data["bad_point2"]
	LINE3.global_position = data["bad_point1"] * data["scaling"] + data["offset"]
	LINE3.rotation = (data["bad_point2"] - data["bad_point1"]).angle()
	# line 4 goes from data["point1"] to data["point2"]
	LINE4.global_position = data["point1"] * data["scaling"] + data["offset"]
	LINE4.rotation = (data["point2"] - data["point1"]).angle()
	ANIM_PLAYER.play("short")

func play_long():
	ANIM_PLAYER.play("long")

func _on_animation_player_animation_finished(anim_name:StringName):
	if anim_name == "short" or anim_name == "long":
		animation_finished.emit()