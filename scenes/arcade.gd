extends Node2D
## scene than handles the arcade mode logic

# - signals -
signal quit_gamemode

# - vars -
var level_paths: Array[String] = [
	"res://levels/demo/1.json",
	"res://levels/demo/2.json",
	"res://levels/demo/3.json",
	"res://levels/demo/4.json",
	"res://levels/demo/5.json",
	"res://levels/demo/6.json",
	"res://levels/demo/7.json",
	"res://levels/demo/8.json",
	"res://levels/demo/9.json"
]
var current_level_idx: int = 0

## total score
var total_score = 0

## array of dictionaries to store the scores and ranks of each level
var results: Array[Dictionary] = []

# - child nodes -
@onready var TOTAL_SCORE_LABEL = $CanvasLayer/HUD/score_container/total_score_label
@onready var MENU = $CanvasLayer/MENU
@onready var LEVEL = null # assigned dynamically
@onready var ANIM_PLAYER = $AnimationPlayer
@onready var RANK_LABEL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/RankHBoxContainer/rank_label
@onready var RANK_MESSAGE = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/rank_message
@onready var RANK_BONUS_LABEL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/RankBonuxHBoxContainer/bonus_label
@onready var BUDGET_BONUS_LABEL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/VBoxContainer/BudgetBonusHBoxContainer2/budget_label
@onready var BUDGET_BONUS_DETAIL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/VBoxContainer/detail
@onready var LEVEL_FINISH_POPUP = $CanvasLayer/LEVEL_FINISH_POPUP
@onready var NEXT_LEVEL_BTN = $CanvasLayer/LEVEL_FINISH_POPUP/panel/next_level_btn

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	# fill the results array with initial values
	for i in range(level_paths.size()):
		results.append({
			"score": 0,
			"rank": "-"
		})
	# create and add the level scene
	load_level(level_paths[current_level_idx])

func load_level(level_json_path: String):
	if LEVEL != null:
		LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.level_json_path = level_json_path
	LEVEL.INFINITE_BUDGET = false
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)
	LEVEL.level_completed.connect(_on_level_completed)
	LEVEL.cut_made.connect(_on_cut_made)

func _on_level_open_menu():
	get_tree().paused = true
	MENU.visible = true

func _on_x_pressed():
	get_tree().paused = false
	MENU.visible = false

func _on_exit_pressed():
	get_tree().paused = false
	quit_gamemode.emit()
	queue_free()

func _on_cut_made(score: int):
	# update the total score
	total_score += score
	TOTAL_SCORE_LABEL.text = str(total_score)

func _on_level_completed(rank: String, rank_bonus: int, budget_bonus: int, remaining_circle: int, remaining_gomory: int, remaining_split: int):
	RANK_LABEL.text = rank
	RANK_MESSAGE.text = SCORE.RANK_MESSAGES[rank]
	RANK_BONUS_LABEL.text = str(rank_bonus)
	BUDGET_BONUS_LABEL.text = str(budget_bonus)
	BUDGET_BONUS_DETAIL.text = "(%d X %d + %d X %d + %d X %d)" % \
		[remaining_circle, SCORE.CIRCLE_CUT_BONUS, remaining_gomory, SCORE.GOMORY_CUT_BONUS, remaining_split, SCORE.SPLIT_CUT_BONUS]
	# update total
	total_score += rank_bonus + budget_bonus
	# update the results array
	results[current_level_idx]["score"] = LEVEL.score
	results[current_level_idx]["rank"] = rank
	CRT.play_zoom()
	play_level_finish_anim()

func _on_next_level_btn_pressed():
	DEBUG.log("Next level button pressed", 10)
	if current_level_idx < level_paths.size() - 1:
		current_level_idx += 1
		load_level(level_paths[current_level_idx])
		CRT.play_buzz()
		LEVEL_FINISH_POPUP.visible = false
	else:
		# final popup
		pass

# - animations for coordinating popus with crt filter -
func play_level_finish_anim():
	ANIM_PLAYER.play("level_finish")

func play_next_level_anim():
	ANIM_PLAYER.play("next_level")
