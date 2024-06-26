extends Node

@onready var canvas_layer  = CanvasLayer.new()
@onready var container = VBoxContainer.new()

func _ready() -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	add_child(canvas_layer)
	canvas_layer.layer = 1_000_000 # on top of everything
	canvas_layer.add_child(container)

## TRUE IF DEBUG MODE IS ENABLED
func is_enabled() -> bool:
	return OS.is_debug_build()

## DEBUG LOGGING [br]
## Prints a message on the top left corner of the screen for a specified amount of time
func log(message: Variant, seconds: float = 2) -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	var label = Label.new() # message label
	label.text = str(message)
	# black outline, white text
	label.set("theme_override_constants/outline_size", 2)
	label.set("theme_override_colors/font_outline_color", Color.BLACK)
	container.add_child(label)
	container.move_child(label, 0)
	# wait for the specified time, then erase the label
	await get_tree().create_timer(seconds).timeout
	container.remove_child(label)
	label.queue_free()