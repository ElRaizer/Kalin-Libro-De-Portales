extends RefCounted
class_name GameSession

## Dueño del progreso mutable. No conoce SceneTree, nodos, archivos ni UI.
var magic_points: int = 0
var economy: Dictionary = MagicEconomy.empty_state()
var garden: Dictionary = GardenLayout.empty_state()
var village_visit: Dictionary = {}
var village_experiences: Dictionary = VillageNeighbours.empty_experiences()
var _personal_album: Array[Dictionary] = []
var rest_corner: Dictionary = RestCornerState.empty_state()
var laboratory_favorites: Array[String] = []
var garden_identity: Dictionary = {}
var garden_compositions: Dictionary = {}
var snack_project: Dictionary = SnackState.empty_state()
var village_expansion: Dictionary = VillageExpansion.empty_state()
var words_learned: Dictionary = {}
var completed_levels: Array[String] = []
var resume_scene_key: String = ""
var practice_return_key: String = ""
var scene_states: Dictionary = {}
var tutorials_seen: Array[String] = []
var learning_progress: Dictionary = {}
var learning_clock: int = 0


func snapshot() -> Dictionary:
	return (
		{
			"version": SaveSchema.CURRENT_VERSION,
			"magic_points": magic_points,
			"economy": economy,
			"garden": garden,
			"village_visit": village_visit,
			"village_experiences": village_experiences,
			"personal_album": _personal_album,
			"rest_corner": rest_corner,
			"laboratory_favorites": laboratory_favorites,
			"garden_identity": garden_identity,
			"garden_compositions": garden_compositions,
			"snack_project": snack_project,
			"village_expansion": village_expansion,
			"words_learned": words_learned,
			"completed_levels": completed_levels,
			"resume_scene_key": resume_scene_key,
			"practice_return_key": practice_return_key,
			"scene_states": scene_states,
			"tutorials_seen": tutorials_seen,
			"learning_progress": learning_progress,
			"learning_clock": learning_clock,
		}
		. duplicate(true)
	)


## La validación termina antes de modificar ningún campo; false conserva
## íntegro el progreso anterior. El resultado normalizado tampoco comparte datos.
func restore(data: Dictionary) -> bool:
	var validated: Dictionary = SaveSchema.validate(data)
	if validated.has("_load_error"):
		return false
	var state: Dictionary = SessionCodec.decode(validated)
	magic_points = state.magic_points
	economy = state.economy
	garden = state.garden
	village_visit = state.village_visit
	village_experiences = state.village_experiences
	_personal_album.assign(state.personal_album)
	rest_corner = state.rest_corner
	laboratory_favorites.assign(state.laboratory_favorites)
	garden_identity = state.garden_identity
	garden_compositions = state.garden_compositions
	snack_project = state.snack_project
	village_expansion = state.village_expansion
	words_learned = state.words_learned
	completed_levels.assign(state.completed_levels)
	resume_scene_key = state.resume_scene_key
	practice_return_key = state.practice_return_key
	scene_states = state.scene_states
	tutorials_seen.assign(state.tutorials_seen)
	learning_progress = state.learning_progress
	learning_clock = state.learning_clock
	return true


func reset() -> void:
	magic_points = 0
	economy = MagicEconomy.empty_state()
	garden = GardenLayout.empty_state()
	village_visit = {}
	village_experiences = VillageNeighbours.empty_experiences()
	_personal_album.clear()
	rest_corner = RestCornerState.empty_state()
	laboratory_favorites.clear()
	garden_identity.clear()
	garden_compositions.clear()
	snack_project = SnackState.empty_state()
	village_expansion = VillageExpansion.empty_state()
	words_learned.clear()
	completed_levels.clear()
	resume_scene_key = ""
	practice_return_key = ""
	scene_states.clear()
	tutorials_seen.clear()
	learning_progress.clear()
	learning_clock = 0


func personal_moment_count() -> int:
	return _personal_album.size()


func personal_moments() -> Array[Dictionary]:
	return _personal_album.duplicate(true)


func album_with_moment(moment: Dictionary, replacement: int = -1) -> Array[Dictionary]:
	var candidate: Array[Dictionary] = personal_moments()
	if not PersonalAlbum.valid_moment(moment, words_learned):
		return []
	if replacement == -1 and candidate.size() < PersonalAlbum.LIMIT:
		candidate.append(moment.duplicate(true))
	elif replacement in range(candidate.size()):
		candidate[replacement] = moment.duplicate(true)
	else:
		return []
	return candidate


