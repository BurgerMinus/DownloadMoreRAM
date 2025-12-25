extends Object

func take_damage(chain: ModLoaderHookChain, attack):
	
	var saber = chain.reference_object as FreeSaber
	var break_sword = saber.anchored
	var anchor_entity = saber.anchor_entity
	
	var impulse = attack.get_impulse_on(saber)
	if impulse.is_zero_approx(): break_sword = false
	if attack.causality.source is ControlledSaber: break_sword = false
	
	var s = attack.causality.original_source
	if not (is_instance_valid(s) and s is Enemy and 'sword_break' in s and s.sword_break > 0): break_sword = false
	
	if Attack.Tag.CWBIDBSC in attack.tags and is_instance_valid(s) and 'true_focus' in s and not s.true_focus:
		if is_instance_valid(anchor_entity) and Util.get_embedded_sabers(anchor_entity).size() == 1: break_sword = false
	
	chain.execute_next([attack])
	
	if break_sword:
		saber.damage *= (1 + s.sword_break) / (1 + 2*s.sword_break)
		for i in range(0, 1 + 2 * s.sword_break):
			var side_saber = ControlledSaber.FreeSaberScene.instantiate()
			side_saber.damage = saber.damage
			side_saber.global_position = saber.global_position
			side_saber.global_rotation = 2*PI*randf()
			side_saber.velocity = saber.velocity.rotated(randf() * PI/12.0 * pow(-1, i))
			side_saber.mass = saber.mass
			side_saber.scale = saber.scale
			side_saber.angular_velocity = saber.angular_velocity
			side_saber.launch_in_arc(0.5, 10)
			side_saber.causality.set_source(attack.causality.source)
			side_saber.lifetime = 2.0
			side_saber.ignored_entities.append(anchor_entity)
			GameManager.objects_node.add_child(side_saber)
			Util.set_object_elevation(side_saber, anchor_entity.elevation)
		saber.queue_free()
