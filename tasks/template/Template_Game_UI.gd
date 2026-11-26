extends Control
signal solved


func _ready() -> void:
	set_process(false)

func start() -> void:
	set_process(true)


func stop() -> void:
	set_process(false)


func _process(delta: float) -> void:
	pass
