@tool
extends Node2D

var radius: float = 2
var color: Color = Color(0.5, 0.5, 0.5)
@export var alpha: float = 1.0

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

func play():
	ANIM_PLAYER.play("fade")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

func _draw():
	draw_circle(Vector2(0, 0), radius, Color(color, alpha))

func _on_animation_player_animation_finished(anim_name:StringName):
	if anim_name == "fade":
		queue_free()
