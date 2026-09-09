## Level2.gd — La Casa Maya (Objetos del hogar)
## Palabras: mayak(Mesa), lak(Plato), chan(Silla)
## Dificultad: 6 obstáculos — rutas verificadas con BFS
extends "res://scripts/world1/WordPathLevel.gd"

func _setup_data() -> void:
	LEVEL_TITLE = "Nivel 2 — La Casa Maya (Objetos)"
	LEVEL_WORLD = 1
	LEVEL_NUM   = 2

	WORDS = [
		{ "id": 0, "maya": "mayak",  "spanish": "Mesa",   "emoji": "🪑",
		  "grid_pos": Vector2i(0,1), "house_pos": Vector2i(8,1),
		  "color": Color(0.85, 0.42, 0.18),
		  "estructura": "Ti' yaan jun mayak",
		  "traduccion":  "Hay una mesa" },
		{ "id": 1, "maya": "lak",    "spanish": "Plato",  "emoji": "🍽️",
		  "grid_pos": Vector2i(0,3), "house_pos": Vector2i(8,3),
		  "color": Color(0.30, 0.55, 0.82),
		  "estructura": "Ti' yaan jun lak",
		  "traduccion":  "Hay un plato" },
		{ "id": 2, "maya": "chan",   "spanish": "Silla",  "emoji": "💺",
		  "grid_pos": Vector2i(0,5), "house_pos": Vector2i(8,5),
		  "color": Color(0.22, 0.62, 0.28),
		  "estructura": "Ti' yaan jun chan",
		  "traduccion":  "Hay una silla" },
	]

	# 6 obstáculos — BFS confirma 3 rutas no solapadas
	OBSTACLES = [
		Vector2i(2,1), Vector2i(6,1),   # bloquean fila de mayak
		Vector2i(1,3), Vector2i(5,3),   # bloquean fila de lak
		Vector2i(3,5), Vector2i(7,5),   # bloquean fila de chan
	]
