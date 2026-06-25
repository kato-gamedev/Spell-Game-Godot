class_name Interactable extends Area3D

signal interacted(interactor: Node)

# @export variables in ALL UPPER CASE
@export var PROMPT_MESSAGE: String = "Interact"
@export var IS_INTERACTABLE: bool = true

func interact(interactor: Node) -> void:
	if IS_INTERACTABLE:
		interacted.emit(interactor)
