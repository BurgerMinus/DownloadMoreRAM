extends "res://Scripts/Hosts/SaberBot/SaberBot.gd"

var sword_break = 0
var zen = false

func toggle_enhancement(state):
	
	sword_break = 0
	zen = false
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	sword_break = upgrades_to_apply['percussive_strike']
	zen = upgrades_to_apply['medium_maximization']

func player_action():
	
	if zen and in_kill_mode and not slashing and Input.is_action_just_pressed("attack2"):
		special_cooldown = 0.0
	
	super()

func during_kill_mode(delta):
	if zen and kill_mode_timer <= delta:
		kill_mode_timer += delta
	super(delta)

func trigger_suspended_slashes():
	var flag = suspended_slashes.is_empty()
	super()
	if zen and not flag and not slashing:
		special_cooldown = 0.0
