extends "res://Scripts/Hosts/SaberBot/SaberBot.gd"

var sword_break = 0
var zen = false

func toggle_enhancement(state):
	
	sword_break = 0
	zen = false
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	sword_break = upgrades_to_apply['percussive_strike']
	zen = upgrades_to_apply['inner_peace']

func during_kill_mode(delta):
	super(delta)
	if zen:
		kill_mode_timer = 999
		if remaining_slashes > 0:
			special_cooldown = 0.0
		else:
			special_cooldown = max_special_cooldown

func trigger_suspended_slashes():
	var flag = suspended_slashes.is_empty()
	super()
	if zen and not flag and not slashing:
		special_cooldown = 0.0
