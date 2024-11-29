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

func refresh_scores():
	if not leaderboard_id:
		printerr("[Quiver Leaderboards] Scores couldn't be fetched since leaderboard ID not set in Leaderboard UI.")
		return

	prev_button.disabled = score_offset == 0
	next_button.disabled = true

	score_list.clear()
	var root: TreeItem = score_list.create_item()
	var score_data: Dictionary
	if score_filter == Leaderboards.ScoreFilter.ALL:
		score_data = await Leaderboards.get_scores(leaderboard_id, score_offset, score_limit)
	elif score_filter == Leaderboards.ScoreFilter.PLAYER:
		score_data = await Leaderboards.get_player_scores(leaderboard_id, score_offset, score_limit)
	elif score_filter == Leaderboards.ScoreFilter.NEARBY:
		score_data = await Leaderboards.get_nearby_scores(leaderboard_id, nearby_count, nearby_anchor)
	if score_data["scores"].size() > 0:
		for score in score_data["scores"]:
			var row: TreeItem = score_list.create_item(root)
			row.set_text(0, str(score["rank"]))
			row.set_text(1, str(score["name"]))
			row.set_text(2, str(score["metadata"]["formated_time"])) # the only change
			if score["is_current_player"]:
				for i in range(3):
					row.set_custom_bg_color(i, current_player_highlight_color)
	else:
		var row: TreeItem = score_list.create_item(root)
		if score_data["error"]:
			row.set_text(0, "There was an error fetching scores.")
		else:
			row.set_text(0, "No scores were found")

	next_button.disabled = not score_data["has_more_scores"]
