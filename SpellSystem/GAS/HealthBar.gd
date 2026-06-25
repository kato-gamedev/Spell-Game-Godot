extends Node3D
class_name HealthBar

@onready var progress_bar_health: ProgressBar = $"SubViewport/VBoxContainer/ProgressBar - Health"

func set_value(value: float):
	progress_bar_health.value = value
