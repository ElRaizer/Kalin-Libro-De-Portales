extends RefCounted
class_name CharacterReaction

## Reacciones breves que respetan la pausa del árbol y no bloquean la acción.
static func play(actor: Control, happy: bool = true) -> void:
	if actor.has_meta("reaction_tween"):
		var previous: Tween = actor.get_meta("reaction_tween")
		if previous and previous.is_valid():
			previous.kill()
	actor.pivot_offset = actor.size * Vector2(0.5, 0.9)
	actor.scale = Vector2.ONE
	actor.rotation = 0
	var old := actor.get_node_or_null("ReactionBadge")
	if old:
		actor.remove_child(old)
		old.queue_free()
	var badge := GameManager.visual_catalog.reaction_badge_scene.instantiate() as TextureRect
	badge.name = "ReactionBadge"
	badge.texture = GameManager.get_visual_texture("ui_corazon" if happy else "ui_pensar")
	badge.position = Vector2(actor.size.x * 0.65, 0)
	actor.add_child(badge)
	var tween := actor.create_tween()
	actor.set_meta("reaction_tween", tween)
	var texture_property := "texture" if actor is TextureRect else ("icon" if actor is Button else "")
	if not texture_property.is_empty():
		var source: Texture2D = actor.get(texture_property)
		if source:
			if source.resource_path.contains("_reaccion_"):
				source = actor.get_meta("reaction_base_texture", source)
			actor.set_meta("reaction_base_texture", source)
			var key := GameManager.get_visual_key(source)
			var entry := GameManager.visual_catalog.find_entry(key)
			var expression_name := "reaccion_feliz" if happy else "reaccion_duda"
			if entry != null and entry.expressions.has(expression_name):
				var expression := entry.expression(expression_name)
				actor.set(texture_property, expression)
				tween.finished.connect(func():
					# Una ronda nueva puede haber cambiado ya el animal de este control.
					if actor.get(texture_property) == expression:
						actor.set(texture_property, source)
				)
	if happy:
		tween.tween_property(actor, "scale", Vector2(1.08, 0.94), 0.14)
		tween.tween_property(actor, "scale", Vector2(0.97, 1.06), 0.18)
	else:
		tween.tween_property(actor, "rotation", -0.055, 0.16)
		tween.tween_property(actor, "rotation", 0.055, 0.2)
	tween.tween_property(actor, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(actor, "rotation", 0.0, 0.18)
	tween.tween_interval(1.0)
	tween.tween_property(badge, "position:y", -18.0, 0.3)
	tween.parallel().tween_property(badge, "modulate:a", 0.0, 0.3)
	tween.tween_callback(badge.queue_free)
