extends Node

func activate_ability(character: Character, ability: GameplayAbility):
	if character._casting == true:
		return
	
	# Magic orb
	if ability as GA_MagicOrb:
		var ability_magic_orb := ability as GA_MagicOrb
		var player = character as Player
		if player:
			var aiming_location = player.get_aiming_location()
			ability_magic_orb._activate(Enum.TargetingType.DIRECTION, player, aiming_location, null)
