extends Object

var super_melee = {}

func toggle_enhancement(chain : ModLoaderHookChain, is_player):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	chain.execute_next([is_player])
	
	var upgrades_to_apply = steeltoe.get_currently_applicable_upgrades()
	
	super_melee[steeltoe] = [upgrades_to_apply['volume_settings_overclock'], steeltoe.melee_collider.scale, steeltoe.melee_sprite.scale]

func die(chain: ModLoaderHookChain, attack = null):
	
	var steeltoe = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	super_melee.erase(steeltoe)

func shoot(chain: ModLoaderHookChain):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	var melee_boost = clamp(1.0 - abs(steeltoe.melee_charge_timer)*5.0, 0.0, 1.0)
	if melee_boost < 0.3:
		melee_boost = 0.0
	else:
		melee_boost = min(1.0, melee_boost + 0.1*(steeltoe.melee_boost_window_mult - 1.0))
	
	if super_melee[steeltoe][0] and melee_boost > 0.9:
		steeltoe.melee_collider.scale *= 2.0
		steeltoe.melee_sprite.scale *= 2.0
		
		var count = 4
		if steeltoe.melee_charge_timer - 0.0001 > 0.0:
			count += 1
		
		for i in range(0, count):
			steeltoe.melee()
			steeltoe.velocity += 250*steeltoe.aim_direction.normalized()
		
		steeltoe.apply_melee_boost_aftereffects(melee_boost)
		reset_values(steeltoe)
		
		steeltoe.loaded_shells = 0
		steeltoe.attack_cooldown = steeltoe.max_attack_cooldown
		if steeltoe.blast_dynamo:
			steeltoe.special_cooldown = 0.3
			steeltoe.attack_cooldown = 0.5*steeltoe.max_attack_cooldown
	else:
		chain.execute_next()

func reset_values(steeltoe):
	
	await steeltoe.get_tree().create_timer(0.5).timeout
	steeltoe.melee_collider.scale = super_melee[steeltoe][1]
	steeltoe.melee_sprite.scale = super_melee[steeltoe][2]
