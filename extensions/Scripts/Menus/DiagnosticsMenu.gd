extends "res://Scripts/Menus/DiagnosticsMenu.gd"

func set_upgrade_selected(selection):
	var already_selected = selected_upgrade_name == selection
	super(selection)
	if SaveManager.stats.progression_stats[selection] < 1:
		return
	if not already_selected and 'credits' in selected_upgrade:
		upgrade_stats.text += "\n" + selected_upgrade['credits']
