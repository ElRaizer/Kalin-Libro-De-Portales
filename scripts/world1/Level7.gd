## Level7.gd — Agua y Cielo (temática: animales)
## Palabras: Kay(Pez), Ch'íich'(Pájaro), Aak'(Tortuga)
## Es el nivel final por ahora: "Siguiente" regresa al Menú Principal.
extends "res://scripts/world1/WordPathLevel.gd"

func _setup_data() -> void:
	LEVEL_TITLE = "Nivel 7 — Agua y Cielo"
	LEVEL_WORLD = 1
	LEVEL_NUM   = 7
	BG_PATH     = "res://Arte/backgrounds/bg_level_agua.svg"

	WORDS = [
		{ "id": 0, "maya": "Kay",      "spanish": "Pez",     "emoji": "🐟",
		  "sprite": "res://Arte/sprites/animal_kay.svg",
		  "grid_pos": Vector2i(0,1), "house_pos": Vector2i(8,1),
		  "color": Color(0.85, 0.45, 0.15),
		  "estructura": "In k'aaba'e' Kay",
		  "traduccion":  "Me llamo Pez" },
		{ "id": 1, "maya": "Ch'íich'", "spanish": "Pájaro",  "emoji": "🐦",
		  "sprite": "res://Arte/sprites/animal_chiich.svg",
		  "grid_pos": Vector2i(0,3), "house_pos": Vector2i(8,3),
		  "color": Color(0.16, 0.48, 0.58),
		  "estructura": "In k'aaba'e' Ch'íich'",
		  "traduccion":  "Me llamo Pájaro" },
		{ "id": 2, "maya": "Aak'",     "spanish": "Tortuga", "emoji": "🐢",
		  "sprite": "res://Arte/sprites/animal_aak.svg",
		  "grid_pos": Vector2i(0,5), "house_pos": Vector2i(8,5),
		  "color": Color(0.32, 0.52, 0.24),
		  "estructura": "In k'aaba'e' Aak'",
		  "traduccion":  "Me llamo Tortuga" },
	]

	OBSTACLES = [
		Vector2i(2,1), Vector2i(4,1), Vector2i(7,1),
		Vector2i(3,3), Vector2i(6,3),
		Vector2i(2,5), Vector2i(4,5), Vector2i(7,5),
	]

## Nivel final por ahora: regresar al menú.
func _on_next_level_pressed() -> void:
	_safe_navigate("main_menu")
