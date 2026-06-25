@tool
extends BTAction


## Note: Each method declaration is optional.
## At minimum, you only need to define the "_tick" method.

@export var ability: GameplayAbility

# Called to generate a display name for the task (requires @tool).
func _generate_name() -> String:
	return "Play ability"


# Called to initialize the task.
func _setup() -> void:
	pass


# Called when the task is entered.
func _enter() -> void:
	var character: Character = agent as Character
	if character:
		HolyAbilityActivator.activate_ability(character, ability)

# Called when the task is exited.
func _exit() -> void:
	pass

# Called each time this task is ticked (aka executed).
func _tick(delta: float) -> Status:
	return SUCCESS
