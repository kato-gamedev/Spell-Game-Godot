extends Character
class_name Player

# Debug
var draw_debug_movement = false

# Customize
@export var JUMP_VELOCITY: float = 4.5
@export var LOCOMOTION_BLENDSPACE_RATE: float = 0.3 # From 0.0 - 1.0
@export var AIMING_BLENDSPACE_RATE: float = 0.1 # From 0.0 - 1.0
@export var CAMERA_ZOOM_SPEED: float = 0.5

# Movement
var current_move_speed := 6.0
@export var DEFAULT_MOVE_SPEED := 6.0
@export var AIM_MOVE_SPEED := 3.0
@export var LERP_VALUE := 0.15

# Camera
const CAMERA_CONTROLLER_ROTATION_SPEED: float = 3.0
const CAMERA_MOUSE_ROTATION_SPEED: float = 0.001
# A minimum angle lower than or equal to -90 breaks movement if the player is looking upward.
const CAMERA_X_ROT_MIN: float = deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX: float = deg_to_rad(70.0)

# Skill system
@export var ability_1: GameplayAbility
@export var ability_2: GameplayAbility
@export var ability_3: GameplayAbility

# Camera
@onready var camera_base: Node3D = %CameraBase
@onready var camera_rot: Node3D = $CameraBase/CameraRot
@onready var _camera := %Camera3D as Camera3D
@onready var camera_animation: AnimationPlayer = $CameraBase/CameraAnimation
@export_range(0.0, 1.0) var mouse_sensitivity = 0.003
@export var tilt_limit = deg_to_rad(75)
var is_flying: bool = false
var is_aiming = false
var is_moving = false
var use_hold_to_aim = false

@onready var player_model: Node3D = $PlayerModel

# Internal
@onready var collision_shape_3d: CollisionShape3D = $Collision
@onready var debug_text: Label = $DebugText
@onready var interactor: Interactor = %Interactor
@onready var projectile_cast: RayCast3D = $CameraBase/CameraRot/SpringArm3D/Camera3D/ProjectileCast
@onready var health_bar_2d: ProgressBar = $HealthBar2D

# See through ray trace
@export var transparent_mat: StandardMaterial3D
@export var see_through_material_overlay: Material
var hidden_objects: Array[Node3D]

# Inventory system
var current_interactable: Node3D

# Weapon system
@onready var current_weapon: Gun1 = $PlayerModel/Skeleton/BoneAttachment3D/Gun1

# Recoil System
@export var RECOIL_SNAP: float = 15.0   # How fast the camera kicks from the shot
var target_recoil: Vector2 = Vector2.ZERO
var current_recoil_offset: Vector2 = Vector2.ZERO

# Spell system
@onready var magic_staff: MagicStaff = $MagicStaff

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	pass

