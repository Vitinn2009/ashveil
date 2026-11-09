class_name InventoryWindow
extends Control

## Janela da mochila, no estilo medieval do Ashveil e no formato do Surve RPG: equipamento em
## 9 casas ao lado do herói, mochila em grade com busca, filtro e ordenação, detalhe do item com
## comparação com o que está vestido, toque duplo para equipar, arrastar e soltar e lixeira com
## confirmação. Abre pausando o jogo (o Game decide); funciona também com o jogo pausado.

signal closed
signal consumable_used(id: String)
## O jogador tocou num equipamento (da mochila ou vestido): o Ferreiro mostra os atributos dele.
signal item_selected(item: Item)

const SLOT := 40.0
## Casas de equipamento (maiores) e o desenho do bloco do herói, como no Surve RPG.
const EQUIP_SLOT := 40.0
const EQUIP_AREA := Vector2(276.0, 226.0)
const EQUIP_POSITIONS := {
	"weapon": Vector2(0, 0), "offhand": Vector2(0, 46), "cloak": Vector2(0, 138), "mask": Vector2(0, 184),
	"helmet": Vector2(236, 0), "armor": Vector2(236, 46), "gloves": Vector2(236, 92), "boots": Vector2(236, 138),
	"ring": Vector2(74, 0), "necklace": Vector2(118, 0), "ring2": Vector2(162, 0),
}
## A casa do pet ativo, embaixo à direita.
const PET_POSITION := Vector2(236, 184)
const DOCK_WIDTH := 316.0
const COLUMNS := 6
const CONSUMABLES := ["potion", "bread", "roast", "stew"]
const FILTERS := ["all", "weapons", "armor", "accessories"]
const FILTER_NAMES := {"all": "Todos", "weapons": "Armas", "armor": "Armaduras", "accessories": "Acessórios"}
## O toque que abre a janela chega de novo como clique do mouse; ignora cliques logo depois de abrir.
const OPEN_GRACE_MSEC := 300
const DOUBLE_TAP_MSEC := 400
const GREEN := Color("7ee08a")
const RED := Color("ff7a6a")

var _player: Player
var _inventory: Inventory
var _filter := "all"
var _selected: Item
var _selected_equipped := false
var _trash_armed := false
var _opened_at := -10000
var _last_tap := ""
var _last_tap_msec := -10000
var _message_tween: Tween
var _open_tween: Tween
## Embutida: faz parte da tela (castelo), sem fundo escuro, sem botão de fechar e sempre aberta, à esquerda.
var embedded := false
## Margens de cima e de baixo da mochila embutida (o castelo deixa espaço para as barras).
var dock_top := 12.0
var dock_bottom := 12.0
## O castelo deixa trocar o pet pela casa do pet; na partida ela só mostra o pet.
var pet_changeable := false

var _dimmer: ColorRect
var _panel: PanelContainer
var _gold_label: Label
var _bag_label: Label
var _equip_grid: Control
var _equip_area: Control
var _consumable_row: HBoxContainer
var _bag_grid: GridContainer
var _search: LineEdit
var _filter_button: Button
var _sort_button: Button
var _info: RichTextLabel
var _message: Label
var _equip_button: Button
var _sell_button: Button
var _trash_button: Button
var _dismantle_button: Button
var _stats_label: Label
var _hint: Label
var _detail_panel: PanelContainer
var _fragments_label: RichTextLabel
var _materials_label: Label
var _key_button: Button
var _close_button: Button
var _consumable_slots := {}


func bind(player: Player) -> void:
	_player = player
	_inventory = player.inventory
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()
	_inventory.changed.connect(_on_inventory_changed)
	player.health_changed.connect(func(_current: float, _maximum: float) -> void:
		if visible:
			_refresh_stats())


func is_open() -> bool:
	return visible


