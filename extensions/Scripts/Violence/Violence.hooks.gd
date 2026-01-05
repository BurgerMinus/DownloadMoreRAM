extends Object

static func shoot_bullet(chain: ModLoaderHookChain, source, origin, vel, damage_ = 10, mass_ = 0.25, lifetime_ = 10, type = Bullet.BulletType.PELLET, stun_ = 0, size = Vector2.ONE, explosion_size = 0, explosion_damage = 0, explosion_kb = 0):
	var bullet = chain.execute_next([source, origin, vel, damage_, mass_, lifetime_, type, stun_, size, explosion_size, explosion_damage, explosion_kb])
	if source is FlakBullet:
		bullet.modulate = source.modulate
	return bullet

static func melee_attack(chain: ModLoaderHookChain, collider, attack):
	
	if not (is_instance_valid(attack) and is_instance_valid(attack.causality) and is_instance_valid(attack.causality.source)):
		return chain.execute_next([collider, attack])
	
	var source = attack.causality.source
	
	if source is ChainBot and source.charge_time >= source.MIN_CHARGE_TIME_TO_LAUNCH*source.min_charge_time_to_launch_mult:
		var point_defense = source.get_currently_applicable_upgrades()['point_defense']
		if point_defense:
			
			var effective_charge_level = min(1.5, source.charge_time * source.charge_speed)
			var overcharge_level = effective_charge_level - source.charge_level
			
			print(source.charge_level)
			print(effective_charge_level)
			print(overcharge_level)
			
			var speed_toward_target = source.velocity.length() - (300 if source.footwork else 0)
			if source.velocity.normalized().dot(source.attack_direction) < -0.5:
				speed_toward_target = 0.0
	
			var velocity_power_mult = 1.0 + max(0.0, (speed_toward_target - 200)/600.0)
			
			attack.damage += source.charge_damage*overcharge_level*source.damage_mult*velocity_power_mult
			attack.impulse += source.aim_direction*(200 + 500*overcharge_level)*source.kb_mult*velocity_power_mult
			attack.deflect_speed_mult += overcharge_level
			
			attack.deflect_type = Attack.DeflectType.TARGET_CURSOR
			attack.deflect_speed_mult *= 2.0
			attack.deflect_damage_mult *= 2.0
	
	if source is ShotgunBot:
		attack.deflect_speed_mult = source.deflect_speed_mult
		attack.deflect_damage_mult = source.deflect_damage_mult
	
	var hit_entities = chain.execute_next([collider, attack])
	
	if source is ShotgunBot:
		var improvised_nails = source.get_currently_applicable_upgrades()['improvised_nails']
		for entity in hit_entities:
			for i in range(0, improvised_nails * 4):
				var angle = source.global_position.direction_to(entity.global_position).rotated(0.35*PI*(randf() - 0.5)).normalized()
				var bullet = Violence.shoot_bullet(source, entity.global_position, angle*source.shot_speed, source.bullet_damage)
				bullet.ignored.append(entity)
				bullet.set_appearance(source.bullet_type)
	
	return hit_entities
