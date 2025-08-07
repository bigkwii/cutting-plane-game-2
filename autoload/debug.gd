extends Node
## Debug logging and other utilities.

@onready var canvas_layer  = CanvasLayer.new()
@onready var log_container = VBoxContainer.new()
@onready var fps_container = HBoxContainer.new()
@onready var fps_now_label = Label.new()
@onready var fps_avg_label = Label.new()
@onready var fps_color = FPS_BAD
const FPS_BAD = Color(1, 0, 0, 1)
const FPS_OK = Color(1, 1, 0, 1)
const FPS_GOOD = Color(0, 1, 0, 1)
var show_fps: bool = false

func _ready() -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	InputMap.load_from_project_settings() # workaround for a bug where @tool scripts load before the input map
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas_layer)
	canvas_layer.layer = 1_000_000 # on top of everything
	canvas_layer.add_child(log_container)

	fps_avg_label.set("theme_override_constants/outline_size", 2)
	fps_avg_label.set("theme_override_colors/font_color", Color(0, 1, 0, 1))
	fps_avg_label.set("theme_override_colors/font_outline_color", Color(0, 0, 0, 1))
	fps_avg_label.set("theme_override_font_sizes/font_size", 14)
	fps_container.add_child(fps_avg_label)

	fps_now_label.set("theme_override_constants/outline_size", 2)
	fps_now_label.set("theme_override_colors/font_color", Color(0, 1, 0, 1))
	fps_now_label.set("theme_override_colors/font_outline_color", Color(0, 0, 0, 1))
	fps_now_label.set("theme_override_font_sizes/font_size", 14)
	fps_container.add_child(fps_now_label)

	fps_container.set("layout_direction", Control.LAYOUT_DIRECTION_RTL)
	canvas_layer.add_child(fps_container)

	fps_container.set("mouse_filter", Control.MOUSE_FILTER_IGNORE)
	log_container.set("mouse_filter", Control.MOUSE_FILTER_IGNORE)

	show_fps = true

func _process(delta) -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	if not show_fps:
		fps_now_label.text = ""
		fps_avg_label.text = ""
		return
	var fps_now: float = 1/delta
	var fps_avg: float = Engine.get_frames_per_second()

	if fps_now < 29.9:
		fps_now_label.set("theme_override_colors/font_color", FPS_BAD)
	elif fps_now < 59.9:
		fps_now_label.set("theme_override_colors/font_color", FPS_OK)
	else:
		fps_now_label.set("theme_override_colors/font_color", FPS_GOOD)

	if fps_avg < 29.9:
		fps_avg_label.set("theme_override_colors/font_color", FPS_BAD)
	elif fps_avg < 59.9:
		fps_avg_label.set("theme_override_colors/font_color", FPS_OK)
	else:
		fps_avg_label.set("theme_override_colors/font_color", FPS_GOOD)

	fps_now_label.text = "FPS: %d" % fps_now
	fps_avg_label.text = "(%d)" % fps_avg

## TRUE IF DEBUG MODE IS ENABLED
func is_enabled() -> bool:
	return OS.is_debug_build()

## DEBUG LOGGING [br]
## Prints a message on the top left corner of the screen for a specified amount of time
func log(message: Variant, seconds: float = 2) -> void:
	# do NOT show debug on release builds
	if not is_enabled():
		return
	print(message)
	var label = Label.new() # message label
	label.text = str(message)
	# black outline, white text
	label.set("theme_override_constants/outline_size", 2)
	label.set("theme_override_colors/font_color", Color(1, 1, 1, 0.5))
	label.set("theme_override_colors/font_outline_color", Color(0, 0, 0, 1))
	label.set("theme_override_font_sizes/font_size", 18)
	log_container.add_child(label)
	log_container.move_child(label, 0)
	# wait for the specified time, then erase the label
	await get_tree().create_timer(seconds).timeout
	if label in log_container.get_children(): # could have been deleted some other way
		log_container.remove_child(label)
		label.queue_free()

## Clears the debug log
func clear_log() -> void:
	if not is_enabled():
		return
	for child in log_container.get_children():
		log_container.remove_child(child)
		child.queue_free()

func _input(event):
	if not is_enabled():
		return
	if event.is_action_pressed("DEBUG_clear_log"):
		clear_log()
	if event.is_action_pressed("DEBUG_show_fps"):
		show_fps = not show_fps
