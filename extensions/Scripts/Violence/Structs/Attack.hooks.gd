extends Object

func inflict_on(chain: ModLoaderHookChain, target):
	
	var attack = chain.reference_object as Attack
	
	# slightly redundant logic is necessary because of how i had to implement the router dodge upgrade
	if attack.can_hit(target) and 'invincibility_timer' in target and target.invincibility_timer > 0.0:
		if attack.causality.original_source != target and 'on_attack_dodged' in target:
			target.on_attack_dodged(attack)
		return false
	else:
		return chain.execute_next([target])

func duplicate(chain: ModLoaderHookChain):
	
	var attack = chain.reference_object as Attack
	
	var d = chain.execute_next()
	
	# fixes the resonance bug (not really my job but yk since im already here)
	d.deflect_added_stun = attack.deflect_added_stun
	
	return d
