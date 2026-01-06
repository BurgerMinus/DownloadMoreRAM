extends Object

# contains all living hosts that were at one point controlled by the player
# value of the entry is the temerity invincibilty timer
var past_hosts = {}

var burn_dot = {}
var burn_dot_duration = 5.0
var burn_dot_tick_duration = 0.5
var burn_dot_dps = 5.0
const burn_dot_tag = 17342

var ScrapScene = null

func toggle_enhancement(chain: ModLoaderHookChain, state):
	
	var enemy = chain.reference_object as Enemy
	
	chain.execute_next([state])
	
	if state:
		past_hosts[enemy] = 3.0
		burn_dot.erase(enemy)
	elif past_hosts.has(enemy):
		past_hosts[enemy] = 0.0

func can_be_hit(chain: ModLoaderHookChain, _attack):
	
	var enemy = chain.reference_object as Enemy
	
	if GameManager.player.upgrades['temerity'] > 0 and enemy == GameManager.player.true_host and past_hosts.has(enemy) and past_hosts[enemy] > 0.0:
		return false
	
	return chain.execute_next([_attack])
	

func get_currently_applicable_upgrades(chain: ModLoaderHookChain):
	
	var enemy = chain.reference_object as Enemy
	
	var temp = enemy.is_player
	if GameManager.player.upgrades['mimesis'] > 0 and past_hosts.has(enemy):
		enemy.is_player = true
	
	var to_apply = chain.execute_next()
	
	for upgrade in Upgrades.upgrades.keys():
		
		if Upgrades.upgrades[upgrade].type == enemy.enemy_type or Upgrades.upgrades[upgrade].type == Enemy.EnemyType.UNKNOWN:
			
			# handle residual control case (normally not necessary but yk)
			if enemy.player_enhancements_active and not enemy.is_player and Upgrades.get_antiupgrade_value("shared_upgrades") == 0:
				if upgrade in GameManager.player.upgrades:
					to_apply[upgrade] += GameManager.player.upgrades[upgrade]
	
	if not temp:
		enemy.is_player = false
	
	return to_apply

func _physics_process(chain: ModLoaderHookChain, delta):
	
	var enemy = chain.reference_object as Enemy
	
	var temp = enemy.time_since_swap + delta
	if GameManager.player.upgrades['mimesis'] > 0 and past_hosts.has(enemy) and not enemy.is_player and temp <= 6:
		enemy.time_since_swap *= 0.33
	
	chain.execute_next([delta])
	
	if not enemy.dead and not enemy.can_be_hit(Attack.new(enemy, 0, 0)):
#	if GameManager.player.upgrades['temerity'] > 0 and past_hosts.has(enemy) and past_hosts[enemy] > 0.0: 
		if enemy.sprite.material != enemy.default_material:
			enemy.sprite.material = enemy.default_material
		enemy.sprite.modulate.a = 0.5
	else:
		enemy.sprite.modulate.a = 1.0
	
	enemy.time_since_swap = temp
	
	if past_hosts.has(enemy):
		past_hosts[enemy] -= delta
		if GameManager.player.upgrades['temerity'] > 0:
			if past_hosts[enemy] < 0.0:
				if enemy == GameManager.player.true_host:
					enemy.health = min(enemy.health, 1)
	
	if burn_dot.has(enemy):
		if burn_dot[enemy][0] > 0.0:
			burn_dot[enemy][0] -= delta
			burn_dot[enemy][1] -= delta
			if burn_dot[enemy][1] < 0.0:
				burn_dot[enemy][1] = burn_dot_tick_duration
				var burn_dot_attack = Attack.new(burn_dot[enemy][2], burn_dot_dps * burn_dot_tick_duration)
				burn_dot_attack.bonuses.append(Fitness.Bonus.BBQ)
				burn_dot_attack.hit_allies = true
				burn_dot_attack.inflict_on(enemy)

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
