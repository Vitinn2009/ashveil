class_name DropPanel
extends Control

## Janela "Drop" da partida: escolhe que tipos de equipamento pegar dos drops (os outros ficam no chão) e
## quais raridades viram fragmentos sozinhas ao serem pegas (ver Session.ignored_types e auto_fragment).

signal closed


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
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(560, 0)
	panel.add_child(column)
	column.add_child(Ribbon.new("DROPS", 40))

	column.add_child(Brand.make_label("Tipos de equipamento que quero pegar", 17, Brand.GOLD))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	column.add_child(grid)
	for type_name in Item.SLOTS:
		var check := CheckBox.new()
		check.text = Item.SLOT_NAMES[type_name]
		check.button_pressed = not Session.ignored_types.has(type_name)
		check.focus_mode = Control.FOCUS_NONE
		check.add_theme_font_size_override("font_size", 16)
		check.add_theme_color_override("font_color", Color("ffe9a8"))
		check.custom_minimum_size = Vector2(170, 34)
		check.toggled.connect(func(on: bool) -> void: Session.set_type_ignored(type_name, not on))
		grid.add_child(check)

	column.add_child(Brand.make_label("Transformar em fragmentos automaticamente", 17, Brand.GOLD))
	var hint := Brand.make_label("Itens dessas raridades viram fragmentos ao serem pegos. Use os fragmentos no Ferreiro para subir o nível de raridade dos equipamentos da mesma raridade.", 12, Color("b8c9a0"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(540, 0)
	column.add_child(hint)
	var rarity_row := HBoxContainer.new()
	rarity_row.add_theme_constant_override("separation", 10)
	column.add_child(rarity_row)
	for rarity in Item.RARITIES.size():
		var check := CheckBox.new()
		check.text = Item.RARITIES[rarity]["name"]
		check.button_pressed = bool(Session.auto_fragment[rarity])
		check.focus_mode = Control.FOCUS_NONE
		check.add_theme_font_size_override("font_size", 16)
		check.add_theme_color_override("font_color", Item.RARITIES[rarity]["color"])
		check.add_theme_color_override("font_hover_color", Item.RARITIES[rarity]["color"])
		check.add_theme_color_override("font_pressed_color", Item.RARITIES[rarity]["color"])
		check.custom_minimum_size = Vector2(130, 34)
		check.toggled.connect(func(on: bool) -> void: Session.set_auto_fragment(rarity, on))
		rarity_row.add_child(check)

	var close := Brand.make_wood_button("Fechar", Vector2(0, 50), 20)
	close.pressed.connect(close_panel)
	column.add_child(close)


func close_panel() -> void:
	Session.save_game()
	hide()
	closed.emit()
