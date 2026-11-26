extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.color = Color("#000000")
	animation_player.play("default")
