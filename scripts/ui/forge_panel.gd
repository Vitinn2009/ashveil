class_name ForgePanel
extends VBoxContainer

## Página "Ferreiro" do menu do castelo. Arraste um equipamento da mochila (ou toque num da fileira de
## equipados, ou num da mochila) para a bigorna: os atributos dele aparecem com a origem de cada ponto, e ao
## lado ficam as melhorias, valendo para todos os equipamentos: forja (até o nível 20), nível de raridade (com fragmentos) e despertar
## (com pergaminhos).

signal changed

var _item: Item
var _materials: RichTextLabel
var _strip: VBoxContainer
var _anvil: ItemSlot
var _name_label: Label
var _info: RichTextLabel
var _hint: Label
var _forge_label: Label
var _forge_bar: MedievalBar
var _forge_button: Button
var _rank_label: Label
var _rank_bar: MedievalBar
var _rank_button: Button
var _awake_label: Label
var _awake_button: Button
var _message: Label


func _init() -> void:
	add_theme_constant_override("separation", 8)
	_materials = RichTextLabel.new()
	_materials.bbcode_enabled = true
	_materials.fit_content = true
	_materials.scroll_active = false
	_materials.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_materials.add_theme_font_size_override("normal_font_size", 14)
	_materials.add_theme_color_override("default_color", Brand.PARCHMENT)
	add_child(_materials)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	add_child(main)
	# A coluna dos equipados, em pé: toque numa peça para pô-la na bigorna.
	_strip = VBoxContainer.new()
	_strip.add_theme_constant_override("separation", 4)
	main.add_child(_strip)

	# Esquerda: a bigorna e os atributos do equipamento.
	var left := PanelContainer.new()
	var left_style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
	left_style.set_content_margin_all(10)
	left.add_theme_stylebox_override("panel", left_style)
	left.custom_minimum_size = Vector2(250, 0)
	main.add_child(left)
	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 6)
	left.add_child(left_column)
	var anvil_row := VBoxContainer.new()
	anvil_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	anvil_row.add_theme_constant_override("separation", 6)
	left_column.add_child(anvil_row)
	_anvil = ItemSlot.new(84.0)
	_anvil.drag_kind = "forge"
	_anvil.show_item(null, "weapon")
	_anvil.item_dropped.connect(_on_dropped)
	_anvil.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	anvil_row.add_child(_anvil)
	var anvil_side := VBoxContainer.new()
	anvil_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	anvil_row.add_child(anvil_side)
	_name_label = Brand.make_label("", 17, Color("ffe9a8"))
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(220, 0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anvil_side.add_child(_name_label)
	var clear := Brand.make_wood_button("Limpar", Vector2(80, 28), 12)
	clear.pressed.connect(set_item.bind(null))
	anvil_side.add_child(clear)
	_hint = Brand.make_label("Arraste um equipamento da mochila para a bigorna, ou toque num item.", 13, Color("b8c9a0"))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size = Vector2(220, 0)
	left_column.add_child(_hint)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.scroll_active = false
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info.custom_minimum_size = Vector2(220, 0)
	_info.add_theme_font_size_override("normal_font_size", 13)
	_info.add_theme_font_size_override("bold_font_size", 15)
	_info.add_theme_color_override("default_color", Brand.PARCHMENT)
	left_column.add_child(_info)

	# Direita: as melhorias.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	var forge_card := _make_card(right, "Forja")
	_forge_label = Brand.make_label("", 13, Brand.PARCHMENT)
	forge_card.add_child(_forge_label)
	_forge_bar = MedievalBar.new(12.0, 0.0)
	_forge_bar.max_value = Item.MAX_FORGE
	_forge_bar.fill_top = Color("ff9a3a")
	_forge_bar.fill_bottom = Color("b8461a")
	_forge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forge_card.add_child(_forge_bar)
	_forge_button = Brand.make_wood_button("Forjar", Vector2(0, 32), 13)
	_forge_button.pressed.connect(_on_forge)
	forge_card.add_child(_forge_button)
	var rank_card := _make_card(right, "Nível de raridade")
	_rank_label = Brand.make_label("", 13, Brand.PARCHMENT)
	rank_card.add_child(_rank_label)
	_rank_bar = MedievalBar.new(12.0, 0.0)
	_rank_bar.max_value = Item.MAX_RANK
	_rank_bar.fill_top = Color("b36bff")
	_rank_bar.fill_bottom = Color("6a3aa8")
	_rank_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_card.add_child(_rank_bar)
	_rank_button = Brand.make_wood_button("Melhorar raridade", Vector2(0, 32), 13)
	_rank_button.pressed.connect(_on_rank)
	rank_card.add_child(_rank_button)
	var awake_card := _make_card(right, "Despertar")
	_awake_label = Brand.make_label("", 13, Color("d9a8ff"))
	_awake_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_awake_label.custom_minimum_size = Vector2(240, 0)
	awake_card.add_child(_awake_label)
	_awake_button = Brand.make_wood_button("Despertar", Vector2(0, 32), 13)
	_awake_button.pressed.connect(_on_awaken)
	awake_card.add_child(_awake_button)
	_message = Brand.make_label("", 14, Color("ffe9a8"))
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(240, 0)
	right.add_child(_message)


func _make_card(parent: Control, title: String) -> VBoxContainer:
	var card := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	column.add_child(Brand.make_label(title, 15, Brand.GOLD))
	return column


# --- Escolha do equipamento ----------------------------------------------------------

## Põe um equipamento na bigorna (ou esvazia, com null).
func set_item(item: Item) -> void:
	_item = item
	refresh()


func _on_dropped(from_slot: ItemSlot) -> void:
	if from_slot.item != null:
		set_item(from_slot.item)


func _still_owned(item: Item) -> bool:
	if item == null:
		return false
	return Session.inventory.bag.has(item) or Session.inventory.equipped.values().has(item)


func refresh() -> void:
	var inventory := Session.inventory
	if not _still_owned(_item):
		_item = null
	var fragment_parts := PackedStringArray()
	for rarity in Item.RARITIES.size():
		fragment_parts.append("[color=#%s]%d[/color]" % [Item.RARITIES[rarity]["color"].to_html(false), inventory.fragments[rarity]])
	_materials.text = "[color=#ffe9a8]Ouro %d[/color]   Pedra %d   Lua %d   Pergaminho %d   Fragmentos: %s" % [
		inventory.gold, inventory.stone, inventory.moonstone, inventory.scrolls, "  ".join(fragment_parts)]
	_rebuild_strip()
	_anvil.show_item(_item, "weapon" if _item == null else "")
	_anvil.selected = _item != null
	_hint.visible = _item == null
	_refresh_info()
	_refresh_forge()
	_refresh_rank()
	_refresh_awake()


## A fileira dos equipados: tocar numa casa põe o item na bigorna.
func _rebuild_strip() -> void:
	for child in _strip.get_children():
		_strip.remove_child(child)
		child.queue_free()
	for key in Item.EQUIP_KEYS:
		var worn: Item = Session.inventory.equipped.get(key)
		var slot := ItemSlot.new(38.0)
		slot.show_item(worn, Item.type_of(key))
		slot.selected = worn != null and worn == _item
		slot.drag_kind = "equip" if worn != null else ""
		slot.slot_key = key
		if worn != null:
			slot.pressed.connect(set_item.bind(worn))
		_strip.add_child(slot)


func _refresh_info() -> void:
	if _item == null:
		_name_label.text = "Bigorna vazia"
		_name_label.add_theme_color_override("font_color", Color("8a7f6a"))
		_info.text = ""
		return
	_name_label.text = _item.display_name()
	_name_label.add_theme_color_override("font_color", _item.color())
	var lines := PackedStringArray()
	lines.append("%s · %s · Nv %d" % [_item.rarity_name(), Item.SLOT_NAMES[_item.slot], _item.level])
	# Blocos separados: atributos do item (com a origem de cada ponto), despertar e runas.
	var groups := _item.stat_groups()
	for key in ["base", "awake", "runes"]:
		var group: Dictionary = groups[key]
		if group.is_empty():
			continue
		var color: String = Item.GROUP_COLORS[key]
		lines.append("[color=#%s][b]%s[/b][/color]" % [color, Item.GROUP_TITLES[key]])
		for stat in group:
			var value := int(group[stat])
			var detail := ""
			if key == "base":
				detail = "  [color=#8a7f6a][font_size=11]%s[/font_size][/color]" % _base_sources(stat)
			lines.append("  [color=#%s]%s[/color]%s" % [color if value > 0 else "ff7a6a", Item.stat_line(stat, value), detail])
	var filled := 0
	for i in _item.socket_count():
		if _item.rune_in(i) != "":
			filled += 1
	lines.append("[color=#8a7f6a]Casas de runa: %d/%d[/color]" % [filled, _item.socket_count()])
	_info.text = "\n".join(lines)


func _base_sources(stat: String) -> String:
	var s := _item.stat_sources(stat)
	var parts := PackedStringArray()
	if int(s["base"]) != 0:
		parts.append("base %d" % s["base"])
	if int(s["rarity"]) != 0:
		parts.append("raridade %+d" % s["rarity"])
	if int(s["forge"]) != 0:
		parts.append("forja %+d" % s["forge"])
	return " · ".join(parts)


func _refresh_forge() -> void:
	var inventory := Session.inventory
	if _item == null:
		_forge_label.text = "Forja: escolha um equipamento"
		_forge_bar.value = 0.0
		_forge_bar.label_text = ""
		_forge_button.text = "Forjar"
		_forge_button.disabled = true
		return
	var primary: String = Item.STAT_NAMES[Item.PRIMARY[_item.slot]].to_lower()
	var crit_note := ", +1 crítico a cada 5" if _item.slot == "weapon" else ""
	_forge_label.text = "Nível %d de %d (+1 %s por nível%s)" % [_item.forge, Item.MAX_FORGE, primary, crit_note]
	_forge_bar.value = _item.forge
	_forge_bar.label_text = "+%d" % _item.forge
	if _item.forge >= Item.MAX_FORGE:
		_forge_button.text = "Forja no nível máximo"
		_forge_button.disabled = true
		return
	var cost := Item.forge_cost(_item.forge)
	var text := "Forjar para +%d · %d pedras · %d ouro" % [_item.forge + 1, cost["stone"], cost["gold"]]
	if cost["moonstone"] > 0:
		text += " · %d lua" % cost["moonstone"]
	_forge_button.text = text
	_forge_button.disabled = inventory.stone < cost["stone"] or inventory.gold < cost["gold"] or inventory.moonstone < cost["moonstone"]


func _refresh_rank() -> void:
	var inventory := Session.inventory
	if _item == null:
		_rank_label.text = "Escolha um equipamento"
		_rank_bar.value = 0.0
		_rank_bar.label_text = ""
		_rank_button.text = "Melhorar raridade"
		_rank_button.disabled = true
		return
	_rank_label.text = "Nível %d de %d (+%d%% nos atributos base)" % [_item.rank, Item.MAX_RANK, int(round(_item.rank * Item.RANK_BONUS * 100.0))]
	_rank_bar.value = _item.rank
	_rank_bar.label_text = "R%d" % _item.rank
	if _item.rank >= Item.MAX_RANK:
		_rank_button.text = "Nível de raridade máximo"
		_rank_button.disabled = true
		return
	var cost := Item.rank_cost(_item.rank)
	_rank_button.text = "Melhorar · %d fragmentos %s (tem %d)" % [cost, _item.rarity_name().to_lower(), inventory.fragments[_item.rarity]]
	_rank_button.disabled = int(inventory.fragments[_item.rarity]) < cost


func _refresh_awake() -> void:
	var inventory := Session.inventory
	if _item == null:
		_awake_label.text = "Escolha um equipamento"
		_awake_button.text = "Despertar"
		_awake_button.disabled = true
		return
	var hint := "raro: roubo de vida" if _item.slot == "weapon" else ("raro: refletir" if _item.slot == "armor" else "raro: regen de HP")
	_awake_label.text = "%s%s  (%d de %d)\n50%% de falhar, 20%% de vir negativo. %s" % [
		"★".repeat(_item.awakenings), "☆".repeat(Item.MAX_AWAKEN - _item.awakenings), _item.awakenings, Item.MAX_AWAKEN, hint]
	if _item.awakenings >= Item.MAX_AWAKEN:
		_awake_button.text = "Despertar completo"
		_awake_button.disabled = true
	else:
		_awake_button.text = "Despertar com pergaminho (tem %d)" % inventory.scrolls
		_awake_button.disabled = inventory.scrolls <= 0


# --- Ações ---------------------------------------------------------------------------

func _say(text: String, color := Color("ffe9a8")) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)


