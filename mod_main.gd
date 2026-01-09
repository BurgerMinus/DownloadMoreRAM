extends Node

const MOD_DIR := "BurgerMinus-DownloadMoreRAM"

var mod_dir_path := ""
var overwrites = []
var upgrade_names = [
	'improvised_nails', 'volume_settings_overclock', 'hollow_pointer', 'embedded_vision', 'flak_shell',
	'phase_shift', 'total_recall', 'flash_flame', 'pyroclastic_flow',
	'underpressure', 'slipstream', 'filtration_purge', 
	'point_defense', 'repurposed_scrap',
	'static_shock', 'quasar_amplification', 'event_horizon', 
	'percussive_strike', 'medium_maximization',
	'refresh_overclocking',
	'big_stick', 'helikon_berra_postulate', 'corium_infusion'
	]

var golem_upgrade_names = ['mimesis', 'temerity', 'bloodlust', 'desperation', 'echopraxia']

func _init() -> void:
	
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	
	reorder_and_install_upgrades()
	
	if ModLoaderMod.is_mod_loaded("BurgerMinus-EndpointManagement"):
		var EM_dir_path = ModLoaderMod.get_unpacked_dir().path_join("BurgerMinus-EndpointManagement")
		ModLoaderMod.install_script_hooks(EM_dir_path.path_join("extensions/Scripts/Hosts/Bosses/Lv3/GolemBoss.gd"), mod_dir_path.path_join("extensions/Scripts/Hosts/Bosses/Lv3/GolemBoss.hooks.gd"))
	
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/FlameBot/FlameBot.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/WheelBot/WheelBot.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/SaberBot/SaberBot.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/ShieldBot/ShieldBot.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/ArcherBot/ArcherBot.gd"))
	
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/EnemyAI.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/EnemyAI.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/Enemy.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/Enemy.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/GolemSpider.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/GolemSpider.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/ShotgunBot/ShotgunBot.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/ShotgunBot/ShotgunBot.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/ChainBot/ChainBot.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/ChainBot/ChainBot.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/BatBot/BatBot.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/BatBot/BatBot.hooks.gd"))
	
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/ChainBot/Grapple.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Violence/Bullet.gd", mod_dir_path.path_join("extensions/Scripts/Violence/Bullet.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Violence/Grenade.gd", mod_dir_path.path_join("extensions/Scripts/Violence/Grenade.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/SaberBot/FreeSaber.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/SaberBot/FreeSaber.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/BatBot/EnergyBall.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/BatBot/EnergyBall.hooks.gd"))
	
	ModLoaderMod.install_script_hooks("res://Scripts/Violence/Violence.gd", mod_dir_path.path_join("extensions/Scripts/Violence/Violence.hooks.gd"))
	ModLoaderMod.install_script_hooks("res://Scripts/Violence/Structs/Attack.gd", mod_dir_path.path_join("extensions/Scripts/Violence/Structs/Attack.hooks.gd"))
	ModLoaderMod.add_hook(attack_init, "res://Scripts/Violence/Structs/Attack.gd", "_init")
	
	ModLoaderMod.install_script_hooks("res://Scripts/Player/SwapManager.gd", mod_dir_path.path_join("extensions/Scripts/Player/SwapManager.hooks.gd"))
	
	handle_overwrites()

# im so mad that this has to be here and not in attacks.hooks.gd my organization is in shambles
func attack_init(chain: ModLoaderHookChain, source_, damage_ = 0, impulse_ = Vector2.ZERO):
	
	var attack = chain.reference_object as Attack
	
	chain.execute_next([source_, damage_, impulse_])
	
	if not is_instance_valid(attack.causality.original_source):
		return
	
	var source = attack.causality.original_source
	if source.is_in_group('dmr_player_echopraxia'):
		if not source.is_in_group('dmr_melog_echopraxia') or randf() > 0.5:
			attack.hit_allies = true
			attack.hit_source = false

