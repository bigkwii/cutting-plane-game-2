extends Node2D

@export var radius: float = 15
@export var color: Color = Color(1, 1, 1, 1)
@export var growing_factor: float = 0 # from 0 to 1

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

func _draw():
	draw_circle(Vector2(0, 0), growing_factor * radius, color, false, 1, true)

func play_click(backwards = false):
	if backwards:
		ANIM_PLAYER.play_backwards("click")
	else:
		ANIM_PLAYER.play("click")

func _on_animation_player_animation_finished(anim_name:StringName):
	if anim_name == "click":
		queue_free()