func open() -> void:
	_selected = null
	_selected_equipped = false
	_trash_armed = false
	_opened_at = Time.get_ticks_msec()
	show()
	_refresh()
	# Abre com um pequeno "pop": a janela cresce de 92% e aparece.
	if _open_tween:
		_open_tween.kill()
	if embedded:
		return
	_panel.pivot_offset = Vector2(_panel.size.x, _panel.size.y * 0.5)
	_panel.scale = Vector2(0.94, 0.94)
	_panel.modulate.a = 0.0
	if embedded:
		return
	_open_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_open_tween.tween_property(_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(_panel, "modulate:a", 1.0, 0.12)


func close() -> void:
	if not visible or embedded:
		return
	hide()
	closed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible and not embedded:
		close()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if embedded:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer = ColorRect.new()
	_dimmer.color = Color(0.0, 0.0, 0.0, 0.5)
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.gui_input.connect(_on_dimmer_input)
	add_child(_dimmer)
	_dimmer.visible = not embedded
	# A mochila fica ancorada no canto direito da tela, e o jogo aparece ao lado.
	_panel = Brand.make_wood_panel(14, Color(Brand.WOOD, 0.98))
	_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_right = -12.0
	_panel.offset_left = -(DOCK_WIDTH + 12.0)
	if embedded:
		_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		_panel.grow_horizontal = Control.GROW_DIRECTION_END
		_panel.offset_left = 16.0
		_panel.offset_right = 16.0 + DOCK_WIDTH
		_panel.offset_top = dock_top
		_panel.offset_bottom = -dock_bottom
	else:
		_panel.offset_top = 12.0
		_panel.offset_bottom = -12.0
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var ribbon := Ribbon.new("MOCHILA", 32)
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(ribbon)
	_close_button = Brand.make_wood_button("X", Vector2(52, 44), 22)
	_close_button.pressed.connect(close)
	_close_button.visible = not embedded
	header.add_child(_close_button)
	column.add_child(header)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var page_scroll := ScrollContainer.new()
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(content)
	column.add_child(page_scroll)
	content.add_child(body)
	body.add_child(_build_equipment_column())
	body.add_child(_build_bag_column())

	content.add_child(_build_info_area())


## Equipamento no estilo do Surve RPG: o herói no meio, a arma, as luvas e o anel à esquerda, o colar,
## a capa e o escudo à direita, e o elmo, a armadura e as botas em coluna no centro.
func _build_equipment_column() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_equip_area = Control.new()
	_equip_area.custom_minimum_size = EQUIP_AREA
	box.add_child(_equip_area)
	# Um disco atrás do herói, como uma plataforma.
	var plate := ColorRect.new()
	plate.color = Color(0.0, 0.0, 0.0, 0.0)
	plate.position = Vector2.ZERO
	plate.size = EQUIP_AREA
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_area.add_child(plate)
	var art := TextureRect.new()
	art.texture = load(_player.hero["art"])
	art.position = Vector2(54.0, 48.0)
	art.size = Vector2(168.0, 170.0)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_area.add_child(art)
	_equip_grid = Control.new()
	_equip_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_equip_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_area.add_child(_equip_grid)
	_stats_label = Brand.make_label("", 12, Color("b8c9a0"))
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.custom_minimum_size = Vector2(EQUIP_AREA.x, 0)
	# Os atributos do herói saíram da mochila (ficam só no cálculo, sem aparecer).
	_stats_label.visible = false
	box.add_child(_stats_label)
	return box


func _build_bag_column() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	top.add_child(CoinIcon.new())
	_gold_label = Brand.make_label("", 19, Color("ffe9a8"))
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_gold_label)
	_bag_label = _section_label("")
	top.add_child(_bag_label)
	box.add_child(top)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 6)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar"
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(70, 34)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_text: String) -> void: _refresh())
	tools.add_child(_search)
	_filter_button = Brand.make_wood_button("Todos", Vector2(58, 32), 12)
	_filter_button.pressed.connect(_cycle_filter)
	tools.add_child(_filter_button)
	_sort_button = Brand.make_wood_button("Ordenar", Vector2(62, 32), 12)
	_sort_button.pressed.connect(func() -> void: _inventory.sort_bag())
	tools.add_child(_sort_button)
	var best_button := Brand.make_wood_button("Melhores", Vector2(70, 32), 12)
	best_button.pressed.connect(_on_equip_best_pressed)
	tools.add_child(best_button)
	box.add_child(tools)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(SLOT * COLUMNS + 4.0 * (COLUMNS - 1) + 14.0, SLOT * 4.0 + 18.0)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = COLUMNS
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_bag_grid)
	box.add_child(scroll)

	_fragments_label = RichTextLabel.new()
	_fragments_label.bbcode_enabled = true
	_fragments_label.fit_content = true
	_fragments_label.scroll_active = false
	_fragments_label.custom_minimum_size = Vector2(0, 20)
	_fragments_label.add_theme_font_size_override("normal_font_size", 12)
	_fragments_label.add_theme_color_override("default_color", Brand.PARCHMENT)
	_fragments_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_fragments_label)

	_consumable_row = HBoxContainer.new()
	_consumable_row.add_theme_constant_override("separation", 6)
	for id in CONSUMABLES:
		var slot := ItemSlot.new(SLOT)
		slot.pressed.connect(_use_consumable.bind(id))
		_consumable_slots[id] = slot
		_consumable_row.add_child(slot)
	_materials_label = Brand.make_label("", 12, Color("c9d8ff"))
	_materials_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var extras := VBoxContainer.new()
	extras.add_theme_constant_override("separation", 2)
	extras.add_child(_materials_label)
	_key_button = Brand.make_wood_button("Chave", Vector2(0, 26), 12)
	_key_button.pressed.connect(_on_key_pressed)
	extras.add_child(_key_button)
	_consumable_row.add_child(extras)
	box.add_child(_consumable_row)
	return box


