extends "res://Scripts/Hosts/ShieldBot/ShieldBot.gd"

var gravity_tackle = false
var base_base_shield_enemy_repulsion = 1500
var GRAVITY_STRENGTH = 3.0

func toggle_enhancement(state):
	gravity_tackle = false
	base_base_shield_enemy_repulsion = 1500
	super(state)
	gravity_tackle = get_currently_applicable_upgrades()['event_horizon'] > 0
	base_base_shield_enemy_repulsion = base_shield_enemy_repulsion

func start_tackle():
	super()
	if gravity_tackle:
		invincible = true
		base_shield_enemy_repulsion = -base_base_shield_enemy_repulsion * GRAVITY_STRENGTH
		set_shield_width(2*PI)
		set_shield_color(Vector3(0.33, 0, 0.5))
		set_shield_active(true)

func end_tackle():
	super()
	if gravity_tackle:
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
