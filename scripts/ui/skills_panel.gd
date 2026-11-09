class_name SkillsPanel
extends VBoxContainer

## Página "Habilidades" do menu do castelo: o nível do herói (acumulativo, sem máximo) com o XP, e duas
## partes: a árvore de habilidades (onde se gastam os pontos ganhos a cada nível, ver SkillTreePanel) e a
## evolução individual do herói.

signal changed

var _hero_id := ""
var _level_label: Label
var _xp_bar: MedievalBar
var _tree_button: Button
var _evolution_button_tab: Button
var _tree_panel: SkillTreePanel
var _skill_upgrades: SkillUpgradePanel
var _evolution_box: PanelContainer
var _evolution_title: Label
var _evolution_text: Label
var _evolution_button: Button
var _show_evolution := false


func _init() -> void:
	add_theme_constant_override("separation", 8)
	_level_label = Brand.make_label("", 22, Brand.GOLD)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_color_override("font_outline_color", Color("120a05"))
	_level_label.add_theme_constant_override("outline_size", 6)
	add_child(_level_label)
	_xp_bar = MedievalBar.new(20.0, 0.0)
	_xp_bar.fill_top = Color("6ec6ff")
	_xp_bar.fill_bottom = Color("2f6fd0")
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_xp_bar)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(tabs)
	_tree_button = Brand.make_wood_button("Árvore de habilidades", Vector2(220, 36), 14)
	_tree_button.toggle_mode = true
	_tree_button.pressed.connect(_show_tab.bind(false))
	tabs.add_child(_tree_button)
	_evolution_button_tab = Brand.make_wood_button("Evolução", Vector2(160, 36), 14)
	_evolution_button_tab.toggle_mode = true
	_evolution_button_tab.pressed.connect(_show_tab.bind(true))
	tabs.add_child(_evolution_button_tab)

	_tree_panel = SkillTreePanel.new()
	_tree_panel.changed.connect(func() -> void:
		refresh(_hero_id)
		changed.emit())
	add_child(_tree_panel)
	_skill_upgrades = SkillUpgradePanel.new()
	_skill_upgrades.changed.connect(func() -> void:
		refresh(_hero_id)
		changed.emit())
	add_child(_skill_upgrades)

	_evolution_box = PanelContainer.new()
	var evolution_style := Brand.make_box(Color("1a100a"), Brand.BRASS_DARK, 2, 6)
	evolution_style.set_content_margin_all(12)
	_evolution_box.add_theme_stylebox_override("panel", evolution_style)
	var evolution_column := VBoxContainer.new()
	evolution_column.add_theme_constant_override("separation", 6)
	_evolution_box.add_child(evolution_column)
	_evolution_title = Brand.make_label("", 20, Color("ffe9a8"))
	evolution_column.add_child(_evolution_title)
	_evolution_text = Brand.make_label("", 14, Brand.PARCHMENT)
	_evolution_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_evolution_text.custom_minimum_size = Vector2(560, 0)
	evolution_column.add_child(_evolution_text)
	_evolution_button = Brand.make_wood_button("Evoluir", Vector2(0, 44), 15)
	_evolution_button.pressed.connect(_on_evolve)
	evolution_column.add_child(_evolution_button)
	add_child(_evolution_box)
	_show_tab(false)


func _show_tab(evolution: bool) -> void:
	_show_evolution = evolution
	_tree_panel.visible = not evolution
	_skill_upgrades.visible = not evolution
	_evolution_box.visible = evolution
	_tree_button.set_pressed_no_signal(not evolution)
	_evolution_button_tab.set_pressed_no_signal(evolution)


func _on_evolve() -> void:
	if Session.evolve_hero(_hero_id):
		Sound.play("level")
	refresh(_hero_id)
	changed.emit()


func refresh(hero_id: String) -> void:
	var hero := Heroes.get_hero(hero_id)
	var progress := Session.progress_for(hero_id)
	var level: int = progress["level"]
	var needed := Progression.xp_needed(level)
	_hero_id = hero_id
	_level_label.text = "%s · Nível %d" % [hero["name"], level]
	_xp_bar.max_value = needed
	_xp_bar.value = minf(float(progress["xp"]), needed)
	_xp_bar.label_text = "XP %d / %d  (faltam %d para o nível %d)" % [int(progress["xp"]), int(ceil(needed)), int(ceil(needed - float(progress["xp"]))), level + 1]
	_tree_panel.refresh(hero_id)
	_skill_upgrades.refresh(hero_id)

	var tier := Session.evolution_tier(hero_id)
	var current := Evolution.title(hero_id, tier)
	_evolution_title.text = "Evolução: %s (%d/%d)" % [current if current != "" else "ainda sem evolução", tier, Evolution.TIERS]
	if tier >= Evolution.TIERS:
		_evolution_text.text = "Bônus atuais: %s" % Evolution.bonus_text(Evolution.bonus(hero_id, tier))
		_evolution_button.text = "Evolução máxima"
		_evolution_button.disabled = true
		return
	var next: Dictionary = Evolution.tier_data(hero_id, tier + 1)
	var need: Dictionary = Evolution.REQUIREMENTS[tier]
	_evolution_text.text = "Próxima: %s (%s)\nExige nível %d, %d ouro e %d pedras da lua." % [
		next["name"], Evolution.bonus_text(next["bonus"]), need["level"], need["gold"], need["moonstone"]]
	var block := Session.evolution_block(hero_id)
	_evolution_button.text = "Evoluir para %s" % next["name"] if block == "" else block
	_evolution_button.disabled = block != ""
