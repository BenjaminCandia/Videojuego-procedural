
extends Node2D

@onready var hud = $HUD  # tu HUD con monedas y cronómetro

func _ready():
	$Puerta.connect("body_entered", Callable(self, "_on_Puerta_body_entered"))


func _on_body_entered(body):
	if body.is_in_group("Player"):
		Global.award_coin()
		$HUD.update_coins()
		$NivelSuperadoUI.visible = true
		get_tree().change_scene_to_file("res://Niveles/nivel_2.tscn")
		get_tree().paused = true   # Pausa el juego mientras está el menú


func _on_puerta_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
