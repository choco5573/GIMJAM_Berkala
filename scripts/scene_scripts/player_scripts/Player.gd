extends CharacterBody2D

@onready var animation = $AnimatedSprite2D

var direction = Vector2(0,0)
var screen_size = Vector2(1152 , 648)
var current_phase : String = GameManager.current_phase
var speed : int = 200

const SFX_STEP = preload("res://assets/audios/Walking.mp3") 
const STEP_INTERVAL: float = 0.3   

var step_sfx: AudioStreamPlayer
var step_timer: float = 0.0


func _ready() -> void:
	step_sfx = AudioStreamPlayer.new()
	step_sfx.stream = SFX_STEP
	step_sfx.volume_db = -6.0
	add_child(step_sfx)


func _physics_process(_delta: float) -> void:
	if GameManager.game_paused or GameManager.on_task:
		velocity = Vector2.ZERO
		return

	if Input.is_action_pressed("ui_left"):
		animation.flip_h = true
	if Input.is_action_pressed("ui_right"):
		animation.flip_h = false
	calculate_direction()
	# gerak lewat velocity supaya move_and_slide() menghentikan player di tembok / perabot
	velocity = direction * speed
	update_animation()
	move_and_slide()
	_update_footsteps(_delta)


# variabel game_phase untuk animasi sprite 3 bentuk karakter yang berbeda
func update_animation():
	if direction.y < 0:
		animation.play("walk_up" + " " + str(current_phase))
	elif direction.y > 0:
		animation.play("walk_down" + " " + str(current_phase))	
	elif direction.x != 0:
		animation.play("walk_horizontal" + " " + str(current_phase))
	else:
		animation.play("idle" + " " + str(current_phase))


func calculate_direction():
	direction = Vector2(0,0)
	if Input.is_action_pressed("ui_up"):
		direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
	elif Input.is_action_pressed("ui_left"):
		direction.x = -1


func _update_footsteps(delta: float) -> void:
	if get_real_velocity().length() > 1.0:
		step_timer -= delta
		if step_timer <= 0.0:
			step_sfx.pitch_scale = randf_range(0.9, 1.1)  
			step_sfx.play()
			step_timer = STEP_INTERVAL
	else:
		step_timer = 0.0  
