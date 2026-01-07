extends Object

func update(chain: ModLoaderHookChain, delta_):
	
	var ai = chain.reference_object as EnemyAI
	
	var enemy = ai.body
	var player = GameManager.player.true_host
	
	if player == enemy or not (is_instance_valid(enemy) and is_instance_valid(player) and (enemy is Enemy) and (player is Enemy)):
		chain.execute_next([delta_])
		return
	
	var dist = enemy.global_position.distance_to(player.global_position)
	
	
	if GameManager.player.upgrades['echopraxia'] > 0 and enemy is Enemy and player is Enemy and enemy.enemy_type == player.enemy_type and dist < 100:
		
		enemy.player_action()
		enemy.aim_direction = (player.get_global_mouse_position() - player.global_position).normalized()
		
		if not enemy.is_in_group('dmr_hit_allies'):
			enemy.toggle_enhancement(true)
			enemy.add_to_group('dmr_hit_allies')
		
		if dist < 75:
			enemy.player_move(delta_)
		else:
			enemy.target_velocity = enemy.max_speed * enemy.global_position.direction_to(player.global_position).normalized()
	else:
		if enemy.is_in_group('dmr_hit_allies'):
			enemy.toggle_enhancement(false)
			enemy.remove_from_group('dmr_hit_allies')
		chain.execute_next([delta_])
