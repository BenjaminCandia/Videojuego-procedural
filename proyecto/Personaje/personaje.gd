extends CharacterBody2D

@export var move_speed: float = 210
@export var jump_speed: float = 350
@export var coyote_time: float = 0.15
@export var gravity: float = 950
@export var dash_speed: float = 600
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

@onready var animated_sprite = $AnimatedSprite2D

var is_facing_right = true
var coyote_timer: float = 0.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

func _physics_process(delta):
	# --- Dash cooldown ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- Dash activo ---
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0 or is_on_wall():
			is_dashing = false
		move_and_slide()
		return  # 🔹 Evita que el resto del movimiento se ejecute durante el dash

	# --- Movimiento lateral ---
	var input_axis = Input.get_axis("izquierda", "derecha")
	velocity.x = input_axis * move_speed

	# --- Gravedad ---
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- Coyote time ---
	if is_on_floor():
		coyote_timer = coyote_time
		can_dash = true  # 🔹 Recupera el dash al tocar el suelo
	else:
		coyote_timer -= delta

	# --- Salto ---
	if Input.is_action_just_pressed("saltar") and coyote_timer > 0.0:
		velocity.y = -jump_speed
		coyote_timer = 0.0

	# --- Dash ---
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0:
		start_dash()

	# --- Cambio de dirección (corregido) ---
	if velocity.x > 0:
		is_facing_right = true
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		is_facing_right = false
		animated_sprite.flip_h = true

	# --- Animaciones ---
	if velocity.x != 0:
		animated_sprite.play("correr")
	else:
		animated_sprite.play("estatico")

	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("salto")
		else:
			animated_sprite.play("caida")

	# --- Movimiento final ---
	move_and_slide()


func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	# 🔹 Cancela la gravedad y salto durante el dash
	velocity.y = 0

	# 🔹 Si hay input, úsalo; si no, usa la dirección actual
	var input_axis = Input.get_axis("izquierda", "derecha")
	if input_axis != 0:
		is_facing_right = input_axis > 0
		animated_sprite.flip_h = not is_facing_right

	var direction = 1 if is_facing_right else -1
	velocity.x = dash_speed * direction

	animated_sprite.play("dash")
