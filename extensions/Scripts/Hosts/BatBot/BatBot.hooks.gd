extends Object

var jackhammer = {}
const jackhammer_delay = 0.35

func toggle_enhancement(chain : ModLoaderHookChain, is_player):
	
	var epitaph = chain.reference_object as BatBot
	
	epitaph.paddle.scale = Vector2(1, 1)
	epitaph.paddle_sprite.scale = Vector2(1, 1)
	
	chain.execute_next([is_player])
	
	var upgrades_to_apply = epitaph.get_currently_applicable_upgrades()
	
	epitaph.paddle.scale *= 1 + 0.5*upgrades_to_apply['long_stick']
	jackhammer[epitaph] = upgrades_to_apply['jackhammer'] > 0

func hit_with_paddle(chain : ModLoaderHookChain, entity):
	
	var epitaph = chain.reference_object as BatBot
	
	if jackhammer[epitaph] and entity is EnergyBall and entity.combo == 2:
		
		var hit_angle = epitaph.paddle_angle + 0.5*PI*sign(epitaph.paddle_vel)
		var hit_dir = Vector2(cos(hit_angle), sin(hit_angle))
		var dir = hit_dir
		
		var target = get_auto_aim_target(epitaph, entity.global_position, hit_dir)
		if is_instance_valid(target):
			dir = entity.global_position.direction_to(target.global_position)
		
		var beam_attack = Attack.new(epitaph, max(50, 50*entity.damage_mult), dir*1000)
		beam_attack.ignored.append(entity)
		beam_attack.bonuses.append(Fitness.Bonus.RALLY)
		beam_attack.bonuses.append(Fitness.Bonus.RALLY)
		
		var laser = LaserParams.new(entity.global_position, dir, beam_attack)
		laser.pierces = 0
		laser.style = LaserParams.Style.RAIL
		laser.width = 10.0 * entity.damage_mult
		if epitaph.piercing_balls:
			laser.bounces = 3
			laser.pierces = 3
		
		var explosion_attack = Attack.new(epitaph, 100*entity.damage_mult, 800*entity.damage_mult)
		laser.explosion_attack = explosion_attack
		laser.explosion_size = 1.33*entity.damage_mult
		explosion_attack.bonuses.append(Fitness.Bonus.RALLY)
		explosion_attack.bonuses.append(Fitness.Bonus.RALLY)
		
		fire_jackhammer_laser(entity, laser)
		
#		entity.queue_free()
#		Violence.shoot_laser(laser)
		
		if epitaph.was_recently_player():
			epitaph.bat_strike_audio.play()
			GameManager.time_manager.duck_timescale('player', 0.001, jackhammer_delay, 100)
	else:
		chain.execute_next([entity])

func fire_jackhammer_laser(ball, laser):
	await ball.get_tree().create_timer(jackhammer_delay*0.1).timeout
	ball.queue_free()
	Violence.shoot_laser(laser)

func get_auto_aim_target(epitaph, beam_origin, hit_dir):
	
	var max_homing_angle = PI/9.0
	var max_homing_dist = 100
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 4
	query.transform = epitaph.global_transform
	var shape = CircleShape2D.new()
	shape.radius = 500
	query.set_shape(shape)
	
	var results = epitaph.get_world_2d().direct_space_state.intersect_shape(query, 128)
	var attack = Attack.new(epitaph)
	var valid_entities = []
	for hit in results:
		var collider = hit.collider
		if collider.is_in_group('hitbox'):
			var entity = collider.get_parent()
			if (entity is Enemy or entity is ImpactSwitch) and not entity == epitaph and attack.can_hit(entity):
				var angle = hit_dir.angle_to(entity.global_position - beam_origin)
				var dist = entity.global_position.distance_to(beam_origin) / sin(angle)
				if abs(angle) < max_homing_angle or abs(dist) < max_homing_dist:
					valid_entities.append(entity)
				
	valid_entities.sort_custom(func(a, b): return abs(hit_dir.angle_to(a.global_position - beam_origin)) < abs(hit_dir.angle_to(b.global_position - beam_origin)))
	for entity in valid_entities:
		if epitaph.AI.point_has_LOS_to_entity(beam_origin, entity, epitaph.elevation) and not entity is EnergyBall:
			return entity
	return null

func die(chain: ModLoaderHookChain, attack = null):
	
	var epitaph = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	jackhammer.erase(epitaph)
