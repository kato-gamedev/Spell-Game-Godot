extends GameplayAbility
class_name GA_MagicOrb

#const MAGIC_ORB_SCENE = preload("uid://p4oxexmdoro2")
const orb_offset: Vector3 = Vector3(0, 1, 0)

# Property
var targeting_type: Enum.TargetingType
var team_type: Enum.TeamType

func _activate(in_targeting_type: Enum.TargetingType, in_character: Character, in_target_location: Vector3, in_target_character: Character):
	if (in_character == null):
		return
	if (in_character as Player):
		team_type = Enum.TeamType.ALLY
	if (in_character as Wizard):
		team_type = Enum.TeamType.ENEMY
	
	#var orb: MagicOrb = MAGIC_ORB_SCENE.instantiate()
	#orb.global_position = in_character.global_position + orb_offset
	#in_character.owner.add_child(orb)
	
	#if in_targeting_type == Enum.TargetingType.DIRECTION:
		#orb.initialize(in_targeting_type, team_type, in_target_location, null)
	#if in_targeting_type == Enum.TargetingType.TARGET_UNIT:
		#orb.initialize(in_targeting_type, team_type, Vector3.ZERO, in_target_character)
