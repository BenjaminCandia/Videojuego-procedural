extends Node2D

# ============================================================
# 🔹 MÓDULO: VARIABLES (exports, capas y estado)
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

# --- Spawns por esquina (opcional) ---
@export_enum("random","top_left","top_right","bottom_left","bottom_right") var start_corner := "random"
@export_enum("opposite","random","top_left","top_right","bottom_left","bottom_right") var end_corner := "opposite"
@export var margin_tiles := 2

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
	return Vector2i(16,16)

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
# 🧱 MÓDULO: GENERAR PAREDES (borde grueso 2 tiles)
# ============================================================

func fill_walls() -> void:
	if wall == null: return
	var size := _grid_from_viewport()
	wall.clear()
	for x in range(size.x):
		for y in range(size.y):
			var on_border := (x < border_thickness) or (x >= size.x - border_thickness) or (y < border_thickness) or (y >= size.y - border_thickness)
			if on_border:
				var ax := (x + WALL_ATLAS_BASE.x) % 2
				var ay := (y + WALL_ATLAS_BASE.y) % 2
				wall.set_cell(Vector2i(x,y), WALL_SOURCE_ID, Vector2i(ax,ay))


# ============================================================
# 🪨 MÓDULO: GENERAR SUELO (route + plataformas por sectores)
# ============================================================

