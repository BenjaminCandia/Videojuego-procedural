extends Area2D

@export var next_scene: String

func _ready():
	if not next_scene:
		push_error("next_scene no está asignado en la puerta")

func _on_body_entered(body: Node):
	if body == null:
		return

	if body.is_in_group("Player"):
		# Evitar activaciones repetidas
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)

		# Sumar moneda y actualizar HUD
		if Global.has_method("award_coin"):
			Global.award_coin()
		if Hud.has_method("update_coins"):
			Hud.update_coins()

		# Guardar tiempo del nivel
		var level_name = get_tree().current_scene.name
		if Global.has_method("save_level_time"):
			Global.save_level_time(level_name, Global.elapsed_time)

		# Cambiar de escena
		if next_scene != "":
			get_tree().call_deferred("change_scene_to_file", next_scene)
		else:
			push_error("next_scene está vacío, no se puede cambiar de escena")
