extends CanvasLayer
## scene for CRT filter effect. mostly for controlling animations.

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## buzz is 1.5s long
func play_buzz(speed = 1.0):
	ANIM_PLAYER.play("buzz", speed)

## zoom is 0.5s long
func play_zoom(speed = 1.0):
	ANIM_PLAYER.play("zoom", speed)