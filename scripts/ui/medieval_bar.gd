class_name MedievalBar
extends Control

## Barra de vida, energia ou XP no estilo medieval: moldura de latão, trilho
## escuro, preenchimento em duas faixas com brilho, divisões e um medalhão com
## ícone na ponta. `value` e `max_value` funcionam como na ProgressBar.

var value := 0.0:
	set(new_value):
		if not is_equal_approx(new_value, value):
			value = new_value
			queue_redraw()
var max_value := 100.0:
	set(new_value):
		new_value = maxf(new_value, 0.001)
		if not is_equal_approx(new_value, max_value):
			max_value = new_value
			queue_redraw()
var label_text := "":
	set(new_text):
		if new_text != label_text:
			label_text = new_text
			queue_redraw()
var fill_top := Color("e8604a")
var fill_bottom := Color("a02a22")
var icon_kind := ""
var show_ticks := true


func _init(bar_height := 22.0, bar_width := 0.0) -> void:
	custom_minimum_size = Vector2(bar_width, bar_height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func ratio() -> float:
	return clampf(value / max_value, 0.0, 1.0)


func _draw() -> void:
	var h := size.y
	var start := h * 0.85 if icon_kind != "" else 0.0
	var track := Rect2(start, 0, size.x - start, h)
	draw_rect(track.grow(1.0), Color("120a05"))
	draw_rect(track, Color("1c120a"))
	var inner := track.grow(-3.0)
	draw_rect(inner, Color("2a1c12"))
	var fill_width := inner.size.x * ratio()
	if fill_width > 0.5:
		draw_rect(Rect2(inner.position, Vector2(fill_width, inner.size.y * 0.5)), fill_top)
		draw_rect(Rect2(inner.position + Vector2(0, inner.size.y * 0.5), Vector2(fill_width, inner.size.y * 0.5)), fill_bottom)
		draw_rect(Rect2(inner.position + Vector2(0, 1), Vector2(fill_width, 1.5)), Color(1, 1, 1, 0.4))
		draw_rect(Rect2(inner.position + Vector2(fill_width - 1.5, 0), Vector2(1.5, inner.size.y)), Color(1, 1, 1, 0.35))
	if show_ticks:
		for i in range(1, 4):
			var x := inner.position.x + inner.size.x * i / 4.0
			draw_line(Vector2(x, inner.position.y), Vector2(x, inner.end.y), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(track, Brand.BRASS_DARK, false, 2.0)
	draw_rect(track.grow(-1.0), Color(Brand.BRASS, 0.5), false, 1.0)
	if icon_kind != "":
		var center := Vector2(h * 0.5, h * 0.5)
		draw_circle(center, h * 0.72, Color("120a05"))
		draw_circle(center, h * 0.64, Brand.BRASS_DARK)
		draw_circle(center, h * 0.54, Color("2a1a0e"))
		Icons.draw(self, icon_kind, Rect2(center - Vector2.ONE * h * 0.4, Vector2.ONE * h * 0.8), fill_top.lightened(0.15))
	if label_text != "":
		var font := get_theme_default_font()
		var font_size := int(clampf(h * 0.58, 11.0, 18.0))
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var origin := Vector2(track.position.x + (track.size.x - text_size.x) * 0.5, h * 0.5 + font_size * 0.36)
		draw_string_outline(font, origin, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color("120a05"))
		draw_string(font, origin, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("fff4d6"))
