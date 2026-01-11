extends Object

# contains all living hosts that were at one point controlled by the player
# value of the entry is the temerity invincibilty timer
var past_hosts = {}

# same as above but for enemy golem
var boss_hosts = {}

var melog = null

var echopraxia_radius = 100

var burn_dot = {}
var burn_dot_duration = 5.0
var burn_dot_tick_duration = 0.5
var burn_dot_dps = 5.0
const burn_dot_tag = 17342

var ScrapScene = null

func toggle_enhancement(chain: ModLoaderHookChain, state):
	
	var enemy = chain.reference_object as Enemy
	
	chain.execute_next([state])
	
	if is_instance_valid(enemy.enemy_golem):
		boss_hosts[enemy] = 3.0
	elif boss_hosts.has(enemy):
		boss_hosts[enemy] = 0.0
	
	if state:
		past_hosts[enemy] = 3.0
		burn_dot.erase(enemy)
	elif past_hosts.has(enemy):
		past_hosts[enemy] = 0.0

func can_be_hit(chain: ModLoaderHookChain, _attack):
	
	var enemy = chain.reference_object as Enemy
	
	if enemy.is_player and GameManager.player.upgrades['temerity'] > 0:
		if past_hosts.has(enemy) and past_hosts[enemy] > 0.0:
			return false
	 
	if enemy.enemy_golem and 'golem_upgrades' in enemy.enemy_golem and enemy.enemy_golem.golem_upgrades.has('temerity') and enemy.enemy_golem.golem_upgrades['temerity']:
		if boss_hosts.has(enemy) and boss_hosts[enemy] > 0.0:
			return false
	
	return chain.execute_next([_attack])

func get_currently_applicable_upgrades(chain: ModLoaderHookChain):
	
	var enemy = chain.reference_object as Enemy
	
	var player_flag = false
	var melog_flag = false
	
	if not is_instance_valid(GameManager.player):
		return chain.execute_next()
	
	if not enemy.is_player and not Upgrades.get_antiupgrade_value("shared_upgrades") > 0:
		if enemy.player_enhancements_active:
			player_flag = true
		if GameManager.player.upgrades['mimesis'] > 0 and past_hosts.has(enemy):
			player_flag = true
	
	if not enemy.enemy_golem:
		if enemy.was_recently_enemy_golem():
			melog_flag = true
		if enemy.prev_enemy_golem and 'golem_upgrades' in enemy.prev_enemy_golem and enemy.prev_enemy_golem.golem_upgrades.has('mimesis') and enemy.prev_enemy_golem.golem_upgrades['mimesis'] and boss_hosts.has(enemy):
			melog_flag = true
	
	var to_apply = chain.execute_next()
	
	for upgrade in Upgrades.upgrades.keys():
		
		if Upgrades.upgrades[upgrade].type == enemy.enemy_type or Upgrades.upgrades[upgrade].type == Enemy.EnemyType.UNKNOWN:
			
			if melog_flag and upgrade in enemy.prev_enemy_golem.upgrades:
				to_apply[upgrade] += enemy.prev_enemy_golem.upgrades[upgrade]
			
			if player_flag and upgrade in GameManager.player.upgrades:
				to_apply[upgrade] += GameManager.player.upgrades[upgrade]
	
	return to_apply

func _physics_process(chain: ModLoaderHookChain, delta):
	
	var enemy = chain.reference_object as Enemy
	
	# it will be so convenient to have a constant reference to this little guy
	if melog == null and enemy.enemy_golem:
		melog = enemy.enemy_golem
	
	if not is_instance_valid(GameManager.player):
		chain.execute_next([delta])
		return
	
	var temp = enemy.time_since_swap + delta
	if GameManager.player.upgrades['mimesis'] > 0 and past_hosts.has(enemy) and not enemy.is_player and temp <= 6:
		enemy.time_since_swap *= 0.33
	
	var temp2 = enemy.time_since_enemy_golem_swap + delta
	if enemy.prev_enemy_golem and 'golem_upgrades' in enemy.prev_enemy_golem and enemy.prev_enemy_golem.golem_upgrades.has('mimesis') and enemy.prev_enemy_golem.golem_upgrades['mimesis'] and not enemy.enemy_golem and temp2 <= 6:
		enemy.time_since_enemy_golem_swap *= 0.33
	
	chain.execute_next([delta])
	
	enemy.time_since_swap = temp
	enemy.time_since_enemy_golem_swap = temp2
	
	handle_echopraxia_groups(enemy)
	handle_invincibility_visual(enemy)
	handle_temerity_self_damage(enemy, delta)
	handle_bleed_damage(enemy, delta)

func player_move(chain: ModLoaderHookChain, _delta):
	
	var enemy = chain.reference_object as Enemy
	
	if enemy.is_player and enemy.is_in_group('dmr_melog_echopraxia') and is_instance_valid(melog) and is_instance_valid(melog.host):
		if not GameManager.player.upgrades['echopraxia'] > 0 or randf() > 0.5:
			if enemy.global_position.distance_to(melog.host.global_position) <= echopraxia_radius*0.8:
				enemy.target_velocity = melog.host.target_velocity
			else:
				enemy.target_velocity = enemy.max_speed * enemy.global_position.direction_to(melog.host.global_position)
			return
	
	chain.execute_next([_delta])

func take_damage(chain: ModLoaderHookChain, attack):
	
	var enemy = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	if burn_dot_tag in attack.tags:
		if burn_dot.has(enemy):
			burn_dot[enemy][0] = burn_dot_duration
			burn_dot[enemy][2] = attack.causality.original_source
		else:
			burn_dot[enemy] = [burn_dot_duration, burn_dot_tick_duration, attack.causality.original_source]

