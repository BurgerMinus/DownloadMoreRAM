extends "res://Scripts/Hosts/ShieldBot/ShieldBot.gd"

var gravity_tackle = false
var base_base_shield_enemy_repulsion = 1500
var GRAVITY_STRENGTH = 2.5

var static_shock = 0
var shield_attack_cooldown = 0.25
var shield_attack_timer = 0.0
var shield_attack_damage = 2.5
var shield_attack_stun = 0.1

var quasar_amplification = false
var death_ray_damage = 25.0
var death_ray_kb = 2.5
var death_ray_charge = 0.0
var death_ray_width = 15.0
var death_ray_angle = 0.0
var death_ray_slowdown = 0.25
var death_ray_turn_speed = 0.5

func toggle_enhancement(state):
	
	static_shock = 0
	quasar_amplification = false
	gravity_tackle = false
	
	base_base_shield_enemy_repulsion = 1500
	super(state)
	base_base_shield_enemy_repulsion = base_shield_enemy_repulsion
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	static_shock = upgrades_to_apply['static_shock']
	quasar_amplification = upgrades_to_apply['quasar_amplification'] > 0
	gravity_tackle = upgrades_to_apply['event_horizon'] > 0

func player_action():
	retaliation_locked = death_ray_charge > 0.0
	# the following code ensures that you can still fire even if you have no projectiles as long as you have fuel
	if Input.is_action_pressed("attack1") and not attacking:
		if not beeftank_mode and quasar_amplification and death_ray_charge > 0.0:
			toggle_retaliation(true)
			retaliation_target_point = get_global_mouse_position()
			return
	if quasar_amplification and not retaliation_locked and not shield_active:
		if (captured_projectiles.is_empty() and death_ray_charge < 0.0) or not Input.is_action_pressed("attack1"):
			toggle_retaliation(false)
	
	super()

func _physics_process(delta):
	super(delta)
	if quasar_amplification:
		if retaliating:
			var angle_diff = Vector2.RIGHT.rotated(death_ray_angle).angle_to(global_position.direction_to(retaliation_target_point))
			var turn_speed = death_ray_turn_speed * deg_to_rad(sign(angle_diff)) * (min(bullet_orbit_speed, 33.0) / 6.0)
			death_ray_angle += sign(angle_diff) * min(abs(turn_speed), abs(deg_to_rad(angle_diff)))
		else:
			death_ray_angle = Vector2.RIGHT.angle_to(global_position.direction_to(get_global_mouse_position()))

func while_retaliating(delta):
	super(delta)
	if quasar_amplification and death_ray_charge > 0.0:
		if captured_projectiles.is_empty():
			apply_effect(EffectType.SPEED_MULT, self, 0.65)
		apply_effect(EffectType.SPEED_MULT, self, death_ray_slowdown)
		fire_death_ray(delta)
	elif captured_projectiles.is_empty():
		toggle_retaliation(false)

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
#	clear_previous_death_ray()
	set_shield_active(false) # edge case handling
	var dps_mult = bullet_orbit_speed / 6.0 #(1.0 + (bullet_orbit_speed - 6.0)/9.0)
	var damage_mult = (1.0 + dps_mult) * retaliation_damage_mult
	var dir = Vector2.RIGHT.rotated(death_ray_angle).normalized()
	var beam_attack = Attack.new(self, damage_mult * death_ray_damage * delta, death_ray_kb)
	var laser = LaserParams.new(global_position + 25*dir, dir, beam_attack)
	laser.style = LaserParams.Style.RAIL
	laser.pierces = 999
	laser.width = death_ray_width
	Violence.shoot_laser(laser)
	death_ray_charge -= delta * dps_mult
	special_cooldown -= delta * dps_mult * 0.2

func clear_previous_death_ray():
	pass # i have no idea how to do this

func apply_shield_effects(delta):
	super(delta)
	
	shield_attack_timer -= delta*static_shock
	if shield_attack_timer < 0.0:
		inflict_shield_attack()
		shield_attack_timer = shield_attack_cooldown

func inflict_shield_attack():
	var shield_attack = Attack.new(self, shield_attack_damage)
	shield_attack.stun = shield_attack_stun
	for e in nearby_enemies:
		if not is_in_shield_AOE(e.global_position) or (e.was_recently_player() == was_recently_player()): continue
		shield_attack.inflict_on(e)

func start_tackle():
	super()
	if gravity_tackle:
		shield_attack_cooldown = 0.05
		shield_attack_stun = 0.5
		base_shield_enemy_repulsion = -base_base_shield_enemy_repulsion * GRAVITY_STRENGTH
		set_shield_width(2*PI)
		set_shield_color(Vector3(0.33, 0, 0.5))
		set_shield_active(true)

func end_tackle():
	super()
	# reset event horizon effects
	shield_attack_cooldown = 0.25
	shield_attack_stun = 0.1
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
