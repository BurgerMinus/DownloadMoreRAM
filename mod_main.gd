extends Node

const MOD_DIR := "BurgerMinus-DownloadMoreRAM"

var mod_dir_path := ""
const upgrade_names = ['point_defense', 'static_shock', 'quasar_amplification', 'event_horizon', 'refresh_overclocking']
var overwrites = []

func _init() -> void:
	
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	
	Upgrades.upgrades['point_defense'] = {
		'name': 'Point Defense',
		'desc': 'Bullseye.',
		'effects': ['Deflect projectiles towards the cursor with increased speed and damage', 'Overcharge punches up to 150%', '+100% punch charge speed'],
		'type': Enemy.EnemyType.CHAIN,
		'tier': 1, 
		'max_stack': 1,
		'ai_useable': true,
		'credits': "Upgrade by BurgerMinus"
	}
	
	Upgrades.upgrades['static_shock'] = {
		'name': 'Static Shock',
		'desc': 'First, maybe do a little harm.',
		'effects': ['Damage and stun enemies within your shield (+100% shock rate per stack)'],
		'type': Enemy.EnemyType.SHIELD,
		'tier': 1, 
		'max_stack': 2,
		'ai_useable': true,
		'credits': "Concept and Icon by Lettuce\nImplementation by BurgerMinus"
	}
	
	Upgrades.upgrades['event_horizon'] = {
		'name': 'Event Horizon',
		'desc': 'Universal gravitation.',
		'effects': ['Tackles create a gravity well that pulls in enemies, absorbs lasers (boosting the damage of all collected projectiles), and instantly captures projectiles', 'With Static Shock: 5x shock rate and shock stun duration while tackling'],
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
	
	Upgrades.upgrades['refresh_overclocking'] = {
		'name': 'Refresh Overclocking',
		'desc': 'CBF activated.',
		'effects': ['Fire up to 4 more suspended lasers during bomb boost', '+66% bomb boost duration'],
		'type': Enemy.EnemyType.ARCHER,
		'tier': 2, 
		'max_stack': 1,
		'ai_useable': true,
		'credits': "Upgrade by BurgerMinus"
	}
	
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/ShieldBot/ShieldBot.gd"))
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Hosts/ArcherBot/ArcherBot.gd"))
	
	ModLoaderMod.install_script_hooks("res://Scripts/Hosts/ChainBot/ChainBot.gd", mod_dir_path.path_join("extensions/Scripts/Hosts/ChainBot/ChainBot.hooks.gd"))
	
	ModLoaderMod.install_script_extension(mod_dir_path.path_join("extensions/Scripts/Menus/DiagnosticsMenu.gd"))
	
	# completely cosmetic change, allows event horizon effect to display properly
	var shield = load(mod_dir_path.path_join("Circle_234.png"))
	shield.take_over_path("res://Art/Shields/Circle_234.png")
	overwrites.append(shield)
	
	for upgrade in upgrade_names:
		var icon = load(mod_dir_path.path_join("icons/" + upgrade + ".png"))
		icon.take_over_path("res://Art/Upgrades/" + upgrade + ".png")
		overwrites.append(icon)
	

