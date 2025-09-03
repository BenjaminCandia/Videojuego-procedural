extends CharacterBody2D

@export var move_speed: float
@export var jump_speed: float
@onready var animated_sprite = $AnimatedSprite2D
var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta): 
	
	#Movimiento lateral del personaje
	var input_axis = Input.get_axis("izquierda","derecha")	
	velocity.x = input_axis * move_speed
	move_and_slide()
	
	#Salto
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = -jump_speed
		
	if not is_on_floor():
		velocity.y += gravity * delta
	
	#Cambio de eje para que mire a la izquierda y a la derecha 
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right
		
	#Animaciones
	if velocity.x:
		animated_sprite.play("correr")
	else:
		animated_sprite.play("estatico")
		
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("salto")
		else:
			animated_sprite.play("caida")
		return
	
	move_and_slide()
	
		
