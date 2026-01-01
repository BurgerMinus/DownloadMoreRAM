extends "res://Scripts/GameObjects/BoulderActor.gd"

var is_currently_grappled = false
var lifetime = 5.0
var enemy_type = Enemy.EnemyType.UNKNOWN

var recolors = {
	Enemy.EnemyType.UNKNOWN: 
		Color.WHITE,
	Enemy.EnemyType.BOSS1:
		Color.DARK_SLATE_GRAY,
	Enemy.EnemyType.BOSS2:
		Color.WEB_GRAY,
	Enemy.EnemyType.SPIDER:
		Color.WHITE,
	Enemy.EnemyType.SHOTGUN:
		Color.REBECCA_PURPLE,
	Enemy.EnemyType.WHEEL:
		Color.DARK_BLUE,
	Enemy.EnemyType.FLAME:
		Color.DARK_GREEN,
	Enemy.EnemyType.CHAIN:
		Color.RED,
	Enemy.EnemyType.SHIELD:
		Color.SILVER,
	Enemy.EnemyType.SABER:
		Color.WEB_GRAY,
	Enemy.EnemyType.ARCHER:
		Color.DARK_RED,
	Enemy.EnemyType.BAT:
		Color.GOLDENROD
}

func _ready():
#	rubble_paths = [rubble_paths[0]]
	super()

func _physics_process(delta):
	
	super(delta)
	
	if is_currently_grappled:
		lifetime = max(lifetime, 1.0)
	else:
		lifetime -= delta
	
	if lifetime < 0.0:
		die(null)

func take_damage(attack):
	attack.damage *= 0.5
	super(attack)

func set_type(type):
	enemy_type = type
	if not is_instance_valid(sprite):
		sprite = $Sprite
#	sprite.modulate = recolors[enemy_type].lightened(0.2)
