extends Area2D

@export var speed: float = 400.0
var velocity: Vector2 = Vector2.ZERO
@export var lifetime: float = 2.0

func _ready():
	# se autodestruye después de cierto tiempo
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Aquí es donde se mueve la bala 👇
	position += velocity * delta

func _on_body_entered(body):
	# Si quieres que desaparezca al chocar
	queue_free()
