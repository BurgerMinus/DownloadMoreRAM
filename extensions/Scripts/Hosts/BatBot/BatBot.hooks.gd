extends Object

var big_stick = {}

var jackhammer = {}
const jackhammer_delay = 0.35
const jackhammer_hit_sound = preload("res://Sounds/SoundEffects/Tom/WheelBot/RAM_wheelbotGrenadeImpact.wav")

var GravityVortexScene = null

func toggle_enhancement(chain : ModLoaderHookChain, is_player):
	
	var epitaph = chain.reference_object as BatBot
	
	epitaph.paddle.scale = Vector2(1, 1)
	epitaph.paddle_max_vel = 5*PI
	
	chain.execute_next([is_player])
	
	var upgrades_to_apply = epitaph.get_currently_applicable_upgrades()
	
	if upgrades_to_apply['big_stick'] > 0:
		epitaph.paddle.scale *= 1 + 0.5*upgrades_to_apply['big_stick']
		epitaph.paddle_max_vel *= 1.5#1.0 + 0.5*upgrades_to_apply['big_stick']
		big_stick[epitaph] = true
	
	jackhammer[epitaph] = upgrades_to_apply['corium_infusion'] > 0

func start_swing(chain: ModLoaderHookChain, lunge_dir = Vector2.ZERO):
	
	var epitaph = chain.reference_object as BatBot
	
	if lunge_dir == Vector2.ZERO:
		lunge_dir = epitaph.get_movement_input_vector().normalized()
	
	chain.execute_next([lunge_dir])
	
	if big_stick.has(epitaph):
		epitaph.paddle_accel *= 1.75#1.0 + 0.5*big_stick[epitaph]

func hit_with_paddle(chain: ModLoaderHookChain, entity):
	
	var epitaph = chain.reference_object as BatBot
	
	if jackhammer[epitaph] and entity is EnergyBall and entity.combo >= 2:
		
		var mult = entity.damage_mult * (1.0 + 0.2*(entity.combo - 2))
		var hit_angle = epitaph.paddle_angle + 0.5*PI*sign(epitaph.paddle_vel)
		var hit_dir = Vector2(cos(hit_angle), sin(hit_angle))
		var dir = hit_dir
		
		var target = get_auto_aim_target(epitaph, entity.global_position, hit_dir)
		if is_instance_valid(target):
			dir = entity.global_position.direction_to(target.global_position)
		
		var beam_attack = Attack.new(epitaph, max(50, 50 * mult), dir*1000)
		beam_attack.ignored.append(entity)
		for i in range(0, entity.combo):
			beam_attack.bonuses.append(Fitness.Bonus.RALLY)
		
		var laser = LaserParams.new(entity.global_position, dir, beam_attack)
		laser.pierces = 0
		laser.style = LaserParams.Style.RAIL
		laser.width = 10.0 * mult
		if epitaph.piercing_balls:
			laser.bounces = 3
			laser.pierces = 3
		
		var explosion_attack = Attack.new(epitaph, 100*mult, 800*mult)
		laser.explosion_attack = explosion_attack
		laser.explosion_size = 1.33*mult
		for i in range(0, entity.combo):
			explosion_attack.bonuses.append(Fitness.Bonus.RALLY)
		
		fire_jackhammer_laser_delayed(epitaph, entity, laser, epitaph.get_currently_applicable_upgrades()['helikon_berra_postulate'] > 0)
		
		if epitaph.was_recently_player():
			GameManager.time_manager.duck_timescale('player', 0.001, jackhammer_delay, 100)
	else:
		chain.execute_next([entity])

