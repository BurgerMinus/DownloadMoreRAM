extends "res://Scripts/Hosts/ArcherBot/ArcherBot.gd"

var bonus_shots = 0

func toggle_enhancement(state):
	bonus_shots = 0
	bomb_boost_duration = 0.3
	super(state)
	bonus_shots = 4 * get_currently_applicable_upgrades()['refresh_overclocking']
	bomb_boost_duration = 0.3 + 0.05 * bonus_shots

func start_bomb_boost(bomb_pos):
	super(bomb_pos)
	bomb_boost_remaining_shots = 3 + bonus_shots
