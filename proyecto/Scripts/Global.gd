extends Node

# Variables globales
var coins_total := 4
var elapsed_time := 0.0
var timer_running := false

# Aumenta monedas
func award_coin():
	coins_total += 1

# Reinicia y activa cronómetro
func start_timer():
	elapsed_time = 0.0
	timer_running = true

# Detiene cronómetro
func stop_timer():
	timer_running = false

# Guarda tiempo de nivel (opcional)
var level_times := {}
func save_level_time(level_name: String, time: float):
	level_times[level_name] = time
