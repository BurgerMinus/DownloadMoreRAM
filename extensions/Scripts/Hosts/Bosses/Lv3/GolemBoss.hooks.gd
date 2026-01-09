extends Object

var bloodlust = {}

func _ready(chain: ModLoaderHookChain):
	
	var enemy_golem = chain.reference_object
	
	chain.execute_next()
	
	bloodlust[enemy_golem] = {
		'duration': 2.5,
		'timer': 0.0,
		'drain': 0.0
	}
	
	enemy_golem.golem_upgrades['bloodlust'] = false
	enemy_golem.golem_upgrades['desperation'] = false
	enemy_golem.golem_upgrades['echopraxia'] = false
	enemy_golem.golem_upgrades['mimesis'] = false
	enemy_golem.golem_upgrades['temerity'] = false
	
	enemy_golem.give_golem_upgrades = true #|#

func generate_golem_upgrade_set(chain: ModLoaderHookChain):
	
	var enemy_golem = chain.reference_object
	
	var upgrade_set = chain.execute_next()
	
	if randf() < 0.25:
		upgrade_set = Util.choose_random([
			['bloodlust', 'indulgence'], 
			['echopraxia', 'mimesis'], 
			['temerity', 'haste']])
	
	if randf() < 0.1:
		upgrade_set.append('desperation')
	
	return upgrade_set

func generate_hyperopia_sets(chain: ModLoaderHookChain):
	
	var enemy_golem = chain.reference_object
	
	var hyperopia_upgrade_sets = chain.execute_next()
	
	hyperopia_upgrade_sets[Enemy.EnemyType.SHOTGUN].append('flak_shell')
	hyperopia_upgrade_sets[Enemy.EnemyType.WHEEL].append('pyroclastic_flow')
	hyperopia_upgrade_sets[Enemy.EnemyType.CHAIN].append('point_defelse')
	hyperopia_upgrade_sets[Enemy.EnemyType.SHIELD].append('event_horizon')
	hyperopia_upgrade_sets[Enemy.EnemyType.SABER].append(['percussive_strike', 2])
	hyperopia_upgrade_sets[Enemy.EnemyType.BAT].append('big_stick')
	
	return hyperopia_upgrade_sets

func generate_obsession_set(chain: ModLoaderHookChain, bot):
	
	var enemy_golem = chain.reference_object
	
	var obsession_set = chain.execute_next(bot)
	
	match bot:
		"Steeltoe": 
			obsession_set.erase('soldering_fingers')
			obsession_set.erase('induction_barrel')
			if randf() < 0.5:
				obsession_set.append('soldering_fingers')
			else:
				obsession_set.append('embedded_vision')
			if randf() < 0.5:
				obsession_set.append('induction_barrel')
			else:
				obsession_set.append('flak_shell')
		"Router":
			if 'shaped_charges' in obsession_set:
				obsession_set.append('phase_shift')
			else:
				obsession_set.append('pyroclastic_flow')
		"Aphid": 
			obsession_set.append(['slipstream', 2])
		"Deadlift":
			obsession_set.append('point_defense')
		"Collider":
			obsession_set.append('event_horizon')
		"Tachi":
			obsession_set.append(['percussive_strike', 2])
		"Epitaph":
			obsession_set.append('big_stick')
	
	return obsession_set

func _process(chain: ModLoaderHookChain, delta):
	
	var enemy_golem = chain.reference_object
	
	if enemy_golem.golem_upgrades['bloodlust'] and bloodlust[enemy_golem]['timer'] > 0.0:
		bloodlust[enemy_golem]['timer'] -= delta
		var amount = bloodlust[enemy_golem]['drain'] * delta
		var local_spent = min(enemy_golem.local_juice, amount)
		enemy_golem.local_juice -= local_spent
		amount -= local_spent
		if amount > 0.0:
			enemy_golem.global_juice = max(0.0, enemy_golem.global_juice - amount)
	
	chain.execute_next([delta])

func convert_juice(chain: ModLoaderHookChain, amount):
	
	var enemy_golem = chain.reference_object
	
	var converted_amount = chain.execute_next([amount])
	
	if enemy_golem.golem_upgrades['bloodlust'] and bloodlust[enemy_golem]['timer'] <= 0.0:
		converted_amount *= 1.5
	
	return converted_amount

func spend_juice(chain: ModLoaderHookChain, amount):
	
	var enemy_golem = chain.reference_object
	
	if enemy_golem.golem_upgrades['bloodlust'] and bloodlust[enemy_golem]['timer'] <= 0.0:
		if not (enemy_golem.free_swap or enemy_golem.infinite_energy):
			bloodlust[enemy_golem]['drain'] = enemy_golem.convert_juice(amount) / bloodlust[enemy_golem]['duration']
			if enemy_golem.golem_upgrades["indulgence"]:
				if enemy_golem.indulgence_timer > 0.0 and not enemy_golem.host.dead:
					bloodlust[enemy_golem]['drain'] *= 0.33
			bloodlust[enemy_golem]['timer'] = bloodlust[enemy_golem]['duration']
			amount = 0
	
	chain.execute_next([amount])

func restore_swap_juice_from_kill(chain: ModLoaderHookChain, equivalent_basic_kills):
	
	var enemy_golem = chain.reference_object
	
	bloodlust[enemy_golem]['timer'] = 0.0
	
	chain.execute_next([equivalent_basic_kills])

func spawn_ad(chain: ModLoaderHookChain):
	
	var enemy_golem = chain.reference_object
	
	if enemy_golem.golem_upgrades['echopraxia'] and randf() < 0.35:
		var corners = [0, 1, 2, 3]
		corners.remove_at(enemy_golem.last_ad_spawn_corner)
		enemy_golem.last_ad_spawn_corner = corners.pick_random()
		var corner = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)][enemy_golem.last_ad_spawn_corner]
		var point = enemy_golem.arena_center + Vector2(150*corner.x, 100*corner.y)
		enemy_golem.ads.append(GameManager.spawn_and_place_enemy(enemy_golem.host.enemy_type, point, 0))
		enemy_golem.ad_spawn_timer = 2.0
	else:
		chain.execute_next()
	
