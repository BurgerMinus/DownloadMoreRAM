extends "res://Scripts/Hosts/ShieldBot/ShieldBot.gd"

var gravity_tackle = false

func toggle_enhancement(state):
	gravity_tackle = false
	super(state)
	gravity_tackle = get_currently_applicable_upgrades()['event_horizon'] > 0

func start_tackle():
	super()
	if gravity_tackle:
		set_shield_width(2*PI)
		set_shield_color(Vector3(0.33, 0, 0.5))
		set_shield_active(true)

func end_tackle():
	super()
	if gravity_tackle:
		update_overburden_penalties() # reset shield width and color

func update_overburden_penalties():
	if not (gravity_tackle and tackling): # do not override event horizon shield effects
		super()

func _on_shield_area_entered(area):
	super(area)
	if tackling and gravity_tackle and area is Projectile:
		on_projectile_tackled(area)
