class_name InventoryPanel
extends PanelContainer

## Inventário fixo na direita da tela: ouro, poções, equipamentos e mochila.

const WIDTH := 270.0

var _player: Player
var _inventory: Inventory
var _gold_label: Label
var _potion_button: Button
var _equip_box: VBoxContainer
var _bag_label: Label
var _bag_grid: GridContainer
var _info_label: Label
var _action_row: HBoxContainer
var _equip_button: Button
var _sell_button: Button
var _stats_label: Label
var _selected: Item


func bind(player: Player) -> void:
	_player = player
	_inventory = player.inventory
	_build()
	_inventory.changed.connect(_refresh)
	player.health_changed.connect(func(_current: float, _maximum: float) -> void: _refresh_stats())
	_refresh()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_left = -WIDTH
	var style := Brand.make_box(Color(Brand.NIGHT, 0.92), Brand.GOLD, 3, 0)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)

	column.add_child(Brand.make_label("INVENTÁRIO", 22, Brand.GOLD))

	_gold_label = Brand.make_label("", 18, Brand.GOLD)
	column.add_child(_gold_label)

	_potion_button = Brand.make_button("", Vector2(0, 38))
	_potion_button.add_theme_font_size_override("font_size", 15)
	_potion_button.pressed.connect(func() -> void: _inventory.use_potion(_player))
	column.add_child(_potion_button)

	column.add_child(Brand.make_label("Equipamento", 16, Brand.PARCHMENT))
	_equip_box = VBoxContainer.new()
	_equip_box.add_theme_constant_override("separation", 3)
	column.add_child(_equip_box)

	_bag_label = Brand.make_label("", 16, Brand.PARCHMENT)
	column.add_child(_bag_label)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 4
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(_bag_grid)

	_info_label = Brand.make_label("Toque em um item da mochila.", 14, Brand.PARCHMENT)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.custom_minimum_size = Vector2(WIDTH - 30.0, 52)
	column.add_child(_info_label)

	_action_row = HBoxContainer.new()
	_action_row.add_theme_constant_override("separation", 6)
	_equip_button = Brand.make_button("Equipar", Vector2(0, 34))
	_sell_button = Brand.make_button("Vender", Vector2(0, 34))
	for button in [_equip_button, _sell_button]:
		button.add_theme_font_size_override("font_size", 14)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_action_row.add_child(button)
	_equip_button.pressed.connect(func() -> void:
		if _selected:
			_inventory.equip(_selected)
			_selected = null
			_refresh())
	_sell_button.pressed.connect(func() -> void:
		if _selected:
			_inventory.sell(_selected)
			_selected = null
			_refresh())
	column.add_child(_action_row)

	_stats_label = Brand.make_label("", 13, Brand.MOSS.lightened(0.45))
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_stats_label)


func _refresh() -> void:
	_gold_label.text = "Ouro: %d" % _inventory.gold
	_potion_button.text = "Poção de vida x%d  (Q)" % _inventory.potions
	_potion_button.disabled = _inventory.potions <= 0

	for child in _equip_box.get_children():
		child.queue_free()
	for slot in Item.SLOTS:
		_equip_box.add_child(_make_equip_slot(slot))

	_bag_label.text = "Mochila (%d/%d)" % [_inventory.bag.size(), Inventory.BAG_SIZE]
	for child in _bag_grid.get_children():
		child.queue_free()
	for i in Inventory.BAG_SIZE:
		var item = _inventory.bag[i] if i < _inventory.bag.size() else null
		_bag_grid.add_child(_make_bag_slot(item))

	if _selected and _inventory.bag.find(_selected) < 0:
		_selected = null
	_action_row.visible = _selected != null
	if _selected:
		_sell_button.text = "Vender %d" % _selected.sell_value()
		_info_label.text = _selected.describe()
		_info_label.add_theme_color_override("font_color", _selected.color())
	else:
		_info_label.text = "Toque em um item da mochila."
		_info_label.add_theme_color_override("font_color", Brand.PARCHMENT)
	_refresh_stats()


func _refresh_stats() -> void:
	if _stats_label == null:
		return
	_stats_label.text = "Vida %d/%d · Defesa %d\nAtaque +%d%% · Rapidez +%d%%\nSorte %d (XP +%d%%)" % [
		int(_player.health), int(_player.max_health), int(_player.get_defense()),
		int(round((_player.get_damage_mult() - 1.0) * 100.0)),
		int(round(_player.stat_points("speed") * Player.SPEED_PER_POINT * 100.0)),
		_player.get_luck(), int(round((_player.get_xp_mult() - 1.0) * 100.0))]


func _make_equip_slot(slot: String) -> Button:
	var item = _inventory.equipped.get(slot)
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 30)
	button.clip_text = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 13)
	var border := Color("5a4a8a")
	if item:
		button.text = "%s: %s" % [Item.SLOT_NAMES[slot], item.item_name]
		button.tooltip_text = item.describe()
		border = item.color()
		button.add_theme_color_override("font_color", item.color())
		button.pressed.connect(func() -> void: _inventory.unequip(slot))
	else:
		button.text = "%s: vazio" % Item.SLOT_NAMES[slot]
		button.add_theme_color_override("font_color", Color("8a84a8"))
	button.add_theme_stylebox_override("normal", Brand.make_box(Color("1f1440"), border, 2, 6))
	button.add_theme_stylebox_override("hover", Brand.make_box(Color("2a1a4d"), border, 2, 6))
	button.add_theme_stylebox_override("pressed", Brand.make_box(Color("120a24"), border, 2, 6))
	return button


func _make_bag_slot(item) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(56, 56)
	button.clip_text = true
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 11)
	var border := Color("52467f")
	if item:
		border = item.color()
		button.text = item.item_name
		button.tooltip_text = item.describe()
		button.add_theme_color_override("font_color", item.color())
		button.pressed.connect(func() -> void:
			_selected = item
			_refresh())
	var width := 4 if item and item == _selected else 2
	button.add_theme_stylebox_override("normal", Brand.make_box(Color("1f1440"), border, width, 6))
	button.add_theme_stylebox_override("hover", Brand.make_box(Color("2a1a4d"), border, width, 6))
	button.add_theme_stylebox_override("pressed", Brand.make_box(Color("120a24"), border, width, 6))
	button.add_theme_stylebox_override("disabled", Brand.make_box(Color("160d30"), border, 2, 6))
	button.disabled = item == null
	return button
