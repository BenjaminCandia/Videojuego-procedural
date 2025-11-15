extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var label = $Label
@onready var tienda_ui = $"../TiendaUI"

var player_near = false

func _ready():
	animated_sprite.play("estatico_tienda")
	label.visible = false
	
	animated_sprite.play("estatico_tienda")
	label.visible = false
	# Conectamos señales del área
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_near = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_near = false
		label.visible = false

func _input(event):
	if player_near and event.is_action_pressed("interactuar"):
		if tienda_ui:
			tienda_ui.mostrar_tienda()
