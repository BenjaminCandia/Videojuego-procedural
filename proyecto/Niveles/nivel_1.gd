extends Node2D

@export var next_scene_path: String = "res://Niveles/nivel_2.tscn"
@onready var puerta = $puerta
# @onready var nivel_superado_ui = $NivelSuperadoUI

func _ready():
	if puerta != null:
		puerta.connect("body_entered", Callable(self, "_on_puerta_body_entered"))
	else:
		push_error("Nodo 'puerta' no encontrado en la escena")

	# if nivel_superado_ui:
	#     nivel_superado_ui.visible = false

func _on_puerta_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		# Evita activaciones repetidas
		puerta.set_deferred("monitoring", false)
		puerta.set_deferred("monitorable", false)

		# Suma moneda y actualiza HUD
		Global.award_coin()
		Hud.update_coins()

		# Guarda tiempo en memoria
		var level_name = self.name
		Global.save_level_time(level_name, Global.elapsed_time)

		# Muestra UI
		# if nivel_superado_ui:
		#     nivel_superado_ui.visible = true

		# Cambia de nivel tras 1.5 segundos
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.5
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_on_timer_timeout").bind(next_scene_path))
		timer.start()

func _on_timer_timeout(next_scene_path):
	get_tree().call_deferred("change_scene_to_file", next_scene_path)
