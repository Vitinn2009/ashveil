class_name SkillUpgradePanel
extends VBoxContainer

## Abaixo da árvore: as habilidades ativas do herói, o que cada uma faz e o botão para melhorá-la. Cada
## habilidade tem 5 níveis; o nível N custa N pontos de habilidade (1, 2, 3, 4 e 5), os mesmos pontos da árvore.

signal changed

var _hero := ""
var _title: Label
var _rows: VBoxContainer


func _init() -> void:
	add_theme_constant_override("separation", 6)
	_title = Brand.make_label("", 16, Brand.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	add_child(_rows)


func refresh(hero: String) -> void:
	_hero = hero
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var points := int(Session.progress_for(hero)["points"])
	_title.text = "Habilidades do herói · %d pontos de habilidade" % points
	for entry in Heroes.skill_entries(Heroes.get_hero(hero)):
		_rows.add_child(_make_row(entry, points))


func _make_row(entry: Dictionary, points: int) -> Control:
	var id: String = entry["id"]
	var def := Skills.def(id)
	var level := Session.skill_level(_hero, id)
	var frame := PanelContainer.new()
	var style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
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
	var glyph := Brand.make_label(str(def["glyph"]), 24, def["color"])
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
	description.custom_minimum_size = Vector2(330, 0)
	column.add_child(description)
	var current := Brand.make_label("Agora: %s" % Skills.level_effect_text(level), 12, Color("b8c9a0"))
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(current)
	if int(entry["unlock_level"]) > 0:
		column.add_child(Brand.make_label("Liberada no nível %d do herói" % entry["unlock_level"], 11, Color("8a7f6a")))
	var button: Button
	if level >= Skills.MAX_LEVEL:
		button = Brand.make_wood_button("Nível máximo", Vector2(150, 40), 13)
		button.disabled = true
	else:
		var cost := Skills.upgrade_cost(level)
		button = Brand.make_wood_button("Melhorar · %d %s" % [cost, "ponto" if cost == 1 else "pontos"], Vector2(150, 40), 13)
		button.disabled = points < cost
		button.tooltip_text = "Nível %d: %s" % [level + 1, Skills.level_effect_text(level + 1)]
		button.pressed.connect(_on_upgrade.bind(id))
	row.add_child(button)
	return frame


func _on_upgrade(id: String) -> void:
	if Session.upgrade_skill(_hero, id):
		Sound.play("level")
	refresh(_hero)
	changed.emit()
