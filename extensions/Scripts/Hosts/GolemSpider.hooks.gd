extends Object

var desperation_invincibility = {}

func _ready(chain: ModLoaderHookChain):
	
	var mite = chain.reference_object as GolemSpider
	
	chain.execute_next()
	
	desperation_invincibility[mite] = 3.0

func take_damage(chain: ModLoaderHookChain, attack):
	
	var mite = chain.reference_object as GolemSpider
	
	var player_check = GameManager.player.upgrades['desperation'] > 0 and mite.is_player
	var melog_check = not mite.is_player and is_instance_valid(mite.enemy_golem) and 'golem_upgrades' in mite.enemy_golem and mite.enemy_golem.golem_upgrades['desperation'] 
	
	if player_check or melog_check:
		var mult = 0.0 if desperation_invincibility[mite] > 0.0 else 3.0
		attack.damage *= mult
	
	chain.execute_next([attack])

func misc_update(chain: ModLoaderHookChain, delta):
	
	var mite = chain.reference_object as GolemSpider
	
	desperation_invincibility[mite] -= delta
	
	var player_check = GameManager.player.upgrades['desperation'] > 0 and mite.is_player
	var melog_check = not mite.is_player and is_instance_valid(mite.enemy_golem) and 'golem_upgrades' in mite.enemy_golem and mite.enemy_golem.golem_upgrades['desperation'] 
	
	if player_check or melog_check:
		var mult = 0.0 if desperation_invincibility[mite] > 0.0 else 3.0
		if mite.lunging:
			mite.while_lunging(delta)
		if is_instance_valid(mite.grabbed_host):
			mite.while_grabbing_host(delta)
		elif mite.climbed_pillar != null:
			mite.while_climbing_pillar(delta)
		elif mite.is_player and GameManager.player.is_in_combat and not GameManager.in_cutscene:
			if is_instance_valid(GameManager.player.swap_manager.juice_system):
				GameManager.player.swap_manager.juice_system.spend_global_juice(mult*delta*0.1)
			elif is_instance_valid(GameManager.player.swap_manager.timer_system):
				GameManager.player.swap_manager.timer_system.add_swap_cooldown(mult*delta*0.1)
	else:
		chain.execute_next([delta])

func die(chain: ModLoaderHookChain, attack):
	
	var mite = chain.reference_object as GolemSpider
	
	desperation_invincibility.erase(mite)
	
	chain.execute_next([attack])
	
