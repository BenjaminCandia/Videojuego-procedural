extends CharacterBody2D

const EnemyRun = 70  # velocidad horizontal

func _ready():
	velocity.x = -EnemyRun
	$AnimatedSprite2D.play("estatico")
	$AnimatedSprite2D.flip_h = true  # empieza mirando a la izquierda

func _physics_process(delta):
	# Sin gravedad → flota
	velocity.y = 0  

	# Mover al enemigo
	var collision = move_and_collide(velocity * delta)
	
	# Si choca con algo, cambia dirección
	if collision:
		velocity.x = -velocity.x

	# Ajustar dirección visual del sprite
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
