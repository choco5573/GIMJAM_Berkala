extends Area2D
signal diary_solved

var player_on_collision : bool = false


func _input(event: InputEvent) -> void:
	if !player_on_collision: return
	if GameManager.on_task: return   # sedang cutscene / minigame / transisi

	if event.is_action_pressed("e_accept"):
		check_task()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.interact = true
		player_on_collision = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.interact = false
		player_on_collision = false


# hari baru hanya bisa dimulai kalau semua cutscene dan task hari ini selesai
func check_task() -> void:
	if StoryDirector.is_day_complete():
		diary_solved.emit()
	else:
		StoryDirector.flash_hint("Masih ada yang harus dilakukan hari ini...")