func _finish() -> void:
	refresh()
	changed.emit()


func _on_forge() -> void:
	var error := Session.inventory.forge_item(_item)
	if error != "":
		_say(error, Color("ff7a6a"))
	else:
		_say("%s forjada!" % _item.display_name(), Color("7ee08a"))
		Sound.play("level")
	_finish()


func _on_rank() -> void:
	var error := Session.inventory.upgrade_rank_item(_item)
	if error != "":
		_say(error, Color("ff7a6a"))
	else:
		_say("%s subiu para o nível de raridade %d!" % [_item.item_name, _item.rank], Color("7ee08a"))
		Sound.play("level")
	_finish()


func _on_awaken() -> void:
	var error := Session.inventory.awaken_target(_item)
	if error != "":
		_say(error, Color("ff7a6a"))
		_finish()
		return
	var result: Dictionary = Session.inventory.last_awakening
	var line := Item.stat_line(result["stat"], int(result["amount"]))
	if result.get("special", false):
		_say("STATUS LENDÁRIO DE DESPERTAR! %s" % line, Color("ffd24a"))
		Sound.play("level")
	else:
		match result["result"]:
			"fail":
				_say("O pergaminho falhou e se desfez.", Color("ff7a6a"))
			"negative":
				_say("Despertar negativo! %s" % line, Color("ff7a6a"))
			"super":
				_say("DESPERTAR SUPER RARO! %s" % line, Color("ffd24a"))
				Sound.play("level")
			_:
				_say("Despertou! %s" % line, Color("d9a8ff"))
				Sound.play("level")
	_finish()


## Ao abrir o Ferreiro sem nada na bigorna, já põe a arma vestida (o que mais se melhora).
func auto_pick() -> void:
	if _item == null:
		_item = Session.inventory.equipped.get("weapon")
	refresh()
