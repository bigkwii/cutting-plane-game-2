extends Node2D

@onready var POLYGON = $polygon
@onready var VFXS = $vfxs
@onready var FREE_PLAY_LEVEL_SELECT = $CanvasLayer/UI/free_play_level_select
@onready var ARCADE_MODE_POPUP = $CanvasLayer/UI/arcade_mode_popup

# - signals -
signal start_free_play(level_path: String)
signal start_arcade

# - preloaded scenes -
var cut_vfx = preload("res://scenes/cut_vfx.tscn")
var level_scene = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	POLYGON.build_polygon()
	FREE_PLAY_LEVEL_SELECT.visible = false
	ARCADE_MODE_POPUP.visible = false
	DEBUG.log("This is exported with debug enabled. Please let me know if anything weird happens. You can clear the debug log with CTRL+L.", 20)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	# make polygon rotate
	# change axis of rotation
	POLYGON.rotation += 0.15 * delta
	
	# fire random vfxs every 1-2 seconds
	if randf() < delta * 2:
		var vfx = cut_vfx.instantiate()
		vfx.position = Vector2(randf_range(-400, 400), randf_range(-300, 300))
		vfx.rotation = randf() * 360
		VFXS.add_child(vfx)
		vfx.play()

func _input(event):
	# close menus with esc
	if event.is_action_pressed("esc"):
		if FREE_PLAY_LEVEL_SELECT.visible:
			FREE_PLAY_LEVEL_SELECT.visible = false
		elif ARCADE_MODE_POPUP.visible:
			ARCADE_MODE_POPUP.visible = false

func _on_exit_btn_pressed():
	get_tree().quit()


func _on_free_play_btn_pressed():
	if not FREE_PLAY_LEVEL_SELECT.visible:
		FREE_PLAY_LEVEL_SELECT.visible = true


func _on_x_btn_pressed():
	if FREE_PLAY_LEVEL_SELECT.visible:
		FREE_PLAY_LEVEL_SELECT.visible = false

# - free play level selector -

func _on_lvl_1_btn_pressed():
	start_free_play.emit("res://levels/demo/1.json")

func _on_lvl_2_btn_pressed():
	start_free_play.emit("res://levels/demo/2.json")


func _on_lvl_3_btn_pressed():
	start_free_play.emit("res://levels/demo/3.json")

func _on_lvl_4_btn_pressed():
	start_free_play.emit("res://levels/demo/4.json")

func _on_lvl_5_btn_pressed():
	start_free_play.emit("res://levels/demo/5.json")

func _on_lvl_6_btn_pressed():
	start_free_play.emit("res://levels/demo/6.json")

func _on_lvl_7_btn_pressed():
	start_free_play.emit("res://levels/demo/7.json")

func _on_lvl_8_btn_pressed():
	start_free_play.emit("res://levels/demo/8.json")

func _on_lvl_9_btn_pressed():
	start_free_play.emit("res://levels/demo/9.json")

# - arcade mode -

func _on_arcade_btn_pressed():
	if not ARCADE_MODE_POPUP.visible:
		ARCADE_MODE_POPUP.visible = true

func _on_arcade_x_btn_pressed():
	if ARCADE_MODE_POPUP.visible:
		ARCADE_MODE_POPUP.visible = false

func _on_start_arcade_pressed():
	start_arcade.emit()
	