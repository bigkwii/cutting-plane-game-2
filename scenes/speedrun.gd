extends Node2D
## speedrun scene.
## [br][br]
## basically the same as arcade, but instead of keeping score, it keeps time, and the player must get S ranks to progress.

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

## flag to count time
var counting_time: bool = false
## total time
var total_time: float = 0
var minutes: int = 0
var seconds: int = 0
var milliseconds: int = 0
## keep track of level time as well
var level_time: float = 0
## keep track of it the player got an S rank in the current level
var got_s_rank: bool = false

## array of dictionaries to store the scores and ranks of each level
var results: Array[Dictionary] = []

# - child nodes -
@onready var TOTAL_MINUTES_LABEL = $CanvasLayer/HUD/time_container/total_time_container/minutes
@onready var TOTAL_SECONDS_LABEL = $CanvasLayer/HUD/time_container/total_time_container/seconds
@onready var TOTAL_MILLISECONDS_LABEL = $CanvasLayer/HUD/time_container/total_time_container/milliseconds
@onready var MENU = $CanvasLayer/MENU
@onready var LEVEL = null # assigned dynamically
@onready var RANK_LABEL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/RankHBoxContainer/rank_label
@onready var RANK_MESSAGE = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/rank_message
@onready var LEVEL_TIME_LABEL = $CanvasLayer/LEVEL_FINISH_POPUP/panel/VBoxContainer/VBoxContainer/level_time_container/level_time_label
@onready var LEVEL_FINISH_POPUP = $CanvasLayer/LEVEL_FINISH_POPUP
@onready var NEXT_LEVEL_BTN = $CanvasLayer/LEVEL_FINISH_POPUP/panel/next_level_btn
@onready var GAME_FINISH_POPUP = $CanvasLayer/GAME_FINISH_POPUP

@onready var SUBMIT_TIME_BTN = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/HBoxContainer/submit_btn
@onready var SUBMIT_TIME_NAME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/HBoxContainer/name_entry

@onready var GAME_FINISH_TOTAL_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/timeHBoxContainer2/score_label
@onready var GAME_FINISH_EXIT_BTN = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/exit

@onready var GAME_FINISH_LVL1_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl1/hbox/rank
@onready var GAME_FINISH_LVL1_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl1/time
@onready var GAME_FINISH_LVL2_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl2/hbox/rank
@onready var GAME_FINISH_LVL2_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl2/time
@onready var GAME_FINISH_LVL3_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl3/hbox/rank
@onready var GAME_FINISH_LVL3_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl3/time
@onready var GAME_FINISH_LVL4_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl4/hbox/rank
@onready var GAME_FINISH_LVL4_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl4/time
@onready var GAME_FINISH_LVL5_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl5/hbox/rank
@onready var GAME_FINISH_LVL5_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl5/time
@onready var GAME_FINISH_LVL6_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl6/hbox/rank
@onready var GAME_FINISH_LVL6_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl6/time
@onready var GAME_FINISH_LVL7_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl7/hbox/rank
@onready var GAME_FINISH_LVL7_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl7/time
@onready var GAME_FINISH_LVL8_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl8/hbox/rank
@onready var GAME_FINISH_LVL8_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl8/time
@onready var GAME_FINISH_LVL9_RANK = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl9/hbox/rank
@onready var GAME_FINISH_LVL9_TIME = $CanvasLayer/GAME_FINISH_POPUP/panel/VBoxContainer/results/lvl9/time

