extends Area2D
signal on_door_pressed

const SFX_DOOR = preload("res://assets/audios/PindahAreaDiLuar (1).mp3")  

var player_on_collision : bool = false


func _input(event: InputEvent) -> void:
	if !player_on_collision: return
	if GameManager.on_task: return   

	if event.is_action_pressed("e_accept"):
		_play_door_sound()
		on_door_pressed.emit()


func _play_door_sound() -> void:
	var sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_DOOR
	get_tree().root.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.interact = true
		player_on_collision = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.interact = false
		player_on_collision = false
