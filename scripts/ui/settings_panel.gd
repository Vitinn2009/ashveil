class_name SettingsPanel
extends Control

## Janela de configurações (menu inicial e pausa da partida): volume geral, da música e dos efeitos,
## tremor de tela e números de dano. As mudanças valem na hora e são salvas ao fechar.

signal closed

var _value_labels := {}


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := Brand.make_wood_panel(16, Color(Brand.WOOD, 0.98))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.custom_minimum_size = Vector2(520, 0)
	panel.add_child(column)
	column.add_child(Ribbon.new("CONFIGURAÇÕES", 40))
	column.add_child(_make_slider("Volume geral", "master"))
	column.add_child(_make_slider("Música", "music"))
	column.add_child(_make_slider("Efeitos sonoros", "sfx"))
	column.add_child(_make_toggle("Tremor de tela", "screen_shake"))
	column.add_child(_make_toggle("Números de dano", "damage_numbers"))
	var close := Brand.make_wood_button("Fechar", Vector2(0, 52), 20)
	close.pressed.connect(close_panel)
	column.add_child(close)


func close_panel() -> void:
	Settings.save_settings()
	hide()
	closed.emit()


func _make_slider(title: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Brand.make_label(title, 18, Color("ffe9a8"))
	label.custom_minimum_size = Vector2(170, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(Settings.get(key))
	slider.custom_minimum_size = Vector2(220, 36)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label := Brand.make_label("%d%%" % int(round(slider.value * 100.0)), 18, Brand.PARCHMENT)
	value_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(value_label)
	_value_labels[key] = value_label
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set(key, value)
		value_label.text = "%d%%" % int(round(value * 100.0))
		Settings.apply())
	return row


func _make_toggle(title: String, key: String) -> Control:
	var toggle := CheckButton.new()
	toggle.text = title
	toggle.button_pressed = bool(Settings.get(key))
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", 18)
	toggle.add_theme_color_override("font_color", Color("ffe9a8"))
	toggle.custom_minimum_size = Vector2(0, 40)
	toggle.toggled.connect(func(on: bool) -> void: Settings.set(key, on))
	return toggle
