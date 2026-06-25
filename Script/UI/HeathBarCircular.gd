extends Control

class_name HealthBarCircular

@onready var texture_progress_bar_health: TextureProgressBar = $"TextureProgressBar - Health"
@onready var texture_progress_bar_mana: TextureProgressBar = $"TextureProgressBar - Mana"

func set_value(value: float):
	texture_progress_bar_health.value = value
