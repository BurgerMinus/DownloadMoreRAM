extends "res://Scripts/Hosts/SaberBot/SaberBot.gd"

var sword_break = false

func toggle_enhancement(state):
	
	sword_break = 0
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	sword_break = upgrades_to_apply['sword_break'] > 0
	
#	if saber_state == DRAWN:
#		for saber in sabers:
#			update_saber_stats(saber)


