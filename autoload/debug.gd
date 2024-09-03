@tool # added so other @tool scripts can access this script in the editor

extends Node
## Debug logging and other utilities.

@onready var canvas_layer  = CanvasLayer.new()
@onready var container = VBoxContainer.new()

func _ready() -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	InputMap.load_from_project_settings() # workaround for a bug where @tool scripts load before the input map
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
	label.set("theme_override_colors/font_color", Color(1, 1, 1, 0.5))
	label.set("theme_override_colors/font_outline_color", Color(0, 0, 0, 1))
	container.add_child(label)
	container.move_child(label, 0)
	# wait for the specified time, then erase the label
	await get_tree().create_timer(seconds).timeout
	if label in container.get_children(): # could have been deleted some other way
		container.remove_child(label)
		label.queue_free()

## Clears the debug log
func clear_log() -> void:
	if not is_enabled():
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _input(event):
	if not is_enabled():
		return
	if event.is_action_pressed("DEBUG_clear_log"):
		clear_log()
