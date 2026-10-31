@tool
## Mundo 4, nivel 2 — Las piedras que cuentan.
## En el tianguis, los animales piden números sorteados del 1 al 50 y Kalin los
## escribe como los antiguos mayas: granos de cacao (1), varitas (5) y la concha
## del cero, en dos pisos (unidades abajo, veintenas arriba). Las reglas viven
## en CountingSession; este controlador sólo presenta y conecta la entrada.
extends Node2D

const COLOR_SUCCESS := Color("2e8b57")
const COLOR_ERROR := Color("b93c3c")
## Notas pentatónicas (semitonos) para que cada grano suene un poco más agudo.
const COUNT_NOTES: Array[int] = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

@export var content: CountingSet

var guide: LearningGuide
var _session: CountingSession = CountingSession.new()
var _help_stage: int = 0
var _navigating: bool = false

@onready var header: LevelHeader = $UI/LevelHeader
@onready var round_label: Label = $UI/RequestPanel/Content/RoundLabel
@onready var animal_sprite: TextureRect = $UI/RequestPanel/Content/AnimalSprite
@onready var animal_label: Label = $UI/RequestPanel/Content/AnimalLabel
@onready var target_label: Label = $UI/RequestPanel/Content/TargetNumber
@onready var hint_label: Label = $UI/RequestPanel/Content/HintLabel
@onready var upper_floor: Button = $UI/StagePanel/Tablet/UpperFloor
@onready var lower_floor: Button = $UI/StagePanel/Tablet/LowerFloor
@onready var upper_numeral: NumeralView = $UI/StagePanel/Tablet/UpperFloor/Numeral
@onready var lower_numeral: NumeralView = $UI/StagePanel/Tablet/LowerFloor/Numeral
@onready var dot_button: Button = $UI/StagePanel/Pieces/DotButton
@onready var bar_button: Button = $UI/StagePanel/Pieces/BarButton
@onready var shell_button: Button = $UI/StagePanel/Pieces/ShellButton
@onready var clear_button: Button = $UI/StagePanel/Pieces/ClearButton
@onready var feedback_label: Label = $UI/FeedbackPanel/FeedbackLabel
@onready var _feedback_color: Color = feedback_label.get_theme_color("font_color")
@onready var mission_progress: MissionProgress = $UI/MissionProgress
@onready var action_button: Button = $UI/ActionButton
@onready var completion: CompletionOverlay = $UI/CompletionOverlay
@onready var libro: CanvasLayer = $LibroHechizos


