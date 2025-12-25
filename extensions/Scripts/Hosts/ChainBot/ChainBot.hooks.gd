extends Object

func toggle_enhancement(chain: ModLoaderHookChain, state):
	
	var deadlift = chain.reference_object as ChainBot
	
	deadlift.charge_speed = 1.0
	
	chain.execute_next([state])
	
	var upgrades_to_apply = deadlift.get_currently_applicable_upgrades()
	
	deadlift.charge_speed *= (1 + upgrades_to_apply['point_defense'])
