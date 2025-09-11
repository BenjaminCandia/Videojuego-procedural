extends CharacterBody2D

@export var move_speed: float
@export var jump_speed: float
@export var coyote_time: float = 0.15  
@export var gravity: float 
@onready var animated_sprite = $AnimatedSprite2D
var is_facing_right = true

var coyote_timer: float = 0.0

const bala = preload("res://disparo/area_2d.tscn")

func _physics_process(delta): 
	# Movimiento lateral
	var input_axis = Input.get_axis("izquierda", "derecha")	
	velocity.x = input_axis * move_speed

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# Coyote time (resetea si estás en suelo, baja si no)
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Salto con coyote time
	if Input.is_action_just_pressed("saltar") and coyote_timer > 0.0:
		velocity.y = -jump_speed
		coyote_timer = 0.0

	# Cambio de dirección
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right
		
	# Animaciones
	if velocity.x != 0:
		animated_sprite.play("correr")
	else:
		animated_sprite.play("estatico")
		
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("salto")
		else:
			animated_sprite.play("caida")
	# Disparo
	if Input.is_action_just_pressed("Disparar"):
		var shoot = bala.instantiate()
		get_parent().add_child(shoot)
		shoot.global_position = global_position  

	# Movimiento final
	move_and_slide()
