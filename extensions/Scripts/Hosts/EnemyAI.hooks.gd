extends Object

var melog = null
var player_skin_active = {}

func update(chain: ModLoaderHookChain, delta_):
	
	var ai = chain.reference_object as EnemyAI
	
	var enemy = ai.body
	
	for bot in player_skin_active.keys():
		if not is_instance_valid(bot):
			player_skin_active.erase(bot)
	
	if not is_instance_valid(enemy):
		chain.execute_next([delta_])
		return
	
	if not player_skin_active.has(enemy):
		player_skin_active[enemy] = false
	
	if melog == null and enemy.enemy_golem:
		melog = enemy.enemy_golem
	
	var p = enemy.is_in_group('dmr_player_echopraxia') and is_instance_valid(GameManager.player)
	var m = enemy.is_in_group('dmr_melog_echopraxia') and is_instance_valid(melog)
	
	if p or m:
		
		var player_host = null
		var melog_host = null
		
		if p:
			player_host = GameManager.player.true_host
			if not is_instance_valid(player_host):
				player_host = null
		if m:
			melog_host = melog.host
			if not is_instance_valid(melog_host):
				melog_host = null
		
		if player_host == null or not player_host is Enemy:
			p = false
		if melog_host == null or not melog_host is Enemy:
			m = false
		
		
		if p and (not (m or enemy.enemy_golem) or randf() > 0.5): # PLAYER CONTROL SUCCEEDS
			
			# mimic player action
			if enemy.enemy_golem:
				chain.execute_next([delta_])
			else:
				if enemy is CityBossOrb:
					handle_heap_orb_action(enemy, delta_)
				enemy.player_action()
				enemy.aim_direction = (player_host.get_global_mouse_position() - player_host.global_position).normalized()
			
			# use player skin
			if not player_skin_active[enemy]:
				player_skin_active[enemy] = true
				var temp = enemy.is_player # should always be false but idk
				enemy.is_player = true
				enemy.handle_skin()
				enemy.is_player = temp
			
			# match player movement
			if enemy.global_position.distance_to(player_host.global_position) <= 80:
				enemy.target_velocity = player_host.target_velocity
			else:
				enemy.target_velocity = enemy.max_speed * enemy.global_position.direction_to(player_host.global_position).normalized()
			
		elif m: # MELOG CONTROL SUCCEEDS
			
			# do normal ai actions
			chain.execute_next([delta_])
			
			# use normal skin
			if player_skin_active[enemy]:
				player_skin_active[enemy] = false # probably
				enemy.handle_skin()
			
			# match melog movement
			if enemy.global_position.distance_to(melog_host.global_position) <= 80:
				enemy.target_velocity = melog_host.target_velocity
			else:
				enemy.target_velocity = enemy.max_speed * enemy.global_position.direction_to(melog_host.global_position).normalized()
			
		else: # something has went terribly wrong
			
			# do normal ai actions
			chain.execute_next([delta_])
			
			# use normal skin
			if player_skin_active[enemy]:
				player_skin_active[enemy] = false # probably
				enemy.handle_skin()
	
	else: # normal things are happening
		
		# do normal ai actions
		chain.execute_next([delta_])
		
		# use normal skin
		if player_skin_active[enemy]:
			player_skin_active[enemy] = false # probably
			enemy.handle_skin()

func handle_heap_orb_action(orb, delta):
	
	if orb.player_charging_laser or orb.laser_active:
		var target_endpoint = orb.get_player_target_laser_endpoint()
		var prev_endpoint = orb.laser_endpoint
		var new_endpoint = prev_endpoint + prev_endpoint.direction_to(target_endpoint)*min(prev_endpoint.distance_to(target_endpoint), 150*delta)
		orb.set_laser_endpoint(new_endpoint)
		
		orb.player_laser_timer -= delta
		if orb.player_charging_laser:
			if orb.player_laser_timer < 0.0:
				orb.player_charging_laser = false
				orb.laser_endpoint_sprite.visible = true
				orb.player_laser_timer = 2.0
				orb.activate_laser()
		
		else:
			var positions = [orb.global_position, orb.global_position - orb.velocity*delta]
			for pos in positions:
				var to_controller = orb.controller.global_position - pos
				if orb.tethered and sign((prev_endpoint - pos).cross(to_controller)) != sign((new_endpoint - pos).cross(to_controller)) and to_controller.length() > new_endpoint.distance_to(orb.controller.global_position):
					orb.break_tether()
					break
				
			if orb.player_laser_timer < 0.0:
				orb.deactivate_laser()
