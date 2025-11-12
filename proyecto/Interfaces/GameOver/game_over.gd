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
	http.connect("request_completed", Callable(self, "_on_request_completed"))
	dialogo_guardado.connect("confirmed", Callable(self, "_on_dialog_confirmed"))
	dialogo_guardado.popup_centered()
	dialogo_guardado.hide()

func _on_guardar_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name == "":
		push_warning("Por favor, ingresa tu nombre antes de guardar.")
		return

	send_post_request(player_name)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/menus/MainMenu/main_menu.tscn")

func send_post_request(player_name: String):
	var url = "http://127.0.0.1:9292/#hero"
	var data = {
		"player": player_name,
		"levels": total_levels,
		"time": total_time
	}
	var headers = ["Content-Type: application/json"]
	var json_body = JSON.stringify(data)
	http.request(url, headers, HTTPClient.METHOD_POST, json_body)
	print("Puntaje enviado:", data)

func _calculate_totals():
	for value in Global.level_times.values():
		total_time += value
	total_levels = Global.level_times.size()

func _on_request_completed(result, response_code, headers, body):
	if result == OK and (response_code == 200 or response_code == 201):
		dialogo_guardado.dialog_text = "✅ ¡Puntaje guardado correctamente!"
	else:
		dialogo_guardado.dialog_text = "❌ Error al guardar el puntaje."
	dialogo_guardado.popup_centered()

func _on_dialog_confirmed():
	get_tree().change_scene_to_file("res://Interfaces/menus/MainMenu/main_menu.tscn")
