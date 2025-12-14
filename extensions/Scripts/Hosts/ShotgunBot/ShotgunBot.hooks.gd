extends Object

var improvised_nails = {}

func toggle_enhancement(chain : ModLoaderHookChain, is_player):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	chain.execute_next([is_player])
	
	var upgrades_to_apply = steeltoe.get_currently_applicable_upgrades()
	
	improvised_nails[steeltoe] = upgrades_to_apply['improvised_nails']

func die(chain: ModLoaderHookChain, attack = null):
	
	var steeltoe = chain.reference_object as Enemy
	
	chain.execute_next([attack])
	
	improvised_nails.erase(steeltoe)

func melee(chain: ModLoaderHookChain):
	
	var steeltoe = chain.reference_object as ShotgunBot
	
	if true or improvised_nails[steeltoe] == 0:
		chain.execute_next()
	else:
		# vanilla code
		if steeltoe.is_player:
			GameManager.camera.set_trauma(0.6)
		steeltoe.velocity -= 250*steeltoe.aim_direction.normalized()
		var melee_attack = Attack.new(self, steeltoe.melee_damage)
		melee_attack.stun = steeltoe.melee_stun
		melee_attack.impulse = 1000
		melee_attack.deflect_type = Attack.DeflectType.TARGET_SOURCE
		melee_attack.deflect_speed_mult = 3.0
		melee_attack.deflect_damage_mult = 2.0
		melee_attack.deflect_added_stun = steeltoe.melee_stun
		melee_attack.tags.append(Attack.Tag.MELEE)
		melee_attack.bonuses.append(Fitness.Bonus.MELEE)
		steeltoe.melee_sprite.rotation = steeltoe.aim_direction.angle()
		steeltoe.melee_sprite.play()
		var hit_entities = Violence.melee_attack(steeltoe.melee_collider_shape, melee_attack) # first change (i need this list)
		
		for i in range(0, improvised_nails[steeltoe]*hit_entities.size()*4):
			var angle = steeltoe.aim_direction.angle().rotated(0.5*PI*(randf() - 0.5))
			var bullet = Violence.shoot_bullet(steeltoe, steeltoe.global_position, angle*steeltoe.shot_speed, steeltoe.bullet_damage)
			bullet.ignored.append_array(hit_entities)
