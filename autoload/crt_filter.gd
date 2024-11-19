extends CanvasLayer
## scene for CRT filter effect. mostly for controlling animations. Now a global scene!

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
func _input(event):
	if event.is_action_pressed("toggle_crt_filter"):
		visible = !visible

## buzz is 1.5s long
func play_buzz(speed = 1.0):
	ANIM_PLAYER.play("buzz", speed)

## zoom is 0.5s long
func play_zoom(speed = 1.0):
	ANIM_PLAYER.play("zoom", speed)
