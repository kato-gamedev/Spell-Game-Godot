extends CharacterBody3D

@export var MAX_FORWARD_SPEED: float = 60.0
@export var MAX_UP_SPEED: float = 15.0
@export var ACCELERATION: float = 3.0
@export var ROTATION_SPEED: float = 1.2
@export var ROLL_AMOUNT: float = 0.4
@export var PITCH_AMOUNT: float = 0.15
@export var MESH_SMOOTHING: float = 4.0

var is_driving: bool = false
var player_ref: Node3D = null

var target_velocity: Vector3 = Vector3.ZERO
var current_pitch: float = 0.0
var current_roll: float = 0.0

@onready var car_mesh: Node3D = $CarMesh
@onready var car_camera: Camera3D = $SpringArm3D/Camera3D
@onready var exit_point: Marker3D = $ExitPoint

func _physics_process(delta: float) -> void:
	if not is_driving:
		# Apply gravity when nobody is driving so it lands smoothly
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		else:
			# Add friction to slide to a stop when unpiloted
			velocity = velocity.lerp(Vector3.ZERO, ACCELERATION * delta)
		move_and_slide()
		return
		
	# Input handling (Assume custom input actions exist)
	var forward_input: float = Input.get_axis("move_forward", "move_backward")
	var turn_input: float = Input.get_axis("move_right", "move_left")
	var vertical_input: float = Input.get_axis("fly_down", "fly_up")
	
	# Calculate direction based on the car's current rotation
	var local_forward: Vector3 = -transform.basis.z
	
	# Build the target velocity
	target_velocity = (local_forward * forward_input * MAX_FORWARD_SPEED)
	target_velocity.y = vertical_input * MAX_UP_SPEED
	
	# Smoothly interpolate current velocity to target velocity (creates the heavy Blade Runner feel)
	velocity = velocity.lerp(target_velocity, ACCELERATION * delta)
	
	# Yaw rotation (turning the actual physics body)
	rotate_y(turn_input * ROTATION_SPEED * delta)
	
	# Visual Banking (Pitch and Roll)
	# We tilt the mesh forward/backward based on acceleration, and roll side-to-side when turning
	var target_pitch: float = forward_input * PITCH_AMOUNT
	var target_roll: float = turn_input * ROLL_AMOUNT
	
	current_pitch = lerp(current_pitch, target_pitch, MESH_SMOOTHING * delta)
	current_roll = lerp(current_roll, target_roll, MESH_SMOOTHING * delta)
	
	car_mesh.rotation.x = current_pitch
	car_mesh.rotation.z = current_roll
	
	move_and_slide()
	
	# Listen for exit input
	if Input.is_action_just_pressed("interact"):
		exit_car()

func exit_car() -> void:
	if not is_driving or player_ref == null:
		return
		
	# Move the player to the exit point outside the car
	player_ref.global_position = exit_point.global_position
	
	# Re-enable the player
	player_ref.process_mode = Node.PROCESS_MODE_INHERIT
	player_ref.visible = true
	
	# Find the player's camera and make it active again
	# Adjust this path based on your actual player scene hierarchy!
	var player_cam: Camera3D = player_ref.get_node("SpringArm3D/Camera3D")
	if player_cam:
		player_cam.make_current()
		
	is_driving = false
	player_ref = null


func _on_interactable_interacted(interactor: Node) -> void:
	if is_driving:
		return
		
	player_ref = interactor
	
	# Disable the player completely and hide them
	player_ref.process_mode = Node.PROCESS_MODE_DISABLED
	player_ref.visible = false
	
	# Switch to the car's third person camera
	car_camera.make_current()
	is_driving = true
