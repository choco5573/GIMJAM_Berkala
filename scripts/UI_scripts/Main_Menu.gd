extends Control
# untuk sementara/mungkin selamanya, game bakal di load dari main menu.

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")
const MENU_CYCLE_SELECT = preload("res://assets/audios/MenuCycle&Select.mp3")
var sfx: AudioStreamPlayer

func _ready() -> void:
	sfx = AudioStreamPlayer.new()
	sfx.stream = MENU_CYCLE_SELECT
	add_child(sfx)

func _on_play_button_pressed() -> void:
	StoryDirector.start_new_game()
	sfx.play()

func _on_quit_button_pressed() -> void:
	sfx.play()
	sfx.finished.connect(GameManager.quit_game, CONNECT_ONE_SHOT)
