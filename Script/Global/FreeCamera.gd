extends Node

# Configuration
const MOVE_SPEED = 10.0
const MOUSE_SENSITIVITY = 0.002
const TOGGLE_KEY = KEY_F10

var is_active = false
var free_cam: Camera3D = null
var saved_camera: Camera3D = null
var look_angles = Vector2.ZERO

func _ready():
	# This is the "magic" line that allows this script to run while paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY:
		toggle_free_cam()
		return

	if is_active:
		if event is InputEventMouseMotion:
			look_angles.y -= event.relative.x * MOUSE_SENSITIVITY
			look_angles.x -= event.relative.y * MOUSE_SENSITIVITY
			look_angles.x = clamp(look_angles.x, -PI/2, PI/2)
			
			free_cam.quaternion = Quaternion.from_euler(Vector3(look_angles.x, look_angles.y, 0))
			
		get_viewport().set_input_as_handled()

func _process(delta):
	if not is_active:
		return

	var move_vec = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): move_vec += -free_cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): move_vec += free_cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_A): move_vec += -free_cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): move_vec += free_cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_E): move_vec += Vector3.UP
	if Input.is_key_pressed(KEY_Q): move_vec += Vector3.DOWN

	# We use delta here to ensure smooth movement regardless of framerate
	free_cam.global_position += move_vec.normalized() * MOVE_SPEED * delta

func toggle_free_cam():
	is_active = !is_active
	
	if is_active:
		activate_free_cam()
	else:
		deactivate_free_cam()

func activate_free_cam():
	saved_camera = get_viewport().get_camera_3d()
	
	free_cam = Camera3D.new()
	# We must set the camera's process mode to Always too, 
	# otherwise it won't update its internal matrices while paused
	free_cam.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(free_cam)
	
	if saved_camera:
		free_cam.global_transform = saved_camera.global_transform
		look_angles.y = free_cam.rotation.y
		look_angles.x = free_cam.rotation.x
	
	free_cam.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# --- PAUSE THE GAME ---
	get_tree().paused = true

func deactivate_free_cam():
	if saved_camera and is_instance_valid(saved_camera):
		saved_camera.make_current()
	
	if free_cam:
		free_cam.queue_free()
		free_cam = null
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# --- UNPAUSE THE GAME ---
	get_tree().paused = false