# 🗺️ Generador de terreno por sectores (estilo Spelunky)
func generate_ground() -> Dictionary:
	# RNG
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	# Dimensiones del mapa y sectores
	var map_width: int = 32
	var map_height: int = 20
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

	# Puntos de inicio posibles (6 puntos: 3 por lado)
	var start_positions: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 3),
		Vector2i(3, 0), Vector2i(3, 2), Vector2i(3, 3)
	]

	var start_index: int = rng.randi_range(0, start_positions.size() - 1)
	var start_sector: Vector2i = start_positions[start_index]

	# Elegir meta válida
	var valid_ends: Array[Vector2i] = []
	for i in range(start_positions.size()):
		if i == start_index:
			continue
		var sp: Vector2i = start_positions[i]
		var same_col: bool = sp.x == start_sector.x
		var diff_row: int = abs(sp.y - start_sector.y)
		if (not same_col) or (diff_row >= 2):
			valid_ends.append(sp)
	var end_sector: Vector2i = valid_ends[rng.randi_range(0, valid_ends.size() - 1)]

	# Camino sectorial (DFS simple + greedy)
	var stack: Array[Vector2i] = [start_sector]
	while stack.size() > 0:
		var current: Vector2i = stack.pop_back()
		sector_path.append(current)
		visited[str(current)] = true

		if current == end_sector:
			break

		var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		dirs.shuffle()

		for d in dirs:
			var nxt: Vector2i = current + d
			if nxt.x >= 0 and nxt.x < sectors_x and nxt.y >= 0 and nxt.y < sectors_y:
				if not visited.has(str(nxt)):
					stack.append(nxt)
					break

	# Dibujar plataformas dentro de cada sector del camino
	for sec in sector_path:
		var base_x: int = sec.x * sector_w
		var base_y: int = sec.y * sector_h
		var plat_y: int = base_y + rng.randi_range(2, sector_h - 2)
		var plat_x: int = base_x + rng.randi_range(1, sector_w - 4)
		var width: int = rng.randi_range(3, 5)
		for i in range(width):
			# Puedes cambiar el atlas por _ground_atlas_for(plat_x + i, plat_y) si quieres patrón
			ground.set_cell(Vector2i(plat_x + i, plat_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		route_tiles.append(Vector2i(plat_x, plat_y))

	# Bloque inicial (ancho 3)
	var start_tile: Vector2i = Vector2i(start_sector.x * sector_w + 2, start_sector.y * sector_h + 3)
	for i in range(3):
		ground.set_cell(start_tile + Vector2i(i, 0), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	route_tiles.insert(0, start_tile)

	# Bloque final (ancho 6)
	var end_tile: Vector2i = Vector2i(end_sector.x * sector_w + 2, end_sector.y * sector_h + 3)
	for i in range(6):
		ground.set_cell(end_tile + Vector2i(i, 0), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	route_tiles.append(end_tile)

	return {
		"route_tiles": route_tiles,
		"sector_path": sector_path,
		"start_sector": start_sector,
		"end_sector": end_sector,
		"start_tile": start_tile,
		"end_tile": end_tile,
		"grid_size": Vector2i(sectors_x, sectors_y)
	}


# ============================================================
# 👤 MÓDULO: UBICAR PERSONAJE (instancia y posiciona)
# ============================================================

# Utilidades de esquinas/spawns (opcionales — no usadas en _ready actual)
func _corner_tiles(grid_wh: Vector2i, m: int) -> Dictionary:
	var gw := grid_wh.x; var gh := grid_wh.y
	var mm: int = clamp(m, 0, max(0, min(gw, gh) - 1))
	return {
		"top_left": Vector2i(mm,mm),
		"top_right": Vector2i(max(0,gw-1-mm), mm),
		"bottom_left": Vector2i(mm, max(0,gh-1-mm)),
		"bottom_right": Vector2i(max(0,gw-1-mm), max(0,gh-1-mm))
	}

func _opposite(c:String)->String:
	match c:
		"top_left": return "bottom_right"
		"bottom_right": return "top_left"
		"top_right": return "bottom_left"
		"bottom_left": return "top_right"
		_: return "bottom_right"

func _pick_corners(grid_wh: Vector2i) -> Dictionary:
	var c := _corner_tiles(grid_wh, margin_tiles)
	var keys := ["top_left", "top_right", "bottom_left", "bottom_right"]

	# Selección del inicio
	var s: String = keys[randi() % keys.size()] if start_corner == "random" else start_corner

	# Selección del final
	var e: String
	if end_corner == "opposite":
		e = _opposite(s)
	elif end_corner == "random":
		var pool := []
		for k in keys:
			if k != s:
				pool.append(k)
		e = pool[randi() % pool.size()]
	else:
		e = end_corner

	return {
		"start_tile": c[s],
		"end_tile": c[e],
		"start_key": s,
		"end_key": e
	}

# Instancia player y door si faltan
func _spawn_nodes_if_needed() -> bool:
	var ok: bool = true
	if player == null:
		if player_scene:
			player = player_scene.instantiate() as Node2D
			if player: add_child(player)
			else: ok = false
		else:
			ok = false
	if door == null:
		if door_scene:
			door = door_scene.instantiate() as Node2D
			if door: add_child(door)
			else: ok = false
		else:
			ok = false
	return ok

# Posiciona usando tiles de inicio/fin
func _place_from_tiles(start_tile: Vector2i, end_tile: Vector2i) -> void:
	if not _spawn_nodes_if_needed():
		push_error("No se pudo instanciar player o door.")
		return
	await get_tree().process_frame
	if player:
		player.global_position = _tile_center_world(start_tile)
	if door:
		door.global_position = _tile_center_world(end_tile)

# Versión equivalente (mantengo por compatibilidad)
func _place(start_tile: Vector2i, end_tile: Vector2i) -> void:
	if not _spawn_nodes_if_needed():
		return
	await get_tree().process_frame
	if player:
		player.global_position = _tile_center_world(start_tile)
	else:
		push_error("player es null al posicionar.")
	if door:
		door.global_position = _tile_center_world(end_tile)
	else:
		push_error("door es null al posicionar.")


# ============================================================
# 🚀 CICLO DE VIDA (ready)
# ============================================================

func _ready() -> void:
	# Alinear TileMap y capas al origen
	$TileMap.position = Vector2.ZERO
	if wall:    wall.position = Vector2.ZERO
	if ground:  ground.position = Vector2.ZERO
	if objects: objects.position = Vector2.ZERO

	# 1) Paredes
	fill_walls()

	# 2) Suelo procedural
	var gen: Dictionary = generate_ground()
	var start_tile: Vector2i = gen["start_tile"] as Vector2i
	var end_tile: Vector2i = gen["end_tile"] as Vector2i

	# 3) Instanciar y ubicar player/door
	_place_from_tiles(start_tile, end_tile)
