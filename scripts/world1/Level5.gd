## Level5.gd — Los Animales del Bosque (temática: animales)
## Palabras: Kéej(Venado), K'éek'en(Cerdo), Ma'ax(Mono)
## Mecánica heredada de WordPathLevel (conectar palabra maya con su traducción).
## Es el nivel final por ahora: el botón "Siguiente" regresa al Menú Principal.
extends "res://scripts/world1/WordPathLevel.gd"

func _setup_data() -> void:
	LEVEL_TITLE = "Nivel 5 — Los Animales del Bosque"
	LEVEL_WORLD = 1
	LEVEL_NUM   = 5
	BG_PATH     = "res://Arte/backgrounds/bg_level_monte.svg"

	WORDS = [
		{ "id": 0, "maya": "Kéej",     "spanish": "Venado", "emoji": "🦌",
		  "sprite": "res://Arte/sprites/animal_keej.svg",
		  "grid_pos": Vector2i(0,1), "house_pos": Vector2i(8,1),
		  "color": Color(0.70, 0.45, 0.20),
		  "estructura": "In k'aaba'e' Kéej",
		  "traduccion":  "Me llamo Venado" },
		{ "id": 1, "maya": "K'éek'en", "spanish": "Cerdo",  "emoji": "🐷",
		  "sprite": "res://Arte/sprites/animal_keek_en.svg",
		  "grid_pos": Vector2i(0,3), "house_pos": Vector2i(8,3),
		  "color": Color(0.85, 0.45, 0.55),
		  "estructura": "In k'aaba'e' K'éek'en",
		  "traduccion":  "Me llamo Cerdo" },
		{ "id": 2, "maya": "Ma'ax",    "spanish": "Mono",   "emoji": "🐒",
		  "sprite": "res://Arte/sprites/animal_maax.svg",
		  "grid_pos": Vector2i(0,5), "house_pos": Vector2i(8,5),
		  "color": Color(0.45, 0.32, 0.20),
		  "estructura": "In k'aaba'e' Ma'ax",
		  "traduccion":  "Me llamo Mono" },
	]

	# Obstáculos solo en las filas de los animales; las filas pares (0,2,4,6)
	# quedan libres, así siempre hay una ruta de rodeo. BFS-seguro.
	OBSTACLES = [
		Vector2i(2,1), Vector2i(5,1),   # fila Kéej
		Vector2i(3,3), Vector2i(6,3),   # fila K'éek'en
		Vector2i(2,5), Vector2i(5,5),   # fila Ma'ax
	]
