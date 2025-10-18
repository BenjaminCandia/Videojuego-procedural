extends CanvasLayer

# Carga la escena del HUD
var hud_scene = preload("res://Interfaces/HUD/HUD.tscn")

var instance

var coins_label
var time_label

var elapsed_time := 0.0

func _ready():
	# Instancia HUD
	instance = hud_scene.instantiate()
	get_tree().current_scene.add_child(instance)

	# Referencias a los labels
	var control = instance.get_node("Control")
	coins_label = control.get_node("Monedas")
	time_label = control.get_node("Cronometro")

	update_coins()  

	# 🔹 Activa _process ahora que los labels existen
	set_process(true)

func _process(delta):
	if not time_label:
		return  # 🔹 Protege contra null
	elapsed_time += delta
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	time_label.text = "[center][color=#ffffff]%02d:%02d[/color][/center]" % [minutes, seconds]

func update_coins():
	if coins_label:
		coins_label.text = "[center][color=#ffffff]%d[/color][/center]" % Global.coins_total
