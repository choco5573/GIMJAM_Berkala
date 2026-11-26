extends Node2D
signal launching
signal landed   # dipancarkan saat karakter mendarat (dicek UI: aman / lava)

var active: bool = false   # input hanya dibaca saat minigame berjalan
@onready var anchor: Control = %Anchor
@onready var animated: AnimatedSprite2D = %AnimatedSprite2D

var initial_speed: float
var throw_angle_degrees: float
const gravity: float = 9.8
var time: float = 0.0
var the_direction:= Vector2(0, 1)
var aimed_distance: float = 0

var initial_position: Vector2
var throw_direction: Vector2

var z_axis = 0.0 # Simulate throwing the projectile on the z-axis by adding the z-axis to the y-axis
var is_launch: bool = false

var time_mult: float = 10

#hold_jump
const max_distance: float = 80
const min_distance: float = 2
var hold_threshold: float = 1.2
var press_time: float = 0
var jump_height = min_distance
var is_holding = false
var is_jumping = false
const SFX_JUMP = preload("res://assets/audios/Loncat.mp3") 
var jump_sfx: AudioStreamPlayer


func _ready() -> void:
	jump_sfx = AudioStreamPlayer.new()
	jump_sfx.stream = SFX_JUMP
	add_child(jump_sfx)
	
func _process(delta):
	if not active and not is_launch:
		return
	if is_launch:
		time += delta * time_mult
		z_axis = initial_speed * sin(deg_to_rad(throw_angle_degrees)) * time - 0.5 * gravity * pow(time, 2)

		if z_axis > 0:
			var x_axis: float = initial_speed * cos(deg_to_rad(throw_angle_degrees)) * time
			global_position = initial_position + throw_direction * x_axis
			
			animated.position.y = -z_axis
		else:
			# Landed: finish the launch
			z_axis = 0.0
			animated.position.y = z_axis
			is_launch = false
			anchor.visible = true
			landed.emit()
	else:
		if Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right"):
			the_direction = Vector2(1,-1)
			anchor.rotation = deg_to_rad(225)
		elif Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left"):
			the_direction = Vector2(-1,-1)
			anchor.rotation = deg_to_rad(135)
		elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right"):
			the_direction = Vector2(1,1)
			anchor.rotation = deg_to_rad(315)
		elif Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left"):
			the_direction = Vector2(-1,1)
			anchor.rotation = deg_to_rad(45)
		elif Input.is_action_just_pressed("ui_up"):
			the_direction = Vector2(0,-1)
			anchor.rotation = deg_to_rad(180)
			animated.animation = "back_walk"
		elif Input.is_action_just_pressed("ui_down"):
			the_direction = Vector2(0,1)
			anchor.rotation = 0
			animated.animation = "front_walk"
		elif Input.is_action_just_pressed("ui_right"):
			the_direction = Vector2(1,0)
			anchor.rotation = deg_to_rad(270)
			animated.animation = "right_walk"
		elif Input.is_action_just_pressed("ui_left"):
			the_direction = Vector2(-1, 0)
			anchor.rotation = deg_to_rad(90)
			animated.animation = "left_walk"
		
		if Input.is_action_just_pressed("ui_select"):
			aimed_distance = min_distance
			press_time = 0.0
			is_holding = true
			is_jumping = true
		elif Input.is_action_pressed("ui_select") and is_holding and is_jumping:
			hold_jump(delta)
		elif Input.is_action_just_released("ui_select"):
			is_holding = false
			is_jumping = false
			launching.emit()
			anchor.visible = false
			LaunchProjectile(global_position, the_direction, aimed_distance, 75)

func LaunchProjectile(initial_pos: Vector2, direction: Vector2, desired_distance: float, desired_angle_deg: float):
	initial_position = initial_pos
	throw_direction = direction.normalized()
	
	throw_angle_degrees = desired_angle_deg
	# Find initial speed based on desired distance (R) and desired angle (theta)
	initial_speed = pow(desired_distance * gravity / sin(2 * deg_to_rad(desired_angle_deg)), 0.5)
	
	global_position = initial_position
	time = 0.0
	
	z_axis = 0
	is_launch = true
	jump_sfx.pitch_scale = randf_range(0.95, 1.05)
	jump_sfx.play()

func hold_jump(delta):
	press_time += delta
	if press_time < hold_threshold:
		aimed_distance = lerp(min_distance, max_distance, press_time/hold_threshold)
	else:
		aimed_distance = max_distance
		is_holding = false
		is_jumping = false


# kembalikan karakter ke posisi awal (dipanggil UI saat jatuh ke lava / mulai ulang)
func reset_to(pos: Vector2) -> void:
	is_launch = false
	is_holding = false
	is_jumping = false
	press_time = 0.0
	time = 0.0
	z_axis = 0.0
	position = pos
	animated.position.y = 0.0
	anchor.visible = true
