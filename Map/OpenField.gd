extends Node3D
class_name OpenField

@export_category("Spawner Settings")
## The enemy scene you want to spawn
@export var enemy_scene: PackedScene 
## How many seconds between each spawn
@export var spawn_interval: float = 1.5 
## The maximum number of enemies allowed at once
@export var max_enemies: int = 50 

# Internal
var initial_difficulty: float = 2.0 

@export_category("Spawn Area")
## The closest an enemy can spawn to the center
@export var min_radius: float = 1.0 
## The furthest an enemy can spawn from the center
@export var max_radius: float = 2.0 

var enemy_timer: float = 0.0

@onready var time_text: Label = $Time
var time_since_begin: float = 0.0


func _process(delta: float) -> void:
	time_since_begin += delta
	var minutes: int = int(time_since_begin / 60) 
	var seconds: int = int(time_since_begin) % 60
	time_text.text = "%02d:%02d" % [minutes, seconds]
	
	# Don't do anything if we haven't assigned an enemy scene in the inspector
	if enemy_scene == null:
		return
		
	# Count down/up the timer
	enemy_timer += delta
	if enemy_timer >= spawn_interval:
		enemy_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemy_spawner").is_empty():
		return
	# Check if we have reached the maximum number of enemies
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	if current_enemies >= max_enemies:
		return
		
	var enemy: Enemy = enemy_scene.instantiate()
	
	# 3. Calculate a random circular position around the spawner
	var random_angle = randf() * PI * 2 # Random angle in a full circle
	var random_distance = randf_range(min_radius, max_radius)
	
	var random_offset = Vector3(
		cos(random_angle) * random_distance,
		0.0, # Keep Y at 0 so they spawn on the floor
		sin(random_angle) * random_distance
	)
	
	var enemy_spawner: Node3D = get_tree().get_nodes_in_group("enemy_spawner").pick_random()
	if not enemy_spawner:
		return
	
	enemy.global_position = enemy_spawner.global_position + random_offset
	enemy.add_to_group("enemy")
	
	# 6. Add the enemy to the main game scene
	get_tree().current_scene.add_child(enemy)
	var difficulty = initial_difficulty + int(time_since_begin / 30) * 0.5
	enemy.initialize(difficulty)
