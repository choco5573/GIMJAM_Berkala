extends Control
signal solved
signal failed

const AssignmentQuestions = preload("res://tasks/assignment_game/Assignment_Questions.gd")
@onready var progress_label: Label = $ColorRect/MarginContainer/VBoxContainer/ProgressLabel
@onready var question_label: Label = $ColorRect/MarginContainer/VBoxContainer/QuestionLabel
@onready var options: VBoxContainer = $ColorRect/MarginContainer/VBoxContainer/Options

var questions: Array = []
var option_buttons: Array = []
var current_index: int = 0
var running: bool = false

# jumlah soal yang dipakai (0 = semua soal). Diatur task wrapper lewat configure().
var question_count: int = 3

# latar: kertas PR untuk "tugas", layar komputer untuk tutor online & UTBK
const BG_TUGAS = preload("res://assets/tasks/assignment/tugas.png")
const BG_SCREEN = preload("res://assets/tasks/assignment/utbk.png")
const AREA_TUGAS = Rect2(102, 128, 280, 125)    # kotak putih di kertas
const AREA_SCREEN = Rect2(80, 38, 190, 180)   # panel kanan di layar
const DARK_TEXT = Color(0.15, 0.13, 0.2)
var bg: TextureRect

func _ready() -> void:
	for i in options.get_child_count():
		var button = options.get_child(i) as Button
		button.pressed.connect(_on_option_pressed.bind(i))
		option_buttons.append(button)
	_fit_small_screen()


# layar game kecil (384x288): soal dibungkus dan tombol dibuat ringkas
func _fit_small_screen() -> void:
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.custom_minimum_size = Vector2(320, 0)
	if question_label.label_settings:
		var ls: LabelSettings = question_label.label_settings.duplicate()
		ls.font_size = 12
		question_label.label_settings = ls
	options.custom_minimum_size = Vector2(320, 0)
	options.add_theme_constant_override("separation", 4)
	for button in option_buttons:
		button.custom_minimum_size = Vector2(320, 0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 12)


# Dipanggil dari skrip Node2D saat UI dibuka
func start() -> void:
	questions = AssignmentQuestions.QUESTIONS.duplicate(true)
	questions.shuffle()   # hapus baris ini kalau urutan soal mau tetap
	if question_count > 0 and question_count < questions.size():
		questions.resize(question_count)
	current_index = 0
	running = true
	show_question()


func stop() -> void:
	running = false


func show_question() -> void:
	var q = questions[current_index]
	progress_label.text = "%d / %d" % [current_index + 1, questions.size()]
	question_label.text = q["question"]

	for i in option_buttons.size():
		var button = option_buttons[i]
		if i < q["options"].size():
			button.text = q["options"][i]
			button.visible = true
		else:
			button.visible = false


func _on_option_pressed(index: int) -> void:
	if not running: return

	if index == questions[current_index]["answer"]:
		current_index += 1
		if current_index >= questions.size():
			stop()
			solved.emit()
		else:
			show_question()
	else:
		stop()
		failed.emit()


# dipanggil task wrapper (configure): pilih latar & area teks sesuai task
func set_background(task_name: String) -> void:
	if bg == null:
		bg = TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

	var area: Rect2 = AREA_TUGAS
	if task_name == "tugas":
		bg.texture = BG_TUGAS
	else:
		bg.texture = BG_SCREEN
		area = AREA_SCREEN

	$ColorRect.color = Color(0, 0, 0, 0)
	var box: MarginContainer = $ColorRect/MarginContainer
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.position = area.position
	box.size = area.size

	var w = area.size.x 
	question_label.custom_minimum_size = Vector2(w, 0)
	options.custom_minimum_size = Vector2(w, 0)
	for button in option_buttons:
		button.custom_minimum_size = Vector2(w, 0)
		button.add_theme_font_size_override("font_size", 12)

	for label in [question_label, progress_label]:
		var ls: LabelSettings = label.label_settings.duplicate() if label.label_settings else LabelSettings.new()
		ls.font_color = DARK_TEXT
		ls.font_size = 12
		label.label_settings = ls
