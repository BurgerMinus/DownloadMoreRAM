extends PhysicsActor

@onready var suction_particles = $GPUParticles2D

var strength := 100000
var falloff_power := 1.0

var affected_entities = []
var active := true
var lifetime := 5.0
var ignore_player = true

func _ready():
	immobile = true
	suction_particles.emitting = active
	suction_particles.modulate = Color(1, 0.8, 0.5, 1)

func _physics_process(delta):
	
	super(delta)
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	
	if active:
		for entity in affected_entities:
			if ignore_player and entity == GameManager.player.true_host: continue
			var dist = max(global_position.distance_to(entity.global_position), 15.0)
			var dir = (global_position - entity.global_position)/dist
			entity.velocity += strength*delta*dir/pow(dist, falloff_power)

func add_affected_entity(entity):
	affected_entities.append(entity)

func remove_affected_entity(entity):
	if entity in affected_entities:
		affected_entities.erase(entity)

func _on_attraction_area_entered(area):
	if area.is_in_group('hitbox'):
		var entity = area.get_parent()
		if entity is Enemy or entity is PhysicsActor and entity.elevation == elevation:
			add_affected_entity(entity)
			
	elif area is PhysicsProjectile:
		add_affected_entity(area)

func _on_attraction_area_exited(area):
	if area.is_in_group('hitbox'):
		var entity = area.get_parent()
		remove_affected_entity(entity)
			
	elif area is PhysicsProjectile:
		remove_affected_entity(area)
