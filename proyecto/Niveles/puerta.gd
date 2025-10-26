extends Area2D

@export var next_scene: String

func _on_body_entered(body):
	if body == null:
		return

<<<<<<< HEAD
=======
	# Usar grupo es más fiable que comparar nombre
>>>>>>> 733d96ed6e46c82ae8117cb2211227b5276dddb0
	if body.is_in_group("Player"):
		# Evitar activaciones repetidas
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

<<<<<<< HEAD
		# Suma moneda y actualiza HUD 
		Global.award_coin()
		Hud.update_coins()

		# Guardar tiempo usando el singleton Global 
=======
		# Suma moneda y actualiza HUD (asumiendo que Global y Hud son autoloads)
		Global.award_coin()
		Hud.update_coins()

		# Guardar tiempo usando el singleton Global (más consistente)
>>>>>>> 733d96ed6e46c82ae8117cb2211227b5276dddb0
		var level_name = get_tree().current_scene.name
		Global.save_level_time(level_name, Global.elapsed_time)

		# Cambiar de escena de forma diferida para evitar errores durante la señal
		get_tree().call_deferred("change_scene_to_file", next_scene)
