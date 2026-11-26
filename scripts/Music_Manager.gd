extends Node

var player: AudioStreamPlayer
var fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps playing in the pause menu
	player = AudioStreamPlayer.new()
	player.volume_db = -8.0
	add_child(player)



func play(stream: AudioStream, fade_time: float = 1.0) -> void:
	if player.stream == stream and player.playing:
		return
	if fade_tween:
		fade_tween.kill()
	player.stream = stream
	player.volume_db = -40.0
	player.play()
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", -8.0, fade_time)


func stop(fade_time: float = 1.0) -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", -40.0, fade_time)
	fade_tween.tween_callback(player.stop)
