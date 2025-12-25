extends "res://Scripts/Hosts/FlameBot/FlameBot.gd"

var tar_deployment_boost = 0.0
var tar_speed_boost_mult = 1.0
var tar_speed_boost_timer = 0.0
var tar_bomb = false
var tar_bomb_charge = 0
var tar_bomb_texture

func _ready():
	super()
	TarProjectileScene = null # forces the scene to be reloaded
	tar_bomb_texture = Util.get_cached_texture(ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-DownloadMoreRAM").path_join("tar_bomb.png"))

func toggle_enhancement(state):
	
	tar_deployment_boost = 0.0
	tar_pressure_drop_rate = 0.4
	tar_pressure_recharge_rate = 0.5
	tar_durability_mult = 1.0
	tar_speed_boost_mult = 1.0
	tar_bomb = false
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	tar_deployment_boost += 0.5 * upgrades_to_apply['underpressure']
	tar_pressure_recharge_rate *= 1.0 + 0.5 * upgrades_to_apply['underpressure']
	tar_speed_boost_mult = 1.0 + upgrades_to_apply['slipstream']
	tar_durability_mult += 0.5 * upgrades_to_apply['slipstream']
	tar_bomb = upgrades_to_apply['filtration_purge'] > 0
	if tar_bomb:
		tar_pressure_drop_rate *= 1.0 + 0.5 * upgrades_to_apply['underpressure']

func _physics_process(delta):
	
	super(delta)
	
	if tar_speed_boost_timer > 0.0:
		apply_effect(EffectType.SPEED_MULT, self, tar_speed_boost_mult * min(1, tar_speed_boost_timer*10))
	else:
		cancel_effect(EffectType.SPEED_MULT, self)

func update_timers(delta):
	super(delta)
	
	tar_timer -= delta*tar_deployment_boost
	
	var overlaps = hitbox.get_overlapping_areas()
	for area in overlaps:
		if area.is_in_group('tar'):
			tar_speed_boost_timer = min(tar_speed_boost_timer + delta, 0.15)
			return
	tar_speed_boost_timer = max(tar_speed_boost_timer - delta, 0.0)
	

func while_emitting_tar(delta):
	if tar_bomb:
		if tar_pressure > 0:
			tar_bomb_charge = min(tar_bomb_charge + delta*tar_pressure_drop_rate, 1.0)
		tar_pressure = max(tar_pressure - delta*tar_pressure_drop_rate, 0.0)
		explode_if_flamethrower_active()
	else:
		super(delta)

func stop_emitting_tar():
	super()
	if tar_bomb:
		shoot_tar_bomb()
		tar_bomb_charge = 0

func shoot_tar_bomb():
	var dist = min(global_position.distance_to(get_global_mouse_position()), tar_range) if is_player else tar_range
	var target_point = global_position + aim_direction*dist + Vector2.RIGHT.rotated(randf()*TAU)*randf()*10*(dist/100.0)
	var charge_level = 0
	if tar_bomb_charge >= 0.1:
		charge_level += 1
	if tar_bomb_charge >= 0.25:
		charge_level += 1
	if tar_bomb_charge >= 0.5:
		charge_level += 1
	if tar_bomb_charge >= 0.95:
		charge_level += 1
	
	if not is_instance_valid(TarProjectileScene):
		TarProjectileScene = Util.get_cached_resource('res://Scenes/Hosts/Flamebot/TarProjectile.tscn')
	
	var projectile = TarProjectileScene.instantiate()
	projectile.causality.set_source(self)
	projectile.durability_mult = tar_durability_mult
	projectile.water_mode = water_mode
	projectile.global_position = global_position
	projectile.charge_level = charge_level
	
	Util.set_object_elevation(projectile, elevation)
	get_parent().add_child(projectile)
	projectile.launch_to_point(target_point)
	
	if charge_level > 0:
		set_bomb_appearance(projectile)

func set_bomb_appearance(bomb):
	while not is_instance_valid(bomb.sprite):
		pass
	bomb.sprite.texture = tar_bomb_texture
	bomb.sprite.modulate = Color(0.5, 0.5, 0.5, 1)
	bomb.scale *= 0.1 * (0.5*bomb.charge_level + 1)