## Na partida, os detalhes do item aparecem numa caixa à esquerda da mochila (sobre o campo de jogo).
func _build_detail_panel() -> void:
	_detail_panel = PanelContainer.new()
	var style := Brand.make_box(Color(Brand.WOOD, 0.97), Brand.BRASS, 3, 10)
	style.set_content_margin_all(12)
	_detail_panel.add_theme_stylebox_override("panel", style)
	_detail_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_detail_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_detail_panel.offset_right = -(DOCK_WIDTH + 12.0 + 10.0)
	_detail_panel.offset_top = 12.0
	_detail_panel.custom_minimum_size = Vector2(250, 0)
	_detail_panel.visible = false
	add_child(_detail_panel)
	_detail_panel.add_child(_info)


func _build_info_area() -> Control:
	var info_box := PanelContainer.new()
	var info_style := Brand.make_box(Color("2b1d12"), Brand.BRASS_DARK, 2, 4)
	info_style.set_content_margin_all(10)
	info_box.add_theme_stylebox_override("panel", info_style)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	info_box.add_child(row)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.custom_minimum_size = Vector2(240 if embedded else 226, 40)
	_info.add_theme_font_size_override("normal_font_size", 13)
	_info.add_theme_font_size_override("bold_font_size", 15)
	_info.add_theme_color_override("default_color", Brand.PARCHMENT)
	if embedded:
		text_column.add_child(_info)
	else:
		_build_detail_panel()
		_hint = Brand.make_label("Toque em um item para ver os detalhes. Toque duplo equipa; arraste para mover.", 12, Brand.PARCHMENT)
		_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_hint.custom_minimum_size = Vector2(240, 0)
		text_column.add_child(_hint)
	_message = Brand.make_label("", 13, Brand.GOLD)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(240, 0)
	text_column.add_child(_message)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	_equip_button = Brand.make_wood_button("Equipar", Vector2(66, 28), 12)
	_sell_button = Brand.make_wood_button("Vender", Vector2(66, 28), 12)
	_trash_button = Brand.make_wood_button("Descartar", Vector2(66, 28), 12)
	_dismantle_button = Brand.make_wood_button("Desmantelar", Vector2(86, 28), 12)
	for button in [_equip_button, _sell_button, _dismantle_button, _trash_button]:
		buttons.add_child(button)
	_equip_button.pressed.connect(_on_equip_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_trash_button.pressed.connect(_on_trash_pressed)
	_dismantle_button.pressed.connect(_on_dismantle_pressed)
	row.add_child(buttons)
	return info_box


func _section_label(text: String) -> Label:
	var label := Brand.make_label(text, 15, Brand.BRASS)
	label.add_theme_color_override("font_outline_color", Color("120a05"))
	label.add_theme_constant_override("outline_size", 3)
	return label


# --- Dados na tela ---------------------------------------------------------------------

func _on_inventory_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if _inventory == null:
		return
	_gold_label.text = "Ouro: %d" % _inventory.gold
	_materials_label.text = "Pedra %d · Lua %d\nPergaminho %d" % [_inventory.stone, _inventory.moonstone, _inventory.scrolls]
	_key_button.text = "Chave de espaço (%d)" % _inventory.slot_keys
	var fragment_parts := PackedStringArray()
	for rarity in Item.RARITIES.size():
		fragment_parts.append("[color=#%s]%d[/color]" % [Item.RARITIES[rarity]["color"].to_html(false), _inventory.fragments[rarity]])
	_fragments_label.text = "Fragmentos: " + "  ".join(fragment_parts)
	_key_button.disabled = _inventory.slot_keys <= 0 or _inventory.bag_capacity >= Inventory.MAX_BAG_SIZE
	_bag_label.text = "Mochila %d/%d" % [_inventory.bag.size(), _inventory.bag_capacity]
	_filter_button.text = FILTER_NAMES[_filter]
	if _selected and _selected_equipped and _inventory.key_of(_selected) == "":
		_selected = null
	elif _selected and not _selected_equipped and _inventory.bag.find(_selected) < 0:
		_selected = null
	_rebuild_equipment()
	_rebuild_bag()
	for id in CONSUMABLES:
		_consumable_slots[id].show_consumable(id, _inventory.count(id))
	_refresh_info()
	_refresh_stats()


func _rebuild_equipment() -> void:
	_clear(_equip_grid)
	for slot_name in Item.EQUIP_KEYS:
		var worn = _inventory.equipped.get(slot_name)
		var slot := ItemSlot.new(EQUIP_SLOT)
		slot.show_item(worn, Item.type_of(slot_name))
		slot.drag_kind = "equip"
		slot.slot_key = slot_name
		slot.position = EQUIP_POSITIONS[slot_name]
		slot.selected = worn != null and worn == _selected
		slot.tooltip_text = worn.describe() if worn else Item.SLOT_NAMES[slot_name]
		slot.pressed.connect(_on_equip_slot_pressed.bind(slot_name))
		slot.item_dropped.connect(_on_dropped.bind(slot))
		_equip_grid.add_child(slot)
	_equip_grid.add_child(_make_pet_slot())


## A casa do pet: mostra o pet ativo. No castelo, tocar nela passa para o próximo pet da coleção.
func _make_pet_slot() -> ItemSlot:
	var slot := ItemSlot.new(EQUIP_SLOT)
	slot.show_item(null, "")
	slot.position = PET_POSITION
	var pet_data := Pets.get_pet(Session.active_pet)
	slot.tooltip_text = ("Pet: %s (nível %d)" % [pet_data["name"], Session.pet_level(Session.active_pet)]) if not pet_data.is_empty() else "Pet: nenhum"
	if not pet_data.is_empty():
		var art := PetFollower.new()
		art.pet_id = Session.active_pet
		art.scale = Vector2(1.1, 1.1)
		art.position = Vector2(EQUIP_SLOT * 0.5, EQUIP_SLOT * 0.58)
		slot.add_child(art)
	slot.pressed.connect(_on_pet_pressed)
	return slot


func _on_pet_pressed() -> void:
	if not pet_changeable:
		show_message("Troque de pet no castelo (aba Pets)")
		return
	Session.cycle_pet()
	if _player != null:
		_player.pet_stats = Session.active_pet_stats()
		_player.refresh_stats()
	_refresh()


func _rebuild_bag() -> void:
	_clear(_bag_grid)
	var filtering := _is_filtering()
	var shown := 0
	for i in _inventory.bag_capacity:
		var entry = _inventory.bag[i] if i < _inventory.bag.size() else null
		if filtering and (entry == null or not _matches(entry)):
			continue
		var slot := ItemSlot.new(SLOT)
		slot.show_item(entry)
		slot.drag_kind = "bag"
		slot.bag_index = i
		slot.selected = entry != null and entry == _selected and not _selected_equipped
		slot.pressed.connect(_on_bag_slot_pressed.bind(i))
		slot.item_dropped.connect(_on_dropped.bind(slot))
		_bag_grid.add_child(slot)
		shown += 1
	if filtering and shown == 0:
		var empty := Brand.make_label("Nada encontrado.", 15, Color("a08a6a"))
		_bag_grid.add_child(empty)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _is_filtering() -> bool:
	return _filter != "all" or _search.text.strip_edges() != ""


func _matches(item: Item) -> bool:
	if _filter != "all" and Item.group_of(item.slot) != _filter:
		return false
	var query := _search.text.strip_edges().to_lower()
	return query == "" or item.display_name().to_lower().contains(query) or Item.SLOT_NAMES[item.slot].to_lower().contains(query)


func _cycle_filter() -> void:
	_filter = FILTERS[(FILTERS.find(_filter) + 1) % FILTERS.size()]
	_refresh()


func _refresh_info() -> void:
	_equip_button.visible = _selected != null
	_sell_button.visible = _selected != null and not _selected_equipped
	_trash_button.visible = _selected != null and not _selected_equipped
	_dismantle_button.visible = _selected != null and not _selected_equipped
	if not embedded:
		_detail_panel.visible = _selected != null
		_hint.visible = _selected == null
	if _selected == null:
		_info.text = "Toque em um item para ver os detalhes. Toque duplo equipa; arraste para mover."
		return
	_equip_button.text = "Tirar" if _selected_equipped else "Equipar"
	_sell_button.text = "Vender %d" % _selected.sell_value()
	_trash_button.text = "Confirmar?" if _trash_armed else "Descartar"
	_dismantle_button.text = "Desmantelar +%d" % _selected.fragment_value()
	_info.text = _info_bbcode(_selected)


## Nome na cor da raridade, atributos e, para itens da mochila, a diferença para o que está vestido.
func _info_bbcode(item: Item) -> String:
	var worn = _inventory.equipped.get(_inventory.key_for(item))
	var compare: bool = not _selected_equipped and worn != null
	var lines := PackedStringArray()
	lines.append("[b][color=#%s]%s[/color][/b]" % [item.color().to_html(false), item.display_name()])
	lines.append("%s · %s · Nv %d" % [item.rarity_name(), Item.SLOT_NAMES[item.slot], item.level])
	# Um bloco para cada origem: atributos do item, despertar e runas.
	lines.append_array(item.sections_bbcode())
	if item.sockets.size() > 0 or item.socket_count() > 0:
		var filled := 0
		for i in item.socket_count():
			if item.rune_in(i) != "":
				filled += 1
		lines.append("[color=#8a7f6a]Casas de runa: %d/%d[/color]" % [filled, item.socket_count()])
	if compare:
		lines.append("[color=#a08a6a]Comparado com %s:[/color]" % worn.display_name())
		for stat in Item.STAT_NAMES:
			var delta: int = item.stat_total(stat) - worn.stat_total(stat)
			if delta != 0:
				lines.append("  [color=#%s]%s%d%s %s[/color]" % [(GREEN if delta > 0 else RED).to_html(false), "+" if delta > 0 else "", Item.display_value(stat, delta), "%" if stat == "critdmg" or stat == "lifesteal" or stat == "reflect" else "", Item.STAT_NAMES[stat]])
	return "\n".join(lines)


func _refresh_stats() -> void:
	if _stats_label == null or _player == null:
		return
	_stats_label.text = "Vida %d/%d · Def %d · Atq +%d%% · Veloc +%d%%
Sorte %d (XP +%d%%) · Dest %d (esq %d%%) · Crít %d%% x%.2f" % [
		int(_player.health), int(_player.max_health), int(_player.get_defense()),
		int(round((_player.get_damage_mult() - 1.0) * 100.0)),
		int(round(_player.stat_points("speed") * Player.SPEED_PER_POINT * 100.0)),
		_player.get_luck(), int(round((_player.get_xp_mult() - 1.0) * 100.0)),
		_player.get_dexterity(), int(round(_player.get_dodge_chance() * 100.0)),
		int(round(_player.get_crit_chance() * 100.0)), _player.crit_multiplier()]


