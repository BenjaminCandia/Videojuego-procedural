extends CharacterBody2D

@export var move_speed: float = 210
@export var jump_speed: float = 350
@export var coyote_time: float = 0.15
@export var gravity: float = 950
@export var dash_speed: float = 400
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 0.4

@onready var animated_sprite = $AnimatedSprite2D

var is_facing_right = true
var coyote_timer: float = 0.0
var is_dashing: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dead: bool = false   # 👈 Nuevo: evita mover al jugador cuando muere


func _physics_process(delta):
	
	# Si está muerto, NO se mueve
	if is_dead:
		return

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0 or is_on_wall():
			is_dashing = false
		move_and_slide()
		return

	var input_axis = Input.get_axis("izquierda", "derecha")
	velocity.x = input_axis * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_on_floor():
		coyote_timer = coyote_time
		can_dash = true
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("saltar") and coyote_timer > 0.0:
		velocity.y = -jump_speed
		coyote_timer = 0.0

	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0:
		start_dash()

	if velocity.x > 0:
		is_facing_right = true
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		is_facing_right = false
		animated_sprite.flip_h = true

	if is_dashing:
		animated_sprite.play("dash")
	elif not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("salto")
		else:
			animated_sprite.play("caida")
	elif velocity.x != 0:
		animated_sprite.play("correr")
	else:
		animated_sprite.play("estatico")

	move_and_slide()


func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity.y = 0

	var input_axis = Input.get_axis("izquierda", "derecha")
	if input_axis != 0:
		is_facing_right = input_axis > 0
		animated_sprite.flip_h = not is_facing_right

	var direction = 1 if is_facing_right else -1
	velocity.x = dash_speed * direction
	animated_sprite.play("dash")


# --- COLISIÓN DEL ÁREA ---
func _on_area_2d_body_entered(body):
	if body.is_in_group("enemigo"):
		die()


# --- COLISIÓN DEL HITBOX ---
func _on_hitbox_body_entered(body):
	if body.is_in_group("enemigo"):
		die()


# --- MUERTE DEL JUGADOR ---
func die():
	if is_dead:
		return  # evita que muera dos veces

	print("Jugador muerto!")
	is_dead = true      # Detiene el control del jugador
	velocity = Vector2.ZERO  # No se mueve más
	animated_sprite.play("muerte")   # 🎞 Reproduce animación
	
	call_deferred("_restart_level_with_delay")


# --- REINICIAR NIVEL CON RETRASO ---
func _restart_level_with_delay():
	await get_tree().create_timer(0.5).timeout   # 🕒 Espera 1 segundo

	var current_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene_path)
