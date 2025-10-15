extends Node2D

# --- Referencias a TileMapLayers ---
@onready var wall: TileMapLayer = $TileMap/Wall
@onready var ground: TileMapLayer = $TileMap/Ground

# --- IDs y atlas ---
@export var WALL_SOURCE_ID := 3
@export var WALL_ATLAS := Vector2i(0, 0)
@export var GROUND_SOURCE_ID := 5
@export var GROUND_ATLAS := Vector2i(0, 0)


# ============================================================
# 🧱 CREA MUROS DE 2 TILES DE GROSOR, PATRÓN 2×2 REPETIDO
# ============================================================
func fill_walls(tiles_x: int, tiles_y: int) -> void:
	wall.clear()
	for x in range(tiles_x):
		for y in range(tiles_y):
			if x < 2 or x >= tiles_x - 2 or y < 2 or y >= tiles_y - 2:
				var atlas_x = x % 2
				var atlas_y = y % 2
				wall.set_cell(Vector2i(x, y), WALL_SOURCE_ID, Vector2i(atlas_x, atlas_y))


# ============================================================
# 🗺️ GENERADOR DE TERRENO POR SECTORES (ESTILO SPELUNKY)
# ============================================================
func generate_ground() -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var map_width = 32
	var map_height = 20
	var sector_w = 8
	var sector_h = 5
	var sectors_x = map_width / sector_w
	var sectors_y = map_height / sector_h

	var route_tiles: Array = []
	var sector_path: Array = []
	var visited = {}

	# --- Puntos de inicio y fin posibles (6 puntos: 3 por lado) ---
	var start_positions = [
		Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(3, 0), Vector2i(3, 2), Vector2i(3, 3)
	]

	var start_index = rng.randi_range(0, start_positions.size() - 1)
	var start_sector = start_positions[start_index]

	# --- Seleccionar meta que cumpla las reglas ---
	var valid_ends = []
	for i in range(start_positions.size()):
		if i == start_index:
			continue
		var sp = start_positions[i]
		var same_col = sp.x == start_sector.x
		var diff_row = abs(sp.y - start_sector.y)
		if (not same_col) or (diff_row >= 2):
			valid_ends.append(sp)
	var end_sector = valid_ends[rng.randi_range(0, valid_ends.size() - 1)]

	# --- Generar camino sectorial (DFS simple) ---
	var stack = [start_sector]
	while stack.size() > 0:
		var current = stack.pop_back()
		sector_path.append(current)
		visited[str(current)] = true

		if current == end_sector:
			break

		var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		dirs.shuffle()
		for d in dirs:
			var next = current + d
			if next.x >= 0 and next.x < sectors_x and next.y >= 0 and next.y < sectors_y:
				if not visited.has(str(next)):
					stack.append(next)
					break

	# --- Dibujar plataformas en los sectores del camino ---
	for sec in sector_path:
		var base_x = sec.x * sector_w
		var base_y = sec.y * sector_h
		var plat_y = base_y + rng.randi_range(2, sector_h - 2)
		var plat_x = base_x + rng.randi_range(1, sector_w - 4)
		var width = rng.randi_range(3, 5)
		for i in range(width):
			ground.set_cell(Vector2i(plat_x + i, plat_y), GROUND_SOURCE_ID, GROUND_ATLAS)
		route_tiles.append(Vector2i(plat_x, plat_y))

	# --- Bloque inicial ---
	var start_tile = Vector2i(start_sector.x * sector_w + 2, start_sector.y * sector_h + 3)
	for i in range(3):
		ground.set_cell(start_tile + Vector2i(i, 0), GROUND_SOURCE_ID, GROUND_ATLAS)
	route_tiles.insert(0, start_tile)

	# --- Bloque meta ---
	var end_tile = Vector2i(end_sector.x * sector_w + 2, end_sector.y * sector_h + 3)
	for i in range(6):
		ground.set_cell(end_tile + Vector2i(i, 0), GROUND_SOURCE_ID, GROUND_ATLAS)
	route_tiles.append(end_tile)

	return {
		"route_tiles": route_tiles,
		"sector_path": sector_path,
		"start_sector": start_sector,
		"end_sector": end_sector,
		"grid_size": Vector2i(sectors_x, sectors_y)
	}