func album_without_moment(index: int) -> Array[Dictionary]:
	var candidate: Array[Dictionary] = personal_moments()
	candidate.remove_at(index)
	return candidate


func apply_personal_album(candidate: Array[Dictionary]) -> void:
	_personal_album.assign(candidate.duplicate(true))


func learn_word(key: String) -> bool:
	if key not in GameContent.VOCABULARY or key in words_learned:
		return false
	words_learned[key] = VocabularyCatalog.entry(key)
	return true


func complete_level(world: int, level: int) -> bool:
	var key: String = "w%d_l%d" % [world, level]
	if key in completed_levels:
		return false
	var exists: bool = false
	for entry: Dictionary in GameContent.LEVEL_ORDER:
		if entry.world == world and entry.level == level:
			exists = true
			break
	if not exists:
		return false
	completed_levels.append(key)
	return true


func is_level_completed(world: int, level: int) -> bool:
	return "w%d_l%d" % [world, level] in completed_levels


func next_unlocked_scene() -> String:
	for level: Dictionary in GameContent.LEVEL_ORDER:
		if not is_level_completed(level.world, level.level):
			return level.scene_key
	return "main_menu"


func recovered_word_count() -> int:
	var count: int = 0
	for word: String in words_learned:
		if word in GameContent.VOCABULARY and word not in GameContent.FUTURE_VOCABULARY:
			count += 1
	return count


func record_learning(
	words: Array,
	phase: String,
	context: String,
	supported: bool = false,
	mistakes: int = 0,
	evidence: Dictionary = {},
	award_points: bool = true
) -> Dictionary:
	var fresh: bool = false
	for word: String in words:
		var key: String = VocabularyCatalog.resolve(word)
		if (
			not key.is_empty()
			and context not in LearningProgress.sanitize(learning_progress.get(key)).contexts
		):
			fresh = true
	if not fresh:
		return {"changed": false, "learned": []}
	var learned: Array[String] = []
	var awarded: int = 0
	learning_clock += 1
	for word: String in words:
		var key: String = VocabularyCatalog.resolve(word)
		if key.is_empty():
			continue
		if learn_word(key):
			learned.append(key)
		var record: Dictionary = LearningProgress.sanitize(learning_progress.get(key))
		var detail: Dictionary = evidence.get(word, {})
		if (
			award_points
			and context not in record.contexts
			and key in VocabularyCatalog.learnable_keys()
		):
			var word_phase: String = str(detail.get("phase", phase))
			var amount: int = MagicEconomy.reward(word_phase, supported, detail)
			var previous: int = int(economy.awards.get(key, 0))
			var difference: int = maxi(0, amount - previous)
			if (
				previous > 0
				and learning_clock - int(record.last_seen) < LearningProgress.RECALL_GAP
			):
				difference = 0
			if difference > 0:
				economy.awards[key] = amount
				magic_points += difference
				awarded += difference
		LearningProgress.record_result(
			record, phase, context, supported, mistakes, learning_clock, evidence.get(word, {})
		)
		learning_progress[key] = record
	return {"changed": true, "learned": learned, "awarded": awarded}


func prepare_sharing_corner() -> bool:
	if MagicEconomy.FIRST_PROJECT in economy.preparations:
		return false
	for word: String in MagicEconomy.FIRST_DESIGNS:
		if word not in words_learned or int(economy.awards.get(word, 0)) < 4:
			return false
	economy.preparations.append(MagicEconomy.FIRST_PROJECT)
	magic_points += MagicEconomy.PREPARATION_POINTS
	return true


func purchase_design(word: String) -> bool:
	if not MagicEconomy.can_purchase(economy, word, words_learned, magic_points):
		return false
	magic_points -= MagicEconomy.DESIGN_PRICE
	economy.designs.append(word)
	return true


func set_laboratory_favorite(id: String, enabled: bool, limit: int) -> bool:
	if not enabled:
		if id not in laboratory_favorites:
			return false
		laboratory_favorites.erase(id)
		return true
	if (
		limit < 1
		or limit > LaboratoryState.MAX_FAVORITES
		or laboratory_favorites.size() >= limit
		or id in laboratory_favorites
		or not LaboratoryState.known_combination(id, words_learned)
	):
		return false
	laboratory_favorites.append(id)
	return true


func purchase_combination_designs(id: String) -> bool:
	var missing: Array[String] = MagicEconomy.missing_designs(economy, id)
	if missing.is_empty() or not LaboratoryState.known_combination(id, words_learned):
		return false
	var candidate: Dictionary = economy.duplicate(true)
	var remaining: int = magic_points
	for word: String in missing:
		if not MagicEconomy.can_purchase(candidate, word, words_learned, remaining):
			return false
		candidate.designs.append(word)
		remaining -= MagicEconomy.DESIGN_PRICE
	economy = candidate
	magic_points = remaining
	return true


