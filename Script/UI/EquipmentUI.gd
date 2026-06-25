extends Control

## Attached directly onto the player for node reference
# External
@onready var player: Player = $".."

# Internal
@onready var bullet_count: Label = $BulletCount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(player.name)
	# Wait for ammo_changed to load on player
	await player.ready
	#player.current_weapon.ammo_changed.connect(on_ammo_changed)
	## This is a one-time init code
	#on_ammo_changed(player.current_weapon.current_ammo, player.current_weapon.MAGAZINE_CAPACITY)

func on_ammo_changed(current_ammo: int, max_ammo: int):
	bullet_count.text = "{1}/{2}".format({"1": current_ammo, "2": max_ammo})
