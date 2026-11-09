class_name Ribbon
extends Control

## Faixa de título medieval, vermelha com borda de latão e pontas entalhadas.

var text := "":
	set(value):
		text = value
		queue_redraw()
var font_size := 20


func _init(label := "", height := 34.0) -> void:
	text = label
	custom_minimum_size = Vector2(0, height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y
	var tail := 14.0
	var left_tail := PackedVector2Array([
		Vector2(0, h * 0.18), Vector2(tail + 4.0, h * 0.18), Vector2(tail + 4.0, h),
		Vector2(0, h), Vector2(tail * 0.55, h * 0.59)])
	var right_tail := PackedVector2Array([
		Vector2(w, h * 0.18), Vector2(w - tail - 4.0, h * 0.18), Vector2(w - tail - 4.0, h),
		Vector2(w, h), Vector2(w - tail * 0.55, h * 0.59)])
	draw_colored_polygon(left_tail, Color("5a1812"))
	draw_colored_polygon(right_tail, Color("5a1812"))
	var banner := Rect2(tail, 0, w - tail * 2.0, h - h * 0.12)
	draw_rect(banner, Color("8a241a"))
	draw_rect(Rect2(banner.position, Vector2(banner.size.x, banner.size.y * 0.5)), Color("a22c20"))
	draw_rect(banner, Brand.BRASS, false, 2.0)
	draw_rect(banner.grow(-4.0), Color(Brand.BRASS_DARK, 0.7), false, 1.0)
	var font := get_theme_default_font()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var origin := Vector2((w - text_size.x) * 0.5, banner.size.y * 0.5 + font_size * 0.36)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color("2a0a06"))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("ffe9a8"))
