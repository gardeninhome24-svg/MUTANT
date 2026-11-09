extends RefCounted
class_name SurvivorVisualSystem

## Shared production UI vocabulary for the entire game.
## StyleBoxFlat keeps this usable on Android, without heavyweight per-frame blur.
const INK := Color(0.018, 0.035, 0.055, 0.975)
const STEEL := Color(0.044, 0.074, 0.100, 0.97)
const GOLD := Color(1.0, 0.70, 0.16)
const LIME := Color(0.61, 0.94, 0.16)
const CYAN := Color(0.17, 0.79, 0.94)
const TEXT := Color(0.94, 0.97, 0.98)
const MUTED := Color(0.62, 0.73, 0.77)

static func panel(accent: Color = CYAN, emphasis: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = STEEL if emphasis else INK
	style.border_color = accent.darkened(0.12) if emphasis else accent.darkened(0.44)
	style.set_border_width_all(2 if emphasis else 1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12.0 if emphasis else 10.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 5 if emphasis else 3
	return style

static func button_style(accent: Color, state: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var is_disabled := state == "disabled"
	var is_pressed := state == "pressed"
	var is_hover := state == "hover"
	style.bg_color = Color(0.075, 0.12, 0.13, 0.98) if not is_disabled else Color(0.046, 0.053, 0.060, 0.90)
	if is_hover:
		style.bg_color = Color(0.11, 0.19, 0.19, 1.0)
	if is_pressed:
		style.bg_color = Color(0.16, 0.25, 0.20, 1.0)
	style.border_color = Color(0.21, 0.24, 0.25, 0.65) if is_disabled else accent.darkened(0.22 if is_hover else 0.40)
	style.set_border_width_all(2 if is_hover else 1)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(9.0)
	if not is_disabled:
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18 if is_hover else 0.09)
		style.shadow_size = 5 if is_hover else 2
	return style

static func decorate_button(button: Button, accent: Color = CYAN, minimum_height: float = 44.0) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, minimum_height)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, button_style(accent, state))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", LIME)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.25))
	button.add_theme_font_size_override("font_size", 14)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func decorate_section(label: Label, accent: Color = GOLD, font_size: int = 18) -> void:
	label.add_theme_color_override("font_color", accent)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_y", 1)

static func rarity_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common": return Color(0.66, 0.76, 0.83)
		"uncommon": return LIME
		"rare": return CYAN
		"epic": return Color(0.71, 0.38, 0.95)
		"legendary": return GOLD
		"mythic": return Color(1.0, 0.26, 0.36)
	return CYAN

static func decorate_inventory_card(card: Control, rarity: String, selected: bool = false) -> void:
	var accent := rarity_color(rarity)
	if card is PanelContainer:
		card.add_theme_stylebox_override("panel", panel(accent, selected))
	elif card is Button:
		decorate_button(card, accent)
		if selected:
			card.add_theme_stylebox_override("normal", button_style(accent, "hover"))
