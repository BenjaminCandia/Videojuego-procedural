extends Node2D

@export var next_scene_path: String = "res://Niveles/nivel_2.tscn"
@onready var puerta = $puerta
# @onready var nivel_superado_ui = $NivelSuperadoUI

func _ready():
	if puerta != null:
		puerta.connect("body_entered", Callable(self, "_on_puerta_body_entered"))
	else:
		push_error("Nodo 'puerta' no encontrado en la escena")
		
	if MusicManager and not MusicManager.playing:
		MusicManager.play()


func _on_puerta_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		# Evita activaciones repetidas
		puerta.set_deferred("monitoring", false)
		puerta.set_deferred("monitorable", false)

		# Guarda tiempo en memoria
		var level_name = self.name
		Global.save_level_time(level_name, Global.elapsed_time)
		get_tree().call_deferred("change_scene_to_file", next_scene_path)
