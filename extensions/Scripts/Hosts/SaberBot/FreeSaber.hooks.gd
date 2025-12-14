extends Object

var sword_break = {}

func anchor_in(chain: ModLoaderHookChain, entity, offset = Vector2.ZERO):
	
	var saber = chain.reference_object as FreeSaber
	
	chain.execute_next([entity, offset])
	
#	if 'sword_break' in saber.causality.source:
#		sword_break[str(saber)] = saber.causality.source.sword_break

func take_damage(chain: ModLoaderHookChain, attack):
	
	var saber = chain.reference_object as FreeSaber
	var break_sword = saber.anchored# and sword_break[str(saber)]
	var anchor_entity = saber.anchor_entity
	
	var impulse = attack.get_impulse_on(saber)
	if impulse.is_zero_approx(): break_sword = false
	if attack.causality.source is ControlledSaber: break_sword = false
	
	var s = attack.causality.original_source
	if not (is_instance_valid(s) and s is Enemy and 'sword_break' in s and s.sword_break): break_sword = false
	
	if Attack.Tag.CWBIDBSC in attack.tags and is_instance_valid(s) and 'true_focus' in s and not s.true_focus:
		if is_instance_valid(anchor_entity) and Util.get_embedded_sabers(anchor_entity).size() == 1: break_sword = false
	
	if break_sword:
		saber.damage *= 0.66
	
	chain.execute_next([attack])
	
	if break_sword:
		
		for i in range(0, 2):
			var side_saber = ControlledSaber.FreeSaberScene.instantiate()
			side_saber.damage = saber.damage
			side_saber.global_position = saber.global_position
			side_saber.global_rotation = saber.global_rotation
			side_saber.velocity = saber.velocity.rotated(randf() * PI/12.0 * (1 if i == 0 else -1))
			side_saber.angular_velocity = saber.angular_velocity
			side_saber.launch_in_arc(0.5, 10)
			side_saber.causality.set_source(attack.causality.source)
			side_saber.lifetime = 2.0
			side_saber.ignored_entities.append(anchor_entity)
			GameManager.objects_node.add_child(side_saber)
			Util.set_object_elevation(side_saber, anchor_entity.elevation)

func free_from_anchor(chain: ModLoaderHookChain):
	
	var saber = chain.reference_object as FreeSaber
	
	chain.execute_next()
	
#	sword_break.erase(str(saber))
