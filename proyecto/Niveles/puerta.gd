extends Area2D

@export var next_scene: String

func _on_body_entered(body):
	if body.is_in_group("Player"):
		# Suma moneda y actualiza HUD
		Global.award_coin()
		Hud.update_coins()

		# Guarda tiempo del nivel
		var level_name = get_tree().current_scene.name
		Global.save_level_time(level_name, Hud.elapsed_time)

		# Cambia de nivel
		get_tree().change_scene_to_file(next_scene)
