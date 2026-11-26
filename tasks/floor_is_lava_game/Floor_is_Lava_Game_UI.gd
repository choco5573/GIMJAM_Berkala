extends Control
signal solved
signal failed   # tidak dipakai (jatuh ke lava = ulang dari sofa)

# Floor is Lava:
#   Panah / WASD = pilih arah, tahan SPASI = isi tenaga, lepas = lompat.
#   Mendarat di perabot = aman. Mendarat di lantai = lava, ulang dari sofa.
#   Sampai ke lantai bata (kotak hijau) = menang.
#
# Kotak aman dalam koordinat UI (384x288). Kalau ruangannya diubah, sesuaikan angka ini.
const SAFE_ZONES: Array = [
	Rect2(124, 78, 54, 43),    # sofa atas (posisi awal)
	Rect2(86, 124, 32, 34),    # kursi kiri
	Rect2(133, 129, 51, 28),   # meja
	Rect2(124, 158, 54, 34),   # sofa bawah
	Rect2(188, 111, 96, 47),   # karpet
	Rect2(182, 60, 98, 44),    # lemari TV
]
const GOAL_ZONES: Array = [
	Rect2(216, 194, 96, 62),   # lantai bata bawah kanan
	Rect2(280, 160, 32, 34),
]
const ZONE_MARGIN: float = 4.0

# area lantai yang ditutup lava (lantai bata kanan bawah dibiarkan, itu tujuan)
const LAVA_AREAS: Array = [
	Rect2(86, 95, 226, 99),
	Rect2(86, 194, 130, 62),
]

@onready var character: Node2D = %character
@onready var floor_layer: CanvasItem = get_node_or_null("tilemaps/Floor")

var running: bool = false
var start_position: Vector2
var info_label: Label
var reset_tween: Tween

func _process(delta: float) -> void:
	if character.position.y > 155:
		$"Sofa Back".z_index = 0
	else:
		$"Sofa Back".z_index = 6
		
func _ready() -> void:
	start_position = character.position
	character.active = false
	character.landed.connect(_on_landed)

	# lantai berubah jadi lava (tile lava di atas lantai, di bawah perabot)
	_make_lava()

	for zone in GOAL_ZONES:
		var goal = ColorRect.new()
		goal.color = Color(0.2, 1.0, 0.3, 0.35)
		goal.position = zone.position
		goal.size = zone.size
		goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(goal)
		move_child(goal, 1)   # di bawah karakter

	info_label = Label.new()
	info_label.position = Vector2(8, 262)
	info_label.size = Vector2(368, 20)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_constant_override("outline_size", 4)
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_label)
	_show_help()


func start() -> void:
	running = true
	character.reset_to(start_position)
	character.active = true
	_show_help()


func stop() -> void:
	running = false
	character.active = false
	if reset_tween:
		reset_tween.kill()


func _show_help() -> void:
	info_label.text = "Panah: arah  |  tahan SPASI: lompat  |  sampai ke kotak hijau!"


func _on_landed() -> void:
	if not running: return
	var feet: Vector2 = character.position

	if _inside(GOAL_ZONES, feet):
		info_label.text = "Aman! Lara berhasil!"
		stop()
		solved.emit()
		return

	if _inside(SAFE_ZONES, feet):
		return

	# jatuh ke lava
	info_label.text = "Aduh, kena lava! Ulang dari sofa..."
	character.active = false
	if reset_tween:
		reset_tween.kill()
	reset_tween = create_tween()
	reset_tween.tween_property(character, "modulate", Color(1, 0.3, 0.3), 0.15)
	reset_tween.tween_interval(0.6)
	reset_tween.tween_callback(_restart_from_sofa)
	reset_tween.tween_property(character, "modulate", Color.WHITE, 0.15)


func _restart_from_sofa() -> void:
	if not running: return
	character.reset_to(start_position)
	character.active = true
	_show_help()


func _inside(zones: Array, point: Vector2) -> bool:
	for zone in zones:
		if zone.grow(ZONE_MARGIN).has_point(point):
			return true
	return false


func _make_lava() -> void:
	var tilemaps = get_node_or_null("tilemaps")
	if tilemaps == null: return
	var index = 0
	if floor_layer:
		index = floor_layer.get_index() + 1
	for zone in LAVA_AREAS:
		var lava = TextureRect.new()
		lava.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lava.stretch_mode = TextureRect.STRETCH_TILE
		lava.position = zone.position
		lava.size = zone.size
		lava.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tilemaps.add_child(lava)
		tilemaps.move_child(lava, index)
		index += 1
		# lava "berdenyut" pelan
		var glow = lava.create_tween().set_loops()
		glow.tween_property(lava, "modulate", Color(1.15, 1.0, 0.9), 0.8)
		glow.tween_property(lava, "modulate", Color.WHITE, 0.8)