func confirm_sharing_corner(id: String) -> bool:
	if economy.built or id != "mayak|chich":
		return false
	if not MagicEconomy.can_build(economy, id, words_learned):
		return false
	economy.built = true
	return true


func create_garden_object(id: String, district: String) -> int:
	if not MagicEconomy.can_build(economy, id, words_learned):
		return 0
	return GardenLayout.add_object(garden, id, district)


func set_garden_identity(district: String, title: String, decorations: Array[String]) -> bool:
	var candidate: Dictionary = garden_identity.duplicate(true)
	candidate[district] = {"name": title, "decorations": decorations.duplicate()}
	if not GardenIdentity.valid_state(candidate, rest_corner.complete):
		return false
	garden_identity = candidate
	return true


func select_snack(guests: Array[String], food: String, decoration: String) -> bool:
	if (
		not has_finished_adventure()
		or not snack_project.preparation.is_empty()
		or snack_project.complete
	):
		return false
	var candidate: Dictionary = snack_project.duplicate(true)
	candidate.guests = guests.duplicate()
	candidate.food = food
	candidate.decoration = decoration
	if not SnackState.valid_state(candidate, words_learned, scene_states):
		return false
	snack_project = candidate
	return true


func begin_snack_preparation() -> bool:
	if (
		not has_finished_adventure()
		or snack_project.guests.is_empty()
		or snack_project.food.is_empty()
		or not snack_project.preparation.is_empty()
	):
		return false
	var activity: CountingActivity = CountingActivity.new()
	activity.setup(SnackState.counting_set(), {}, SnackState.targets(snack_project.guests))
	snack_project.preparation = activity.snapshot()
	return true


func update_snack_preparation(state: Dictionary) -> bool:
	if snack_project.complete or snack_project.preparation.is_empty():
		return false
	var candidate: Dictionary = snack_project.duplicate(true)
	candidate.preparation = state.duplicate(true)
	if not SnackState.valid_state(candidate, words_learned, scene_states):
		return false
	if int(state.counting.round) < int(snack_project.preparation.counting.round):
		return false
	snack_project = candidate
	return true


func confirm_snack_project() -> bool:
	if (
		snack_project.complete
		or snack_project.preparation.is_empty()
		or int(snack_project.preparation.counting.round) != 2
	):
		return false
	snack_project.complete = true
	return true


func expansion_ready() -> bool:
	return rest_corner.complete and snack_project.complete and has_finished_adventure()


func try_expansion(purpose: String) -> bool:
	if not expansion_ready() or purpose not in VillageExpansion.PURPOSES:
		return false
	if purpose not in village_expansion.tried:
		village_expansion.tried.append(purpose)
	village_expansion.purpose = purpose
	return true


func select_expansion_guests(guests: Array[String]) -> bool:
	if not expansion_ready() or not VillageExpansion.valid_guests(guests, words_learned, false):
		return false
	village_expansion.guests = guests.duplicate()
	return true


func inaugurate_expansion() -> bool:
	if (
		not expansion_ready()
		or village_expansion.complete
		or village_expansion.tried.size() != 2
		or village_expansion.purpose not in VillageExpansion.PURPOSES
		or not VillageExpansion.valid_guests(village_expansion.guests, words_learned, false)
		or not VillageGround.extension_accessible(garden, GameContent.VILLAGE_SPACES.space("shore"))
	):
		return false
	village_expansion.opening = {
		"purpose": village_expansion.purpose, "guests": village_expansion.guests.duplicate()
	}
	village_expansion.complete = true
	return true


func save_garden_composition(district: String, slot: int, capacity: int) -> bool:
	if (
		district not in GardenIdentity.DISTRICTS
		or capacity < 1
		or capacity > GardenCompositions.MAX_SLOTS
		or slot < 0
		or slot >= capacity
	):
		return false
	var candidate: Dictionary = garden_compositions.duplicate(true)
	var slots: Array = candidate.get(district, [])
	while slots.size() <= slot:
		slots.append({})
	slots[slot] = GardenCompositions.capture(garden, district)
	candidate[district] = slots
	if not GardenCompositions.valid_state(
		candidate,
		words_learned,
		int(garden.next_id),
		GameContent.VILLAGE_SPACES,
		village_expansion.complete
	):
		return false
	garden_compositions = candidate
	return true


