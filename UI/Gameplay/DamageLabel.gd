extends Label3D
class_name DamageLabel

@export var FLOAT_HEIGHT: float = 1.5
@export var ANIM_DURATION: float = 0.5
@export var FINAL_ALPHA: float = 1.0

func initialize(damage: int) -> void:
	text = str(damage)

func _ready() -> void:
	var tween: Tween = create_tween()
	# Move the label up smoothly using a Quad transition
	tween.tween_property(self, "position:y", position.y + FLOAT_HEIGHT, ANIM_DURATION) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out the text opacity at the same time
	tween.parallel().tween_property(self, "modulate:a", FINAL_ALPHA, ANIM_DURATION)
	# Delete the node once the animation completes
	tween.tween_callback(queue_free)
