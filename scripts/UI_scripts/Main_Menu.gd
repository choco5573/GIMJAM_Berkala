extends Control
# untuk sementara/mungkin selamanya, game bakal di load dari main menu.

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")


func _ready() -> void:
	pass # Replace with function body.


func _on_play_button_pressed() -> void:
	# reset progres, layar "Masa Kecil - Hari ke-1", lalu masuk kamar
	StoryDirector.start_new_game()


func _on_quit_button_pressed() -> void:
	GameManager.quit_game()
