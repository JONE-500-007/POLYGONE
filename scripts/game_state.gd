extends Node

var selected_character: CharacterData
var paused_players: Dictionary = {}  # player id -> true (players who have the pause menu open)

func set_player_paused(id: int, value: bool) -> void:
	if value:
		paused_players[id] = true
	else:
		paused_players.erase(id)
	var total := get_tree().get_nodes_in_group("player").size()
	get_tree().paused = total > 0 and paused_players.size() >= total
