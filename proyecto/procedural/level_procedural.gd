extends Node2D

# ============================================================
# 🧩 MÓDULO: Variables
# ============================================================

# --- Escenas a instanciar ---
@export var player_scene: PackedScene
@export var door_scene: PackedScene

# --- Capas (TileMapLayer) ---
@onready var wall:    TileMapLayer = $TileMap/Wall
@onready var ground:  TileMapLayer = $TileMap/Ground
@onready var objects: TileMapLayer = $TileMap/Objects

# --- Config de muros (borde de 2) ---
@export var WALL_SOURCE_ID := 3
@export var WALL_ATLAS_BASE := Vector2i(0, 0)
@export var border_thickness := 2

# --- Config de suelo (tiles/atlas) ---
@export var GROUND_SOURCE_ID: int = 5
@export var GROUND_ATLAS_BASE: Vector2i = Vector2i(0, 0)
@export_enum("checker_x","solid","checker_2x2") var ground_pattern := "checker_x"

# --- Estado runtime ---
var player: Node2D = null
var door: Node2D = null

# ============================================================
# 🧩 MÓDULO: TILES (utilidades de tiles y grilla)
# ============================================================

func _ts_tile_size() -> Vector2i:
	# Detecta el tamaño real del tileset (16×16 si no hay)
	if ground and ground.tile_set:
		return ground.tile_set.tile_size
	return Vector2i(32,32)

func _grid_from_viewport() -> Vector2i:
	var ts := _ts_tile_size()
	var vp := get_viewport().get_visible_rect().size
	return Vector2i(ceil(vp.x / ts.x), ceil(vp.y / ts.y))

func _tile_center_world(tile: Vector2i) -> Vector2:
	# Centro del tile en coordenadas globales
	var ts: Vector2i =  ground.tile_set.tile_size if ground and ground.tile_set else  Vector2i(16, 16)
	return Vector2((tile.x + 0.5) * ts.x, (tile.y + 0.5) * ts.y)