func _ready() -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return
	var issues: PackedStringArray = get_configuration_issues()
	if not issues.is_empty():
		push_error("Configuración incompleta: " + "; ".join(issues))
		return
	header.menu_pressed.connect(_on_menu_pressed)
	header.book_pressed.connect(_on_book_pressed)
	completion.next_pressed.connect(_on_next_pressed)
	completion.replay_pressed.connect(_on_replay_pressed)
	completion.menu_pressed.connect(_on_menu_pressed)
	action_button.pressed.connect(_on_action_pressed)
	upper_floor.pressed.connect(_on_floor_pressed.bind(MayaNumeral.Floor.TWENTIES))
	lower_floor.pressed.connect(_on_floor_pressed.bind(MayaNumeral.Floor.UNITS))
	dot_button.pressed.connect(_on_dot_pressed)
	bar_button.pressed.connect(_on_bar_pressed)
	shell_button.pressed.connect(_on_shell_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	guide = LearningGuide.install(self, $UI/LevelHeader/Bar, _show_help)
	var state: Dictionary = GameManager.get_scene_state(self)
	if not state.has("layout_seed"):
		state.layout_seed = randi_range(1, 2000000000)
	_session.restore(state, content)
	_show_round()


## Número que se busca en la ronda actual.
func current_target() -> int:
	return _session.target(content)


# ─── Rondas ──────────────────────────────────────────────────────────────────
func _show_round() -> void:
	guide.stop()
	_help_stage = 0
	if _session.is_finished(content.round_count):
		_finish_level()
		return
	var target: int = current_target()
	var requester: String = _session.requester(content)
	round_label.text = "Número %d de %d" % [_session.round_index + 1, content.round_count]
	animal_label.text = requester
	animal_sprite.texture = GameManager.get_visual_texture(requester)
	target_label.text = str(target)
	hint_label.text = (
		_breakdown(target) if _session.is_guided(content) else "Escríbelo con piezas mayas."
	)
	_set_feedback("Elige un piso de la tablilla y pon piezas.", _feedback_color)
	_set_pieces_enabled(true)
	action_button.text = "Comprobar ✦"
	action_button.disabled = false
	_refresh_tablet()
	_update_progress()
	if _session.waiting:
		_render_success(false)
	else:
		dot_button.grab_focus()
		if _session.round_index == 0 and "numbers" not in GameManager.session.tutorials_seen:
			call_deferred("_show_help")
	GameManager.checkpoint(self)


## Cómo se reparte el número entre los pisos, en palabras sencillas.
func _breakdown(number: int) -> String:
	var twenties: int = MayaNumeral.twenties_of(number)
	var units: int = MayaNumeral.units_of(number)
	var below: String = (
		"la concha del cero" if units == 0 else "%d (%s)" % [units, _pieces_text(units)]
	)
	if twenties == 0:
		return "%d = %s" % [number, _pieces_text(units)]
	return (
		"%d = %d %s arriba y %s abajo"
		% [number, twenties, "veintena" if twenties == 1 else "veintenas", below]
	)


func _pieces_text(units: int) -> String:
	var bars: int = MayaNumeral.bars_of(units)
	var dots: int = MayaNumeral.dots_of(units)
	var parts: PackedStringArray = []
	if bars > 0:
		parts.append("%d %s" % [bars, "varita" if bars == 1 else "varitas"])
	if dots > 0:
		parts.append("%d %s" % [dots, "grano" if dots == 1 else "granos"])
	return " y ".join(parts)


# ─── Entrada ─────────────────────────────────────────────────────────────────
func _on_floor_pressed(selected: MayaNumeral.Floor) -> void:
	if _session.waiting:
		_refresh_tablet()
		return
	guide.stop()
	_session.select_floor(selected)
	AudioManager.play_sfx("palabra_tomar")
	_set_feedback(
		(
			"Piso de arriba: cada grano vale veinte."
			if selected == MayaNumeral.Floor.TWENTIES
			else "Piso de abajo: granos de uno y varitas de cinco."
		),
		_feedback_color
	)
	_refresh_tablet()
	GameManager.checkpoint(self)


func _on_dot_pressed() -> void:
	_place(_session.add_dot)


func _on_bar_pressed() -> void:
	_place(_session.add_bar)


func _on_shell_pressed() -> void:
	_place(_session.add_shell)


func _place(action: Callable) -> void:
	if _session.waiting:
		return
	guide.stop()
	var result: CountingSession.Placement = action.call()
	match result:
		CountingSession.Placement.ADDED:
			var note: int = COUNT_NOTES[mini(_session.units, COUNT_NOTES.size() - 1)]
			AudioManager.play_sfx("camino_trazo", pow(2.0, note / 12.0))
		CountingSession.Placement.MERGED:
			AudioManager.play_sfx("chispas_magia")
			_set_feedback("¡Cinco granos se juntan en una varita!", _feedback_color)
		CountingSession.Placement.CARRIED:
			AudioManager.play_sfx("portal_energia")
			_set_feedback(
				"¡Veinte suben como un grano al piso de arriba! Lo que sobra se queda abajo.",
				_feedback_color
			)
		CountingSession.Placement.SHELL:
			AudioManager.play_sfx("palabra_soltar")
			_set_feedback("La concha marca que en este piso no hay nada: cero.", _feedback_color)
		CountingSession.Placement.FULL:
			AudioManager.play_sfx("camino_bloqueado")
			_set_feedback(
				(
					"En el piso de arriba caben hasta %d granos." % MayaNumeral.MAX_TWENTIES
					if _session.active_floor == MayaNumeral.Floor.TWENTIES
					else "La tablilla ya está llena. Borra y vuelve a contar."
				),
				COLOR_ERROR
			)
		CountingSession.Placement.SHELL_TAKEN:
			AudioManager.play_sfx("camino_bloqueado")
			_set_feedback("La concha va en el piso de abajo cuando está vacío.", COLOR_ERROR)
	_refresh_tablet()
	GameManager.checkpoint(self)


func _on_clear_pressed() -> void:
	if _session.waiting:
		return
	_session.clear_numeral()
	_refresh_tablet()
	AudioManager.play_sfx("camino_borrar")
	GameManager.checkpoint(self)


func _on_action_pressed() -> void:
	if _navigating or _session.is_finished(content.round_count):
		return
	if _session.waiting:
		_session.next_round()
		_show_round()
		return
	var target: int = current_target()
	if _session.is_solved(target):
		_resolve()
		return
	_session.miss()
	AudioManager.play_sfx("error_suave")
	CharacterReaction.play(animal_sprite, false)
	_set_feedback(_mistake_hint(target), COLOR_ERROR)
	if _session.mistakes >= 2:
		_help_stage = 2
		_show_help()
	GameManager.checkpoint(self)


func _mistake_hint(target: int) -> String:
	var built: int = _session.numeral_value()
	if built == target:
		return "Ya vale %d, pero el piso de abajo está vacío: pon la concha del cero." % target
	if (
		_session.twenties != MayaNumeral.twenties_of(target)
		and _session.units == MayaNumeral.units_of(target)
	):
		return "Abajo está bien. Revisa el piso de arriba: cada grano vale veinte."
	return (
		"Tu numeral vale %d y buscas %d: %s."
		% [built, target, "agrega piezas" if built < target else "quita piezas"]
	)


# ─── Acierto ─────────────────────────────────────────────────────────────────
func _resolve() -> void:
	AudioManager.play_sfx("acierto")
	GameManager.mark_tutorial_seen("numbers")
	_render_success(true)


func _render_success(animate: bool) -> void:
	_session.waiting = true
	guide.stop()
	var target: int = current_target()
	_set_feedback("✓ ¡Así escribían los mayas el %d!" % target, COLOR_SUCCESS)
	_set_pieces_enabled(false)
	_refresh_tablet()
	action_button.text = "Continuar →"
	action_button.disabled = false
	action_button.grab_focus()
	mission_progress.update_progress(
		_session.round_index + 1,
		content.round_count,
		"El tianguis · %d / %d · ¡Listo!" % [_session.round_index + 1, content.round_count]
	)
	if animate:
		CharacterReaction.play(animal_sprite)
		guide.watch_continue(action_button)
	GameManager.checkpoint(self)


func _finish_level() -> void:
	guide.stop()
	_set_pieces_enabled(false)
	action_button.disabled = true
	GameManager.complete_level(4, 2)
	completion.show_completion(
		"¡Ya cuentas como los mayas!",
		"Escribiste números con granos, varitas y la concha del cero.",
		"Al portal →"
	)
	GameManager.checkpoint(self)


# ─── Presentación ────────────────────────────────────────────────────────────
func _refresh_tablet() -> void:
	upper_numeral.show_value(_session.twenties)
	lower_numeral.show_value(_session.units, _session.shell)
	upper_floor.set_pressed_no_signal(_session.active_floor == MayaNumeral.Floor.TWENTIES)
	lower_floor.set_pressed_no_signal(_session.active_floor == MayaNumeral.Floor.UNITS)
	var upper: bool = _session.active_floor == MayaNumeral.Floor.TWENTIES
	bar_button.disabled = _session.waiting or upper
	shell_button.disabled = _session.waiting or upper


func _set_pieces_enabled(enabled: bool) -> void:
	for button: Button in [upper_floor, lower_floor, dot_button, bar_button, shell_button]:
		button.disabled = not enabled
	clear_button.disabled = not enabled


func _show_help() -> void:
	if _session.is_finished(content.round_count) or _navigating:
		return
	if _session.waiting:
		guide.point_at(action_button)
		return
	guide.click_at(_help_target(current_target()))
	_help_stage += 1


## El siguiente control que acerca la tablilla al número buscado.
func _help_target(target: int) -> Control:
	var wanted_twenties: int = MayaNumeral.twenties_of(target)
	var wanted_units: int = MayaNumeral.units_of(target)
	if _session.twenties > wanted_twenties or _session.units > wanted_units:
		return clear_button
	if _session.twenties < wanted_twenties:
		if _session.active_floor != MayaNumeral.Floor.TWENTIES:
			return upper_floor
		return dot_button
	if _session.active_floor != MayaNumeral.Floor.UNITS:
		return lower_floor
	if _session.units < wanted_units:
		return bar_button if wanted_units - _session.units >= MayaNumeral.BAR_VALUE else dot_button
	if MayaNumeral.needs_shell(target) and not _session.shell:
		return shell_button
	return action_button


func _set_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)


func _update_progress() -> void:
	mission_progress.update_progress(
		_session.round_index,
		content.round_count,
		"El tianguis · %d / %d" % [_session.round_index + 1, content.round_count]
	)


# ─── Navegación ──────────────────────────────────────────────────────────────
func _on_menu_pressed() -> void:
	_navigating = true
	GameManager.go_to_scene("main_menu")


func _on_next_pressed() -> void:
	_navigating = true
	GameManager.go_to_scene("world4_story1")


func _on_book_pressed() -> void:
	libro.show_book($UI/LevelHeader/Bar/BookButton)


func _on_replay_pressed() -> void:
	GameManager.replay_scene(GameManager.scene_key_for(self))


func get_checkpoint_state() -> Dictionary:
	return _session.snapshot()


func get_configuration_issues() -> PackedStringArray:
	if content == null:
		return PackedStringArray(["Asigna el recurso content del tianguis."])
	return content.get_configuration_issues()


func _get_configuration_warnings() -> PackedStringArray:
	return get_configuration_issues()
