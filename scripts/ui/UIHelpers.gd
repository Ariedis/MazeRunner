class_name UIHelpers


## Creates a styled title with a decorative underline.
static func create_title(text: String, font_size: int = 26, color: Color = Color.TRANSPARENT) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	if UITheme.font_title:
		label.add_theme_font_override("font", UITheme.font_title)
	if color != Color.TRANSPARENT:
		label.add_theme_color_override("font_color", color)
	container.add_child(label)

	var line := ColorRect.new()
	line.color = UITheme.ACCENT
	line.custom_minimum_size = Vector2(0, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(line)

	# Store label reference for animation access.
	container.set_meta("label", label)

	return container


## Creates a dimming overlay ColorRect.
static func create_dim_overlay(alpha: float = 0.6) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, alpha)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay
