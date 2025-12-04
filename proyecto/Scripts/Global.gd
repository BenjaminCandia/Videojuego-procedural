extends Node

# Variables globales
var coins_total := 0
var elapsed_time := 0.0
var timer_running := false
var level_times := {}
var q_levels : int = 0

# Señal para notificar cambios en las monedas
signal monedas_actualizadas(nuevo_total)

# Aumenta monedas
func award_coin():
	coins_total += 1
	var caller = get_stack()[1].get("function", "unknown") if Engine.is_editor_hint() == false else "editor"
	print("[COIN] Se otorgó una moneda. Total:", coins_total, " | Llamado desde:", caller)
	emit_signal("monedas_actualizadas", coins_total)

# Reinicia y activa cronómetro
func start_timer():
	elapsed_time = 0.0
	timer_running = true

# Aumenta q level
func level_complete():
	q_levels += 1

# Detiene cronómetro
func stop_timer():
	timer_running = false

# Guarda tiempo por nivel
func save_level_time(level_name: String, time: float):
	level_times[level_name] = time

# Determina el tipo de tienda según monedas
func obtener_tipo_tienda() -> String:
	if coins_total < 10:
		return "economica"
	elif coins_total < 20:
		return "media"
	else:
		return "alta"

# Intenta gastar monedas (retorna true si se puede)
func gastar_monedas(precio: int) -> bool:
	if coins_total >= precio:
		coins_total -= precio
		print("[COIN] Se gastaron", precio, "monedas. Total restante:", coins_total)
		emit_signal("monedas_actualizadas", coins_total)
		return true
	else:
		print("[COIN] Intento fallido: no hay suficientes monedas. Total actual:", coins_total)
	return false
