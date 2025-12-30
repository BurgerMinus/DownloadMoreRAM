extends "res://Scripts/Hosts/ShieldBot/ShieldBot.gd"

const LaserBeamScene := preload("res://Scenes/Violence/LaserBeam.tscn")

var base_shoot_audio_volume = null

var gravity_tackle = false
var base_base_shield_enemy_repulsion
var GRAVITY_STRENGTH = 2.5

var static_shock = 0
const max_shield_attack_cooldown = 0.25
var shield_attack_cooldown = 0.25
var shield_attack_timer = 0.0
var shield_attack_damage = 2.5
var shield_attack_stun = 0.1
var base_shield_attack_stun = 0.1

var quasar_amplification = false
var death_rays = []
var death_ray_damage = 25.0
var death_ray_kb = 2.5
var death_ray_charge = 0.0
var death_ray_width = 15.0
var death_ray_angle = 0.0
var death_ray_slowdown = 0.5
var death_ray_turn_speed = 2.0

func toggle_enhancement(state):
	
	if base_shoot_audio_volume == null:
		base_shoot_audio_volume = shoot_audio.volume_db
	shoot_audio.volume_db = base_shoot_audio_volume
	
	static_shock = 0
	quasar_amplification = false
	gravity_tackle = false
	
	super(state)
	base_base_shield_enemy_repulsion = base_shield_enemy_repulsion
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	static_shock = upgrades_to_apply['static_shock']
	gravity_tackle = upgrades_to_apply['event_horizon'] > 0
	quasar_amplification = upgrades_to_apply['quasar_amplification'] > 0 and not beeftank_mode # probably redundant?
	if quasar_amplification:
		shoot_audio.volume_db -= 10

func player_action():
	retaliation_locked = death_ray_charge > 0.0
	# the following code ensures that you can still fire even if you have no projectiles as long as you have fuel
	if Input.is_action_pressed("attack1") and not attacking:
		if not beeftank_mode and quasar_amplification and death_ray_charge > 0.0:
			toggle_retaliation(true)
			return
	if quasar_amplification and not retaliation_locked and not shield_active:
		if (captured_projectiles.is_empty() and death_ray_charge < 0.0) or not Input.is_action_pressed("attack1"):
			toggle_retaliation(false)
	super()

func _physics_process(delta):
	
	for i in range(0, nearby_projectiles.size()):
		var p = nearby_projectiles[i]
		if is_instance_valid(p) and p.is_in_group('ignore_shield'):
			nearby_projectiles[i] = null
	
	super(delta)
	
	if quasar_amplification:
		if retaliating or death_ray_charge > 0.0:
			retaliation_target_point = get_global_mouse_position()
			var angle_diff = Vector2.RIGHT.rotated(death_ray_angle).angle_to(global_position.direction_to(retaliation_target_point))
			var turn_speed = death_ray_turn_speed * deg_to_rad(sign(angle_diff)) * (min(bullet_orbit_speed, 33.0) / 6.0)
			death_ray_angle += sign(angle_diff) * min(abs(turn_speed), abs(deg_to_rad(angle_diff)))
			if quasar_amplification and death_ray_charge > 0.0:
				if captured_projectiles.is_empty():
					apply_effect(EffectType.SPEED_MULT, self, 0.65)
				apply_effect(EffectType.SPEED_MULT, self, death_ray_slowdown)
				fire_death_ray(delta)
			elif captured_projectiles.is_empty():
				toggle_retaliation(false)
		else:
			death_ray_angle = Vector2.RIGHT.angle_to(global_position.direction_to(get_global_mouse_position()))

func shoot_captured_projectile(proj_index, target_point, repeat = 0):
	
	if quasar_amplification:
		
		var projectiles = []
		var physics_projectiles = []
		for i in range(captured_projectiles.size()):
			var p = captured_projectiles[i]
			if is_instance_valid(p):
				if p is PhysicsProjectile:
					physics_projectiles.append([i, p])
				else:
					projectiles.append([i, p])
		
		if projectiles.is_empty() and death_ray_charge <= 0.0:
			super(proj_index, target_point, repeat)
			return
		
		expulsion_timer = 0 # should queue up the refueling properly? idk man
		
		if death_ray_charge <= 0.0:
			
			# prefer non-physics projectiles to keep the beam persistent as long as possible
			var total_damage = 0.0
			var fuel_projectile = projectiles[proj_index % projectiles.size()]
			total_damage += fuel_projectile[1].damage
			fuel_projectile[1].despawn()
			captured_projectiles[fuel_projectile[0]] = null
			death_ray_charge = 2 * (total_damage / death_ray_damage)
			
			# only proc entanglement on physics projectiles, as it wouldn't be very useful on bullets
			var bonus_shots = 0
			while bonus_shots < physics_projectiles.size():
				if randf() < bonus_shot_chance:
					bonus_shots += 1
				else:
					break;
			var temp = bonus_shot_chance
			bonus_shot_chance = 0
			for i in range(bonus_shots):
				var original_index = physics_projectiles[(proj_index+ i) % physics_projectiles.size()][0]
				super(original_index, target_point, i + 1)
			bonus_shot_chance = temp
			
			projectiles_formation_update_needed = true
			
	else:
		super(proj_index, target_point, repeat)

