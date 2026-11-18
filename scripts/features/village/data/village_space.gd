extends Resource
class_name VillageSpace

@export var id: String = ""
@export var floor_bounds: Rect2 = Rect2(42, 325, 1190, 260)
@export var plot: Rect2 = Rect2(230, 350, 800, 190)
@export var obstacles: Array[Rect2] = []
@export var arrival: Vector2 = Vector2(640, 570)
@export var extension_plot: Rect2
@export var extension_entry: Rect2
@export var extension_anchor: Vector2
@export var guest_anchors: Array[Vector2] = []
@export var use_clearance: Vector2 = Vector2(180, 40)


func plots(expanded: bool) -> Array[Rect2]:
	var result: Array[Rect2] = [plot]
	if expanded and extension_plot.has_area():
		result.append(extension_plot)
	return result


func walk_regions(expanded: bool) -> Array[Rect2]:
	var result: Array[Rect2] = [floor_bounds]
	if expanded and extension_plot.has_area():
		result.append(extension_plot)
		result.append(extension_entry)
	return result


func configuration_issues() -> Array[String]:
	var issues: Array[String] = []
	if (
		not arrival.is_finite()
		or not use_clearance.is_finite()
		or use_clearance.x <= 0
		or use_clearance.y <= 0
	):
		issues.append("La llegada y el espacio de uso deben ser finitos y positivos.")
	for region: Rect2 in [extension_plot, extension_entry]:
		if (
			not region.position.is_finite()
			or not region.size.is_finite()
			or region.size.x < 0
			or region.size.y < 0
		):
			issues.append("La geometría opcional necesita medidas finitas no negativas.")
	for region: Rect2 in [floor_bounds, plot]:
		if not region.position.is_finite() or not region.size.is_finite() or not region.has_area():
			issues.append("El suelo y la parcela necesitan rectángulos finitos positivos.")
	if not floor_bounds.encloses(plot) or not floor_bounds.has_point(arrival):
		issues.append("La parcela y la llegada deben pertenecer al suelo.")
	for obstacle: Rect2 in obstacles:
		if (
			not obstacle.position.is_finite()
			or not obstacle.size.is_finite()
			or not obstacle.has_area()
		):
			issues.append("Los obstáculos necesitan rectángulos finitos positivos.")
	if extension_plot.has_area():
		if (
			not extension_plot.position.is_finite()
			or not extension_plot.size.is_finite()
			or not extension_entry.position.is_finite()
			or not extension_entry.size.is_finite()
			or not (
				extension_plot.has_point(extension_anchor)
				or extension_entry.has_point(extension_anchor)
			)
			or not extension_plot.intersects(extension_entry)
			or not floor_bounds.intersects(extension_entry)
			or guest_anchors.size() != 2
		):
			issues.append("La ampliación necesita entrada conectada y anclas de uso.")
		for anchor: Vector2 in guest_anchors:
			if not anchor.is_finite() or not extension_plot.has_point(anchor):
				issues.append("Los invitados deben estar dentro de la ampliación.")
	return issues
