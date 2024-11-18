extends Camera2D
## Camera scene that handles zooming and panning.

# Variables to control the zoom and panning
var zoom_min = 1.0
var zoom_max = 5.0
var zoom_step = 0.1
var is_panning = false
var last_mouse_pos = Vector2()
var scene_rect = Rect2(Vector2(), Vector2(1920, 1080)) # just a default value

## signal to notify the zoom level change, where zoom_level=0..1
signal zoom_level_changed(zoom_level: float)

# child nodes
@onready var m1_drag_timer = $m1_drag_timer

func _ready():
	# set scene_rect
	scene_rect.size = get_viewport_rect().size
	# center the camera
	position = scene_rect.position + scene_rect.size / 2
	# Initialize zoom level
	zoom = Vector2(1, 1)

func _input(event):
	# Handle zoom in/out
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

		# Handle panning start/stop
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_pos = event.position
			else:
				is_panning = false
		# Panning with mouse 1 shouldn't be instantaneous. Wait 5 frames before panning
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				m1_drag_timer.start()
			else:
				is_panning = false

	# Handle panning movement
	elif event is InputEventMouseMotion and is_panning:
		pan_camera(event.position)

## function called on timer timeout to determine when to start panning with mouse 1
func _on_m1_drag_timer_timeout():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_panning = true
		last_mouse_pos = get_viewport().get_mouse_position()
	else:
		is_panning = false

func zoom_in():
	var new_zoom = zoom + Vector2(zoom_step, zoom_step)
	if new_zoom.x <= zoom_max and new_zoom.y <= zoom_max:
		adjust_zoom(new_zoom)

func zoom_out():
	var new_zoom = zoom - Vector2(zoom_step, zoom_step)
	if new_zoom.x >= zoom_min and new_zoom.y >= zoom_min:
		adjust_zoom(new_zoom)

func adjust_zoom(new_zoom):
	var old_zoom = zoom
	zoom = new_zoom
	var mouse_world_pos = get_global_mouse_position()
	var camera_pos_delta = (mouse_world_pos - position) * (1 - old_zoom.x / new_zoom.x)
	position += camera_pos_delta
	clamp_camera_position()
	zoom_level_changed.emit( (new_zoom.x - zoom_min) / (zoom_max - zoom_min) )

func pan_camera(new_mouse_pos):
	if zoom != Vector2(1, 1): # Only pan if zoomed in
		var delta = last_mouse_pos - new_mouse_pos
		position += delta / zoom
		last_mouse_pos = new_mouse_pos
		clamp_camera_position()

func clamp_camera_position():
	var screen_size = get_viewport_rect().size / zoom
	var camera_limits_min = scene_rect.position + (screen_size / 2)
	var camera_limits_max = scene_rect.position + scene_rect.size - (screen_size / 2)
	position.x = clamp(position.x, camera_limits_min.x, camera_limits_max.x)
	position.y = clamp(position.y, camera_limits_min.y, camera_limits_max.y)
