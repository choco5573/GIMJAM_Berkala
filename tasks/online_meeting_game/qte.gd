extends Control
# Satu tombol QTE: lingkaran waktu mengecil, tekan huruf yang tampil sebelum habis.

signal finished(isSuccess: bool)

@export var keyString: String = "Q"
@export var keyCode: Key = KEY_Q
@export var eventDuration: float = 1.4
@export var displayDuration: float = 0.3

@onready var color_rect: ColorRect = %ColorRect
@onready var key_label: Label = %KeyLabel
@onready var success_label: Label = %SuccessLabel

var tween: Tween
var done: bool = false


func _ready() -> void:
	add_to_group("QTE")
	_fit_small_screen()
	key_label.text = keyString

	tween = create_tween()
	tween.tween_property(color_rect, "material:shader_parameter/value", 0.0, eventDuration)
	tween.tween_callback(_end.bind(false))


# scene aslinya dibuat untuk layar besar; perkecil untuk layar 384x288
func _fit_small_screen() -> void:
	color_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	color_rect.size = Vector2(56, 56)
	color_rect.position = Vector2(-28, -28)

	key_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	key_label.position = Vector2.ZERO
	key_label.size = color_rect.size
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 28)
	key_label.add_theme_constant_override("outline_size", 6)

	success_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	success_label.rotation = 0.0
	success_label.position = Vector2(4, 54)
	success_label.add_theme_font_size_override("font_size", 16)
	success_label.add_theme_constant_override("outline_size", 4)
	success_label.text = "OK!"


func _input(event: InputEvent) -> void:
	if done: return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	# hanya huruf yang dihitung (E untuk interaksi diabaikan)
	if key.keycode < KEY_A or key.keycode > KEY_Z or key.keycode == KEY_E: return

	get_viewport().set_input_as_handled()
	if key.keycode == keyCode:
		success_label.show()
		_end(true)
	else:
		color_rect.modulate = Color(1, 0.3, 0.3)
		_end(false)


func _end(is_success: bool) -> void:
	if done: return
	done = true
	if tween:
		tween.kill()
	finished.emit(is_success)

	var out = create_tween()
	out.tween_interval(displayDuration)
	out.tween_property(self, "modulate:a", 0.0, 0.15)
	out.tween_callback(queue_free)