# Atlas helper para patrones de suelo (si quieres alternar visual)
func _ground_atlas_for(x:int, y:int) -> Vector2i:
	match ground_pattern:
		"checker_x":
			return Vector2i(GROUND_ATLAS_BASE.x + (x % 2), GROUND_ATLAS_BASE.y + 0)
		"checker_2x2":
			return Vector2i(GROUND_ATLAS_BASE.x + (x % 2), GROUND_ATLAS_BASE.y + (y % 2))
		"solid":
			return GROUND_ATLAS_BASE
		_:
			return GROUND_ATLAS_BASE

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
# 🪨 MÓDULO: GENERAR SUELO (route + plataformas por sectores)
# ============================================================
func generate_ground() -> Dictionary:
	# RNG
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	# Dimensiones del mapa y sectores
	var map_width: int = 40
	var map_height: int = 23
	var sector_w: int = 8
	var sector_h: int = 5
	var sectors_x: int = map_width / sector_w
	var sectors_y: int = map_height / sector_h
	
	# Limpia capa de ground
	if ground:
		ground.clear()
	
	var route_tiles: Array[Vector2i] = []
	var sector_path: Array[Vector2i] = []
	var visited: Dictionary[String, bool] = {}
	
	var start_positions: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(sectors_x - 1, 0),
		Vector2i(0, sectors_y - 1),
		Vector2i(sectors_x - 1, sectors_y - 1)
	]

	var start_index = rng.randi_range(0, start_positions.size() - 1)
	var start_sector = start_positions[start_index]

	var valid_ends: Array[Vector2i] = start_positions.filter(func(p): return p != start_sector)
	var end_sector = valid_ends[rng.randi_range(0, valid_ends.size() - 1)]
	# Parámetros
	var OFFSET_TOP := 5
	var OFFSET_SIDE := 2
	var START_WIDTH := 2
	var END_WIDTH := 6
	var BORDER := border_thickness            # ej: 2

	# Tamaño total del mapa en tiles (usa tus constantes reales si difieren)
	var MAP_W := int(map_width)
	var MAP_H := int(map_height)

	# Helpers de borde “interior” (primera/última celda jugable por lado)
	var LEFT_INNER_X := BORDER
	var RIGHT_INNER_X := MAP_W - BORDER - 1
	var TOP_INNER_Y := BORDER
	var BOTTOM_INNER_Y := MAP_H - BORDER - 1

	# =================== INICIO (2 tiles) ===================
	var start_y: int
	if start_sector.y == 0:
		# esquina superior → a OFFSET_TOP del borde superior (ya dentro del mapa)
		start_y = TOP_INNER_Y + OFFSET_TOP
	else:
		# esquina inferior → a OFFSET_TOP del borde inferior
		start_y = BOTTOM_INNER_Y - OFFSET_TOP

	var start_first_x: int
	if start_sector.x == 0:
		# lado izquierdo → a OFFSET_SIDE del borde izquierdo
		start_first_x = LEFT_INNER_X + OFFSET_SIDE
		# dibujar hacia la derecha
		for i in range(START_WIDTH):
			ground.set_cell(Vector2i(start_first_x + i, start_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	else:
		# lado derecho → el más cercano al borde a OFFSET_SIDE del borde derecho
		var rightmost_x := RIGHT_INNER_X - OFFSET_SIDE
		# dibujar hacia la izquierda (así queda simétrico)
		for i in range(START_WIDTH):
			ground.set_cell(Vector2i(rightmost_x - i, start_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		# coordenada del “primer” tile (más a la izquierda) del bloque
		start_first_x = rightmost_x - (START_WIDTH - 1)

	var start_tile := Vector2i(start_first_x, start_y)
	route_tiles.insert(0, start_tile)

	# ==================== FINAL (6 tiles) ====================
	var end_y: int
	if end_sector.y == 0:
		end_y = TOP_INNER_Y + OFFSET_TOP
	else:
		end_y = BOTTOM_INNER_Y - OFFSET_TOP

	var end_first_x: int
	if end_sector.x == 0:
		# izquierda → hacia la derecha
		end_first_x = LEFT_INNER_X + OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(end_first_x + i, end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	else:
		# derecha → hacia la izquierda (pegado con OFFSET_SIDE al borde)
		var rightmost_x2 := RIGHT_INNER_X - OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(rightmost_x2 - i, end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		end_first_x = rightmost_x2 - (END_WIDTH - 1)

	var end_tile := Vector2i(end_first_x, end_y)
	route_tiles.append(end_tile)
#------------------------------
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
			ground.set_cell(Vector2i(plat_x + i, plat_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		route_tiles.append(Vector2i(plat_x, plat_y))

#------------------------------
	return {
			"route_tiles": route_tiles,
			"sector_path": sector_path,
			"start_sector": start_sector,
			"end_sector": end_sector,
			"grid_size": Vector2i(sectors_x, sectors_y),
			"start_tile": start_tile,
			"end_tile": end_tile
		}
func cell_one_tile_up_global(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	var ts: Vector2i = layer.tile_set.tile_size

	var local := Vector2(
		(cell.x + 0.5) * ts.x,   # centro horizontal
		(cell.y - 1.5) * ts.y    # 1.5 tiles arriba
	)

	return layer.to_global(local)
func cell_one_tile_up_global2(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	var ts: Vector2i = layer.tile_set.tile_size

	var local := Vector2(
		(cell.x + 3) * ts.x,
		(cell.y - 1.3) * ts.y
	)

	return layer.to_global(local)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
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
	
func _ready() -> void:
	# Alinear TileMap y capas al origen
	$TileMap.position = Vector2.ZERO
	if wall:    wall.position = Vector2.ZERO
	if ground:  ground.position = Vector2.ZERO
	if objects: objects.position = Vector2.ZERO
	
	var size = get_viewport().get_visible_rect().size
	var tiles_x = int(size.x / wall.tile_set.tile_size.x)
	var tiles_y = int(size.y / wall.tile_set.tile_size.y)

	fill_walls(tiles_x, tiles_y)
	var gen := generate_ground()

	# Instanciar si hace falta
	if player == null and player_scene:
		player = player_scene.instantiate()
		add_child(player)
		# Asegurar grupo Player
		if not player.is_in_group("Player"):
			player.add_to_group("Player")

	if door == null and door_scene:
		door = door_scene.instantiate()
		add_child(door)
		# Esta escena se vuelve el "siguiente nivel"
		var level_path := get_tree().current_scene.scene_file_path
		door.next_scene = level_path   # 👈 string, no PackedScene
		print("🔍 next_scene =", door.next_scene, "  (tipo:", typeof(door.next_scene), ")")
		
	# Posicionar usando la capa Ground como referencia
	var start_cell: Vector2i = gen["start_tile"]
	var end_cell: Vector2i = gen["end_tile"]

	# Opción A: centro de la celda
	#player.position = cell_center_global(ground, start_cell)
	#door.position   = cell_center_global(ground, end_cell)

	# Opción B: pies sobre la base (útil si el origen del sprite es centrado)
	player.position = cell_one_tile_up_global(ground, start_cell)
	door.position   = cell_one_tile_up_global2(ground, end_cell)
