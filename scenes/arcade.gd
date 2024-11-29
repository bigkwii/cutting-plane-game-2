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
@onready var GAME_FINISH_POPUP = $CanvasLayer/GAME_FINISH_POPUP

@onready var SUBMIT_SCORE_BTN = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/HBoxContainer/submit_btn
@onready var SUBMIT_SCORE_NAME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/HBoxContainer/name_entry

@onready var GAME_FINISH_TOTAL_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/scoreHBoxContainer2/score_label
@onready var GAME_FINISH_EXIT_BTN = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/exit

@onready var GAME_FINISH_LVL1_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl1/hbox/rank
@onready var GAME_FINISH_LVL1_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl1/score
@onready var GAME_FINISH_LVL2_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl2/hbox/rank
@onready var GAME_FINISH_LVL2_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl2/score
@onready var GAME_FINISH_LVL3_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl3/hbox/rank
@onready var GAME_FINISH_LVL3_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl3/score
@onready var GAME_FINISH_LVL4_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl4/hbox/rank
@onready var GAME_FINISH_LVL4_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl4/score
@onready var GAME_FINISH_LVL5_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl5/hbox/rank
@onready var GAME_FINISH_LVL5_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl5/score
@onready var GAME_FINISH_LVL6_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl6/hbox/rank
@onready var GAME_FINISH_LVL6_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl6/score
@onready var GAME_FINISH_LVL7_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl7/hbox/rank
@onready var GAME_FINISH_LVL7_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl7/score
@onready var GAME_FINISH_LVL8_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl8/hbox/rank
@onready var GAME_FINISH_LVL8_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl8/score
@onready var GAME_FINISH_LVL9_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl9/hbox/rank
@onready var GAME_FINISH_LVL9_SCORE = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl9/score

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
	get_tree().paused = false

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
	if current_level_idx < level_paths.size() - 1:
		current_level_idx += 1
		load_level(level_paths[current_level_idx])
		CRT.play_buzz()
		LEVEL_FINISH_POPUP.visible = false
	else: # after final level
		LEVEL_FINISH_POPUP.visible = false
		GAME_FINISH_POPUP.visible = true
		GAME_FINISH_TOTAL_SCORE.text = str(total_score)
		# assign all the results
		GAME_FINISH_LVL1_RANK.text = results[0]["rank"]
		GAME_FINISH_LVL1_SCORE.text = str(results[0]["score"])
		GAME_FINISH_LVL2_RANK.text = results[1]["rank"]
		GAME_FINISH_LVL2_SCORE.text = str(results[1]["score"])
		GAME_FINISH_LVL3_RANK.text = results[2]["rank"]
		GAME_FINISH_LVL3_SCORE.text = str(results[2]["score"])
		GAME_FINISH_LVL4_RANK.text = results[3]["rank"]
		GAME_FINISH_LVL4_SCORE.text = str(results[3]["score"])
		GAME_FINISH_LVL5_RANK.text = results[4]["rank"]
		GAME_FINISH_LVL5_SCORE.text = str(results[4]["score"])
		GAME_FINISH_LVL6_RANK.text = results[5]["rank"]
		GAME_FINISH_LVL6_SCORE.text = str(results[5]["score"])
		GAME_FINISH_LVL7_RANK.text = results[6]["rank"]
		GAME_FINISH_LVL7_SCORE.text = str(results[6]["score"])
		GAME_FINISH_LVL8_RANK.text = results[7]["rank"]
		GAME_FINISH_LVL8_SCORE.text = str(results[7]["score"])
		GAME_FINISH_LVL9_RANK.text = results[8]["rank"]
		GAME_FINISH_LVL9_SCORE.text = str(results[8]["score"])

# - animations for coordinating popus with crt filter -
## this animation opens the menu at the end and pauses the game
func play_level_finish_anim():
	ANIM_PLAYER.play("level_finish")

## toggles pause
func toggle_pause():
	get_tree().paused = !get_tree().paused

func _on_name_entry_text_changed(new_text:String):
	var allowed_chars = " -_<>+=/*'0123456789qwertyuiopasdfghjklñzxcvbnmQWERTYUIOPASDFGHJKLÑZXCVBNM!?.,"
	var old_caret_pos = SUBMIT_SCORE_NAME.caret_column
	var filtered_text = ""
	for character in new_text:
		if allowed_chars.find(character) != -1:
			filtered_text += character
	SUBMIT_SCORE_NAME.text = filtered_text
	SUBMIT_SCORE_NAME.caret_column = old_caret_pos

func _on_submit_btn_pressed():
	DEBUG.log("submitting score...")
	SUBMIT_SCORE_BTN.disabled = true
	SUBMIT_SCORE_BTN.text = "LOADING..."
	var submitted: bool = await Leaderboards.post_guest_score("tcpgv2-arcade-lJ2Z", total_score, SUBMIT_SCORE_NAME.text, {}, 0, true)
	if submitted:
		DEBUG.log("score submitted")
		SUBMIT_SCORE_BTN.disabled = true
		SUBMIT_SCORE_BTN.text = "SUBMITTED"
	else:
		SUBMIT_SCORE_BTN.text = "FAILED.\nTRY AGAIN"
		SUBMIT_SCORE_BTN.disabled = false
		DEBUG.log("score not submitted")
