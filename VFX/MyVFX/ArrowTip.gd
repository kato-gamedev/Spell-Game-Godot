extends PathFollow3D

@export var MOVE_SPEED: float = 10.0
@export var PARTICLE_SPACING: float = 0.05
@export var JITTER_AMOUNT: float = 0.05
@export var TRAIL_SPEED: float = 0.0

@onready var particles: GPUParticles3D = $GPUParticles3D
var _last_particle_pos: Vector3

func _ready() -> void:
	particles.emitting = false
	_last_particle_pos = global_position

func _process(delta: float) -> void:
	progress += MOVE_SPEED * delta
	_emit_trail_particles()

func _emit_trail_particles() -> void:
	var current_pos: Vector3 = global_position
	var distance_to_last: float = _last_particle_pos.distance_to(current_pos)
	# Prevent division by zero and infinite loops
	if distance_to_last < PARTICLE_SPACING or PARTICLE_SPACING <= 0.0:
		return
		
	var direction: Vector3 = _last_particle_pos.direction_to(current_pos)
	# Use the node's actual transform Z-axis (+Z is backward in Godot)
	var backward_velocity: Vector3 = -global_basis.z.normalized() * TRAIL_SPEED
	
	# Step forward exactly by spacing, leaving remainder in _last_particle_pos
	while distance_to_last >= PARTICLE_SPACING:
		_last_particle_pos += direction * PARTICLE_SPACING
		distance_to_last -= PARTICLE_SPACING
		
		var random_offset := Vector3(
			randf_range(-JITTER_AMOUNT, JITTER_AMOUNT),
			randf_range(-JITTER_AMOUNT, JITTER_AMOUNT),
			randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)
		)
		var xform := Transform3D(Basis(), _last_particle_pos + random_offset)
		particles.emit_particle(xform, Vector3.ZERO, Color.WHITE, Color.WHITE, 0)