## Aviso curto no detalhe do item (mochila cheia, item na casa errada...).
func show_message(text: String, color := Brand.GOLD) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_message_tween.tween_interval(1.6)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.4)


# --- Interação -----------------------------------------------------------------------

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Time.get_ticks_msec() - _opened_at > OPEN_GRACE_MSEC:
		close()


func _select(item: Item, equipped: bool) -> void:
	_selected = item
	_selected_equipped = equipped
	_trash_armed = false
	item_selected.emit(item)
	_refresh()


## Dois toques seguidos na mesma casa. A janela guarda o toque (e não a casa), porque as casas
## são refeitas a cada seleção.
func _is_double_tap(key: String) -> bool:
	var now := Time.get_ticks_msec()
	var again := key == _last_tap and now - _last_tap_msec <= DOUBLE_TAP_MSEC
	_last_tap = "" if again else key
	_last_tap_msec = now
	return again


func _on_bag_slot_pressed(index: int) -> void:
	if index >= _inventory.bag.size():
		return
	if _is_double_tap("bag%d" % index):
		_on_bag_double_tap(index)
		return
	_select(_inventory.bag[index], false)


func _on_equip_slot_pressed(slot_name: String) -> void:
	var worn = _inventory.equipped.get(slot_name)
	if not worn:
		return
	if _is_double_tap("equip_" + slot_name):
		if _inventory.bag.size() >= _inventory.bag_capacity:
			show_message("Mochila cheia", RED)
		else:
			_selected = null
			_inventory.unequip(slot_name)
		return
	_select(worn, true)


