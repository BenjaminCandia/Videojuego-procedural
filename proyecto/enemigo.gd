extends CharacterBody2D

const EnemyRun = 70

func _ready():
	add_to_group("enemigo")  # 👈 necesario
	velocity.x = -EnemyRun
	$AnimatedSprite2D.play("estatico")
	$AnimatedSprite2D.flip_h = true

func _physics_process(delta):
	velocity.y = 0
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity.x = -velocity.x

	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