func reorder_and_install_upgrades():
	
	var temp_upgrades = Upgrades.upgrades.duplicate(true)
	Upgrades.upgrades.clear()
	
	for upgrade in temp_upgrades.keys():
		
		Upgrades.upgrades[upgrade] = temp_upgrades[upgrade]
		
		# this code is about to look really dumb
		
		match upgrade:
			
			'digitigrade_optimization': install_steeltoe_upgrades(0)
			'evasive_maneuvers': install_steeltoe_upgrades(1)
			'blast_dynamo': install_steeltoe_upgrades(2)
			
			'preheated_tires': install_router_upgrades(0)
			'unsecured_cargo': install_router_upgrades(1)
			'perforated_envelope': install_router_upgrades(2)
			
			'quadrupedal_optimization': install_aphid_upgrades(0)
			'aerated_fuel_tanks': install_aphid_upgrades(1)
			'second_sun': install_aphid_upgrades(2)
			
			'leg_day_hallucination': install_deadlift_upgrades(0)
			'hassotobi': install_deadlift_upgrades(1)
			'finesse': install_deadlift_upgrades(2)
			
			'exposed_coils': install_collider_upgrades(0)
			'entanglement': install_collider_upgrades(1)
			'beeftank_doctrine': install_collider_upgrades(2)
			
			'cloak_aerodynamics': install_tachi_upgrades(0)
			'harpoon_tip': install_tachi_upgrades(1)
			'fractured_mind': install_tachi_upgrades(2)
			
			'vibro_shimmy': install_thistle_upgrades(0)
			'h_raytracing': install_thistle_upgrades(1)
			'slobberknocker_protocol': install_thistle_upgrades(2)
			
			'frame_interpolation': install_epitaph_upgrades(0)
			'pitching_arm': install_epitaph_upgrades(1)
			'subcriticality': install_epitaph_upgrades(2)
			
	
	var temp_golem_upgrades = Upgrades.GOLEM_upgrades.duplicate(true)
	Upgrades.GOLEM_upgrades.clear()
	
	for upgrade in temp_golem_upgrades.keys():
		if upgrade == 'thorn':
			install_golem_upgrades()
		Upgrades.GOLEM_upgrades[upgrade] = temp_golem_upgrades[upgrade]

