extends Area2D

@export var next_scene: String

func _on_body_entered(body):
	if body == null:
		return

	if body.is_in_group("Player"):
		# Evitar activaciones repetidas
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

		# Suma moneda y actualiza HUD 
		Global.award_coin()
		Hud.update_coins()

		# Guardar tiempo usando el singleton Global 
		var level_name = get_tree().current_scene.name
		Global.save_level_time(level_name, Global.elapsed_time)

		# Cambiar de escena de forma diferida para evitar errores durante la señal
		get_tree().call_deferred("change_scene_to_file", next_scene)
