extends Node

# ============================================================
# Centralized color palette
# ============================================================

const SUCCESS       := Color(0.2, 1.0, 0.3)
const ERROR         := Color(1.0, 0.3, 0.2)
const WARNING       := Color(0.9, 0.8, 0.1)
const GOLD          := Color(1.0, 0.85, 0.0)
const INFO          := Color(0.6, 0.8, 1.0)
const TEXT_DIM      := Color(0.6, 0.6, 0.6)
const TEXT_LIGHT    := Color(0.88, 0.88, 0.92)
const HEADER_GOLD   := Color(0.9, 0.85, 0.5)
const RANK_BLUE     := Color(0.7, 0.9, 1.0)
const TRAP_RED      := Color(0.9, 0.35, 0.35)
const PENALTY_RED   := Color(1.0, 0.3, 0.2)
const REROLL_GRAY   := Color(0.7, 0.7, 0.7)

const BG_DARK       := Color(0.08, 0.08, 0.12)
const OVERLAY_DIM   := Color(0.0, 0.0, 0.0, 0.6)
const ACCENT        := Color(0.25, 0.45, 0.85)
const ACCENT_DIM    := Color(0.15, 0.25, 0.45)

const PANEL_BG      := Color(0.10, 0.10, 0.16)
const PANEL_BORDER  := Color(0.25, 0.35, 0.65)

const BTN_NORMAL    := Color(0.12, 0.12, 0.20)
const BTN_HOVER     := Color(0.18, 0.20, 0.32)
const BTN_PRESSED   := Color(0.08, 0.08, 0.14)
const BTN_DISABLED  := Color(0.10, 0.10, 0.14)
const BTN_BORDER    := Color(0.30, 0.40, 0.70)
const BTN_FOCUS     := Color(0.45, 0.60, 1.0)

const AVATAR_COLORS: Array = [
	Color(0.3, 0.5, 0.9),
	Color(0.9, 0.3, 0.3),
	Color(0.3, 0.8, 0.4),
	Color(0.7, 0.3, 0.9),
	Color(0.9, 0.6, 0.2),
]

# ============================================================
# Fonts
# ============================================================

var font_title: Font = null
var font_body: Font = null

# ============================================================
# Theme resource
# ============================================================

var theme: Theme = null


func _ready() -> void:
	_load_fonts()
	_build_theme()
	# Apply as the default theme for all UI via the root viewport.
	get_tree().root.theme = theme


func _load_fonts() -> void:
	font_title = load("res://assets/fonts/Exo2-Variable.ttf")
	font_body = load("res://assets/fonts/Nunito-Variable.ttf")


func _build_theme() -> void:
	theme = Theme.new()

	# --- Default font ---
	if font_body:
		theme.default_font = font_body
	theme.default_font_size = 15

	# --- Label ---
	theme.set_color("font_color", "Label", TEXT_LIGHT)

	# --- Panel ---
	var panel_style := _make_panel_style()
	theme.set_stylebox("panel", "Panel", panel_style)

	# --- Buttons ---
	_setup_button_styles()

	# --- TabContainer ---
	_setup_tab_styles()

	# --- HSeparator ---
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = PANEL_BORDER.darkened(0.3)
	sep_style.content_margin_top = 4
	sep_style.content_margin_bottom = 4
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 8)

	# --- CheckBox / CheckButton ---
	theme.set_color("font_color", "CheckBox", TEXT_LIGHT)
	theme.set_color("font_hover_color", "CheckBox", Color.WHITE)
	theme.set_color("font_color", "CheckButton", TEXT_LIGHT)
	theme.set_color("font_hover_color", "CheckButton", Color.WHITE)

	# --- OptionButton ---
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var btn_sb: StyleBoxFlat = theme.get_stylebox(state_name, "Button").duplicate()
		theme.set_stylebox(state_name, "OptionButton", btn_sb)
	theme.set_color("font_color", "OptionButton", TEXT_LIGHT)
	theme.set_color("font_hover_color", "OptionButton", Color.WHITE)

	# --- LineEdit ---
	var le_style := StyleBoxFlat.new()
	le_style.bg_color = Color(0.06, 0.06, 0.10)
	le_style.border_color = PANEL_BORDER
	le_style.set_border_width_all(1)
	le_style.set_corner_radius_all(6)
	le_style.set_content_margin_all(8)
	theme.set_stylebox("normal", "LineEdit", le_style)
	var le_focus := le_style.duplicate() as StyleBoxFlat
	le_focus.border_color = BTN_FOCUS
	theme.set_stylebox("focus", "LineEdit", le_focus)
	theme.set_color("font_color", "LineEdit", TEXT_LIGHT)
	theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)

	# --- SpinBox inherits LineEdit + Button styles ---

	# --- ScrollContainer ---
	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = Color.TRANSPARENT
	theme.set_stylebox("panel", "ScrollContainer", scroll_style)


