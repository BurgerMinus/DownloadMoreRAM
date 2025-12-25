extends Object

var homing_target = {}

func _ready(chain: ModLoaderHookChain):
	
	var bullet = chain.reference_object as Bullet
	
	chain.execute_next()
	
	var source = bullet.causality.source
	
	if is_instance_valid(source):
		
		var explosive = false
		var homing = false
		
		if source is ShotgunBot:
			var upgrades_to_apply = source.get_currently_applicable_upgrades() 
			explosive = upgrades_to_apply['flak_shell'] > 0
			homing = upgrades_to_apply['embedded_vision'] > 0
		elif source is FlakBullet:
			homing = homing_target.has(source)
			explosive = source.explosion_size > 0
		
		if homing:
			homing_target[bullet] = [null, 0.1]
		if explosive:
			bullet.explosion_damage = bullet.damage * 0.5
			bullet.explosion_kb = bullet.damage * 10
			bullet.explosion_size = min(bullet.damage, 15) * 0.075

func _physics_process(chain: ModLoaderHookChain, delta):
	
	# this ensures that a soldering slug sticks around long enough to pass on homing information
	for bullet in homing_target.keys():
		if not is_instance_valid(bullet):
			homing_target.erase(bullet)
	
	print(homing_target.keys().size())
	
	var bullet = chain.reference_object as Bullet
	
	chain.execute_next([delta])
	
	if homing_target.has(bullet):
		if homing_target[bullet] == null or homing_target[bullet][1] < 0:
			update_homing_target(bullet)
		homing_target[bullet][1] -= delta
		if homing_target[bullet][0] != null:
			home_to_target(bullet, delta)

func on_pierce(chain: ModLoaderHookChain):
	
	var bullet = chain.reference_object as Bullet
	
	if bullet.explosion_size > 0:
		var explosion_attack = Attack.new(bullet.causality.original_source, bullet.explosion_damage, bullet.explosion_kb)
		Violence.spawn_explosion(bullet.global_position, explosion_attack, bullet.explosion_size)
	
	chain.execute_next()

func despawn(chain: ModLoaderHookChain):
	
	var bullet = chain.reference_object as Bullet
	
	if bullet.explosion_size > 0:
		var explosion_attack = Attack.new(bullet.causality.original_source, bullet.explosion_damage, bullet.explosion_kb)
		Violence.spawn_explosion(bullet.global_position, explosion_attack, bullet.explosion_size)
	
	if not bullet is FlakBullet:
		homing_target.erase(bullet)
	
	chain.execute_next()

func update_homing_target(bullet):
	
	if homing_target[bullet] == null:
		homing_target[bullet] = [null, 0.1]
	
	var enemies = []
	var hits = bullet.get_tree().get_nodes_in_group('hitbox')
	for hit in hits:
		var enemy = null
		if hit is Enemy:
			enemy = hit
		elif hit.get_parent() is Enemy:
			enemy = hit.get_parent()
		if is_instance_valid(enemy) and bullet.get_attack().can_hit(enemy):
			enemies.append(enemy)
	if not enemies.is_empty():
		enemies.sort_custom(func(a, b): return a.global_position.distance_to(bullet.global_position) < b.global_position.distance_to(bullet.global_position))
		if enemies[0].global_position.distance_to(bullet.global_position) < 200:
			homing_target[bullet][0] = enemies[0]

func home_to_target(bullet, delta):
	
	var target = homing_target[bullet][0]
	if not (is_instance_valid(target) and target is Enemy):
		return 
	
	var homing_constant = 5
	var target_angle = bullet.velocity.angle_to(bullet.global_position.direction_to(target.global_position))
	var homing_angle = delta*homing_constant*sign(target_angle)
	
	bullet.velocity = bullet.velocity.rotated(homing_angle)
	bullet.global_rotation += homing_angle