func _on_bag_double_tap(index: int) -> void:
	if index < _inventory.bag.size():
		_equip_item(_inventory.bag[index])


func _equip_item(item: Item) -> void:
	if _inventory.bag.find(item) < 0:
		return
	_selected = null
	var target_key := _inventory.key_for(item)
	_inventory.equip(item)
	_flash_equipment_slot(target_key)


func _flash_equipment_slot(slot_name: String) -> void:
	if not visible:
		return
	for slot in _equip_grid.get_children():
		if slot is ItemSlot and slot.slot_key == slot_name:
			slot.flash()


func _on_equip_best_pressed() -> void:
	var swapped := _inventory.equip_best()
	if swapped > 0:
		show_message("%d peça(s) melhor(es) equipada(s)" % swapped, Color("7ee08a"))
	else:
		show_message("Você já usa os melhores itens")


func _on_equip_pressed() -> void:
	if _selected == null:
		return
	if _selected_equipped:
		var slot_name := _inventory.key_of(_selected)
		if _inventory.bag.size() >= _inventory.bag_capacity:
			show_message("Mochila cheia", RED)
			return
		_selected = null
		_inventory.unequip(slot_name)
	else:
		_equip_item(_selected)


func _on_sell_pressed() -> void:
	if _selected == null or _selected_equipped:
		return
	var item := _selected
	_selected = null
	_inventory.sell(item)
	show_message(("Vendido por %d de ouro
%s" % [item.sell_value(), _inventory.released_text()]).strip_edges(), Color("9fd0ff") if _inventory.released_text() != "" else Brand.GOLD)


func _on_trash_pressed() -> void:
	if _selected == null or _selected_equipped:
		return
	if not _trash_armed:
		_trash_armed = true
		_refresh_info()
		return
	var item := _selected
	_selected = null
	_trash_armed = false
	_inventory.trash(item)
	show_message(("%s descartado
%s" % [item.display_name(), _inventory.released_text()]).strip_edges(), Color("9fd0ff") if _inventory.released_text() != "" else Brand.GOLD)


func _on_dropped(from_slot: ItemSlot, target: ItemSlot) -> void:
	if from_slot.item == null:
		return
	if target.drag_kind == "equip":
		if from_slot.drag_kind != "bag":
			return
		if from_slot.item.slot != Item.type_of(target.slot_key):
			show_message("Esse item vai na casa de %s" % Item.SLOT_NAMES[from_slot.item.slot].to_lower(), RED)
			return
		_inventory.equip_to(target.slot_key, from_slot.item)
		_selected = null
	elif target.drag_kind == "bag":
		if from_slot.drag_kind == "bag":
			_inventory.move_in_bag(from_slot.bag_index, target.bag_index)
		elif from_slot.drag_kind == "equip":
			if _inventory.bag.size() >= _inventory.bag_capacity:
				show_message("Mochila cheia", RED)
				return
			_inventory.unequip(from_slot.slot_key)


func _use_consumable(id: String) -> void:
	if _inventory.use_consumable(id, _player):
		consumable_used.emit(id)
		_consumable_slots[id].flash()


## Usa uma chave de espaço: a mochila ganha +1 casa (até 50).
func _on_key_pressed() -> void:
	var error := _inventory.use_slot_key()
	if error != "":
		show_message(error, RED)
	else:
		show_message("+1 espaço! Mochila com %d" % _inventory.bag_capacity, GREEN)


## Desmantela o item da mochila: vira fragmentos da raridade dele (os mesmos do desmantelamento automático).
func _on_dismantle_pressed() -> void:
	if _selected == null or _selected_equipped:
		return
	var item := _selected
	_selected = null
	var amount := _inventory.convert_to_fragments(item)
	show_message(("%d fragmentos %s
%s" % [amount, item.rarity_name().to_lower(), _inventory.released_text()]).strip_edges(), Color("9fd0ff") if _inventory.released_text() != "" else item.color())
