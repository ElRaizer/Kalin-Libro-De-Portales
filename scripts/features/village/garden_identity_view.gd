extends Control
class_name GardenIdentityView

var _sign: TextureRect
var _border: TextureRect
var _name: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = preload("res://themes/kalin_theme.tres")
	z_index = 330
	_border = TextureRect.new()
	_sign = TextureRect.new()
	for picture: TextureRect in [_border, _sign]:
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(picture)
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.max_lines_visible = 2
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.add_theme_color_override("font_color", Color("563c26"))
	_name.add_theme_font_size_override("font_size", 22)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)


func configure(profile: GardenProfile, entry: Dictionary) -> void:
	_sign.texture = profile.sign_texture
	_sign.position = profile.sign_rect.position
	_sign.size = profile.sign_rect.size
	_sign.visible = "sign" in entry.decorations
	_border.texture = profile.border_texture
	_border.position = profile.border_rect.position
	_border.size = profile.border_rect.size
	_border.visible = "border" in entry.decorations
	_name.position = profile.name_rect.position
	_name.size = profile.name_rect.size
	_name.text = entry.name if not str(entry.name).is_empty() else "Mi rincón"
	_name.visible = not str(entry.name).is_empty() or _sign.visible
