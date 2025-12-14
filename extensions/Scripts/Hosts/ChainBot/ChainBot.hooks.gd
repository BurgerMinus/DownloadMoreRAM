extends Object

var point_defense = {}

func toggle_enhancement(chain: ModLoaderHookChain, state):
	
	var deadlift = chain.reference_object as Enemy
	
	deadlift.charge_speed = 1.0
	
	chain.execute_next([state])
	
	var upgrades_to_apply = deadlift.get_currently_applicable_upgrades()
	
	point_defense[str(deadlift)] = upgrades_to_apply['point_defense'] > 0
	if point_defense[str(deadlift)]:
		deadlift.charge_speed *= 2.0

# "NEEDS REFACTOR" indeed lol
func process_melee_hits(chain: ModLoaderHookChain):
	
	var deadlift = chain.reference_object as Enemy
	
	if point_defense[str(deadlift)]:
		deadlift.charge_level = min(1.5, deadlift.charge_level) #-# CHANGE NUMBER ONE
		var charged = deadlift.charge_time >= deadlift.MIN_CHARGE_TIME_TO_LAUNCH*deadlift.min_charge_time_to_launch_mult
		
		if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and deadlift.is_player:
			Input.start_joy_vibration(0, 0, 0.5, 0.2)
			
		var speed_toward_target = deadlift.velocity.length() - (300 if deadlift.footwork else 0)
		if deadlift.velocity.normalized().dot(deadlift.attack_direction) < -0.5:
			speed_toward_target = 0.0
		
		var velocity_power_mult = 1.0 + max(0.0, (speed_toward_target - 200)/600.0)
		var grappling_toward_wall = deadlift.wall_grapple_timer > 0.0 and deadlift.tug_timer > 0.0 and speed_toward_target > 200
		
		var melee_attack = Attack.new(deadlift, 10 + deadlift.charge_damage*deadlift.charge_level*deadlift.damage_mult*velocity_power_mult)
		melee_attack.impulse = deadlift.aim_direction*(200 + 500*deadlift.charge_level)*deadlift.kb_mult*velocity_power_mult
		melee_attack.deflect_type = Attack.DeflectType.TARGET_CURSOR #-# CHANGE NUMBER TWO
		melee_attack.deflect_speed_mult = 1.0 + deadlift.charge_level
		melee_attack.add_tag(Attack.Tag.MELEE)
		melee_attack.ignored = deadlift.hit_entities
		melee_attack.ignored.append(deadlift)
		
		if deadlift.allow_friendly_fire:
			melee_attack.hit_allies = true
		
		if grappling_toward_wall:
			melee_attack.bonuses.append(Fitness.Bonus.KABEDON)
		elif deadlift.wall_bounce_timer > 0.0:
			melee_attack.bonuses.append(Fitness.Bonus.REBOUND)
			
		if deadlift.reverse_grapple and (deadlift.grappling_toward_wall or deadlift.wall_bounce_timer > 0.0):
			melee_attack.damage *= 1.5
		
		if charged:
			deadlift.play_animation('ChargedAttack')
			deadlift.charged_attack_sprite.play()
		else:
			deadlift.play_animation('Attack')
			deadlift.attack_sprite.play()
		
		var hits = Violence.melee_attack(deadlift.attack_collider, melee_attack)
		for entity in hits:
			deadlift.hit_entities.append(entity)
		
		# Determine which hit entities, if any, to launch
		var to_launch = []
		if grappling_toward_wall or deadlift.wall_bounce_timer > 0.0:
			to_launch = hits
			
		elif deadlift.has_grappled_entity() and deadlift.tug_timer > 0:
			if deadlift.reverse_grapple and speed_toward_target > 200:
				to_launch = hits
				
			elif deadlift.grapple.anchor_entity in hits:
				to_launch = [deadlift.grapple.anchor_entity]
			
		# Calculate launch effects
		for launched in to_launch:
			if not launched is Enemy and not launched is PhysicsActor: continue
			
			deadlift.tug_timer = 0.0
			var rel_speed = (deadlift.velocity - (launched.velocity - melee_attack.impulse/launched.mass)).length()
				
			deadlift.attack_cooldown = 0.0
			var rebound_vel = Vector2.ZERO#-grappled_kb_vel
			var heavy_enemy = launched.mass > deadlift.mass*1.5
	
			var grappled_kb_vel = deadlift.aim_direction
			if deadlift.fishing_mode:
				grappled_kb_vel = Vector2.RIGHT.rotated(clampf(Util.unsigned_wrap(grappled_kb_vel.angle()), PI*0.5, PI*1.5))
		
			#Charged hits break the launched state and launch the enemy
			if charged:
				var finisher_attack = Attack.new(deadlift, pow(deadlift.juggle_combo, 1.3))
				finisher_attack.damage *= (15 if heavy_enemy else 8)
				finisher_attack.inflict_on(launched)
				if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER and deadlift.is_player:
					Input.start_joy_vibration(0, 0, 0.7, 0.2)
					
				grappled_kb_vel *= deadlift.grapple_hit_kb*(1.0 + deadlift.juggle_combo*0.3) + rel_speed*(0.25 if deadlift.reverse_grapple else 0.1) 
				
				if not deadlift.fishing_mode:
					deadlift.launch_entity(launched, deadlift.juggle_combo)
				
				if deadlift.was_recently_player():
					GameManager.time_manager.duck_timescale('player', 0.001, 0.2 if deadlift.juggle_combo < 4 else 0.3, 100)
				
			#Uncharged hits juggle the enemy and maintain launched state	
			else:
				deadlift.juggle_timer = 1.0
				deadlift.juggle_combo = min(deadlift.juggle_combo + 1, deadlift.max_juggle_combo)
				deadlift.handle_juggle_audio(deadlift.juggle_combo)
				grappled_kb_vel *= deadlift.grapple_hit_kb*(1.0 + deadlift.juggle_combo*0.1)*(0.8 if deadlift.reverse_grapple else 1.0) + rel_speed*0.1
				if deadlift.was_recently_player():
					GameManager.time_manager.duck_timescale('player', 0.001, 0.05, 1000)
				
			rebound_vel = -grappled_kb_vel*0.3
			
			#If enemy is heavy, launch self backward	
			if heavy_enemy:
				if not charged:
					rebound_vel = -grappled_kb_vel
					grappled_kb_vel = -rebound_vel*0.5
				
			var effective_grappled_mass = launched.mass if launched.mass  <= 1.0 else (1.0 + (launched.mass - 1.0)/deadlift.mass)
			launched.velocity = grappled_kb_vel / effective_grappled_mass
			
			# Take knockback only from launching grappled entity
			if deadlift.has_grappled_entity() and launched == deadlift.grapple.anchor_entity:
				deadlift.velocity = rebound_vel / deadlift.mass
	else:
		chain.execute_next()

func die(chain: ModLoaderHookChain, attack = null):
	
	var deadlift = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	point_defense.erase(str(deadlift))
