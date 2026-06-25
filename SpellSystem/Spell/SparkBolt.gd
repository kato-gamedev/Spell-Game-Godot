extends Spell
class_name SparkBolt

## A simple projectile spell
# Scene
@export var flying_projectile_scene: PackedScene = null

# Stat
@export var damage: float = 15.0

func cast(caster_context: CasterContext, staff_context: StaffContext):
	var character = caster_context.caster_node
	if not character:
		return
	if not flying_projectile_scene:
		return
	#if (character as Player):
		#character.team_type = Enum.TeamType.ALLY
	#if (character as Wizard):
		#character.team_type = Enum.TeamType.ENEMY
	
	# Apply modifier to damage
	var orb_damage = staff_context.apply_mod_to_damage(damage)
	
	var orb: FlyingProjectile = flying_projectile_scene.instantiate()
	var random_offset = Vector3(randf()*0.5, randf()*0.5, randf()*0.5)
	orb.global_position = caster_context.wand_tip_position + random_offset
	character.owner.add_child(orb)
	orb.initialize(Enum.TargetingType.DIRECTION, Enum.TeamType.ALLY, caster_context.aim_location, null)
	orb.initialize_stat(orb_damage)
	
	#if in_targeting_type == Enum.TargetingType.DIRECTION:
		#orb.initialize(in_targeting_type, team_type, in_target_location, null)
	#if in_targeting_type == Enum.TargetingType.TARGET_UNIT:
		#orb.initialize(in_targeting_type, team_type, Vector3.ZERO, in_target_character)
