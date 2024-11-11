@tool
extends Node2D

@export var radius: float = 100
@export var growing_factor: float = 0 # from 0 to 1
@export var color: Color = Color(1, 1, 1, 1)

signal grow_animation_finished # TODO: this name is already used by anim player

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

func _process(_delta):
	queue_redraw() # TODO: this seems pretty inefficient... maybe draw with shaders?

func _draw():
	draw_circle(Vector2(0, 0), growing_factor * radius, color, false, 1.5)

# play the grow animation
func play_grow():
	ANIM_PLAYER.play("grow")

# play the success animation
func play_success():
	ANIM_PLAYER.play("success")

# play the failed animation
func play_failure():
	ANIM_PLAYER.play("failure")

func _on_animation_player_animation_finished(anim_name:StringName):
	if anim_name == "grow":
		grow_animation_finished.emit()