# ============================================================
# 🧠 VALIDACIÓN DE RUTA SECTORIAL (MACRO)
# ============================================================
func validate_route_sectors(path: Array, start_sector: Vector2i, end_sector: Vector2i, total_x: int, total_y: int) -> bool:
	if path.is_empty():
		print("❌ Ruta vacía.")
		return false

	if path[0] != start_sector:
		print("⚠️ El primer sector no coincide con el inicio.")
	if path[-1] != end_sector:
		print("⚠️ El último sector no coincide con la meta.")

	for i in range(path.size() - 1):
		var a = path[i]
		var b = path[i + 1]
		var diff = b - a

		if abs(diff.x) + abs(diff.y) != 1:
			print("❌ Sectores no adyacentes:", a, "→", b)
			return false

		if b.x < 0 or b.y < 0 or b.x >= total_x or b.y >= total_y:
			print("❌ Sector fuera de rango:", b)
			return false

	print("✅ Ruta sectorial válida con", path.size(), "sectores conectados.")
	return true


# ============================================================
# 🧗 VALIDACIÓN DE RUTA JUGABLE (MICRO)
# ============================================================
func validate_route(route: Array) -> bool:
	var player_height = 3
	var clearance = 1
	var max_up = 3
	var max_down = 5
	var max_jump = 5
	var max_walk = 6

	if route.size() < 2:
		print("Ruta demasiado corta")
		return false

	for i in range(route.size() - 1):
		var a = route[i]
		var b = route[i + 1]
		var dx = abs(b.x - a.x)
		var dy = b.y - a.y

		if dy < 0:
			var up = abs(dy)
			if up > max_up:
				print("❌ Salto muy alto:", up, "tiles de", a, "a", b)
				return false
			elif up >= 2 and dx > max_jump:
				print("❌ Salto alto + desplazamiento largo:", dx, "tiles")
				return false
		elif dy > 0:
			if dy > max_down:
				print("❌ Caída muy grande:", dy, "tiles")
				return false
			elif dx > max_walk:
				print("❌ Caída muy separada:", dx, "tiles")
				return false
		else:
			if dx > max_walk:
				print("❌ Plano demasiado largo:", dx, "tiles")
				return false

		if b.y < (player_height + clearance):
			print("⚠️ Sin espacio libre arriba en", b)
			return false

		print("✅ Salto válido de", a, "a", b, "dx:", dx, "dy:", dy)

	return true


# ============================================================
# 🧾 DEBUG VISUAL DE SECTORES
# ============================================================
func print_sector_map(path: Array, start_sector: Vector2i, end_sector: Vector2i, total_x: int, total_y: int) -> void:
	var grid = []
	for y in range(total_y):
		var row = []
		for x in range(total_x):
			var pos = Vector2i(x, y)
			if pos == start_sector:
				row.append("🟩")
			elif pos == end_sector:
				row.append("🟥")
			elif pos in path:
				row.append("🟨")
			else:
				row.append("⚫")
		grid.append(row)

	print("\n--- MAPA DE SECTORES ---")
	for y in range(total_y):
		print("".join(grid[y]))


# ============================================================
# 🚀 PUNTO DE ENTRADA PRINCIPAL
# ============================================================
func _ready() -> void:
	var size = get_viewport().get_visible_rect().size
	var tiles_x = int(size.x / wall.tile_set.tile_size.x)
	var tiles_y = int(size.y / wall.tile_set.tile_size.y)

	fill_walls(tiles_x, tiles_y)

	var valid_sector = false
	var valid_tiles = false
	var attempts = 0
	var result = {}

	while attempts < 100:
		ground.clear()
		result = generate_ground()
		attempts += 1

		# --- Paso 1: validar estructura de sectores ---
		valid_sector = validate_route_sectors(
			result["sector_path"],
			result["start_sector"],
			result["end_sector"],
			result["grid_size"].x,
			result["grid_size"].y
		)
		if not valid_sector:
			print("Intento %d: ruta sectorial NO válida ❌" % attempts)
			continue

		# --- Paso 2: validar jugabilidad (tiles) ---
		valid_tiles = validate_route(result["route_tiles"])
		print("Intento %d: %s" % [
			attempts,
			("LOGRABLE ✅" if valid_tiles else "NO lograble ❌")
		])

		if valid_tiles:
			break

	if not valid_tiles:
		print("⚠️ No se encontró ruta válida tras 100 intentos.")
	else:
		print("✅ Nivel generado correctamente tras %d intentos" % attempts)
		print_sector_map(
			result["sector_path"],
			result["start_sector"],
			result["end_sector"],
			result["grid_size"].x,
			result["grid_size"].y
		)
