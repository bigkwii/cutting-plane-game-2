class_name LeaderboardUI
extends Control

## The Leaderboard ID can be found on the Quiver website
@export var leaderboard_id: String:
	set(id):
		leaderboard_id = id
		score_offset = 0
		#refresh_scores()

## The offset from the first high score
@export var score_offset: int = 0
## Fetch up to a maximum of this many scores.
@export_range(1, 50) var score_limit := 10
## Fetch this many scores below and this many scores above the player's score
## when using the nearby score filter.
@export_range(1, 25) var nearby_count := 5
## Sets whether scores are fetched near the player's best or latest score
## when using the nearby score filter.
## Only applicable when the leaderboard is using the "All scores" update strategy.
## The color to highlight the current player's scores.
@export var current_player_highlight_color := Color("#005216")
## Secret Leaderboard Code
@export var leaderboard_code: String = ""

@onready var next_button := %NextButton
@onready var prev_button := %PrevButton
@onready var score_list := %ScoreList
@onready var scores_label := %ScoresLabel
@onready var title_label := %TitleLabel


func _ready() -> void:
	score_list.set_column_expand_ratio(1, 3)
	var column_names := ["Rank", "Name", "Score"]
	for column_index in range(column_names.size()):
		var cname: String = column_names[column_index]
		score_list.set_column_title(column_index, cname)
		score_list.set_column_title_alignment(column_index, HORIZONTAL_ALIGNMENT_LEFT)
		column_index += 1
	if leaderboard_id:
		refresh_scores()
	else:
		DEBUG.log("[Leaderboards] No ID set")


func refresh_scores():
	if not leaderboard_id:
		DEBUG.log("[Leaderboards] Invalid Leaderboard ID.")
		return
	var talo_options := Talo.leaderboards.GetEntriesOptions.new()
	@warning_ignore("integer_division")
	var talo_options_page: int = int(score_offset / 50)
	@warning_ignore("integer_division")
	var talo_options_subpage: int = int((score_offset % 50) / score_limit)
	talo_options.page = talo_options_page
	
	DEBUG.log("getting talo entries...")
	score_list.clear()
	prev_button.disabled = true
	next_button.disabled = true
	
	var talo_res := await Talo.leaderboards.get_entries(leaderboard_id, talo_options)
	var talo_entries: Array[TaloLeaderboardEntry] = talo_res.entries
	if leaderboard_code != "":
		talo_entries = talo_entries.filter(func (entry: TaloLeaderboardEntry): return entry.get_prop("leaderboard_code") == leaderboard_code)
	var talo_count: int = talo_res.count
	var talo_is_last_page = talo_res.is_last_page
	var talo_is_last_subpage = talo_is_last_page and (talo_options_subpage + 1) * score_limit >= len(talo_entries)

	var root: TreeItem = score_list.create_item()
	var score_data: Dictionary
	if talo_count > 0:
		for entry in talo_entries.slice(talo_options_subpage*10, (talo_options_subpage+1)*10):
			var row: TreeItem = score_list.create_item(root)
			row.set_text(0, str(int(entry.position + 1)))
			row.set_text(1, str(entry.player_alias.identifier))
			row.set_text(2, str(int(entry.score)))
	else:
		# TODO: ERROR HANDLING
		var row: TreeItem = score_list.create_item(root)
		if score_data["error"]:
			row.set_text(0, "There was an error fetching scores.")
		else:
			row.set_text(0, "No scores were found")

	prev_button.disabled = score_offset == 0
	next_button.disabled = talo_is_last_subpage


func _on_prev_button_pressed() -> void:
	if score_offset > 0:
		score_offset = max(0, score_offset - score_limit)
		refresh_scores()


func _on_next_button_pressed() -> void:
	score_offset = score_offset + score_limit
	refresh_scores()
