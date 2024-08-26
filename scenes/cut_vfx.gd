@tool
extends Node2D

@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	ANIM_PLAYER.play("RESET")

# play the cut animation
func play():
	ANIM_PLAYER.play("cut")
