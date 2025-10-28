extends Control
@onready var time_label = $Control/Cronometro
@onready var http := HTTPRequest.new()
@onready var label_game_over := $MarginContainer/VBoxContainer/VBoxContainer2/Label

var total_time: float = 0.0
var total_levels: int = 0

func _ready():
	# VARIABLES
	add_child(http)
	_calculate_totals()
	# DEBUG
	print("Tiempo total:", total_time)
	print("Niveles totales:", total_levels)
	# SCENE CHANGES
	label_game_over.text = "Tu tiempo fue: " + str(int(round(total_time)))+ " segundos."
	#label_game_over.text = "Has superado " + str(total_levels)+ " niveles."
	# POST
	send_post_request()
	
	
func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Interfaces/menus/MainMenu/main_menu.tscn")

func send_post_request():
	var url = 'https://2af6cdbcc974.ngrok-free.app/api/highscores'
	var data = {
		"player": "niro",
		"levels": total_levels,
		"time": total_time
	}
	var headers = ["Content-Type: application/json"]
	var json_body = JSON.stringify(data)

	http.request(url, headers, HTTPClient.METHOD_POST, json_body)

func _calculate_totals():
	for value in Global.level_times.values():
		total_time += value
	total_levels = Global.level_times.size()
