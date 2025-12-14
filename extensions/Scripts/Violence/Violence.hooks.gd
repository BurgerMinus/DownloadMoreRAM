extends Object

static func melee_attack(chain: ModLoaderHookChain, collider, attack):
	
	var hit_entities = chain.execute_next([collider, attack])
	
	if not (is_instance_valid(attack) and is_instance_valid(attack.causality) and is_instance_valid(attack.causality.source)):
		return
	
	var source = attack.causality.source
	
	if source is ShotgunBot:
		var improvised_nails = source.get_currently_applicable_upgrades()['improvised_nails']
		for entity in hit_entities:
			for i in range(0, improvised_nails * 4):
				var angle = source.global_position.direction_to(entity.global_position).rotated(0.35*PI*(randf() - 0.5)).normalized()
				var bullet = Violence.shoot_bullet(source, entity.global_position, angle*source.shot_speed, source.bullet_damage)
				bullet.ignored.append(entity)
