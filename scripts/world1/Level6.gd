## Level6.gd — Los Guardianes del Monte (temática: animales)
## Palabras: Báalam(Jaguar), Kuuts(Pavo), T'u'ul(Conejo)
## Mecánica heredada de WordPathLevel. El "Siguiente" del padre
## lleva automáticamente a world1_level7.
extends "res://scripts/world1/WordPathLevel.gd"

func _setup_data() -> void:
	LEVEL_TITLE = "Nivel 6 — Los Guardianes del Monte"
	LEVEL_WORLD = 1
	LEVEL_NUM   = 6
	BG_PATH     = "res://Arte/backgrounds/bg_level_monte.svg"

	WORDS = [
		{ "id": 0, "maya": "Báalam", "spanish": "Jaguar", "emoji": "🐆",
		  "sprite": "res://Arte/sprites/animal_baalam.svg",
		  "grid_pos": Vector2i(0,1), "house_pos": Vector2i(8,1),
		  "color": Color(0.80, 0.55, 0.12),
		  "estructura": "In k'aaba'e' Báalam",
		  "traduccion":  "Me llamo Jaguar" },
		{ "id": 1, "maya": "Kuuts",  "spanish": "Pavo",   "emoji": "🦃",
		  "sprite": "res://Arte/sprites/animal_kuuts.svg",
		  "grid_pos": Vector2i(0,3), "house_pos": Vector2i(8,3),
		  "color": Color(0.38, 0.28, 0.55),
		  "estructura": "In k'aaba'e' Kuuts",
		  "traduccion":  "Me llamo Pavo" },
		{ "id": 2, "maya": "T'u'ul", "spanish": "Conejo", "emoji": "🐇",
		  "sprite": "res://Arte/sprites/animal_tuul.svg",
		  "grid_pos": Vector2i(0,5), "house_pos": Vector2i(8,5),
		  "color": Color(0.30, 0.55, 0.45),
		  "estructura": "In k'aaba'e' T'u'ul",
		  "traduccion":  "Me llamo Conejo" },
	]

	# Filas pares libres => siempre hay rodeo posible (BFS-seguro).
	OBSTACLES = [
		Vector2i(3,1), Vector2i(6,1),
		Vector2i(2,3), Vector2i(5,3), Vector2i(7,3),
		Vector2i(3,5), Vector2i(6,5),
	]
