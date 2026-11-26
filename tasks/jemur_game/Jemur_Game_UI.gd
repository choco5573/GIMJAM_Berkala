extends Control
signal solved

# Jemur baju:
#   Klik dan tahan baju, seret ke tempat jemuran (kotak ungu), lalu lepas.
#   Semua baju sudah dijemur = selesai.
#
# Tempat jemuran = node "Placeholder" (group "droppable") di dalam MarginContainer.
# Baju = node "Clothes". Jumlah baju otomatis dibuat sama dengan jumlah tempat jemuran.

const PICK_RADIUS: float = 30.0
const DROP_RADIUS: float = 34.0
const CLOTHES_COLORS: Array = [
	Color(1.0, 0.75, 0.75),
	Color(0.75, 0.85, 1.0),
	Color(1.0, 0.95, 0.7),
	Color(0.8, 1.0, 0.8),
	Color(0.9, 0.8, 1.0),
]
const SFX_DROP = preload("res://assets/audios/Jemur Baju.mp3")

var sfx: AudioStreamPlayer

@onready var holder: Control = $MarginContainer

var running: bool = false
var slots: Array = []            # Placeholder (StaticBody2D)
var clothes_list: Array = []     # Node2D baju
var start_positions: Array = []
var placed: Dictionary = {}      # baju -> slot
var dragging: Node2D = null
var drag_offset: Vector2
var title_label: Label


func _ready() -> void:
	set_process(false)

	for child in holder.get_children():
		if child.is_in_group("droppable"):
			slots.append(child)

	var template: Node2D = holder.get_node_or_null("Clothes")
	if template:
		clothes_list.append(template)
		while clothes_list.size() < slots.size():
			var copy = template.duplicate()
			holder.add_child(copy)
			clothes_list.append(copy)

	# baju diatur oleh skrip ini, bukan oleh clothes.gd
	var count = clothes_list.size()
	for i in count:
		var c: Node2D = clothes_list[i]
		c.set_process(false)
		c.modulate = CLOTHES_COLORS[i % CLOTHES_COLORS.size()]
		var x = 384.0 * (i + 1) / (count + 1)
		start_positions.append(Vector2(x, 235))

	title_label = Label.new()
	title_label.text = "Seret bajunya ke jemuran!"
	title_label.position = Vector2(8, 6)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)
	
	sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_DROP
	add_child(sfx)

func start() -> void:
	placed.clear()
	dragging = null
	GameManager.is_dragging = false
	for i in clothes_list.size():
		clothes_list[i].position = start_positions[i]
	running = true
	set_process(true)


func stop() -> void:
	running = false
	dragging = null
	GameManager.is_dragging = false
	set_process(false)


func _input(event: InputEvent) -> void:
	if not running: return
	var mb := event as InputEventMouseButton
	if mb == null: return
	if mb.button_index != MOUSE_BUTTON_LEFT: return

	if mb.pressed:
		_try_pick()
	elif dragging:
		_drop()


func _process(_delta: float) -> void:
	if dragging:
		dragging.global_position = get_global_mouse_position() - drag_offset


func _try_pick() -> void:
	var mouse = get_global_mouse_position()
	var best: Node2D = null
	var best_dist = PICK_RADIUS
	for c in clothes_list:
		if placed.has(c): continue
		var d = c.global_position.distance_to(mouse)
		if d < best_dist:
			best = c
			best_dist = d
	if best:
		dragging = best
		drag_offset = mouse - best.global_position
		GameManager.is_dragging = true   # placeholder.gd menampilkan kotak jemuran


func _drop() -> void:
	var c = dragging
	dragging = null
	GameManager.is_dragging = false

	var target = null
	var best_dist = DROP_RADIUS
	for slot in slots:
		if placed.values().has(slot): continue
		var d = slot.global_position.distance_to(c.global_position)
		if d < best_dist:
			target = slot
			best_dist = d

	var tween = create_tween()
	if target:
		placed[c] = target
		_play_drop()
		tween.tween_property(c, "global_position", target.global_position, 0.15)
		if placed.size() >= clothes_list.size():
			tween.tween_callback(_finish)
	else:
		var i = clothes_list.find(c)
		tween.tween_property(c, "position", start_positions[i], 0.2)

func _finish() -> void:
	if not running: return
	sfx.reparent(get_tree().current_scene)
	sfx.finished.connect(sfx.queue_free, CONNECT_ONE_SHOT)
	stop()
	solved.emit()


func _play_drop() -> void:
	if not is_instance_valid(sfx) or sfx.get_parent() != self:
		sfx = AudioStreamPlayer.new()
		sfx.stream = SFX_DROP
		add_child(sfx)
	sfx.play()
