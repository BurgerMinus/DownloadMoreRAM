extends "res://Scripts/Hosts/ChainBot/Grapple.gd"

func _physics_process(delta):
	super(delta)
	if state == ANCHORED and is_instance_valid(anchor_entity) and 'is_currently_grappled' in anchor_entity:
		anchor_entity.is_currently_grappled = true

func deactivate():
	if is_instance_valid(anchor_entity) and 'is_currently_grappled' in anchor_entity:
		anchor_entity.is_currently_grappled = false
	super()

func retract(enable_hook = true):
	if is_instance_valid(anchor_entity) and 'is_currently_grappled' in anchor_entity:
		anchor_entity.is_currently_grappled = false
	super(enable_hook)
