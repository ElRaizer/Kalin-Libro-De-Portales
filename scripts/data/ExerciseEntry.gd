extends Resource
class_name ExerciseEntry

@export var maya := ""
@export var spanish := ""
@export var emoji := ""
@export var symbol := ""
@export var animal := ""
@export var animal_spanish := ""
@export_file("*.svg", "*.png", "*.webp") var sprite := ""
var animal_spr := ""
@export var request := ""
var peticion := ""
@export var color := Color.WHITE
@export var first_value := ""
@export var second_value := ""
var noun := ""
var adjective := ""
var food := ""
var modifier := ""
@export var phrase := ""
@export var translation := ""
@export var section := ""
@export_multiline var prompt := ""
@export var clue := ""
@export var correct := ""
@export var options: Array[String] = []
@export var learn := ""

static func from_dictionary(data: Dictionary) -> ExerciseEntry:
	var entry := ExerciseEntry.new()
	entry.maya = str(data.get("maya", ""))
	entry.spanish = str(data.get("spanish", ""))
	entry.emoji = str(data.get("emoji", ""))
	entry.symbol = str(data.get("symbol", ""))
	entry.animal = str(data.get("animal", ""))
	entry.animal_spanish = str(data.get("animal_spanish", ""))
	entry.sprite = str(data.get("sprite", data.get("animal_spr", "")))
	entry.animal_spr = entry.sprite
	entry.request = str(data.get("request", data.get("peticion", "")))
	entry.peticion = entry.request
	entry.color = data.get("color", Color.WHITE)
	entry.first_value = str(data.get("noun", data.get("food", "")))
	entry.second_value = str(data.get("adjective", data.get("modifier", "")))
	entry.noun = str(data.get("noun", ""))
	entry.adjective = str(data.get("adjective", ""))
	entry.food = str(data.get("food", ""))
	entry.modifier = str(data.get("modifier", ""))
	entry.phrase = str(data.get("phrase", ""))
	entry.translation = str(data.get("translation", ""))
	entry.section = str(data.get("section", ""))
	entry.prompt = str(data.get("prompt", ""))
	entry.clue = str(data.get("clue", ""))
	entry.correct = str(data.get("correct", ""))
	entry.options.assign(data.get("options", []))
	entry.learn = str(data.get("learn", ""))
	return entry

static func from_dictionaries(values: Array[Dictionary]) -> Array[ExerciseEntry]:
	var entries: Array[ExerciseEntry] = []
	for value: Dictionary in values:
		entries.append(from_dictionary(value))
	return entries