func fire_jackhammer_laser_delayed(epitaph, ball, params, vortex = false):
	
	if GravityVortexScene == null:
		GravityVortexScene = load(ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-DownloadMoreRAM/GravityVortex.tscn"))
	
	var combo = ball.combo
	
	var hit_audio = AudioStreamPlayer2D.new()
	hit_audio.stream = jackhammer_hit_sound
	hit_audio.global_position = ball.global_position
	hit_audio.volume_db += 10
	ball.get_tree().current_scene.add_child(hit_audio)
	hit_audio.connect("finished", Callable(hit_audio, "queue_free"))
	hit_audio.play()
	
	await ball.get_tree().create_timer(jackhammer_delay*0.1).timeout
	
	# it is possible for the ball to land and reset its combo during the delay which is bad
	ball.set_combo(combo)
	
	epitaph.bat_strike_audio.play()
	
	var ball_recall_position = fire_jackhammer_laser(ball, params, vortex)
	var epitaph_position = ball.causality.original_source.global_position
	
	if ball.combo > ball.max_combo or ball_recall_position.distance_to(epitaph_position) > 1024:
		ball.queue_free()
		return
	
	ball.global_position = ball_recall_position
	ball.launch_to_point(epitaph_position, 1.0, 60)

func fire_jackhammer_laser(ball, params, vortex):
	
	var ball_recall_position = null
	var num_hits = 0
	var initial_combo = ball.combo
	
	var laser = Violence.LaserBeamScene.instantiate()
	var attack = params.attack
	
	# Add laser to scene and set elevation
	Util.set_object_elevation(laser, Util.elevation_from_z_index(attack.causality.source.z_index))
	GameManager.objects_node.add_child(laser)
	
	laser.global_position = params.origin
	laser.rotation = params.direction.angle()
	laser.style = params.style
	
	var excluded = [attack.causality.source.get_node('Hitbox')]
	if attack.causality.source.get_node_or_null('Deflector'):
		excluded.append(attack.causality.source.get_node('Deflector'))
	
	var result = null
	var space_state = attack.causality.source.get_world_2d().direct_space_state

	# Initial raycast to determine how far the laser goes before being blocked by terrain
	var query = PhysicsRayQueryParameters2D.new()
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = Util.bullet_collision_layers[params.attack.elevation]
	query.exclude = excluded
	query.from = params.origin
	query.to = params.origin + params.direction*10000
	
	result = space_state.intersect_ray(query)
	
	# Scale laser based on above raycast so its collider can be used in the next step
	var dist = (result.position - params.origin).length() if result else 2000
	laser.scale = Vector2(dist/384.0, params.width/6.0)
	
	
	# Check laser collider intersects to get hit entities
	var collider = laser.get_node('CollisionShape2D')
	if params.large_hitbox:
		collider.scale.y = 2
	
	query = PhysicsShapeQueryParameters2D.new()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 4 + 32
	query.exclude = []
	query.transform = collider.global_transform
	query.set_shape(collider.shape)
	var results = space_state.intersect_shape(query, 512)
	
	# Sort hits by distance
	var sorted_results = []
	for hit in results:
		# Special laser deflector objects are checked first to confirm if they can block the laser, and have their collision points pre-computed
		if hit.collider.is_in_group('mirror'):
			if params.deflected: continue 
			var entity = hit.collider.get_parent()
			if not 'get_laser_impact_point' in entity: continue
			var impact_point = entity.get_laser_impact_point(params)
			if not impact_point.is_finite(): continue
			sorted_results.append([hit, impact_point.distance_squared_to(params.origin), impact_point])
			
		else:	
			sorted_results.append([hit, hit.collider.global_position.distance_squared_to(params.origin)])
			
	sorted_results.sort_custom(func(a, b): return a[1] < b[1])
	
	# Process the hits from nearest to farthest and exit the loop if something stops the laser
	var col
	var farthest_hit_dist = 0
	var remaining_pierces = params.pierces
	var pierced = []
	var laser_stopped = false
	var laser_split_on_entity = null
	var laser_bounced_off_entity = null
	var precise_distance_known = false
	
	for hit in sorted_results:
		col = hit[0].collider
		
		# Any deflectors that made it into the list are confirmed able to deflect the laser
		# Process like any other laser-blocking collider, and defer specific deflection behaviour to the entity itself
		if col.is_in_group('mirror'):
			var entity = col.get_parent()
			if 'on_laser_deflection' in entity:
				entity.on_laser_deflection(hit[2], params)
		
			farthest_hit_dist = hit[1]
			dist = params.origin.distance_to(hit[2])
			precise_distance_known = true
			break
				
			
		# Ignore dead enemies and any weird non-hitbox colliders the laser shouldn't interact with
		if not col.is_in_group('hitbox'): continue
			
		var entity = col.get_parent()
		#if not (entity is Enemy or entity is PhysicsActor): continue
		
		if attack.duplicate().inflict_on(entity):
			if entity is Enemy:
				attack.bonuses.append(Fitness.Bonus.LASER_PIERCE)
		else:
			pierced.append(col)
			continue
		
		farthest_hit_dist = hit[1]
		if params.explosion_size > 0:
			ball_recall_position = entity.global_position
			num_hits += 1
			Violence.spawn_explosion(entity.global_position, params.explosion_attack, params.explosion_size, params.explosion_delay*(0.8 + randf()*0.4), true, '', false, (entity if params.explosion_delay > 0 else null))
			if vortex:
				var gravity_vortex = GravityVortexScene.instantiate()
				gravity_vortex.global_position = entity.global_position
				gravity_vortex.scale *= 0.75
				if is_instance_valid(GameManager.player.true_host):
					Util.set_object_elevation(gravity_vortex, GameManager.player.true_host.elevation)
				GameManager.objects_node.add_child(gravity_vortex)
		
		# If the entity stops the laser remove it from the "ignored" list
		if remaining_pierces <= 0 or entity.is_in_group('block_pierce'): 
			laser_stopped = true
			break
			
		if params.bounces > 0:
			laser_bounced_off_entity = entity
			laser_stopped = true
			break
			
		# Add each entity that doesn't stop the laser to this list so they can be ignored in the next step
		pierced.append(col)
		remaining_pierces -= 1
		
	# Determine visual length of laser with final raycast to find the precise intersection point with whatever entity stopped the laser
	# If the laser was blocked by a laser deflector, this intersection point was already computed, and so the raycast is skipped
	if not precise_distance_known:
		#print('Calculating precise laser dist (farthest hit = ', sqrt(farthest_hit_dist), ')')
		result = null
		if laser_stopped:
			query = PhysicsRayQueryParameters2D.new()
			query.collide_with_areas = true
			query.collide_with_bodies = false
			query.collision_mask = 4
			query.exclude = pierced
			query.from = params.origin
			query.to = params.origin + params.direction*1000 #(sqrt(farthest_hit_dist) if farthest_hit_dist > 0.0 else 0.0)
			result = space_state.intersect_ray(query)

		if result:
			#print('Precise stopping point found')
			dist = (result.position - params.origin).length() + 5
			
		
	laser.scale = Vector2(dist/384.0, params.width/6.0)
	var impact_point = params.origin + params.direction*dist
	
	if laser_bounced_off_entity:
		var bounced_laser = params.duplicate()
		bounced_laser.attack.ignored.append(laser_bounced_off_entity)
		
		var target_candidates = Violence.get_targetable_enemies_in_radius(params.attack.causality.source, impact_point, 150)
		var best_alignment = 1.0
		var best_candidate = null
		for candidate in target_candidates:
			if candidate in bounced_laser.attack.ignored: continue
			
			var alignment = params.direction.dot(impact_point.direction_to(candidate.global_position))
			if alignment < best_alignment:
				best_candidate = candidate
				best_alignment = alignment
				
		if best_candidate:
			bounced_laser.direction = impact_point.direction_to(best_candidate.global_position)
		elif params.previous_bounces == 0:
			bounced_laser.direction = laser_bounced_off_entity.global_position.direction_to(impact_point)
		else:
			bounced_laser.direction = params.direction
			
		bounced_laser.bounces -= 1
		bounced_laser.previous_bounces += 1
		bounced_laser.origin = impact_point
		bounced_laser.apply_intensity_mult(params.bounce_damage_mult)
		if best_candidate:
			ball_recall_position = fire_jackhammer_laser(ball, bounced_laser, vortex)
	
	# Handle laser visuals
	var sprite = laser.get_node('Sprite')
	if laser.style == LaserParams.Style.RAIL:
		sprite.texture = laser.rail_beam
		laser.last_frame = 6
		laser.frame_width = 64
	else:
		sprite.texture = laser.red_beam
		laser.frame_width = 32
		laser.last_frame = 11
	
	var num_tiles = 1
	if params.style == LaserParams.Style.RED:
		num_tiles = dist/32.0
	elif params.style == LaserParams.Style.RAIL:
		num_tiles = dist/64.0
	sprite.material.set_shader_parameter('h_tiles', num_tiles)
	sprite.modulate = params.modulate
	
	if num_hits == 0: 
		ball_recall_position = params.origin + params.direction*dist # normal return value, only use if the laser misses
	elif initial_combo == ball.combo:
		ball.set_combo(ball.combo + 1)
	
	return ball_recall_position

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
	big_stick.erase(epitaph)
