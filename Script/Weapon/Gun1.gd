extends Node3D
class_name Gun1

signal out_of_ammo
signal reload_requested
signal ammo_changed(current_ammo: int, max_ammo: int)

@export var RPM: float = 1000.0
@export var MAGAZINE_CAPACITY: int = 3000
@export var recoil_pattern: Array[Vector2] = [
	Vector2(0.0000, 0.0000),
	Vector2(-0.0906, 0.0201),
	Vector2(-0.0906, 0.0203),
	Vector2(-0.0881, 0.0294),
	Vector2(-0.0881, 0.0294),
	Vector2(-0.0690, 0.0618),
	Vector2(-0.0630, 0.0670),
	Vector2(-0.0432, 0.0822),
	Vector2(-0.0432, 0.0822),
	Vector2(-0.0041, 0.0918),
	Vector2(0.0087, 0.0904),
	Vector2(0.0478, 0.0796),
	Vector2(0.0586, 0.0719),
	Vector2(0.0640, 0.0661),
	Vector2(0.0783, 0.0499),
	Vector2(0.0764, 0.0527),
	Vector2(0.0706, 0.0598),
	Vector2(0.0656, 0.0657),
	Vector2(0.0570, 0.0733),
	Vector2(0.0204, 0.0880),
	Vector2(0.0097, 0.0923),
	Vector2(-0.0220, 0.0880),
	Vector2(-0.0345, 0.0862),
	Vector2(-0.0495, 0.0785),
	Vector2(-0.0633, 0.0661),
	Vector2(-0.0739, 0.0562),
	Vector2(-0.0751, 0.0546),
	Vector2(-0.0858, 0.0345),
	Vector2(-0.0906, 0.0159),
	Vector2(-0.0926, 0.0062),
]
@export var recoil_magnitude: float = 0.0
@export var recoil_random_variation: Vector2 = Vector2(0.02, 0.015)

@onready var shoot_sound: AudioStreamPlayer3D = $ShootSound
const BLOOD_EXPLOSION = preload("uid://dofx74fq1bl")

var is_holding_input = false
var last_fire_attemp_time: float = 0.0 # In msec
var last_shot_time: float = 0.0 # In msec
var current_ammo: int = 0
var is_reloading: bool = false
var recoil_index: int = 0
var reset_time: float = 0.8 # In s, after this duration or not firing, the recoil pattern resets

func _ready() -> void:
	current_ammo = MAGAZINE_CAPACITY
	ammo_changed.emit(current_ammo, MAGAZINE_CAPACITY)

func _process(delta: float) -> void:
	# 1000 should work, but it didn't, so does 2000, so i put 3000
	if Time.get_ticks_msec() - last_fire_attemp_time > delta * 3000.0:
		is_holding_input = false
	#print(is_holding_input)
	if Time.get_ticks_msec() - last_shot_time >= reset_time * 1000.0:
		recoil_index = 0
	
func fire(target_location: Vector3) -> void:
	# Check when stop holding the input
	is_holding_input = true
	last_fire_attemp_time = Time.get_ticks_msec()
	
	if is_reloading:
		return
		
	if current_ammo <= 0:
		out_of_ammo.emit()
		return
		
	# Limit firing rate to RPM
	var delay_between_shots = (60.0 / RPM) * 1000.0
	
	# FIRE LOGIC
	var current_time = Time.get_ticks_msec()
	if current_time - last_shot_time >= delay_between_shots:
		last_shot_time = current_time
		
		# Deduct ammo
		current_ammo -= 1
		ammo_changed.emit(current_ammo, MAGAZINE_CAPACITY)
		
		# Apply recoil pattern and a little random variation
		var kick := Vector2.ZERO
		if recoil_pattern.size() > 0:
			kick = recoil_pattern[recoil_index % recoil_pattern.size()]
			recoil_index += 1
		kick += Vector2(
			randf_range(-recoil_random_variation.x, recoil_random_variation.x),
			randf_range(-recoil_random_variation.y, recoil_random_variation.y)
		)
		var current_recoil_offset = kick * recoil_magnitude
		
		# Apply recoil to the camera
		var player: Player = get_player()
		if player:
			player.apply_gun_recoil(current_recoil_offset)
		
		# Sound effect
		shoot_sound.pitch_scale = randf_range(0.97, 1.03)
		shoot_sound.play()
		
		# Draw hit point
		Debug.draw_sphere(target_location, 0.05, Color.RED, 0.5)
		
		# Damage
		var projectile_cast: RayCast3D = get_player().projectile_cast
		if projectile_cast.get_collider():
			var enemy = projectile_cast.get_collider().owner as Enemy
			if enemy:
				enemy.ASC.set_health(enemy.ASC.get_health() - 20.0)
				print(enemy.ASC.get_health())
		
		# Blood VFX
		var vfx_instance = BLOOD_EXPLOSION.instantiate()
		get_tree().current_scene.add_child(vfx_instance)
		vfx_instance.global_position = target_location
		
		# Prompt an auto-reload if the magazine is now empty
		if current_ammo <= 0:
			request_reload()

# Called by the player script when they press the reload button
func request_reload() -> void:
	if is_reloading or current_ammo == MAGAZINE_CAPACITY:
		return
		
	is_reloading = true
	# Emit signal so the player script knows to play the third-person reload animation
	reload_requested.emit()

# Call this from the player's AnimationPlayer (via a Call Method Track) 
# at the exact frame the character inserts the new magazine
func finish_reload() -> void:
	current_ammo = MAGAZINE_CAPACITY
	is_reloading = false
	ammo_changed.emit(current_ammo, MAGAZINE_CAPACITY)

func get_player() -> Player:
	var node := get_parent()
	while node:
		if node is Player:
			return node
		node = node.get_parent()
	return null
