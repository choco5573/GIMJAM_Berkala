extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

@onready var portrait_left: TextureRect = $Balloon/PortraitLeft
@onready var portrait_right: TextureRect = $Balloon/PortraitRight

const SIDES = {"Lara": "left", "Mama": "right", "Ibu": "right", "Keisha": "right", "Bos": "right", "Atasan": "right"}   # tambahkan karakter lain di sini

# Portrait VN: <nama>_<fase>_<ekspresi>.png, contoh lara_kid_happy.png, mama_teen_worried.png
# Lara dewasa punya dua set: lara_adult_office_* (di kamar / kerja) dan lara_adult_home_*.
const PORTRAIT_FOLDER = "res://assets/sprites/characters_sprites/portraits_vn/"
const CHARACTER_FILES = {"Lara": "lara", "Mama": "mama", "Ibu": "mama", "Keisha": "keisha"}
const MOOD_ALIASES = {"nuetral": "neutral", "tired": "tireed", "hapi": "happy", "megahapi": "superHappy"}
const PORTRAIT_SCALE: float = 0.3       # tinggi portrait dewasa = 720 * 0.3 = 216 px
const PORTRAIT_BOTTOM_GAP: float = 40.0 # bagian bawah portrait tertutup kotak dialog

const CHATBOX_TEXTURE = preload("res://assets/sprites/UI_sprites/gui/chatbox.png")
const VN_FONT = preload("res://assets/fonts/VT323-Regular.ttf")
const TEXT_COLOR = Color(0.2, 0.15, 0.12)

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given cue when using balloon as a [Node] in a scene.
@export var start_from_cue: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	balloon.hide()
	_style_vn()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()



func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		await dialogue_line.refresh()
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, cue: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not cue.is_empty():
		start_from_cue = cue
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_cue, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")
	
	update_portraits(dialogue_line)
	
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		responses_menu.focus_first_item()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)



# tampilan visual novel: kotak dialog kertas + font VT323 + portrait di belakang kotak
func _style_vn() -> void:
	portrait_left.visible = false
	portrait_right.visible = false
	# portrait digambar lebih dulu supaya tertutup kotak dialog
	balloon.move_child(portrait_left, 0)
	balloon.move_child(portrait_right, 1)

	var box: MarginContainer = $Balloon/MarginContainer
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 6.0
	box.offset_right = -6.0
	box.offset_top = -96.0
	box.offset_bottom = -4.0
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		box.add_theme_constant_override(side, 0)

	var panel: PanelContainer = $Balloon/MarginContainer/PanelContainer
	var sb = StyleBoxTexture.new()
	sb.texture = CHATBOX_TEXTURE
	sb.content_margin_left = 34.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var inner: MarginContainer = $Balloon/MarginContainer/PanelContainer/MarginContainer
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		inner.add_theme_constant_override(side, 0)

	character_label.modulate = Color.WHITE
	for label in [character_label, dialogue_label]:
		label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for font_type in ["normal_font", "bold_font", "italics_font", "bold_italics_font"]:
			label.add_theme_font_override(font_type, VN_FONT)
		for size_type in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
			label.add_theme_font_size_override(size_type, 16)
		label.add_theme_color_override("default_color", TEXT_COLOR)
	character_label.add_theme_color_override("default_color", Color(0.45, 0.25, 0.15))
	progress.color = TEXT_COLOR


func update_portraits(line: DialogueLine) -> void:
	var speaker = line.character.strip_edges()
	if speaker.is_empty(): return   # baris narasi: gambar tidak berubah

	var mood = "neutral"
	for tag in line.tags:
		if not str(tag).begins_with("voice"):
			mood = str(tag)
			break

	var path = _find_portrait(speaker, mood)
	var is_left = SIDES.get(speaker, "left") == "left"
	var active = portrait_left if is_left else portrait_right
	var other = portrait_right if is_left else portrait_left

	if path == "":
		# karakter tanpa gambar (Bos, Atasan, ...): yang lain digelapkan
		portrait_left.modulate = Color(0.5, 0.5, 0.5)
		portrait_right.modulate = Color(0.5, 0.5, 0.5)
		return

	active.texture = load(path)
	_place_portrait(active, is_left)
	active.visible = true
	active.modulate = Color.WHITE
	other.modulate = Color(0.5, 0.5, 0.5)   # yang tidak bicara digelapkan


func _place_portrait(rect: TextureRect, left: bool) -> void:
	rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.scale = Vector2.ONE
	rect.custom_minimum_size = Vector2.ZERO
	var s: Vector2 = rect.texture.get_size() * PORTRAIT_SCALE
	rect.size = s
	var area: Vector2 = get_viewport().get_visible_rect().size   # ukuran layar game (384x288)
	var x = 6.0 if left else area.x - 6.0 - s.x
	rect.position = Vector2(x, area.y - PORTRAIT_BOTTOM_GAP - s.y)


func _find_portrait(speaker: String, mood: String) -> String:
	var key: String = CHARACTER_FILES.get(speaker, speaker.to_lower())
	var phase: String = GameManager.current_phase.to_lower()
	mood = MOOD_ALIASES.get(mood, mood)

	var variants: Array = [phase]
	if key == "lara" and phase == "adult":
		if GameManager.current_room == "Bedroom":
			variants = ["adult_office", "adult_home"]
		else:
			variants = ["adult_home", "adult_office"]
	if key == "keisha":
		variants.append("kid")   # Keisha hanya punya gambar masa kecil

	for m in [mood, "neutral", "smileneutral", "smile", "happy"]:
		for v in variants:
			var path = PORTRAIT_FOLDER + key + "_" + v + "_" + m + ".png"
			if ResourceLoader.exists(path):
				return path
	return ""

#endregion
