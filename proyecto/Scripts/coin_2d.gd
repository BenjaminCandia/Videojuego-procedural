extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Global.award_coin()
		Hud.update_coins()
		queue_free()
