extends LeaderboardUI
# exacly the same as the LeaderboardUI.gd script, except instead of showing time as a float, it shows is as a formatted string

# Called when the node enters the scene tree for the first time.
func _ready():
	score_list.set_column_expand_ratio(1, 3)
	var column_names := ["Rank", "Name", "Time"]
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
			row.set_text(2, str(entry.get_prop("formated_time")))
	else:
		# TODO: ERROR HANDLING
		var row: TreeItem = score_list.create_item(root)
		if score_data["error"]:
			row.set_text(0, "There was an error fetching scores.")
		else:
			row.set_text(0, "No scores were found")

	prev_button.disabled = score_offset == 0
	next_button.disabled = talo_is_last_subpage
