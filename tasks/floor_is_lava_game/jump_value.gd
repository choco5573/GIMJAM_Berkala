extends ProgressBar

@onready var character: Node2D = %character
var reset_tween: Tween

func _ready() -> void:
	min_value = character.min_distance
	max_value = character.max_distance
	value = min_value

func _process(delta: float) -> void:
	if not character.is_holding:
		return
	if reset_tween and reset_tween.is_running():
		reset_tween.kill()
	value = lerp(min_value, max_value, character.press_time/character.hold_threshold)

func _on_character_launching() -> void:
	if reset_tween:
		reset_tween.kill()
	reset_tween = create_tween()
	reset_tween.tween_property(self, "value", min_value, character.press_time*0.25)
	await reset_tween.finished
