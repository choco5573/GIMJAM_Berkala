extends CanvasLayer
# HUD gunanya bakal dipasang (nodenya) disemua stage scene

@onready var interaction_button: AnimatedSprite2D = $MarginContainer/RightBottomContainer/InteractionButton
@onready var room_label: Label = $MarginContainer/LeftTopContainer/RoomLabel
@onready var room_label_timer: Timer = $MarginContainer/LeftTopContainer/RoomLabelTimer
@onready var animation_player: AnimationPlayer = $MarginContainer/AnimationPlayer
@onready var task_list: VBoxContainer = $MarginContainer/TaskList
@onready var day_label: Label = $MarginContainer/LeftTopContainer/DayLabel

var current_phase : String = GameManager.current_phase
var current_day : String = GameManager.current_day

var rows: Dictionary = {}

# petunjuk dari StoryDirector ("Pergi ke Halaman", "Kerjakan PR di meja", ...)
var hint_label: Label
var hint_tween: Tween

func _ready() -> void:
	GameManager.task_completed.connect(refresh_task_list)
	_make_hint_label()
	StoryDirector.hint_changed.connect(_on_hint_changed)
	_on_hint_changed(StoryDirector.current_hint)
	
	interaction_button.visible = false
	day_label.text = "Day " + current_day
	room_label.visible = true
	room_label_timer.start()
	build_task_list()


func _process(_delta: float) -> void:
	if GameManager.interact:
		interaction_button.visible = true
	else:
		interaction_button.visible = false


# kalau timernya udah lewat, label current room akan menghilang
func _on_room_label_timer_timeout() -> void:
	animation_player.play("label_fade")


# TASK HUD
func build_task_list() -> void:
	for child in task_list.get_children():
		task_list.remove_child(child)
		child.queue_free()
	rows.clear()

	# header, selalu ada di paling atas
	var header = Label.new()
	header.text = "To Do List"
	header.add_theme_font_size_override("font_size", 24)
	task_list.add_child(header)

	var tasks = _get_today_tasks()
	for task_name in tasks:
		var prefix = "      - "
		var text = task_name.replace("_", " ").capitalize()

		var label = Label.new()
		label.text = prefix + text

		var line = ColorRect.new()
		line.color = Color(0.45, 0.45, 0.45)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var row = Control.new()
		row.add_child(label)
		row.add_child(line)
		task_list.add_child(row)

		var label_size = label.get_minimum_size()
		row.custom_minimum_size = label_size

		# ukur lebar prefix dan lebar teks tugas saja
		var font = label.get_theme_font("font")
		var font_size = label.get_theme_font_size("font_size")
		var start_x = font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

		line.size = Vector2(0, 2)
		line.position = Vector2(start_x, label_size.y / 2.0)

		rows[task_name] = {"label": label, "line": line, "width": text_width, "done": false}

		if tasks[task_name]:
			_apply_done(task_name, false)


func refresh_task_list() -> void:
	var tasks = _get_today_tasks()
	for task_name in tasks:
		if tasks[task_name] and rows.has(task_name) and not rows[task_name]["done"]:
			_apply_done(task_name, true)


func _apply_done(task_name: String, animate: bool) -> void:
	var r = rows[task_name]
	r["done"] = true

	var dark = Color(0.45, 0.45, 0.45)

	if animate:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(r["line"], "size:x", r["width"], 0.35)
		tween.tween_property(r["label"], "modulate", dark, 0.35)
	else:
		r["line"].size.x = r["width"]
		r["label"].modulate = dark


func _get_today_tasks() -> Dictionary:
	return ToDoList.get_tasks(current_phase, int(current_day))


# HINT HUD
func _make_hint_label() -> void:
	hint_label = Label.new()
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -22
	hint_label.offset_bottom = -6
	hint_label.offset_left = 8
	hint_label.offset_right = -8
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_constant_override("outline_size", 4)
	hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)


func _on_hint_changed(text: String) -> void:
	if hint_tween:
		hint_tween.kill()
	hint_label.text = text
	hint_label.modulate.a = 1.0
	# pesan sementara (misal dari diary) kembali ke petunjuk utama setelah 2.5 detik
	if text != StoryDirector.current_hint:
		hint_tween = create_tween()
		hint_tween.tween_interval(2.5)
		hint_tween.tween_callback(_on_hint_changed.bind(StoryDirector.current_hint))