func _make_panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL_BG
	s.border_color = PANEL_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(12)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	s.shadow_size = 8
	s.set_content_margin_all(4)
	return s


func _setup_button_styles() -> void:
	# Normal
	var normal := StyleBoxFlat.new()
	normal.bg_color = BTN_NORMAL
	normal.border_color = BTN_BORDER
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	theme.set_stylebox("normal", "Button", normal)

	# Hover
	var hover := StyleBoxFlat.new()
	hover.bg_color = BTN_HOVER
	hover.border_color = BTN_FOCUS
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(8)
	hover.content_margin_left = 16
	hover.content_margin_right = 16
	hover.shadow_color = Color(BTN_FOCUS.r, BTN_FOCUS.g, BTN_FOCUS.b, 0.15)
	hover.shadow_size = 4
	theme.set_stylebox("hover", "Button", hover)

	# Pressed
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = BTN_PRESSED
	pressed.border_color = BTN_BORDER.darkened(0.2)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(8)
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16
	theme.set_stylebox("pressed", "Button", pressed)

	# Disabled
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = BTN_DISABLED
	disabled.border_color = Color(0.2, 0.2, 0.28)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(8)
	disabled.set_content_margin_all(8)
	disabled.content_margin_left = 16
	disabled.content_margin_right = 16
	theme.set_stylebox("disabled", "Button", disabled)

	# Focus
	var focus := StyleBoxFlat.new()
	focus.bg_color = BTN_NORMAL
	focus.border_color = BTN_FOCUS
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	focus.set_content_margin_all(8)
	focus.content_margin_left = 16
	focus.content_margin_right = 16
	theme.set_stylebox("focus", "Button", focus)

	# Font colors
	theme.set_color("font_color", "Button", TEXT_LIGHT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", TEXT_LIGHT.darkened(0.15))
	theme.set_color("font_disabled_color", "Button", TEXT_DIM.darkened(0.3))
	theme.set_color("font_focus_color", "Button", Color.WHITE)


func _setup_tab_styles() -> void:
	# Selected tab
	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = PANEL_BG
	tab_sel.border_color = PANEL_BORDER
	tab_sel.border_width_top = 2
	tab_sel.border_width_left = 2
	tab_sel.border_width_right = 2
	tab_sel.border_width_bottom = 0
	tab_sel.corner_radius_top_left = 8
	tab_sel.corner_radius_top_right = 8
	tab_sel.set_content_margin_all(8)
	theme.set_stylebox("tab_selected", "TabContainer", tab_sel)

	# Unselected tab
	var tab_unsel := StyleBoxFlat.new()
	tab_unsel.bg_color = BTN_NORMAL
	tab_unsel.border_color = Color(0.18, 0.20, 0.30)
	tab_unsel.set_border_width_all(1)
	tab_unsel.corner_radius_top_left = 8
	tab_unsel.corner_radius_top_right = 8
	tab_unsel.set_content_margin_all(8)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unsel)

	# Hovered tab
	var tab_hover := tab_unsel.duplicate() as StyleBoxFlat
	tab_hover.bg_color = BTN_HOVER
	theme.set_stylebox("tab_hovered", "TabContainer", tab_hover)

	# Panel underneath tabs
	var tab_panel := _make_panel_style()
	tab_panel.corner_radius_top_left = 0
	theme.set_stylebox("panel", "TabContainer", tab_panel)

	theme.set_color("font_selected_color", "TabContainer", Color.WHITE)
	theme.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	theme.set_color("font_hovered_color", "TabContainer", TEXT_LIGHT)
