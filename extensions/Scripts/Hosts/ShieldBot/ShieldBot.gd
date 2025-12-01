extends "res://Scripts/Hosts/ShieldBot/ShieldBot.gd"

var gravity_tackle = false
var base_base_shield_enemy_repulsion = 1500
var GRAVITY_STRENGTH = 3.0

var static_shock = 0
var shield_attack_cooldown = 0.25
var shield_attack_timer = 0.0

func toggle_enhancement(state):
	
	gravity_tackle = false
	base_base_shield_enemy_repulsion = 1500
	static_shock = 0
	
	super(state)
	
	var upgrades_to_apply = get_currently_applicable_upgrades()
	
	gravity_tackle = upgrades_to_apply['event_horizon'] > 0
	base_base_shield_enemy_repulsion = base_shield_enemy_repulsion
	static_shock = upgrades_to_apply['static_shock']
	

func apply_shield_effects(delta):
	super(delta)
	
	shield_attack_timer -= delta*static_shock
	if shield_attack_timer < 0.0:
		inflict_shield_attack()
		shield_attack_timer = shield_attack_cooldown

func inflict_shield_attack():
	var shield_attack = Attack.new(self, 2.5)
	shield_attack.stun = 0.1
	for e in nearby_enemies:
		if not is_in_shield_AOE(e.global_position) or (e.was_recently_player() == was_recently_player()): continue
		shield_attack.inflict_on(e)

func start_tackle():
	super()
	if gravity_tackle:
		shield_attack_cooldown = 0.05
		invincible = true
		base_shield_enemy_repulsion = -base_base_shield_enemy_repulsion * GRAVITY_STRENGTH
		set_shield_width(2*PI)
		set_shield_color(Vector3(0.33, 0, 0.5))
		set_shield_active(true)

func end_tackle():
	super()
	if gravity_tackle:
		shield_attack_cooldown = 0.25
		invincible = false
		base_shield_enemy_repulsion = base_base_shield_enemy_repulsion
		update_overburden_penalties() # reset shield width and color

func update_overburden_penalties():
	if not (gravity_tackle and tackling): # do not override event horizon shield effects
		super()

func _on_shield_area_entered(area):
	super(area)
	if tackling and gravity_tackle and area is Projectile:
		on_projectile_tackled(area)