# - preloaded scenes -
@onready var LEVEL_SCENE = preload("res://scenes/level.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	counting_time = true
	# fill the results array with initial values
	for i in range(level_paths.size()):
		results.append({
			"rank": "-",
			"time": 0,
		})
	# create and add the level scene
	load_level(level_paths[current_level_idx])

func _process(delta):
	if counting_time:
		level_time += delta
		total_time += delta
	var formated_time = format_time(total_time)
	TOTAL_MINUTES_LABEL.text = formated_time[0]
	TOTAL_SECONDS_LABEL.text = ":" + formated_time[1]
	TOTAL_MILLISECONDS_LABEL.text = "." + formated_time[2]

func load_level(level_json_path: String):
	if LEVEL != null:
		LEVEL.queue_free()
	LEVEL = LEVEL_SCENE.instantiate()
	LEVEL.level_json_path = level_json_path
	LEVEL.INFINITE_BUDGET = false
	add_child(LEVEL)
	LEVEL.open_menu.connect(_on_level_open_menu)
	LEVEL.level_completed.connect(_on_level_completed)
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

func _on_level_completed(rank: String, _rank_bonus: int, _budget_bonus: int, _remaining_circle: int, _remaining_gomory: int, _remaining_split: int):
	RANK_LABEL.text = rank
	results[current_level_idx]["rank"] = rank
	LEVEL_TIME_LABEL.text = format_time(level_time)[0] + ":" + format_time(level_time)[1] + "." + format_time(level_time)[2]
	# if rank is S, save time and allow to continue
	if rank == "S":
		# if level 9, stop counting time
		if current_level_idx == level_paths.size() - 1:
			counting_time = false
		RANK_MESSAGE.text = "YOU PASS!"
		got_s_rank = true
		results[current_level_idx]["time"] = level_time
		NEXT_LEVEL_BTN.text = ">>NEXT LEVEL"
	else:
		RANK_MESSAGE.text = "NOT GOOD ENOUGH."
		NEXT_LEVEL_BTN.text = "<<TRY AGAIN"
	# pause and show the level finish popup
	get_tree().paused = true
	LEVEL_FINISH_POPUP.visible = true

func _on_next_level_btn_pressed():
	if not got_s_rank:
		LEVEL_FINISH_POPUP.visible = false
		get_tree().paused = false
		load_level(level_paths[current_level_idx])
		CRT.play_buzz()
		LEVEL_FINISH_POPUP.visible = false
		return
	if current_level_idx < level_paths.size() - 1:
		current_level_idx += 1
		level_time = 0
		got_s_rank = false
		load_level(level_paths[current_level_idx])
		CRT.play_buzz()
		LEVEL_FINISH_POPUP.visible = false
	else: # after final level
		LEVEL_FINISH_POPUP.visible = false
		GAME_FINISH_POPUP.visible = true
		GAME_FINISH_TOTAL_TIME.text = format_time(total_time)[0] + ":" + format_time(total_time)[1] + "." + format_time(total_time)[2]
		# assign all the results
		GAME_FINISH_LVL1_RANK.text = results[0]["rank"]
		var formated_time_1 = format_time(results[0]["time"])
		GAME_FINISH_LVL1_TIME.text = formated_time_1[0] + ":" + formated_time_1[1] + "." + formated_time_1[2]
		GAME_FINISH_LVL2_RANK.text = results[1]["rank"]
		var formated_time_2 = format_time(results[1]["time"])
		GAME_FINISH_LVL2_TIME.text = formated_time_2[0] + ":" + formated_time_2[1] + "." + formated_time_2[2]
		GAME_FINISH_LVL3_RANK.text = results[2]["rank"]
		var formated_time_3 = format_time(results[2]["time"])
		GAME_FINISH_LVL3_TIME.text = formated_time_3[0] + ":" + formated_time_3[1] + "." + formated_time_3[2]
		GAME_FINISH_LVL4_RANK.text = results[3]["rank"]
		var formated_time_4 = format_time(results[3]["time"])
		GAME_FINISH_LVL4_TIME.text = formated_time_4[0] + ":" + formated_time_4[1] + "." + formated_time_4[2]
		GAME_FINISH_LVL5_RANK.text = results[4]["rank"]
		var formated_time_5 = format_time(results[4]["time"])
		GAME_FINISH_LVL5_TIME.text = formated_time_5[0] + ":" + formated_time_5[1] + "." + formated_time_5[2]
		GAME_FINISH_LVL6_RANK.text = results[5]["rank"]
		var formated_time_6 = format_time(results[5]["time"])
		GAME_FINISH_LVL6_TIME.text = formated_time_6[0] + ":" + formated_time_6[1] + "." + formated_time_6[2]
		GAME_FINISH_LVL7_RANK.text = results[6]["rank"]
		var formated_time_7 = format_time(results[6]["time"])
		GAME_FINISH_LVL7_TIME.text = formated_time_7[0] + ":" + formated_time_7[1] + "." + formated_time_7[2]
		GAME_FINISH_LVL8_RANK.text = results[7]["rank"]
		var formated_time_8 = format_time(results[7]["time"])
		GAME_FINISH_LVL8_TIME.text = formated_time_8[0] + ":" + formated_time_8[1] + "." + formated_time_8[2]
		GAME_FINISH_LVL9_RANK.text = results[8]["rank"]
		var formated_time_9 = format_time(results[8]["time"])
		GAME_FINISH_LVL9_TIME.text = formated_time_9[0] + ":" + formated_time_9[1] + "." + formated_time_9[2]

## toggles pause
func toggle_pause():
	get_tree().paused = !get_tree().paused

## formats time into a list of strings [minutes, seconds, milliseconds]
func format_time(time: float) -> Array[String]:
	var m: int = int(fmod(time, 3600) / 60)
	var s: int = int(fmod(time, 60))
	var ms: int = int(fmod(time, 1) * 1000)
	return ["%02d" % m, "%02d" % s, "%03d" % ms]

func _on_name_entry_text_changed(new_text:String):
	var allowed_chars = " -_<>+=/*'0123456789qwertyuiopasdfghjklñzxcvbnmQWERTYUIOPASDFGHJKLÑZXCVBNM!?.,"
	var old_caret_pos = SUBMIT_TIME_NAME.caret_column
	var filtered_text = ""
	for character in new_text:
		if allowed_chars.find(character) != -1:
			filtered_text += character
	SUBMIT_TIME_NAME.text = filtered_text
	SUBMIT_TIME_NAME.caret_column = old_caret_pos

func _on_submit_btn_pressed():
	DEBUG.log("submitting score...")
	SUBMIT_TIME_BTN.disabled = true
	SUBMIT_TIME_BTN.text = "LOADING..."
	var submitted: bool = await Leaderboards.post_guest_score("tcpgv2-speedrun-Uerr", total_time, SUBMIT_TIME_NAME.text, {}, 0, true)
	if submitted:
		DEBUG.log("score submitted")
		SUBMIT_TIME_BTN.disabled = true
		SUBMIT_TIME_BTN.text = "SUBMITTED"
	else:
		SUBMIT_TIME_BTN.text = "FAILED.\nTRY AGAIN"
		SUBMIT_TIME_BTN.disabled = false
		DEBUG.log("score not submitted")