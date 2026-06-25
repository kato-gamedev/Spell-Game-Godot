extends Node3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	gpu_particles_3d.emitting = true
	await gpu_particles_3d.finished
	
	queue_free()
