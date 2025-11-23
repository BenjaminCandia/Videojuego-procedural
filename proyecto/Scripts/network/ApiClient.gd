extends Node

const BASE_URL := "https://procedural-game-landing.onrender.com" # tu dominio de Ruby (Render, Railway, etc.)

## Endpoints (ajusta estos paths)
const EQUATION_ENDPOINT: String = "/api/math/random?"   # GET
const SCORE_ENDPOINT: String = "/api/highscores"        # POST

## -------------------------------------------------------------------
##  GET /equation  ->  Dictionary con la ecuación
## -------------------------------------------------------------------
func fetch_equation(var_count: int, complexity: int) -> Dictionary:
	var data: Dictionary = {}
	var query: String = "?vars=" + str(var_count) + "&complexity=" + str(complexity)
	var url: String = BASE_URL + EQUATION_ENDPOINT + query

	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)

	var headers: PackedStringArray = PackedStringArray()  # sin headers especiales para GET
	var error: Error = http.request(url, headers, HTTPClient.METHOD_GET)

	if error != OK:
		push_error("Error al iniciar request GET equation: %s" % error)
		http.queue_free()
		return data

	var result: Array = await http.request_completed
	http.queue_free()

	var request_result: int = result[0]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if request_result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Request GET equation falló. Resultado: %s" % request_result)
		return data

	if response_code != 200:
		push_warning("HTTP %s al pedir ecuación" % response_code)
		return data

	var body_string: String = body.get_string_from_utf8()
	var json: JSON = JSON.new()
	var parse_error: int = json.parse(body_string)

	if parse_error != OK:
		push_warning("Error al parsear JSON de equation: %s" % parse_error)
		return data

	var decoded: Variant = json.data
	if decoded is Dictionary:
		data = decoded
	else:
		push_warning("La respuesta de equation no es un Dictionary")

	return data

## -------------------------------------------------------------------
##  POST /scores  ->  true si se envió bien, false si falló
## -------------------------------------------------------------------
func post_score(player_name: String, levels: int, time_seconds: float) -> bool:
	var url: String = BASE_URL + SCORE_ENDPOINT

	var payload: Dictionary = {}
	payload["player"] = player_name
	payload["levels"] = levels
	payload["time"] = time_seconds

	var json_body: String = JSON.stringify(payload)

	var headers: PackedStringArray = PackedStringArray()
	headers.append("Content-Type: application/json")
	headers.append("Accept: application/json")

	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)

	var error: Error = http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if error != OK:
		push_error("Error al iniciar POST score: %s" % error)
		http.queue_free()
		return false

	var result: Array = await http.request_completed
	http.queue_free()

	var request_result: int = result[0]
	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if request_result != HTTPRequest.RESULT_SUCCESS:
		push_warning("Request POST score falló. Resultado: %s" % request_result)
		return false

	if response_code < 200 or response_code >= 300:
		push_warning("HTTP %s al enviar score" % response_code)
		return false

	# Si quieres revisar lo que respondió la API:
	var body_string: String = body.get_string_from_utf8()
	print("Respuesta POST score:", body_string)

	return true

## -------------------------------------------------------------------
##  GET /ping  ->  "wake up" server
## -------------------------------------------------------------------
func warmup_api() -> void:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)

	var url: String = BASE_URL + "/api/ping"

	var headers: PackedStringArray = PackedStringArray()
	var error: Error = http.request(url, headers, HTTPClient.METHOD_GET)

	if error != OK:
		push_error("Error al iniciar warmup: " + str(error))
		http.queue_free()
		return

	var result: Array = await http.request_completed
	http.queue_free()

	var response_code: int = result[1]

	if response_code == 200:
		print("API despierta ✔")
	else:
		print("Warmup falló. La API puede estar despertando…")

func _ready() -> void:
	print("Inicializando API…")
	ApiClient.warmup_api()
