extends Node3D
class_name EnemySpawner

@export_category("Spawner Settings")
## The enemy scene you want to spawn
@export var enemy_scene: PackedScene 
## How many seconds between each spawn
@export var spawn_interval: float = 1.5 
## The maximum number of enemies allowed at once
@export var max_enemies: int = 50 

@export_category("Spawn Area")
## The closest an enemy can spawn to the center
@export var min_radius: float = 1.0 
## The furthest an enemy can spawn from the center
@export var max_radius: float = 2.0 

var _timer: float = 0.0

func _process(delta: float) -> void:
	# Don't do anything if we haven't assigned an enemy scene in the inspector
	if enemy_scene == null:
		return
		
	# Count down/up the timer
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	# 1. Check if we have reached the maximum number of enemies
	# (This prevents your game from lagging/crashing)
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	if current_enemies >= max_enemies:
		return
		
	# 2. Create a new instance of the enemy
	var enemy = enemy_scene.instantiate()
	
	# 3. Calculate a random circular position around the spawner
	var random_angle = randf() * PI * 2 # Random angle in a full circle
	var random_distance = randf_range(min_radius, max_radius)
	
	var random_offset = Vector3(
		cos(random_angle) * random_distance,
		0.0, # Keep Y at 0 so they spawn on the floor
		sin(random_angle) * random_distance
	)
	
	# 4. Set the enemy's position
	enemy.global_position = global_position + random_offset
	
	# 5. Add it to the "enemy" group so our max_enemies check works
	enemy.add_to_group("enemy")
	
	# 6. Add the enemy to the main game scene
	get_tree().current_scene.add_child(enemy)
