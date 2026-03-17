class_name ButtonFX


## Apply micro-interactions to a button: scale on press, pointer cursor on hover.
static func apply(button: Button) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.button_down.connect(func():
		button.pivot_offset = button.size / 2.0
		var tw := button.create_tween()
		tw.tween_property(button, "scale", Vector2(0.95, 0.95), 0.06)
	)

	button.button_up.connect(func():
		button.pivot_offset = button.size / 2.0
		var tw := button.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(button, "scale", Vector2.ONE, 0.15)
	)
