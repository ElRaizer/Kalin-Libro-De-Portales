extends RefCounted
class_name VillageMissionState

## Progreso de los encargos; no conoce nodos, autoloads ni archivos.
var met: Array[int] = []
var delivered: Array[int] = []
var active_task: int = -1
var carried: Dictionary = {}
var task_support: Dictionary = {}
var task_mistakes: Dictionary = {}
var drafts: Dictionary = {}


func restore(saved: Dictionary, items: Array[String], qualities: Array[String]) -> void:
	carried.clear()
	drafts.clear()
	task_support.clear()
	task_mistakes.clear()
	met = ExerciseProgress.restore_markers(saved.get("mission_met"), 3)
	delivered = ExerciseProgress.restore_markers(saved.get("delivered"), 3)
	var active: Variant = saved.get("active_task", -1)
	active_task = -1
	if (active is int or active is float) and is_finite(float(active)):
		if float(active) == floor(float(active)):
			active_task = clampi(int(active), -1, 2)
	var supports: Dictionary = _object(saved.get("task_support"))
	var errors: Dictionary = _object(saved.get("task_mistakes"))
	var stored_drafts: Dictionary = _object(saved.get("drafts"))
	for index: int in range(3):
		var key: String = str(index)
		var support: Variant = supports.get(key, false)
		task_support[key] = support is bool and support
		var mistakes: Variant = errors.get(key, 0)
		task_mistakes[key] = _count(mistakes)
		var draft: Variant = stored_drafts.get(key)
		if draft is Dictionary:
			var attempt: LearningAttempt = LearningAttempt.new()
			attempt.restore(draft.get("attempt"))
			drafts[key] = {
				"item": _text(draft.get("item")),
				"quality": _text(draft.get("quality")),
				"cards": draft.get("cards") is bool and draft.cards,
				"scaffold":
				draft.get("scaffold", {}) if draft.get("scaffold") is Dictionary else {},
				"attempt": attempt.snapshot()
			}
	var candidate: Variant = saved.get("carried")
	if candidate is not Dictionary or candidate.get("item") is not String:
		return
	if candidate.get("quality", "") is not String:
		return
	if candidate.item not in items or candidate.get("quality", "") not in qualities:
		return
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.restore(candidate.get("attempt"))
	var phase: Variant = candidate.get("phase")
	carried = {
		"item": candidate.item,
		"quality": candidate.get("quality", ""),
		"supported": candidate.get("supported") is not bool or candidate.supported,
		"mistakes": _count(candidate.get("mistakes")),
		"phase": "reconstruction" if phase is String and phase == "reconstruction" else "recall",
		"attempt": attempt.snapshot()
	}


func accepts_delivery(index: int, item: String, quality: String) -> bool:
	return index in met and carried.get("item") == item and carried.get("quality") == quality


func snapshot() -> Dictionary:
	return (
		{
			"mission_met": met,
			"delivered": delivered,
			"active_task": active_task,
			"carried": carried,
			"task_support": task_support,
			"task_mistakes": task_mistakes,
			"drafts": drafts
		}
		. duplicate(true)
	)


static func _text(value: Variant) -> String:
	return value.left(100) if value is String else ""


static func _object(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _count(value: Variant) -> int:
	if (value is int or value is float) and is_finite(float(value)):
		if float(value) == floor(float(value)):
			return clampi(int(value), 0, 1000)
	return 0
