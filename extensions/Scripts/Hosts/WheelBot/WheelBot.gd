extends "res://Scripts/Hosts/WheelBot/WheelBot.gd"

var molotov_grenades = false
var invincible_grenades = false
var impact_grenades = false

var dodge_regen = false
var recent_attacks = {}

func toggle_enhancement(state):
	
	molotov_grenades = false
	invincible_grenades = false
	dodge_regen = false
	recent_attacks.clear()
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	molotov_grenades = upgrades_to_apply['pyroclastic_flow'] > 0
	impact_grenades = upgrades_to_apply['flash_flame'] > 0
	invincible_grenades = upgrades_to_apply['phase_shift'] > 0
	dodge_regen = upgrades_to_apply['total_recall'] > 0
	if dodge_regen:
		max_special_cooldown *= 0.2

func begin_charging_dash():
	super()
	if molotov_grenades:
		ignore_tar = true

func misc_update(delta):
	super(delta)
	if not charging_dash and invincibility_timer <= 0.0:
		ignore_tar = false

func update_timers(delta):
	super(delta)
	for key in recent_attacks.keys():
		recent_attacks[key][1] -= delta
		if recent_attacks[key][1] < 0.0:
			recent_attacks.erase(key)

func on_attack_dodged(attack):
	# i dont actually care about the attack lol but i might as well include it here
	if dodge_regen:
		for key in recent_attacks.keys():
			health = min(max_health, health + recent_attacks[key][0])
		recent_attacks.clear()

func can_be_hit(_attack):
	return super(_attack) or (not (invincible or dead or always_invincible_override))

func take_damage(attack):
	super(attack)
	if dodge_regen:
		recent_attacks[str(attack)] = [attack.damage, 1.0]
