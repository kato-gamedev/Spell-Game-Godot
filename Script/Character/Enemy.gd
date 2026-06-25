extends CharacterBody3D
class_name Enemy

const EXP_DROP = preload("uid://blqp17yr620x4")

@onready var STAT: EnemyStat = $EnemyStat
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var damage_area: Area3D = $DamageArea
@onready var label_3d: Label3D = $Label3D

# Behavior tree ref
var player: Player
# Navigation
var nav_cheese: Vector3

# --- NEW DAMAGE VARIABLES ---
@export var damage_amount: float = 10.0
@export var attack_cooldown: float = 0.5 # Wait 0.5 seconds between hits
var current_attack_timer: float = 0.0

# Movement
@export var TURN_SPEED: float = 5.0 # Max rotation speed in radians per second

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Enemy couldn't find the player!")

func initialize(difficulty: float):
	STAT.initialize(difficulty)
	label_3d.text = "%.2f" % difficulty

func _physics_process(delta: float) -> void:
	# Rotate to velocity with a max turn rate
	if velocity.length_squared() > 0.01:
		var look_pos = global_position + Vector3(velocity.x, 0, velocity.z)
		# Get the angle we want to look at
		var target_transform = transform.looking_at(look_pos, Vector3.UP)
		var target_angle = target_transform.basis.get_euler().y
		
		# Find shortest rotation path and clamp it to our max turn speed
		var angle_diff = wrapf(target_angle - rotation.y, -PI, PI)
		rotation.y += clamp(angle_diff, -TURN_SPEED * delta, TURN_SPEED * delta)
	
func _process(delta: float) -> void:
	# Navigation
	if not navigation_agent_3d.is_navigation_finished():
		var next_path_pos = navigation_agent_3d.get_next_path_position()
		var new_velocity = (next_path_pos - global_position).normalized() * Vector3(1, 0, 1) * STAT.movement_speed * STAT.speed_multiplier
		velocity = new_velocity
		move_and_slide()
	else:
		velocity *= Vector3(0, 1, 0)
	
	# Cheese fix for NavigationAgent3D having 1 meter gap to the final
	if navigation_agent_3d.is_navigation_finished() and nav_cheese != Vector3.ZERO:
		if (nav_cheese - global_position).length() > 0.15:
			var next_path_pos = nav_cheese
			var new_velocity = (next_path_pos - global_position).normalized() * Vector3(1, 0, 1) * STAT.movement_speed * STAT.speed_multiplier
			velocity = new_velocity
			move_and_slide()
		else:
			velocity *= Vector3(0, 1, 0)
			
	# --- RUN THE VAMPIRE SURVIVORS DAMAGE LOGIC ---
	_handle_damage(delta)

func _handle_damage(delta: float) -> void:
	# ount down the cooldown timer
	if current_attack_timer > 0.0:
		current_attack_timer -= delta
		
	# If the timer is ready, check for the player
	if current_attack_timer <= 0.0:
		# get_overlapping_bodies() checks who is currently inside the Area3D
		var overlapping_bodies = damage_area.get_overlapping_bodies()
		
		for body in overlapping_bodies:
			var target_player = body as Player
			if target_player:
				# Deal Damage! 
				target_player.ASC.set_health(target_player.ASC.get_health() - damage_amount)
				
				# Reset the cooldown timer so we wait before hitting again
				current_attack_timer = attack_cooldown
				break # We hit the player, no need to check other bodies this frame

func set_navigation_target(in_location: Vector3):
	navigation_agent_3d.target_position = in_location
	nav_cheese = in_location
	
func _on_enemy_stat_died() -> void:
	var exp_drop: ExpDrop = EXP_DROP.instantiate()
	exp_drop.global_position = global_position
	get_tree().current_scene.add_child(exp_drop)
	queue_free()