var camera_target_rotation: Vector3
func _physics_process(delta: float) -> void:
	super(delta)
	clear_debug_lines()
	
	add_debug_line("Range: %d - %d" % [magic_staff.current_spell_range.x, magic_staff.current_spell_range.y])
	add_debug_line("State: ", magic_staff.StaffState.find_key(magic_staff.staff_state))
	
	# Smooth recoil, UNR
	var previous_recoil = current_recoil_offset
	current_recoil_offset = current_recoil_offset.lerp(target_recoil, RECOIL_SNAP * delta)
	var recoil_difference = current_recoil_offset - previous_recoil
	if recoil_difference.length() > 0.0001:
		rotate_camera(recoil_difference)
	
	if (interactor.current_interactable):
		add_debug_line("Interactable: ", interactor.current_interactable.name)
	else:
		add_debug_line("Interactable: None")
	
	# MOVE THE CHARACTER TO INPUT
	# Get the input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Calculate direction relative to the camera's rotation
	var forward := -camera_base.global_transform.basis.z
	var right := -camera_base.global_transform.basis.x
	# Keep movement on the XZ plane
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction = (forward * input_dir.y + right * input_dir.x).normalized()
	if draw_debug_movement:
		Debug.draw_cylinder(global_position+Vector3(0,0.1,0), global_position+direction+Vector3(0,0.1,0), 0.02, Color.LIME, 0.04)
	
	if direction:
		# Smooth movement interpolation
		velocity.x = lerp(velocity.x, direction.x * current_move_speed, LERP_VALUE)
		velocity.z = lerp(velocity.z, direction.z * current_move_speed, LERP_VALUE)
	
	else:
		# Decelerate
		velocity.x = move_toward(velocity.x, 0, DEFAULT_MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0, DEFAULT_MOVE_SPEED)
	
	# ROTATE CHARACTER TO INPUT DIRECTION OR TO AIMING DIRECTION
	if (input_dir != Vector2.ZERO):
		if not is_aiming:
			# Rotate character to face movement direction
			var current_quat = player_model.global_transform.basis.get_rotation_quaternion()
			var target_quat = Basis.looking_at(direction, Vector3(0,1,0), true).get_rotation_quaternion()
			var result_quat = current_quat.slerp(target_quat, 0.075)
			player_model.global_rotation = result_quat.get_euler()
			var quat_debug_point = player_model.global_position + result_quat * Vector3.MODEL_FRONT + Vector3(0,0.1,0)
			if draw_debug_movement:
				Debug.draw_cylinder(player_model.global_position+Vector3(0,0.1,0), quat_debug_point, 0.02, Color.RED, 0.04)
			#player_model.look_at(target_look_at, Vector3.UP, true)
	if is_aiming:
		var cam_forward: Vector3 = -_camera.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		if cam_forward.length() > 0.001:
			var current_quat = player_model.global_transform.basis.get_rotation_quaternion()
			var target_quat = Basis.looking_at(cam_forward, Vector3.UP, true).get_rotation_quaternion()
			var result_quat = current_quat.slerp(target_quat, 0.075)
			player_model.global_transform.basis = Basis(result_quat)

			var debug_dir = result_quat * Vector3.MODEL_FRONT 
			var quat_debug_point = player_model.global_position + debug_dir + Vector3(0, 0.1, 0)
			if draw_debug_movement:
				Debug.draw_cylinder(player_model.global_position + Vector3(0, 0.1, 0), quat_debug_point, 0.02, Color.RED, 0.04)
	
	#var forward_debug_point = player_model.global_position + player_model.global_basis.z.normalized()
	#Debug.draw_cylinder(player_model.global_position+Vector3(0,0.1,0), forward_debug_point+Vector3(0,0.1,0), 0.02, Color.PURPLE, 0.04)
	move_and_slide()
	
	# CHOOSE LOCOMOTION ANIMATION
	if not is_aiming:
		var current_blend_position: float = animation_tree["parameters/StateMachine/Locomotion/blend_position"]
		var target_blend_position := 1.0
		if Vector2(velocity.x, velocity.z).length() > 0.0:
			target_blend_position = 1.0
		else:
			target_blend_position = 0.0
		animation_tree["parameters/StateMachine/Locomotion/blend_position"] = lerpf(current_blend_position, target_blend_position, LOCOMOTION_BLENDSPACE_RATE)
	elif is_aiming:
		var current_blend_position: Vector2 = animation_tree["parameters/StateMachine/RifleAiming/blend_position"]
		var target_blend_position := input_dir.normalized()
		animation_tree["parameters/StateMachine/RifleAiming/blend_position"] = lerp(current_blend_position, target_blend_position, AIMING_BLENDSPACE_RATE)
	
	# Aiming input and camera
	var playback: AnimationNodeStateMachinePlayback = animation_tree["parameters/StateMachine/playback"]
	if use_hold_to_aim:
		if Input.is_action_just_pressed("aim"):
			is_aiming = true
			current_move_speed = AIM_MOVE_SPEED
			camera_animation.play("zoom_in")
			playback.travel("RifleAiming")
		if Input.is_action_just_released("aim"):
			is_aiming = false
			current_move_speed = DEFAULT_MOVE_SPEED
			camera_animation.play("zoom_out")
			playback.travel("Locomotion")
	elif not use_hold_to_aim:
		if Input.is_action_just_pressed("aim"):
			is_aiming = not is_aiming
			if is_aiming:
				current_move_speed = AIM_MOVE_SPEED
				camera_animation.play("zoom_in")
				playback.travel("RifleAiming")
			else:
				current_move_speed = DEFAULT_MOVE_SPEED
				camera_animation.play("zoom_out")
				playback.travel("Locomotion")
			
	if Input.is_action_pressed("shoot"):
		if is_aiming:
			current_weapon.fire(get_aiming_location())
	
	if Input.is_action_pressed("skill_1"):
		#HolyAbilityActivator.activate_ability(self, ability_1)
		magic_staff.cast(get_caster_context())
	
