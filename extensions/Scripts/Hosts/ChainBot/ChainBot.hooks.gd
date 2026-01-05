extends Object

func toggle_enhancement(chain: ModLoaderHookChain, state):
	
	var deadlift = chain.reference_object as ChainBot
	
	deadlift.charge_speed = 1.0
	
	chain.execute_next([state])
	
	var upgrades_to_apply = deadlift.get_currently_applicable_upgrades()
	
	var attack_collider = deadlift.get_node_or_null('AttackCollider')
	
	if upgrades_to_apply['point_defense'] > 0:
		deadlift.charge_speed *= 2.0
