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
	
	# update golem upgrade sets
	var presets = [
			['bloodlust', 'indulgence'], 
			['echopraxia', 'mimesis'], 
			['temerity', 'haste']]
	for preset in presets:
		if randf() < 0.25:
			preset.append('desperation')
		enemy_golem.g_upgrades.append(preset)
	
	# update hyperopia sets
	enemy_golem.h_upgrades[Enemy.EnemyType.SHOTGUN].append('flak_shell')
	enemy_golem.h_upgrades[Enemy.EnemyType.WHEEL].append('pyroclastic_flow')
	enemy_golem.h_upgrades[Enemy.EnemyType.CHAIN].append('point_defense')
	enemy_golem.h_upgrades[Enemy.EnemyType.SHIELD].append('event_horizon')
	enemy_golem.h_upgrades[Enemy.EnemyType.SABER].append(['percussive_strike', 2])
	enemy_golem.h_upgrades[Enemy.EnemyType.BAT].append('big_stick')
	
	# update obsession sets
	enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].erase('soldering_fingers')
	enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].erase('induction_barrel')
	if randf() < 0.5:
		enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].append('soldering_fingers')
	else:
		enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].append('embedded_vision')
	if randf() < 0.5:
		enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].append('induction_barrel')
	else:
		enemy_golem.o_upgrades[Enemy.EnemyType.SHOTGUN].append('flak_shell')
	if 'shaped_charges' in enemy_golem.o_upgrades[Enemy.EnemyType.WHEEL]:
		enemy_golem.o_upgrades[Enemy.EnemyType.WHEEL].append('phase_shift')
	else:
		enemy_golem.o_upgrades[Enemy.EnemyType.WHEEL].append('pyroclastic_flow')
	enemy_golem.o_upgrades[Enemy.EnemyType.FLAME].append(['slipstream', 2])
	enemy_golem.o_upgrades[Enemy.EnemyType.CHAIN].append('point_defense')
	enemy_golem.o_upgrades[Enemy.EnemyType.SHIELD].append('event_horizon')
	enemy_golem.o_upgrades[Enemy.EnemyType.SABER].append(['percussive_strike', 2])
	enemy_golem.o_upgrades[Enemy.EnemyType.BAT].append('big_stick')

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
	
