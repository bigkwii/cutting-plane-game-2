extends Camera2D
## Camera scene that handles zooming and panning for both mouse and touch devices.

# Variables to control the zoom and panning
var zoom_min = 1.0
var zoom_max = 5.0
var zoom_step = 0.1
var is_panning = false
var last_input_pos = Vector2()
var scene_rect = Rect2(Vector2(), Vector2(1920, 1080)) # just a default value
var touch_positions = {}
var initial_pinch_distance = 0
var initial_pinch_zoom = Vector2(1, 1)

signal zoom_level_changed(zoom_level: float)

@onready var m1_drag_timer = $m1_drag_timer

func _ready():
	scene_rect.size = get_viewport_rect().size
	position = scene_rect.position + scene_rect.size / 2
	zoom = Vector2(1, 1)

func _input(event):
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		handle_mouse_wheel_zoom(event)
		handle_mouse_pan_start(event)

	# Mouse motion pan
	elif event is InputEventMouseMotion and is_panning:
		pan_camera(event.position)
	
	# Touch input handling
	if event is InputEventScreenTouch:
		handle_touch_start(event)
	
	if event is InputEventScreenDrag:
		handle_touch_drag(event)

func handle_mouse_wheel_zoom(event):
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_in()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_out()

func handle_mouse_pan_start(event):
	# Panning with middle or right mouse button
	if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			# is_panning = true
			# last_input_pos = event.position
			is_panning = true
			last_input_pos = get_viewport().get_mouse_position()
		else:
			is_panning = false

	# Panning with left mouse button (delayed start)
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			m1_drag_timer.start()
		else:
			is_panning = false

func handle_touch_start(event):
	# Track touch positions
	if event.pressed:
		touch_positions[event.index] = event.position
	else:
		touch_positions.erase(event.index)
	
	# Pinch zoom detection
	if touch_positions.size() == 2:
		var touch_points = touch_positions.values()
		initial_pinch_distance = touch_points[0].distance_to(touch_points[1])
		initial_pinch_zoom = zoom

func handle_touch_drag(event):
	# # Single finger pan
	# if touch_positions.size() == 1:
	# 	pan_camera(event.position)
	
	# Two-finger pinch zoom
	if touch_positions.size() == 2:
		var touch_points = touch_positions.values()
		var current_distance = touch_points[0].distance_to(touch_points[1])
		
		# Calculate zoom factor
		var zoom_factor = current_distance / initial_pinch_distance
		var new_zoom = initial_pinch_zoom * zoom_factor
		
		# Apply zoom
		new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
		new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)
		
		if new_zoom != zoom:
			adjust_zoom(new_zoom)
		
		# Update touch positions for continued tracking
		touch_positions[event.index] = event.position

func _on_m1_drag_timer_timeout():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_panning = true
		last_input_pos = get_viewport().get_mouse_position()
	else:
		is_panning = false

func pan_camera(new_input_pos):
	if zoom != Vector2(1, 1): # Only pan if zoomed in
		var delta = last_input_pos - new_input_pos
		position += delta / zoom
		last_input_pos = new_input_pos
		clamp_camera_position()

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
	zoom_level_changed.emit((new_zoom.x - zoom_min) / (zoom_max - zoom_min))

func clamp_camera_position():
	var screen_size = get_viewport_rect().size / zoom
	var camera_limits_min = scene_rect.position + (screen_size / 2)
	var camera_limits_max = scene_rect.position + scene_rect.size - (screen_size / 2)
	position.x = clamp(position.x, camera_limits_min.x, camera_limits_max.x)
	position.y = clamp(position.y, camera_limits_min.y, camera_limits_max.y)
	