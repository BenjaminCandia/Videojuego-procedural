extends Control

@onready var time_label = $Control/Cronometro
@onready var http := HTTPRequest.new()
@onready var label_game_over = $MarginContainer/VBoxContainer/VBoxContainer2/Label
@onready var name_input = $MarginContainer/VBoxContainer/VBoxContainer2/LineEdit
@onready var save_button = $Guardar
@onready var dialogo_guardado = $DialogoGuardado

var total_time: float = 0.0
var total_levels: int = 0

func _ready():
	add_child(http)
	_calculate_totals()
	label_game_over.text = "Tu tiempo fue: " + str(int(round(total_time))) + " segundos."
	save_button.connect("pressed", Callable(self, "_on_guardar_pressed"))
	dialogo_guardado.connect("confirmed", Callable(self, "_on_dialog_confirmed"))
	dialogo_guardado.popup_centered()
	dialogo_guardado.hide()

	if MusicManager:
		MusicManager.stop()

func _on_guardar_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name == "":
		push_warning("Por favor, ingresa tu nombre antes de guardar.")
		return

	var success: bool = await ApiClient.post_score(player_name, total_levels, total_time)

	if success:
		print("Puntaje enviado correctamente")
		dialogo_guardado.dialog_text = "✅ ¡Puntaje guardado correctamente!"
		dialogo_guardado.popup_centered()

	else:
		dialogo_guardado.dialog_text = "❌ Error al guardar el puntaje."
		push_warning("No se pudo enviar el score. Intenta nuevamente.")
	
func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/menus/MainMenu/main_menu.tscn")

func _calculate_totals():
	for value in Global.level_times.values():
		total_time += value
	total_levels = Global.level_times.size()

func _on_dialog_confirmed():
	get_tree().change_scene_to_file("res://Interfaces/menus/MainMenu/main_menu.tscn")
