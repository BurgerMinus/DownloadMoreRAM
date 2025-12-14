extends Object

var vortex = {}
var GravityVortexScene = null

# vortex has nothing to do with power mult but this is just a convenient time to set vortex property
func apply_power_mult(chain: ModLoaderHookChain, mult):
	
	var ball = chain.reference_object as EnergyBall
	
	if GravityVortexScene == null:
		GravityVortexScene = load(ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-DownloadMoreRAM/GravityVortex.tscn"))
	
	chain.execute_next([mult])
	
	var epitaph = ball.causality.source
	
	if is_instance_valid(epitaph):
		vortex[ball] = epitaph.get_currently_applicable_upgrades()['vortex'] > 0

func hit_entity(chain: ModLoaderHookChain, entity):
	
	for orb in vortex.keys():
		if not is_instance_valid(orb):
			vortex.erase(orb)
	
	var ball = chain.reference_object as EnergyBall
	
	if vortex.has(ball) and vortex[ball] and ball.combo >= 2:
		var check_attack = Attack.new(ball, 0, 0)
		check_attack.hit_allies = ball.can_hit_allies
		if check_attack.can_hit(entity):
			var gravity_vortex = GravityVortexScene.instantiate()
			gravity_vortex.global_position = ball.global_position
			gravity_vortex.scale *= 0.75
			if is_instance_valid(GameManager.player.true_host):
				Util.set_object_elevation(gravity_vortex, GameManager.player.true_host.elevation)
			GameManager.objects_node.add_child(gravity_vortex)
	
	chain.execute_next([entity])

func explode(chain: ModLoaderHookChain):
	
	var ball = chain.reference_object as EnergyBall
	
	vortex.erase(ball)
	
	for orb in vortex.keys():
		if not is_instance_valid(orb):
			vortex.erase(orb)
	
	chain.execute_next()
