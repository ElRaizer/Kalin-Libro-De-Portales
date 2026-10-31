extends RefCounted
class_name RecallFiller

## Completa un RecallPanel con las respuestas dadas, como lo haría el jugador al
## escribir o al colocar los bloques. Sólo para pruebas: el juego ya no trae
## respuestas automáticas.


static func fill(panel: RecallPanel, answers: Array) -> void:
	panel.first.text = str(answers[0]) if not answers.is_empty() else ""
	panel.second.text = str(answers[1]) if answers.size() > 1 else ""
	if panel.mode == RecallPanel.Mode.BLOCKS:
		panel._fill_solution(answers)
	panel.answer_changed.emit()