func get_caster_context() -> CasterContext:
	var context: CasterContext = CasterContext.new(
		magic_staff,
		 self,
		 get_aiming_location(),
		 player_model.global_position + Vector3(0, 0.5, 0)
		)
	return context

func get_aiming_location() -> Vector3:
	# Return where the ray hit
	if projectile_cast.is_colliding():
		return projectile_cast.get_collision_point()
	# Returns a point 1km forward
	else:
		return _camera.global_position - (_camera.global_basis.z * 1000.0)

func clear_debug_lines():
	if debug_text:
		debug_text.text = ""

func add_debug_line(title: String, content: Variant = null) -> void:
	# Format line depending on whether content exists
	var line_prefix: String = title + ": " if content != null else title
	var new_line: String = line_prefix + str(content) if content != null else title
	
	var lines: PackedStringArray = debug_text.text.split("\n", false)
	var found: bool = false
	
	# Update line if it already exists
	for i in range(lines.size()):
		if lines[i].begins_with(line_prefix):
			lines[i] = new_line
			found = true
			break
	
	# Add as new line and update UI
	if not found:
		lines.append(new_line)
	debug_text.text = "\n".join(lines)

func find_interactable():
	pass

# Return top parent if have any, or return child if child is already the top parent
func get_top_parent(child:Node3D) -> Node3D:
	# Get owner if not directly placed into the current scene
	var top_parent = child.owner
	if top_parent && top_parent != get_tree().current_scene:
		return top_parent
	else:
		return child
	
func get_mesh_from_object(object:Node3D) -> MeshInstance3D:
	if object is MeshInstance3D:
		return object
	var meshes = object.find_children("*", "MeshInstance3D", true, false)
	if not meshes.is_empty():
		return meshes[0]
	return null

func get_aiming_enemy() -> Character:
	return null

func apply_gun_recoil(current_recoil: Vector2) -> void:
	var recoil_yaw := -current_recoil.x
	var recoil_pitch := -current_recoil.y
	target_recoil += Vector2(recoil_yaw, recoil_pitch)

func _on_ability_system_component_health_changed(old_health: float, new_health: float, old_max_health: float, new_max_health: float) -> void:
	$HealthBar2D.set_value(new_health / new_max_health * 100)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera_speed_this_frame = CAMERA_MOUSE_ROTATION_SPEED
		if is_aiming:
			camera_speed_this_frame *= 0.75
		rotate_camera(event.screen_relative * camera_speed_this_frame)
		
	if event.is_action_pressed("interact"):
		if (current_interactable):
			#print(current_interactable.name)
			# has_method is used in _physics_process
			current_interactable.interact(self)
		#else:
			#print("No interactable")
	if event.is_action_released("skill_2"):
		if ability_2:
			ability_2.activate_ability(self)
	if event.is_action_released("skill_3"):
		if ability_3:
			ability_3.activate_ability(self)
	pass
	
func rotate_camera(move: Vector2) -> void:
	camera_base.rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	camera_base.orthonormalize()
	camera_rot.rotation.x = clampf(camera_rot.rotation.x + move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
