class_name SkillUpgradePanel
extends VBoxContainer

## Abaixo da árvore: as casas de habilidade da partida (o que o herói leva para a luta) e todas as
## habilidades que ele pode equipar, com o que cada uma faz e o botão para melhorá-la. Toque numa casa e
## depois em "Equipar" para trocar a habilidade dela. Cada habilidade tem 5 níveis; o nível N custa N pontos
## de habilidade (1, 2, 3, 4 e 5), os mesmos pontos da árvore.

signal changed

var slot := 0
var _hero := ""
var _title: Label
var _slots_box: HBoxContainer
var _hint: Label
var _rows: VBoxContainer
var _slot_buttons: Array = []


func _init() -> void:
	add_theme_constant_override("separation", 6)
	_title = Brand.make_label("", 16, Brand.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_slots_box = HBoxContainer.new()
	_slots_box.add_theme_constant_override("separation", 6)
	add_child(_slots_box)
	_hint = Brand.make_label("Toque numa casa da barra e depois em \"Equipar\" na habilidade que quiser levar para ela.", 12, Color("b8c9a0"))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	add_child(_rows)


func refresh(hero: String) -> void:
	if hero != _hero:
		slot = 0
	_hero = hero
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for child in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	_slot_buttons.clear()
	var progress := Session.progress_for(hero)
	var points := int(progress["points"])
	var hero_level := int(progress["level"])
	var hero_data := Heroes.get_hero(hero)
	var loadout := Session.loadout_for(hero)
	slot = clampi(slot, 0, loadout.size() - 1)
	_title.text = "Habilidades do herói · %d pontos de habilidade" % points
	for i in loadout.size():
		var def := Skills.def(loadout[i])
		var button := Brand.make_wood_button("%d · %s" % [i + 1, def["name"]], Vector2(0, 44), 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.set_pressed_no_signal(i == slot)
		button.add_theme_color_override("font_color", def["color"])
		button.pressed.connect(select_slot.bind(i))
		_slots_box.add_child(button)
		_slot_buttons.append(button)
	for id in Heroes.skill_pool(hero_data):
		_rows.add_child(_make_row(id, points, hero_level, loadout))


func select_slot(index: int) -> void:
	slot = index
	for i in _slot_buttons.size():
		_slot_buttons[i].set_pressed_no_signal(i == slot)
	refresh(_hero)


func _make_row(id: String, points: int, hero_level: int, loadout: Array) -> Control:
	var def := Skills.def(id)
	var req := Heroes.skill_req(Heroes.get_hero(_hero), id)
	var level := Session.skill_level(_hero, id)
	var equipped_slot := loadout.find(id)
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.GOLD if equipped_slot >= 0 else Brand.BRASS_DARK, 2, 6)
	style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	frame.add_child(row)
	var badge := PanelContainer.new()
	var badge_style := Brand.make_box(Color("120a05"), def["color"], 3, 24)
	badge_style.set_content_margin_all(4)
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.custom_minimum_size = Vector2(52, 52)
	var glyph := Brand.make_label(str(def["glyph"]), 22, def["color"])
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(glyph)
	row.add_child(badge)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	var pips := "●".repeat(level) + "○".repeat(Skills.MAX_LEVEL - level)
	column.add_child(Brand.make_label("%s   %s  (nível %d/%d)" % [def["name"], pips, level, Skills.MAX_LEVEL], 15, Color("ffe9a8")))
	var description := Brand.make_label("%s Energia %d · recarga %ds." % [def["desc"], int(def["cost"]), int(def["cooldown"])], 12, Brand.PARCHMENT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(300, 0)
	column.add_child(description)
	var current := Brand.make_label("Agora: %s" % Skills.level_effect_text(level), 12, Color("b8c9a0"))
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(current)
	if req > 0:
		column.add_child(Brand.make_label("Exige o nível %d do herói%s" % [req, "" if hero_level >= req else " (você está no %d)" % hero_level], 11, Color("8a7f6a") if hero_level >= req else Color("ff9a6a")))
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	row.add_child(buttons)
	var equip: Button
	if equipped_slot == slot:
		equip = Brand.make_wood_button("Na casa %d" % (slot + 1), Vector2(150, 36), 13)
		equip.disabled = true
	else:
		var text := "Equipar na casa %d" % (slot + 1) if equipped_slot < 0 else "Trocar com a casa %d" % (equipped_slot + 1)
		equip = Brand.make_wood_button(text, Vector2(150, 36), 13)
		equip.disabled = hero_level < req
		equip.pressed.connect(_on_equip.bind(id))
	buttons.add_child(equip)
	var upgrade: Button
	if level >= Skills.MAX_LEVEL:
		upgrade = Brand.make_wood_button("Nível máximo", Vector2(150, 36), 13)
		upgrade.disabled = true
	else:
		var cost := Skills.upgrade_cost(level)
		upgrade = Brand.make_wood_button("Melhorar · %d %s" % [cost, "ponto" if cost == 1 else "pontos"], Vector2(150, 36), 13)
		upgrade.disabled = points < cost
		upgrade.tooltip_text = "Nível %d: %s" % [level + 1, Skills.level_effect_text(level + 1)]
		upgrade.pressed.connect(_on_upgrade.bind(id))
	buttons.add_child(upgrade)
	return frame


func _on_equip(id: String) -> void:
	if Session.equip_skill(_hero, slot, id):
		Sound.play("level")
	refresh(_hero)
	changed.emit()


func _on_upgrade(id: String) -> void:
	if Session.upgrade_skill(_hero, id):
		Sound.play("level")
	refresh(_hero)
	changed.emit()
