extends CharacterBody3D

@onready var health_component: HealthBar = $HealthComponent
@onready var enemy_stat: EnemyStat = $EnemyStat
const DAMAGE_LABEL = preload("uid://bsbm8o2n444vy")

func _ready() -> void:
	health_component.set_value(enemy_stat.health / enemy_stat.max_health * 100)

func _process(delta: float) -> void:
	pass

func _on_enemy_stat_health_changed(old_health: float, new_health: float, old_max_health: float, new_max_health: float) -> void:
	health_component.set_value(new_health / new_max_health * 100)
	if new_health - old_health < 0.0:
		var damage_label: DamageLabel = DAMAGE_LABEL.instantiate()
		get_tree().current_scene.add_child(damage_label)
		damage_label.initialize(int(old_health - new_health))
		damage_label.global_position = global_position + Vector3(0, 1, 0)
	
