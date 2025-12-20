extends Object

const TarPuddle = preload('res://Scenes/Violence/TarPuddle.tscn')

var invincible = {}
var molotov = {}
var flash = {}

func _ready(chain: ModLoaderHookChain):
	
	for grenade in invincible.keys():
		if not is_instance_valid(grenade):
			invincible.erase(grenade)
			molotov.erase(grenade)
			flash.erase(grenade)
	
	for grenade in molotov.keys():
		if not is_instance_valid(grenade):
			invincible.erase(grenade)
			molotov.erase(grenade)
			flash.erase(grenade)
	
	for grenade in flash.keys():
		if not is_instance_valid(grenade):
			invincible.erase(grenade)
			molotov.erase(grenade)
			flash.erase(grenade)
	
	var grenade = chain.reference_object as Grenade
	
	chain.execute_next()
	
	var router = grenade.causality.source
	
	if is_instance_valid(router):
		if 'invincible_grenades' in router and router.invincible_grenades:
			invincible[grenade] = true
		if 'molotov_grenades' in router and router.molotov_grenades:
			molotov[grenade] = true
		if 'impact_grenades' in router and router.impact_grenades:
			flash[grenade] = true

func take_damage(chain: ModLoaderHookChain, attack):
	
	var grenade = chain.reference_object as Grenade
	
	if not (invincible.has(grenade) and invincible[grenade]):
		chain.execute_next([attack])

func on_hit_entity(chain: ModLoaderHookChain, entity):
	
	var grenade = chain.reference_object as Grenade
	
	if entity is Enemy and grenade.can_hit() and flash.has(grenade) and flash[grenade]:
		var damage_mult = 0.8
		var kb_mult = 0.25
		var size_mult = 0.67
		var explosion_attack = Attack.new(grenade, grenade.explosion_damage*damage_mult, 400*grenade.explosion_size*kb_mult)
		explosion_attack.deflect_type = Attack.DeflectType.REPULSE
		if grenade.bounces > 0: explosion_attack.bonuses.append(Fitness.Bonus.REBOUND)
		if grenade.deflected: explosion_attack.bonuses.append(Fitness.Bonus.HOT_POTATO)
		Violence.spawn_explosion(grenade.global_position if not GameManager.level_manager.in_combat_hub else grenade.position, explosion_attack, grenade.explosion_size*size_mult, 0, true, 'grenade')
		
		if molotov.has(grenade) and molotov[grenade]:
			
			var fire_explosion_attack = Attack.new(grenade, 0, 0)
			fire_explosion_attack.add_tag(Attack.Tag.FIRE)
			Violence.spawn_explosion(grenade.global_position if not GameManager.level_manager.in_combat_hub else grenade.position, fire_explosion_attack, grenade.explosion_size*size_mult, 0, true, 'grenade')
			
			var tar = TarPuddle.instantiate()
			tar.global_position = grenade.global_position
			tar.causality.set_source(grenade.causality.source)
			tar.z_index = grenade.z_index - 1
			grenade.get_parent().add_child(tar)
			tar.ignite(null, false)
	
	chain.execute_next([entity])

func explode(chain: ModLoaderHookChain):
	
	var grenade = chain.reference_object as Grenade
	
	chain.execute_next()
	
	if molotov.has(grenade) and molotov[grenade]:
		
		# use duplicate explosion to light up tar puddles
		var explosion_attack = Attack.new(grenade, 0, 0)
		explosion_attack.add_tag(Attack.Tag.FIRE)
		explosion_attack.deflect_type = Attack.DeflectType.REPULSE
		Violence.spawn_explosion(grenade.global_position if not GameManager.level_manager.in_combat_hub else grenade.position, explosion_attack, grenade.explosion_size, 0, true, 'grenade')
		
		# spawn tar
		var is_fragment = grenade.scale.x < 0.8
		var offset = 2*PI*randf()
		for i in range(0, 1 + (0 if is_fragment else 3)):
			var tar = TarPuddle.instantiate()
			tar.global_position = grenade.global_position
			if i != 0:
				tar.global_position += 20*grenade.explosion_size * Vector2.RIGHT.rotated(offset + i*0.67*PI + 2*(randf()-0.5))
			tar.causality.set_source(grenade.causality.source)
			tar.z_index = grenade.z_index - 1
			grenade.get_parent().add_child(tar)
			tar.ignite(null, false)
	
	molotov.erase(grenade)
	invincible.erase(grenade)
	flash.erase(grenade)
