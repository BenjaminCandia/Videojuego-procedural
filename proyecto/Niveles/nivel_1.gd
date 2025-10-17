extends Node2D

func _on_Puerta_body_entered(body):
	if body.is_in_group("Player"):
		$NivelSuperadoUI.visible = true
		get_tree().paused = true   # Pausa el juego mientras está el menú


func _on_puerta_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
