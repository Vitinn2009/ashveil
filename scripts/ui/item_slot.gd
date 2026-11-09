class_name ItemSlot
extends Button

## Casa quadrada do inventário e do mercado, em couro com moldura de latão.
## Mostra um equipamento (borda na cor da raridade), um consumível com contador
## ou o desenho apagado de um slot de equipamento vazio. Na janela da mochila
## também aceita arrastar e soltar, toque duplo e um brilho ao equipar.

## Um item foi solto aqui vindo de `from_slot`.
signal item_dropped(from_slot: ItemSlot)


var item: Item
## Ícone de um consumível (potion, bread, meat, stew) ou do slot vazio (weapon, armor...).
var icon_kind := ""
var icon_color := Color.WHITE
## Quantidade mostrada no canto. -1 esconde o contador.
var count := -1
var selected := false
## "bag" ou "equip" liga o arrastar e soltar; vazio desliga.
var drag_kind := ""
var bag_index := -1
var slot_key := ""

var _flash := 0.0
var _flash_tween: Tween


func _init(slot_size := 54.0) -> void:
	custom_minimum_size = Vector2(slot_size, slot_size)
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)


func show_item(new_item: Item, empty_kind := "") -> void:
	item = new_item
	icon_kind = empty_kind
	count = -1
	tooltip_text = item.describe() if item else ""
	queue_redraw()


func show_consumable(id: String, amount: int) -> void:
	var data := Consumables.def(id)
	item = null
	icon_kind = data["icon"]
	icon_color = data["color"]
	count = amount
	tooltip_text = "%s\n%s" % [data["name"], data["desc"]]
	queue_redraw()


## Brilho rápido (ao equipar ou receber um item).
func flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash = 1.0
	_flash_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_flash_tween.tween_method(func(value: float) -> void:
		_flash = value
		queue_redraw(), 1.0, 0.0, 0.35)



func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_kind == "" or item == null:
		return null
	var preview := Control.new()
	var ghost := ItemSlot.new(custom_minimum_size.x)
	ghost.show_item(item)
	ghost.modulate.a = 0.8
	ghost.position = -custom_minimum_size * 0.5
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(ghost)
	set_drag_preview(preview)
	return {"slot": self}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return drag_kind != "" and data is Dictionary and data.get("slot") is ItemSlot and data["slot"] != self


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data["slot"])


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var frame := Brand.BRASS_DARK
	if item:
		frame = item.color()
	draw_rect(rect, Color("120a05"))
	draw_rect(rect.grow(-2.0), Color("33210f") if not is_hovered() else Color("48301a"))
	draw_rect(Rect2(3, 3, size.x - 6, (size.y - 6) * 0.45), Color(1, 1, 1, 0.04))
	draw_rect(rect, frame, false, 3.0 if selected else 2.0)
	if item:
		draw_circle(Vector2(size.x * 0.5, size.y * 0.52), size.x * 0.36, Color(item.color(), 0.18))
		Icons.draw(self, item.slot, rect.grow(-size.x * 0.2), item.color().lightened(0.15))
	elif icon_kind != "":
		var tint := icon_color if count > 0 else Color(0.55, 0.45, 0.32, 0.4)
		if count == 0:
			tint = Color(icon_color, 0.3)
		Icons.draw(self, icon_kind, rect.grow(-size.x * 0.2), tint)
	var rivet := Color(Brand.BRASS_DARK, 0.9)
	for corner in [Vector2(5, 5), Vector2(size.x - 5, 5), Vector2(5, size.y - 5), Vector2(size.x - 5, size.y - 5)]:
		draw_circle(corner, 1.8, rivet)
	if count >= 0:
		var font := get_theme_default_font()
		var label := "x%d" % count
		var origin := Vector2(size.x - 6 - font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, size.y - 6)
		draw_string_outline(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("120a05"))
		draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe9a8") if count > 0 else Color("a08a6a"))
	if _flash > 0.0:
		draw_rect(rect, Color(1.0, 0.95, 0.7, 0.55 * _flash))
