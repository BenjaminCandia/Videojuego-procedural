extends Node2D

@onready var wall: TileMapLayer = $TileMap/Wall
@onready var ground: TileMapLayer = $TileMap/Ground

@export var WALL_SOURCE_ID := 3
@export var WALL_ATLAS := Vector2i(0, 0)

@export var GROUND_SOURCE_ID := 5
@export var GROUND_ATLAS := Vector2i(0, 0)

func _ready() -> void:
	var size = get_viewport().get_visible_rect().size
	var tiles_x = int(size.x / wall.tile_set.tile_size.x)
	var tiles_y = int(size.y / wall.tile_set.tile_size.y)

	fill_walls(tiles_x, tiles_y)

	var valid = false
	var attempts = 0
	while not valid and attempts < 100:
		ground.clear()
		var route = generate_ground()   # devuelve lista de puntos clave
		valid = validate_route(route)
		attempts += 1
		print("Intento %d: %s" % [attempts, ("LOGRABLE ✅" if valid else "NO lograble ❌")])
	
	if not valid:
		print("⚠️ No se encontró ruta válida después de 100 intentos")

func fill_walls(tiles_x: int, tiles_y: int) -> void:
	wall.clear()
	for x in range(tiles_x):
		wall.set_cell(Vector2i(x, 0), WALL_SOURCE_ID, WALL_ATLAS)              
		wall.set_cell(Vector2i(x, tiles_y - 1), WALL_SOURCE_ID, WALL_ATLAS)    
	for y in range(tiles_y):
		wall.set_cell(Vector2i(0, y), WALL_SOURCE_ID, WALL_ATLAS)              
		wall.set_cell(Vector2i(tiles_x - 1, y), WALL_SOURCE_ID, WALL_ATLAS)

# ========================
# Procedural ground
# ========================
func generate_ground() -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var route = []
	# Zona inicial
	for x in range(2, 4):
		ground.set_cell(Vector2i(x, 15), GROUND_SOURCE_ID, GROUND_ATLAS)
	route.append(Vector2i(3, 15))

	var cur_x = 3
	var cur_y = 15

	while cur_y > 5:
		var step_y = rng.randi_range(2, 3)
		var new_y = cur_y - step_y

		var max_gap = 4 if step_y == 3 else 5
		var step_x = rng.randi_range(3, max_gap)
		var new_x = cur_x + step_x

		var plat_width = rng.randi_range(2, 3)
		for i in range(plat_width):
			ground.set_cell(Vector2i(new_x + i, new_y), GROUND_SOURCE_ID, GROUND_ATLAS)

		route.append(Vector2i(new_x, new_y))
		cur_x = new_x
		cur_y = new_y

	# Meta fija en (27,4) y (28,4)
	ground.set_cell(Vector2i(27, 4), GROUND_SOURCE_ID, GROUND_ATLAS)
	ground.set_cell(Vector2i(28, 4), GROUND_SOURCE_ID, GROUND_ATLAS)
	route.append(Vector2i(27, 4))

	return route

# ========================
# Validation rules
# ========================
func validate_route(route: Array) -> bool:
	var player_height_tiles = 2
	var clearance_tiles = 1
	var min_free_space = player_height_tiles + clearance_tiles  # = 3 tiles

	for i in range(route.size() - 1):
		var a = route[i]
		var b = route[i+1]

		var dx = abs(b.x - a.x)
		var dy = b.y - a.y  # positivo si baja, negativo si sube

		# --- Reglas de saltos ---
		if dy < 0: # sube
			var up = abs(dy)
			if up > 3:
				return false
			elif up == 3 and dx > 4:
				return false
			elif up <= 2 and dx > 5:
				return false
		elif dy == 0: # plano
			if dx > 5:
				return false
		else: # baja
			if dx > 6:
				return false

		# --- Regla de clearance (espacio libre hasta el techo) ---
		# Si la plataforma b está tan arriba que no caben 3 tiles hasta y=0 → inválido
		if b.y < min_free_space:
			print("Ruta inválida: plataforma en", b, "no tiene espacio libre arriba")
			return false

	return true
