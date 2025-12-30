extends Object

var bloodlust_duration = 2.5
var bloodlust_timer = 0.0
var bloodlust_drain = 0.0

func _process(chain: ModLoaderHookChain, delta):
	
	var swap_manager = chain.reference_object as SwapManager
	
	if GameManager.player.upgrades['bloodlust'] > 0 and bloodlust_timer > 0.0:
		bloodlust_timer -= delta
		if swap_manager.juice_system:
			swap_manager.juice_system.spend_juice(bloodlust_drain * delta)
	
	chain.execute_next([delta])

func swap_to_host(chain: ModLoaderHookChain, new_host, free_swap = false, play_sound = true):
	
	var swap_manager = chain.reference_object as SwapManager
	
	# i know this is ugly and horrible but at least it probably works ?
	# the goal is to determine if the swap is going to go through as normal
	if GameManager.player.upgrades['bloodlust'] > 0 and bloodlust_timer <= 0.0:
		if new_host is Host and not new_host is SwapTrigger and not free_swap and not swap_manager.timer_system and is_instance_valid(swap_manager.juice_system):
			if not (new_host.is_in_group('free_swap') or not new_host.uses_swap_restrictions):
				if swap_manager.has_host():
					if not swap_manager.true_host.is_in_group('free_swap'):
						if not (new_host.was_recently_player() and GameManager.player.upgrades['doubt'] and new_host.doubt_swap_cooldown < 0.0):
							free_swap = true
							bloodlust_timer = bloodlust_duration
							var post_mortem = swap_manager.true_host is Enemy and swap_manager.true_host.dead 
							bloodlust_drain = 1.5 * swap_manager.juice_system.get_swap_cost(post_mortem) / bloodlust_duration
	
	chain.execute_next([new_host, free_swap, play_sound])

func add_juice_from_kill(chain: ModLoaderHookChain, equivalent_basic_kills):
	
	var swap_manager = chain.reference_object as SwapManager
	
	bloodlust_timer = 0.0
	
	chain.execute_next([equivalent_basic_kills])