func fire_death_ray(delta):
	
	if death_rays.size() == 6:
		var death_ray = death_rays[0]
		death_rays.pop_front()
		if is_instance_valid(death_ray):
			death_ray.queue_free()
		
	set_shield_active(false) # edge case handling
	
	var dps_mult = bullet_orbit_speed / 6.0
	var damage_mult = (1.0 + dps_mult) * retaliation_damage_mult
	var dir = Vector2.RIGHT.rotated(death_ray_angle).normalized()
	var beam_attack = Attack.new(self, damage_mult * death_ray_damage * delta, death_ray_kb)
	var params = LaserParams.new(global_position + 25*dir, dir, beam_attack)
	params.style = LaserParams.Style.RAIL
	params.pierces = 999
	params.width = death_ray_width
	death_ray_charge -= delta * dps_mult
	special_cooldown -= delta * dps_mult * 0.2
	
	var volume = shoot_audio.volume_db
	shoot_audio.volume_db -= 10
	shoot_audio.play()
	shoot_audio.volume_db = volume
	
	death_rays.append(get_death_ray_beam(params))

# lightly modified version of Violence.shoot_laser(params)
func get_death_ray_beam(params: LaserParams):
	var laser = LaserBeamScene.instantiate()
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
		
		# If the entity stops the laser remove it from the "ignored" list
		if remaining_pierces <= 0 or entity.is_in_group('block_pierce'): 
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
	
	# Handle laser visuals
	var sprite = laser.get_node('Sprite')
	sprite.texture = laser.rail_beam
#	laser.anim_frame = death_ray_frame
	laser.last_frame = 6
	laser.frame_width = 64
	
	var num_tiles = dist/64.0
	sprite.material.set_shader_parameter('h_tiles', num_tiles)
	sprite.modulate = params.modulate
	
	return laser

func apply_shield_effects(delta):
	super(delta)
	
	shield_attack_timer -= delta*static_shock
	if shield_attack_timer < 0.0:
		inflict_shield_attack()
		shield_attack_timer = shield_attack_cooldown

func inflict_tackle_attack(entity):
	var true_velocity = velocity
	# bandaid fix for the relative velocity calculation being bugged (interacts very poorly with gravity well)
	if gravity_tackle and 'velocity' in entity:
		var enemy_vel_component = entity.velocity.project(velocity.normalized())
		if enemy_vel_component.normalized() != velocity.normalized():
			velocity -= 2.0 * enemy_vel_component
	super(entity)
	velocity = true_velocity

func inflict_shield_attack():
	var shield_attack = Attack.new(self, shield_attack_damage)
	shield_attack.stun = shield_attack_stun
	for e in nearby_enemies:
		if not is_in_shield_AOE(e.global_position) or (e.was_recently_player() == was_recently_player()): continue
		shield_attack.inflict_on(e)
		if randf() < max_shield_attack_cooldown:
			generate_captured_bullets(1, e.global_position)

func start_tackle():
	if retaliating and retaliation_locked:
		return
	super()
	if gravity_tackle:
		shield_attack_timer *= 0.2
		shield_attack_cooldown = 0.2*max_shield_attack_cooldown
		shield_attack_stun = 5*base_shield_attack_stun
		base_shield_enemy_repulsion = -base_base_shield_enemy_repulsion * GRAVITY_STRENGTH
		set_shield_width(2*PI)
		set_shield_color(Vector3(0.33, 0, 0.5))
		set_shield_active(true)

func end_tackle():
	super()
	# reset event horizon effects
	shield_attack_cooldown = max_shield_attack_cooldown
	shield_attack_stun = base_shield_attack_stun
	base_shield_enemy_repulsion = base_base_shield_enemy_repulsion
	update_overburden_penalties() # reset shield width and color

func update_overburden_penalties():
	if not (gravity_tackle and tackling): # do not override event horizon effects
		super()

func on_laser_deflection(impact_point, params):
	
	if tackling and gravity_tackle:
		
		var damage_boost = ceil(params.attack.damage/30.0)
		for p in captured_projectiles:
			p.damage += damage_boost
			if p is PhysicsProjectile: # grenades and sabers have their damage halved when launched, so double damage boost to compensate
				p.damage += damage_boost 
		
		# TODO: make laser curve in incrementally it would look cool
		var reflected_laser = params.duplicate()
		reflected_laser.origin = impact_point
		reflected_laser.direction = (global_position - impact_point).normalized()
		reflected_laser.deflected = true
		
		reflected_laser.attack.damage *= 0.0
		reflected_laser.attack.impulse *= 0.0
		reflected_laser.pierces = 0
		reflected_laser.split_count = 0
		reflected_laser.bounces = 0
		reflected_laser.explosion_attack = null
		
		Violence.shoot_laser(reflected_laser)
		
	else:
		super(impact_point, params)

func _on_shield_area_entered(area):
	super(area)
	if tackling and gravity_tackle and area is Projectile:
		on_projectile_tackled(area)
