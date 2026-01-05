extends Object

var super_melee = {}

func toggle_enhancement(chain : ModLoaderHookChain, is_player):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	chain.execute_next([is_player])
	
	var upgrades_to_apply = steeltoe.get_currently_applicable_upgrades()
	
	super_melee[steeltoe] = [upgrades_to_apply['volume_settings_overclock'] > 0, steeltoe.melee_collider.scale, steeltoe.melee_sprite.scale, steeltoe.deflect_speed_mult, steeltoe.deflect_damage_mult]

func die(chain: ModLoaderHookChain, attack = null):
	
	var steeltoe = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	super_melee.erase(steeltoe)

func start_melee(chain: ModLoaderHookChain):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	reset_values(steeltoe)
	
	chain.execute_next()

func shoot(chain: ModLoaderHookChain):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	var melee_boost = clamp(1.0 - abs(steeltoe.melee_charge_timer)*5.0, 0.0, 1.0)
	if melee_boost < 0.3:
		melee_boost = 0.0
	else:
		melee_boost = min(1.0, melee_boost + 0.1*(steeltoe.melee_boost_window_mult - 1.0))
	
	if super_melee[steeltoe][0] and melee_boost > 0.9:
		
		if steeltoe.blast_dynamo:
			steeltoe.melee_sprite.speed_scale *= 3.0
		
		steeltoe.melee_collider.scale *= 2.0
		steeltoe.melee_sprite.scale *= 2.0
		steeltoe.deflect_speed_mult *= 2.0
		steeltoe.deflect_damage_mult *= 2.0
		
		var count = 4
		if steeltoe.melee_charge_timer - 0.0001 > 0.0: # determine if attack has already happened
			count += 1
		
		for i in range(0, count):
			steeltoe.melee()
			steeltoe.velocity += 250*steeltoe.aim_direction.normalized()
		
		steeltoe.apply_melee_boost_aftereffects(melee_boost)
		
		steeltoe.loaded_shells = 0
		steeltoe.attack_cooldown = steeltoe.max_attack_cooldown
		if steeltoe.blast_dynamo:
			steeltoe.special_cooldown = 0.3
			steeltoe.attack_cooldown = 0.5*steeltoe.max_attack_cooldown
	else:
		chain.execute_next()

func reset_values(steeltoe):
	steeltoe.melee_collider.scale = super_melee[steeltoe][1]
	steeltoe.melee_sprite.scale = super_melee[steeltoe][2]
	steeltoe.deflect_speed_mult = super_melee[steeltoe][3]
	steeltoe.deflect_damage_mult = super_melee[steeltoe][4]
	steeltoe.melee_sprite.speed_scale = 1.0