func apply_garden_composition(district: String, slot: int) -> String:
	var slots: Array = garden_compositions.get(district, [])
	if slot < 0 or slot >= slots.size() or slots[slot].is_empty():
		return "Ese acomodo todavía no está guardado."
	var result: Dictionary = GardenCompositions.apply(
		garden, district, slots[slot], GameContent.VILLAGE_SPACES, village_expansion.complete
	)
	if result.has("error"):
		return result.error
	if not replace_garden_layout(result.garden):
		return "Hay una visita usando el mueble. Despídela antes de cambiar el acomodo."
	return ""


func delete_garden_copy(id: int) -> String:
	var object: Dictionary = GardenLayout.object_by_id(garden, id)
	if object.is_empty():
		return "Esa copia ya no está en tu jardín ni en el almacén."
	for child: Dictionary in garden.objects:
		if int(child.support) == id:
			return "La mesa tiene un plato apoyado. Retira primero el plato."
	var candidate: Dictionary = garden.duplicate(true)
	for index: int in range(candidate.objects.size()):
		if int(candidate.objects[index].id) == id:
			candidate.objects.remove_at(index)
			break
	if not replace_garden_layout(candidate):
		return "Un invitado está usando esa copia. Despídelo antes de eliminarla."
	return ""


func _valid_garden_layout(candidate: Dictionary) -> bool:
	if not GardenLayout.valid_state(
		candidate, GameContent.VILLAGE_SPACES, village_expansion.complete
	):
		return false
	if (
		village_expansion.complete
		and not VillageGround.extension_accessible(
			candidate, GameContent.VILLAGE_SPACES.space("shore")
		)
	):
		return false
	for object: Dictionary in candidate.objects:
		if not MagicEconomy.can_build(economy, object.key, words_learned):
			return false
	return true


func replace_garden_layout(candidate: Dictionary) -> bool:
	if not _valid_garden_layout(candidate):
		return false
	if not village_visit.is_empty():
		var id: int = int(village_visit.object_id)
		var before_group: Array[Dictionary] = []
		var after_group: Array[Dictionary] = []
		for object: Dictionary in garden.objects:
			if int(object.id) == id or int(object.support) == id:
				before_group.append(object)
		for object: Dictionary in candidate.objects:
			if int(object.id) == id or int(object.support) == id:
				after_group.append(object)
		if before_group != after_group:
			return false
	var next_id: int = maxi(int(garden.next_id), int(candidate.next_id))
	garden = candidate.duplicate(true)
	garden.next_id = next_id
	return true


func place_new_garden_object(
	key: String, location: Vector2, district: String, orientation: int, support: int = 0
) -> int:
	if (
		not MagicEconomy.can_build(economy, key, words_learned)
		or (not economy.built and key != "mayak|chich")
		or orientation < 0
		or orientation > 3
		or district not in ["patio", "workshop", "shore"]
	):
		return 0
	var candidate: Dictionary = garden.duplicate(true)
	var id: int = GardenLayout.add_object(candidate, key, district)
	if id == 0:
		return 0
	GardenLayout.object_by_id(candidate, id).orientation = orientation
	if support != 0:
		if GardenLayout.object_by_id(candidate, support).get("district", "") != district:
			return 0
		if not GardenLayout.put_on_table(candidate, id, support):
			return 0
	elif not GardenLayout.move_object(
		candidate,
		id,
		location,
		district,
		GameContent.VILLAGE_SPACES.space(district),
		village_expansion.complete
	):
		return 0
	if not replace_garden_layout(candidate):
		return 0
	confirm_sharing_corner(key)
	return id


func place_garden_object(
	id: int, location: Vector2, district: String, orientation: int = -1
) -> bool:
	var candidate: Dictionary = garden.duplicate(true)
	var object: Dictionary = GardenLayout.object_by_id(candidate, id)
	if object.is_empty() or orientation < -1 or orientation > 3:
		return false
	if orientation >= 0:
		object.orientation = orientation
	if not GardenLayout.move_object(
		candidate,
		id,
		location,
		district,
		GameContent.VILLAGE_SPACES.space(district),
		village_expansion.complete
	):
		return false
	if not _valid_garden_layout(candidate):
		return false
	garden = candidate
	confirm_sharing_corner(str(GardenLayout.object_by_id(garden, id).key))
	if int(village_visit.get("object_id", 0)) == id:
		end_village_visit()
	return true


func begin_village_visit(animal: String, id: int, duration: float) -> bool:
	if not village_visit.is_empty():
		return false
	var candidate: Dictionary = {"animal": animal, "object_id": id, "remaining": duration}
	if not VillageVisitState.valid_state(
		candidate, garden, words_learned, has_finished_adventure()
	):
		return false
	village_visit = candidate
	return true