func install_steeltoe_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['improvised_nails'] = {
			'name': 'Improvised Nails',
			'desc': 'If all you have is a resonance hammer, every spike of metal looks like a nail.',
			'effects': ['Hitting enemies with Resonance Hammer launches a spray of +4 projectiles'],
			'type': Enemy.EnemyType.SHOTGUN,
			'tier': 1, 
			'max_stack': 3,
			'ai_useable': true,
			'credits': "Concept and Icon by Lettuce\nImplementation by BurgerMinus"
		}
	else:
		Upgrades.upgrades['hollow_pointer'] = {
			'name': 'Hollow Pointer', # haha you get it bc pointers and robots haha get it
			'desc': 'Even metal will bleed.', # gabriel ultrakill
			'effects': ['Pellets induce non-stacking damage over time'],
			'type': Enemy.EnemyType.SHOTGUN,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		
		Upgrades.upgrades['embedded_vision'] = {
			'name': 'Embedded Vision',
			'desc': 'Nanomachines, son.', # nice argument senator
			'effects': ['Pellets home in on nearby targets'],
			'type': Enemy.EnemyType.SHOTGUN,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['soldering_fingers'],
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		if not Upgrades.upgrades['soldering_fingers'].has('precludes'):
			Upgrades.upgrades['soldering_fingers']['precludes'] = []
		Upgrades.upgrades['soldering_fingers']['precludes'].append('embedded_vision')
		
		Upgrades.upgrades['flak_shell'] = {
			'name': 'Flak Shell', # astroflux reference
			'desc': 'No parry required.', # roundabout ultrakill reference
			'effects': ['Pellets explode on contact'],
			'type': Enemy.EnemyType.SHOTGUN,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['induction_barrel'],
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		if not Upgrades.upgrades['induction_barrel'].has('precludes'):
			Upgrades.upgrades['induction_barrel']['precludes'] = []
		Upgrades.upgrades['induction_barrel']['precludes'].append('flak_shell')
		
		Upgrades.upgrades['volume_settings_overclock'] = {
			'name': 'Volume Settings Overclock',
			'desc': 'Noise-cancelling headphones recommended.',
			'effects': ['Performing a Nail Driver greatly boosts the size and power of the Resonance Hammer, but does not fire pellets'],
			'type': Enemy.EnemyType.SHOTGUN,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Concept by Saynin\nImplementation by BurgerMinus"
		}

func install_router_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['phase_shift'] = {
			'name': 'Phase Shift',
			'desc': 'Who decided that?', # escanor
			'effects': ['Grenades cannot be deflected or blocked by enemies'],
			'type': Enemy.EnemyType.WHEEL,
			'tier': 1, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	else:
		Upgrades.upgrades['total_recall'] = {
			'name': 'Total Recall', # funnily enough not a tracer reference
			'desc': 'Quicker recovery.', # hades reference
			'effects': ['Dodging an attack will negate all damage taken in the last second', '-80% dash cooldown'],
			'type': Enemy.EnemyType.WHEEL,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		
		Upgrades.upgrades['flash_flame'] = {
			'name': 'Flash Flame', # aye itll be out in a jiffy
			'desc': 'External payload(s).', # doom 2016 remote det upgrade
			'effects': ['Grenades create a miniature explosion on hit', '-20% grenade impact damage'],
			'type': Enemy.EnemyType.WHEEL,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Concept by CampfireCollective\nImplementation by BurgerMinus"
		}
		
		Upgrades.upgrades['pyroclastic_flow'] = {
			'name': 'Pyroclastic Flow',
			'desc': 'Lava sold separately.',
			'effects': ['Grenades spawn tar when they explode', 'Grenade explosions ignite tar', 'Become immune to tar when drifting/dashing'],
			'type': Enemy.EnemyType.WHEEL,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['shaped_charges'],
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		if not Upgrades.upgrades['shaped_charges'].has('precludes'):
			Upgrades.upgrades['shaped_charges']['precludes'] = []
		Upgrades.upgrades['shaped_charges']['precludes'].append('pyroclastic_flow')

func install_aphid_upgrades(tier):
	
	if tier == 0:
		Upgrades.upgrades['underpressure'] = {
			'name': 'Underpressure',
			'desc': 'Better out than in.', # shrek?
			'effects': ['+50% tar deployment rate', '+50% tar pressure recharge rate'],
			'type': Enemy.EnemyType.FLAME,
			'tier': 0, 
			'max_stack': 3,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	elif tier == 1:
		Upgrades.upgrades['slipstream'] = {
			'name': 'Slipstream',
			'desc': 'No, not that Bernoulli.', 
			'effects': ['+75% movement speed on tar', '+50% tar lifetime'],
			'type': Enemy.EnemyType.FLAME,
			'tier': 1, 
			'max_stack': 2,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	else:
		Upgrades.upgrades['filtration_purge'] = {
			'name': 'Filtration Purge',
			'desc': 'Unholy hand(?) grenade.',
			'effects': ['Deploy a chargeable tar bomb that creates a spread of tar puddles'],
			'type': Enemy.EnemyType.FLAME,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Concept and Sprites by cheats_blamesman\nImplementation by BurgerMinus"
		}

func install_deadlift_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['point_defense'] = {
			'name': 'Point Defense',
			'desc': 'Bullseye.',
			'effects': ['Charged attacks deflect projectiles towards the cursor with greatly increased speed and damage', 'Punches can be charged up to 150% power', '+100% punch charge speed'],
			'type': Enemy.EnemyType.CHAIN,
			'tier': 1, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	else:
		Upgrades.upgrades['repurposed_scrap'] = {
			'name': 'Repurposed Scrap',
			'desc': 'Reduce, reuse, recycle.',
			'effects': ['Killed enemies will drop grappleable scrap'],
			'type': Enemy.EnemyType.CHAIN,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Concept by Gwonam\nImplementation by BurgerMinus"
		}

func install_collider_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['static_shock'] = {
			'name': 'Static Shock',
			'desc': 'First, maybe do a little harm.',
			'effects': ['Damage and stun enemies within your shield (+100% shock rate per stack)', 'Shock attack will sometimes break off and capture scrap'],
			'type': Enemy.EnemyType.SHIELD,
			'tier': 1, 
			'max_stack': 2,
			'ai_useable': true,
			'credits': "Concept and Icon by Lettuce\nImplementation by BurgerMinus"
		}
	else:
		Upgrades.upgrades['event_horizon'] = {
			'name': 'Event Horizon',
			'desc': 'Universal gravitation.',
			'effects': ['Tackles create a gravity well that pulls in enemies, absorbs lasers, and instantly captures projectiles', 'With Static Shock: 5x shock rate and shock stun duration while tackling'],
			'type': Enemy.EnemyType.SHIELD,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		
		Upgrades.upgrades['quasar_amplification'] = {
			'name': 'Quasar Amplification',
			'desc': 'Hyperluminous.',
			'effects': ['Instead of being fired, bullets are absorbed to charge up a Death Ray', 'Damage scales with orbital velocity', 'Death Ray cannot be canceled until it is out of charge'],
			'type': Enemy.EnemyType.SHIELD,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['beeftank_doctrine'],
			'ai_useable': false,
			'credits': "Upgrade by BurgerMinus"
		}
		if not Upgrades.upgrades['beeftank_doctrine'].has('precludes'):
			Upgrades.upgrades['beeftank_doctrine']['precludes'] = []
		Upgrades.upgrades['beeftank_doctrine']['precludes'].append('quasar_amplification')

func install_tachi_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['percussive_strike'] = {
			'name': 'Percussive Strike',
			'desc': 'Transitional ballistics.',
			'effects': ['Dislodging a sword with a saber or CWBIDBSC will break it into 3 shards (+2 per stack)'],
			'type': Enemy.EnemyType.SABER,
			'tier': 1, 
			'max_stack': 3,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
		
		Upgrades.upgrades['medium_maximization'] = {
			'name': 'Medium Maximization', # the propensity to pursue the means by which a desired outcome is achieved rather than the outcome itself
			'desc': 'The eight winds cannot move you.', # that one chinese guy
			'effects': ['Remain in KILL MODE until slashing or manually cancelling', 'Manually cancelling KILL MODE completely resets special cooldown'],
			'type': Enemy.EnemyType.SABER,
			'tier': 1, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	else:
		pass
	# havent figured out how to balance this in a satisfying way
	#Upgrades.upgrades['lightning_rod'] = {
	#	'name': 'Lightning Rod',
	#	'desc': '',
	#	'effects': ['Hitting an enemy with CWBIDBSC will spawn a delayed AOE lightning strike'],
	#	'type': Enemy.EnemyType.SABER,
	#	'tier': 2, 
	#	'max_stack': 1,
	#	'ai_useable': false,
	#	'credits': "Concept by CampfireCollective\nImplementation by BurgerMinus"
	#}

func install_thistle_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		pass
	else:
		Upgrades.upgrades['refresh_overclocking'] = {
			'name': 'Refresh Overclocking', 
			'desc': 'CBF activated.', # gd click between frames
			'effects': ['Fire up to 4 more suspended lasers during bomb boost', '+66% bomb boost duration'],
			'type': Enemy.EnemyType.ARCHER,
			'tier': 2, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Upgrade by BurgerMinus"
		}
	
	# lol imagine if there was more than one thistle upgrade haha imagine

func install_epitaph_upgrades(tier):
	
	if tier == 0:
		pass
	elif tier == 1:
		Upgrades.upgrades['big_stick'] = {
			'name': 'Big Stick',
			'desc': 'The best kind of diplomacy.', # teddy roosevelt
			'effects': ['+50% paddle size'],
			'type': Enemy.EnemyType.BAT,
			'tier': 1, 
			'max_stack': 1,
			'ai_useable': true,
			'credits': "Concept by Cooley\nImplementation by BurgerMinus"
		}
	else:
		Upgrades.upgrades['corium_infusion'] = {
			'name': 'Corium Infusion',
			'desc': 'Alternative swing.', # ultrakill alt shotgun joke
			'effects': ['Hitting a max-combo orb will fire it as an explosive laser'],
			'type': Enemy.EnemyType.BAT,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['helikon_berra_postulate'],
			'ai_useable': false,
			'credits': "Concept by Enneh\nImplementation by BurgerMinus"
		}
		
		Upgrades.upgrades['helikon_berra_postulate'] = {
			'name': 'Helikon-Berra Postulate', # yogi berra + helikon vortex separation process
			'desc': 'Contraversial [sic].', # contraverse holds
			'effects': ['Max-combo orbs will create a gravity vortex on impact/detonation'],
			'type': Enemy.EnemyType.BAT,
			'tier': 2, 
			'max_stack': 1,
			'precludes': ['corium_infusion'],
			'ai_useable': false,
			'credits': "Concept by Gwonam\nImplementation by BurgerMinus"
		}

func install_golem_upgrades():
	
	Upgrades.GOLEM_upgrades['mimesis'] = {
		'name': 'Mimesis',
		'desc': 'Loving memories / Persistent nightmares.',
		'effects': ['Post-swap residual control lasts 3x as long', 'Enemies permanently retain your upgrades when swapping out'],
		'max_stack': 1,
		'credits': "Concept by Gwonam\nImplementation by BurgerMinus"
	}
	
	Upgrades.GOLEM_upgrades['temerity'] = {
		'name': 'Temerity',
		'desc': 'Short/sweet.',
		'effects': ['Gain temporary invincibility upon swapping', 'Host health set to 1 when invincibility expires'],
		'max_stack': 1,
		'precludes': ['caution'],
		'credits': "Upgrade by BurgerMinus"
	}
	if not Upgrades.GOLEM_upgrades['caution'].has('precludes'):
		Upgrades.GOLEM_upgrades['caution']['precludes'] = []
	Upgrades.GOLEM_upgrades['caution']['precludes'].append('temerity')
	
	Upgrades.GOLEM_upgrades['bloodlust'] = {
		'name': 'Bloodlust',
		'desc': 'Hit/Miss the mark.',
		'effects': ['Instead of spending energy, drain 150% energy over time', 'Get a kill to cancel drain', 'Swapping while energy drain is active costs the normal amount'],
		'max_stack': 1,
		'credits': "Concept by cheats_blamesman\nImplementation by BurgerMinus"
	}
	
	Upgrades.GOLEM_upgrades['echopraxia'] = {
		'name': 'Echopraxia',
		'desc': 'Mimicry/Mockery.',
		'effects': ['Nearby enemies of the same host type will mirror your actions', 'Affected hosts can still damage you'],
		'max_stack': 1,
		'credits': "Concept by TheTimesweeper and CampfireCollective\nImplementation by BurgerMinus"
	}
	
	Upgrades.GOLEM_upgrades['desperation'] = {
		'name': 'Desperation',
		'desc': 'Last/First Stand.',
		'effects': ['MITE is invincible and will not drain global energy for 3 seconds upon ejection', '3x MITE global energy drain'],
		'max_stack': 1,
		'credits': "Concept by AquaTail\nImplementation by BurgerMinus"
	}

func handle_overwrites():
	
	# completely cosmetic change, allows event horizon effect to display properly
	var shield = load(mod_dir_path.path_join("Circle_234.png"))
	shield.take_over_path("res://Art/Shields/Circle_234.png")
	overwrites.append(shield)
	
	for upgrade in upgrade_names:
		var icon = load(mod_dir_path.path_join("icons/" + upgrade + ".png"))
		if icon == null:
			icon = load(mod_dir_path.path_join("icons/placeholder_icon.png"))
		icon.take_over_path("res://Art/Upgrades/" + upgrade + ".png")
		overwrites.append(icon)
	
	for golem_upgrade in golem_upgrade_names:
		var golem_icon = load(mod_dir_path.path_join("icons/" + golem_upgrade + ".png"))
		if golem_icon == null:
			golem_icon = load(mod_dir_path.path_join("icons/placeholder_icon_golem.png"))
		golem_icon.take_over_path("res://Art/Upgrades/" + golem_upgrade + ".png")
		overwrites.append(golem_icon)
