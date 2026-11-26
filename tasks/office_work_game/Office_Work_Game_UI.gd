extends Control
signal solved
signal failed

@export var rounds_needed: int = 8    
@export var time_per_key: float = 1.5  

const KEY: Array = [KEY_Q, KEY_W, KEY_A, KEY_S, KEY_D, KEY_F, KEY_Z, KEY_X]

@onready var progress_label: Label = $ColorRect/MarginContainer/VBoxContainer/ProgressLabel
@onready var prompt_label: Label = $ColorRect/MarginContainer/VBoxContainer/PromptLabel
@onready var time_bar: ProgressBar = $ColorRect/MarginContainer/VBoxContainer/TimeBar

var fill_style: StyleBoxFlat
var running: bool = false
var current_round: int = 0
var current_key: int = KEY_NONE
var time_left: float = 0.0


const BG_KERJA = preload("res://assets/tasks/office/kerja.png")


func _ready() -> void:
	set_process(false)
	_make_background()
	time_bar.show_percentage = false

	fill_style = StyleBoxFlat.new()
	fill_style.set_corner_radius_all(4)
	time_bar.add_theme_stylebox_override("fill", fill_style) 

func start() -> void:
	current_round = 0
	current_key = KEY_NONE
	running = true
	set_process(true)
	next_key()


func stop() -> void:
	running = false
	set_process(false)


func next_key() -> void:
	var new_key = KEY.pick_random()
	while new_key == current_key:
		new_key = KEY.pick_random()
	current_key = new_key

	progress_label.text = "%d / %d" % [current_round + 1, rounds_needed]
	prompt_label.text = OS.get_keycode_string(current_key)

	time_left = time_per_key
	time_bar.max_value = time_per_key
	update_bar()


func _process(delta: float) -> void:
	if not running: return

	time_left -= delta
	update_bar()

	if time_left <= 0.0:
		fail()


func _input(event: InputEvent) -> void:
	if not running: return
	if not event is InputEventKey: return

	var key_event = event as InputEventKey
	if not key_event.pressed or key_event.echo: return

	if not KEY.has(key_event.keycode): return

	get_viewport().set_input_as_handled()

	if key_event.keycode == current_key:
		current_round += 1
		if current_round >= rounds_needed:
			stop()
			solved.emit()
		else:
			next_key()
	else:
		fail()


func fail() -> void:
	stop()
	failed.emit()
	
func update_bar() -> void:
	time_bar.value = time_left
	var ratio = clamp(time_left / time_per_key, 0.0, 1.0)
	# 0.33 = hijau, 0.0 = merah, di tengah kuning
	fill_style.bg_color = Color.from_hsv(ratio * 0.33, 0.85, 0.95)


# latar layar komputer kantor; teks ditaruh di dalam layar
func _make_background() -> void:
	var bg = TextureRect.new()
	bg.texture = BG_KERJA
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	var panel: ColorRect = $ColorRect
	panel.color = Color(0, 0, 0, 0)
	panel.position = Vector2(40, 40)
	panel.size = Vector2(305, 190)

	for label in [progress_label, prompt_label]:
		var ls: LabelSettings = label.label_settings.duplicate() if label.label_settings else LabelSettings.new()
		ls.font_color = Color(0.15, 0.13, 0.2)
		label.label_settings = ls