func has_finished_adventure() -> bool:
	return RestCornerState.has_homecoming(scene_states)


func advance_rest_intro() -> bool:
	if not has_finished_adventure() or int(rest_corner.intro) >= RestCornerState.INTRO_STEPS:
		return false
	rest_corner.intro = int(rest_corner.intro) + 1
	return true


func finish_rest_intro() -> bool:
	if not has_finished_adventure() or int(rest_corner.intro) >= RestCornerState.INTRO_STEPS:
		return false
	rest_corner.intro = RestCornerState.INTRO_STEPS
	return true


func choose_rest_corner(word: String) -> bool:
	if (
		not has_finished_adventure()
		or int(rest_corner.intro) != RestCornerState.INTRO_STEPS
		or rest_corner.complete
		or word not in RestCornerState.WORDS
		or word not in words_learned
	):
		return false
	rest_corner.choice = word
	return true


func confirm_rest_corner() -> bool:
	if (
		not has_finished_adventure()
		or rest_corner.complete
		or int(rest_corner.intro) != RestCornerState.INTRO_STEPS
		or rest_corner.choice not in RestCornerState.WORDS
		or rest_corner.choice not in words_learned
	):
		return false
	rest_corner.complete = true
	if garden_identity.has("patio") and "gathering" not in garden_identity.patio.decorations:
		garden_identity.patio.decorations.append("gathering")
	return true


func advance_rest_result() -> bool:
	if not rest_corner.complete or int(rest_corner.result) >= RestCornerState.RESULT_STEPS:
		return false
	rest_corner.result = int(rest_corner.result) + 1
	return true


func confirm_village_guest(animal: String) -> bool:
	var hosted: bool = not village_visit.is_empty() and animal == village_visit.animal
	var feeding_kay: bool = animal == "Kay" and snack_project.complete and animal in words_learned
	if not (hosted or feeding_kay):
		return false
	if animal not in village_experiences.visits:
		village_experiences.visits.append(animal)
	return true


func confirm_clearing_reunion() -> bool:
	if not village_expansion.complete:
		return false
	for animal: String in village_expansion.guests:
		if animal not in village_experiences.clearing:
			village_experiences.clearing.append(animal)
	return true


func archive_deliveries(scene: String, state: Dictionary) -> void:
	if scene not in VillageNeighbours.MISSIONS:
		return
	for animal: String in VillageNeighbours.delivered_residents(state):
		if animal in words_learned and animal not in village_experiences.deliveries:
			village_experiences.deliveries.append(animal)


func received_village_delivery(animal: String) -> bool:
	if animal in village_experiences.deliveries:
		return true
	for key: String in VillageNeighbours.MISSIONS:
		var state: Variant = scene_states.get(key, {})
		if state is Dictionary and animal in VillageNeighbours.delivered_residents(state):
			return true
	return false


func hosted_village_guest(animal: String) -> bool:
	return animal in village_experiences.visits


func advance_village_visit(delta: float) -> bool:
	if village_visit.is_empty() or not is_finite(delta) or delta <= 0:
		return false
	village_visit.remaining = maxf(0, float(village_visit.remaining) - delta)
	if float(village_visit.remaining) <= 0:
		return end_village_visit()
	return false


func end_village_visit() -> bool:
	if village_visit.is_empty():
		return false
	village_visit = {}
	return true


func unlocked_village_world() -> int:
	var world: int = 1
	for level: Dictionary in GameContent.LEVEL_ORDER:
		world = maxi(world, int(level.world))
		if not is_level_completed(level.world, level.level):
			break
	return world


## Consultar contenido fuera de la sala también pertenece al intento pendiente.
func mark_pending_challenge_help() -> bool:
	var saved: Variant = scene_states.get("village_home", {})
	if saved is not Dictionary or saved.get("challenge_room") is not Dictionary:
		return false
	var room: Dictionary = saved.challenge_room
	var index: Variant = room.get("index")
	if room.get("words") is not Array or not SaveSchema.is_number(index):
		return false
	if float(index) != floor(float(index)) or float(index) < 0 or float(index) >= room.words.size():
		return false
	if room.get("waiting") is bool and room.waiting:
		return false
	var attempt: LearningAttempt = LearningAttempt.new()
	attempt.restore(room.get("attempt"))
	if attempt.context.is_empty() or attempt.content_help:
		return false
	attempt.use_content_help()
	room.attempt = attempt.snapshot()
	return true
