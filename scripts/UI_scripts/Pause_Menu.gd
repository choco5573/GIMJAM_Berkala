extends CanvasLayer
# Pause menu (autoload "PauseMenu").
# ESC saat sedang jalan-jalan di stage -> game berhenti, muncul kertas "game paused".
# ESC tidak membuka pause saat minigame / cutscene / transisi (ESC dipakai menutup popup).

const PAPER = preload("res://assets/sprites/UI_sprites/gui/pause.png")
const CONTINUE_N = preload("res://assets/sprites/UI_sprites/gui/menucontinuenormal.png")
const CONTINUE_H = preload("res://assets/sprites/UI_sprites/gui/menucontinuehover.png")
const SETTINGS_N = preload("res://assets/sprites/UI_sprites/gui/menusettingsnormal.png")
const SETTINGS_H = preload("res://assets/sprites/UI_sprites/gui/menusettingshover.png")
const QUIT_N = preload("res://assets/sprites/UI_sprites/gui/menuquitnormal.png")
const QUIT_H = preload("res://assets/sprites/UI_sprites/gui/menuquithover.png")

const PAPER_SCALE: float = 0.36
const BUTTON_SCALE: float = 0.5

var root: Control
var settings_label: Label


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(root)

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var paper = TextureRect.new()
	paper.texture = PAPER
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.size = PAPER.get_size() * PAPER_SCALE
	paper.position = Vector2(192 - paper.size.x / 2.0, 15)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(paper)

	_make_button(CONTINUE_N, CONTINUE_H, 112, resume)
	_make_button(SETTINGS_N, SETTINGS_H, 146, _toggle_fullscreen)
	_make_button(QUIT_N, QUIT_H, 180, _quit_to_menu)

	settings_label = Label.new()
	settings_label.position = Vector2(120, 212)
	settings_label.size = Vector2(144, 20)
	settings_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_label.add_theme_font_size_override("font_size", 14)
	settings_label.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	root.add_child(settings_label)


func _make_button(normal: Texture2D, hover: Texture2D, y: float, action: Callable) -> void:
	var b = TextureButton.new()
	b.texture_normal = normal
	b.texture_hover = hover
	b.texture_focused = hover
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = normal.get_size() * BUTTON_SCALE
	b.position = Vector2(192 - b.size.x / 2.0, y)
	b.pressed.connect(action)
	root.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	if visible:
		resume()
		get_viewport().set_input_as_handled()
	elif _can_pause():
		pause()
		get_viewport().set_input_as_handled()


# pause hanya saat pemain bebas berjalan di stage
func _can_pause() -> bool:
	if GameManager.on_task: return false
	if CutsceneManager.playing: return false
	if StoryDirector.busy: return false
	var scene = get_tree().current_scene
	return scene != null and scene == StoryDirector.stage


func pause() -> void:
	visible = true
	GameManager.game_paused = true
	get_tree().paused = true
	_update_settings_label()


func resume() -> void:
	visible = false
	GameManager.game_paused = false
	get_tree().paused = false


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_settings_label()


func _update_settings_label() -> void:
	var full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	settings_label.text = "Layar penuh: " + ("ON" if full else "OFF")


func _quit_to_menu() -> void:
	resume()
	GameManager.reset_progress()
	GameManager.load_main_menu()
