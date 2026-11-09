class_name LootFeed
extends VBoxContainer

## Lista de avisos de drops no canto da tela: cada item pego entra com um deslize, fica
## alguns segundos e some. Ouro seguido é somado na mesma linha.

const MAX_LINES := 5
const HOLD_SECONDS := 2.4
const FADE_SECONDS := 0.5
const GOLD_MERGE_SECONDS := 1.2

var _gold_label: Label
var _gold_total := 0
var _gold_time := -10.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)


func add_line(text: String, color: Color) -> Label:
	var label := Brand.make_label(text, 17, color)
	label.add_theme_color_override("font_outline_color", Color("120a05"))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	while get_child_count() > MAX_LINES:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	label.modulate.a = 0.0
	var tween := label.create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_callback(label.queue_free)
	return label


func add_item(item: Item) -> void:
	add_line("+ %s" % item.display_name(), item.color())


func add_gold(amount: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if is_instance_valid(_gold_label) and now - _gold_time <= GOLD_MERGE_SECONDS:
		_gold_total += amount
		_gold_label.text = "+ %d ouro" % _gold_total
		_gold_label.modulate.a = 1.0
	else:
		_gold_total = amount
		_gold_label = add_line("+ %d ouro" % amount, Color("ffe9a8"))
	_gold_time = now
