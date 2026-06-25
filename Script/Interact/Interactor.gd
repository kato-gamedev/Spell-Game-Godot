class_name Interactor extends ShapeCast3D

# @export variables in ALL UPPER CASE
@export var INTERACT_INPUT_ACTION: String = "interact"
@export var CAMERA: Camera3D
const LABEL_OFFSET_Y: float = 0.3

const INTERACT_LABEL: PackedScene = preload("uid://ewd5gk6quf6u")

var current_interactable: Interactable
var active_label: Control = null

func _physics_process(_delta: float) -> void:
	if is_colliding():
		# ShapeCast3D can hit multiple objects, get the first one (closest)
		var collider = get_collider(0) 
		
		if collider is Interactable and collider.IS_INTERACTABLE:
			if current_interactable != collider:
				_clear_interactable() # Clear previous before assigning new
				current_interactable = collider
				_spawn_label()
		else:
			_clear_interactable()
	else:
		_clear_interactable()

func _process(_delta: float) -> void:
	# Update the 2D UI position to follow the 3D object every frame
	if current_interactable and active_label and is_instance_valid(active_label):
		var target_pos_3d = current_interactable.global_position + Vector3(0, LABEL_OFFSET_Y, 0)
		
		if CAMERA.is_position_behind(target_pos_3d):
			active_label.visible = false
		else:
			active_label.visible = true
			var screen_pos_2d = CAMERA.unproject_position(target_pos_3d)
			active_label.position = screen_pos_2d - (active_label.size / 2.0)

func _spawn_label() -> void:
	active_label = INTERACT_LABEL.instantiate()
	
	# Adding to get_tree().root so it sits on top of the screen.
	# NOTE: If your ColorGrade shader is still tinting this, make sure the root node
	# inside your INTERACT_LABEL scene is a CanvasLayer with its Layer set to 2!
	get_tree().root.add_child(active_label)
	
	# Start invisible and fade IN quickly for extra polish
	active_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(active_label, "modulate:a", 1.0, 0.15)

func _clear_interactable() -> void:
	if current_interactable:
		current_interactable = null
		
	# Check if we have a label currently on screen
	if active_label and is_instance_valid(active_label):
		# Save a local reference to it so we can detach active_label immediately
		var label_to_remove = active_label
		active_label = null # This stops _process() from trying to move it
		
		# Fade out over 0.2 seconds, then delete from memory
		var tween = create_tween()
		tween.tween_property(label_to_remove, "modulate:a", 0.0, 0.2)
		tween.tween_callback(label_to_remove.queue_free)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(INTERACT_INPUT_ACTION) and current_interactable:
		print("interact")
		current_interactable.interact(owner)
