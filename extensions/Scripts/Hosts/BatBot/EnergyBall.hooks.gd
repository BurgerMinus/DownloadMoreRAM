extends Object

var GravityVortexScene = null

# vortex has nothing to do with power mult but this is just a convenient time to set vortex property
func apply_power_mult(chain: ModLoaderHookChain, mult):
	
	var ball = chain.reference_object as EnergyBall
	
	if GravityVortexScene == null:
		GravityVortexScene = load(ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-DownloadMoreRAM/GravityVortex.tscn"))
	
	chain.execute_next([mult])
	
	var epitaph = ball.causality.source
	
	if is_instance_valid(epitaph):
		if epitaph.get_currently_applicable_upgrades()['helikon_berra_postulate'] > 0:
			ball.add_to_group('dmr_vortex')
		else:
			ball.remove_from_group('dmr_vortex')

func hit_entity(chain: ModLoaderHookChain, entity):
	
	var ball = chain.reference_object as EnergyBall
	
	if ball.is_in_group('dmr_vortex') and ball.combo >= 2:
		var check_attack = Attack.new(ball, 0, 0)
		check_attack.hit_allies = ball.can_hit_allies
		if check_attack.can_hit(entity):
			var gravity_vortex = GravityVortexScene.instantiate()
			gravity_vortex.global_position = ball.global_position
			gravity_vortex.scale *= 0.75
			Util.set_object_elevation(gravity_vortex, Util.elevation_from_z_index(ball.z_index))
			GameManager.objects_node.add_child(gravity_vortex)
	
	chain.execute_next([entity])

func explode(chain: ModLoaderHookChain):
	
	var ball = chain.reference_object as EnergyBall
	
	if ball.is_in_group('dmr_vortex') and ball.combo >= 2:
		var gravity_vortex = GravityVortexScene.instantiate()
		gravity_vortex.global_position = ball.global_position
		gravity_vortex.scale *= 0.75
		Util.set_object_elevation(gravity_vortex, Util.elevation_from_z_index(ball.z_index))
		GameManager.objects_node.add_child(gravity_vortex)
	
	chain.execute_next()
