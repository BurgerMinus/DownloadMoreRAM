extends "res://Scripts/Hosts/FlameBot/TarProjectile.gd"

var charge_level = 0

var tar_drop_timer = 0.0

var TarProjectileScene
var flamebotgd = Util.get_cached_resource("res://Scripts/Hosts/FlameBot/FlameBot.gd")

func _physics_process(delta):
	super(delta)
	
	tar_drop_timer -= delta*charge_level
	if tar_drop_timer < 0.0:
		tar_drop_timer = 0.2 + 0.1*randf()
		drop_tar_projectile()

func splat():
	
	if charge_level == 0:
		super()
		return
	
	var base_pos = global_position - Vector2.UP*z_height
	var offset = randf()*TAU
	var count = (charge_level * 2 - 1) * (3 + (randi() % 3))
	var spread = charge_level * 15
	for i in range(0, count):
		spawn_tar(base_pos + randf()*spread*Vector2.RIGHT.rotated(offset + i*TAU/count + randf()))
	queue_free()

func drop_tar_projectile():
	
	var target_pos = global_position - Vector2.DOWN*z_height + 10*Vector2.RIGHT.rotated(TAU*randf())
	
	if not is_instance_valid(TarProjectileScene):
		TarProjectileScene = Util.get_cached_resource('res://Scenes/Hosts/Flamebot/TarProjectile.tscn')
	var projectile = TarProjectileScene.instantiate()
	projectile.causality.set_source(causality.source)
	projectile.durability_mult = durability_mult
	projectile.spawn_ignited = spawn_ignited
	projectile.water_mode = water_mode
	projectile.global_position = global_position
	Util.set_object_elevation(projectile, Util.elevation_from_z_index(z_index))
	get_parent().add_child(projectile)
	projectile.launch_to_point(target_pos)

func spawn_tar(position):
	flamebotgd.spawn_tar_at_point(self, position, durability_mult, spawn_ignited, water_mode)
