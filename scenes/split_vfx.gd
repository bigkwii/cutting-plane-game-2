@tool
extends Node2D

@export var width: float = 100
@export var length: float = 1000
@export var is_horizontal = false
@export var growing_factor: float = 0 # from 0 to 1
@export var color: Color = Color(1, 1, 1, 1)
@export var successful_cut: bool = false

signal animation_finished # TODO: this name is already used by anim player

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

func _process(_delta):
	queue_redraw()

func _draw():
	if is_horizontal:
		draw_line(Vector2(-length, growing_factor * width), Vector2(length, growing_factor * width), color, 1)
		draw_line(Vector2(-length, -1 * growing_factor * width), Vector2(length, -1 * growing_factor * width), color, 1)
	else:
		draw_line(Vector2(growing_factor * width, -length), Vector2(growing_factor * width, length), color, 1)
		draw_line(Vector2(-1 * growing_factor * width, -length), Vector2(-1 * growing_factor * width, length), color, 1)

func check_if_successful_cut():
	animation_finished.emit() # !!! TODO !!! i'm not too happy with this solution
	if successful_cut:
		play_success()
	else:
		play_failure()

# play the grow animation
func play_grow():
	ANIM_PLAYER.play("grow")

# play the success animation
func play_success():
	ANIM_PLAYER.play("success")

# play the failed animation
func play_failure():
	ANIM_PLAYER.play("failure")