func die(chain: ModLoaderHookChain, attack):
	
	var enemy = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	past_hosts.erase(enemy)
	burn_dot.erase(enemy)
	
	if not is_instance_valid(attack): return
	
	var killer = attack.causality.original_source
	if is_instance_valid(killer) and killer is ChainBot and killer.get_currently_applicable_upgrades()['repurposed_scrap'] > 0:
		enemy.add_to_group('dmr_scrap')

func actually_die(chain: ModLoaderHookChain):
	
	var enemy = chain.reference_object as Enemy
	
	if enemy.is_in_group('dmr_scrap') and not enemy.actually_dead:
		for i in range(0, 3 if enemy is Boss else 1):
			spawn_scrap(enemy)
		enemy.remove_from_group('dmr_scrap')
	
	chain.execute_next()

### HELPER FUNCTIONS START HERE

func handle_echopraxia_groups(enemy):
	
	if not is_instance_valid(enemy):
		return
	
	var player_echopraxia = false
	
	if is_instance_valid(GameManager.player) and is_instance_valid(GameManager.player.true_host):
		player_echopraxia = true
		player_echopraxia = player_echopraxia and GameManager.player.upgrades['echopraxia'] > 0
		player_echopraxia = player_echopraxia and GameManager.player.true_host is Enemy
		player_echopraxia = player_echopraxia and enemy.enemy_type == GameManager.player.true_host.enemy_type
		player_echopraxia = player_echopraxia and enemy.global_position.distance_to(GameManager.player.true_host.global_position) <= echopraxia_radius
	
	var melog_echopraxia = false
	
	if is_instance_valid(melog) and is_instance_valid(melog.host):
		melog_echopraxia = true
		melog_echopraxia = melog_echopraxia and 'golem_upgrades' in melog and melog.golem_upgrades.has('echopraxia') and melog.golem_upgrades['echopraxia']
		melog_echopraxia = melog_echopraxia and melog.host is Enemy
		melog_echopraxia = melog_echopraxia and enemy.enemy_type == melog.host.enemy_type
		melog_echopraxia = melog_echopraxia and enemy.global_position.distance_to(melog.host.global_position) <= echopraxia_radius
	
	if player_echopraxia:
		enemy.add_to_group('dmr_player_echopraxia')
	else:
		enemy.remove_from_group('dmr_player_echopraxia')
	
	if melog_echopraxia:
		enemy.add_to_group('dmr_melog_echopraxia')
	else:
		enemy.remove_from_group('dmr_melog_echopraxia')

func handle_invincibility_visual(enemy):
#	if GameManager.player.upgrades['temerity'] > 0 and past_hosts.has(enemy) and past_hosts[enemy] > 0.0: 
	if not enemy.dead and not enemy.can_be_hit(Attack.new(enemy, 0, 0)):
		if enemy.sprite.material != enemy.default_material:
			enemy.sprite.material = enemy.default_material
		enemy.sprite.modulate.a = 0.5
	else:
		enemy.sprite.modulate.a = 1.0

func handle_temerity_self_damage(enemy, delta):
	
	if past_hosts.has(enemy):
		past_hosts[enemy] -= delta
		if GameManager.player.upgrades['temerity'] > 0 and enemy == GameManager.player.true_host:
			if past_hosts[enemy] < 0.0:
				enemy.health = min(enemy.health, 1)
	
	if boss_hosts.has(enemy):
		boss_hosts[enemy] -= delta
		if is_instance_valid(enemy.enemy_golem) and 'golem_upgrades' in enemy.enemy_golem and enemy.enemy_golem.golem_upgrades.has('temerity') and enemy.enemy_golem.golem_upgrades['temerity']:
			if boss_hosts[enemy] < 0.0:
				enemy.health = min(enemy.health, 1)

func handle_bleed_damage(enemy, delta):
	if burn_dot.has(enemy):
		if burn_dot[enemy][0] > 0.0:
			burn_dot[enemy][0] -= delta
			burn_dot[enemy][1] -= delta
			if burn_dot[enemy][1] < 0.0:
				burn_dot[enemy][1] = burn_dot_tick_duration
				var burn_dot_attack = Attack.new(burn_dot[enemy][2] if is_instance_valid(burn_dot[enemy][2]) else self, burn_dot_dps * burn_dot_tick_duration)
				burn_dot_attack.bonuses.append(Fitness.Bonus.BBQ)
				burn_dot_attack.hit_allies = true
				burn_dot_attack.inflict_on(enemy)

func spawn_scrap(enemy):
	
	if not is_instance_valid(ScrapScene):
		ScrapScene = load(ModLoaderMod.get_unpacked_dir().path_join('BurgerMinus-DownloadMoreRAM/Scrap.tscn'))
	
	var scrap = ScrapScene.instantiate()
	
	var size_mult
	if enemy.enemy_type == Enemy.EnemyType.BOSS1 or enemy.enemy_type == Enemy.EnemyType.BOSS2:
		size_mult = 1.0
	elif enemy.enemy_type == Enemy.EnemyType.SPIDER:
		size_mult = 0.25
	else:
		size_mult = 0.5
	
	scrap.set_type(enemy.enemy_type)
	scrap.scale *= size_mult
	scrap.mass *= size_mult
	enemy.get_parent().add_child(scrap)
	scrap.global_position = enemy.global_position
	scrap.global_rotation = randf()*TAU
	Util.set_object_elevation(scrap, enemy.elevation)
	
	return scrap
