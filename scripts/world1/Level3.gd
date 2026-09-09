## Level3.gd — El Jardín de los Adjetivos
## Palabras: mejen(Pequeño), nojoch(Grande), ki'(Delicioso)
## Dificultad: 8 obstáculos — rutas verificadas con BFS
extends "res://scripts/world1/WordPathLevel.gd"

func _setup_data() -> void:
	LEVEL_TITLE = "Nivel 3 — Los Adjetivos Magicos"
	LEVEL_WORLD = 1
	LEVEL_NUM   = 3

	WORDS = [
		{ "id": 0, "maya": "mejen",  "spanish": "Pequeño", "emoji": "🔹",
		  "grid_pos": Vector2i(0,1), "house_pos": Vector2i(8,1),
		  "color": Color(0.82, 0.22, 0.22),
		  "estructura": "In peek'e' mejen",
		  "traduccion":  "Mi perro es pequeño" },
		{ "id": 1, "maya": "nojoch", "spanish": "Grande",  "emoji": "🔷",
		  "grid_pos": Vector2i(0,3), "house_pos": Vector2i(8,3),
		  "color": Color(0.55, 0.22, 0.82),
		  "estructura": "In peek'e' nojoch",
		  "traduccion":  "Mi perro es grande" },
		{ "id": 2, "maya": "ki'",    "spanish": "Delicioso","emoji": "😋",
		  "grid_pos": Vector2i(0,5), "house_pos": Vector2i(8,5),
		  "color": Color(0.82, 0.65, 0.10),
		  "estructura": "In janale' ki'",
		  "traduccion":  "Mi comida es deliciosa" },
	]

	# 8 obstáculos — desafío mayor, BFS confirma solución
	OBSTACLES = [
		Vector2i(2,1), Vector2i(5,1), Vector2i(7,1),  # fila mejen
		Vector2i(1,3), Vector2i(4,3), Vector2i(6,3),  # fila nojoch
		Vector2i(3,5), Vector2i(6,5),                 # fila ki'
	]
