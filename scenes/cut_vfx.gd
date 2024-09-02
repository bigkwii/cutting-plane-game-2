@tool
extends Node2D

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

# play the cut animation
func play():
	ANIM_PLAYER.play("cut")

# delete itself when the animation is finished
func _on_animation_player_animation_finished(anim_name: StringName):
	if anim_name == "cut":
		queue_free()
