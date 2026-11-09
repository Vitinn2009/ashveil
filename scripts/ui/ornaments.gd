class_name Ornaments
extends Control

## Enfeites de moldura: um filete fino por dentro e rebites de latão nos cantos.
## Vai como filho de um painel e não recebe cliques.

const INSET := 4.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var box := Rect2(Vector2(-INSET, -INSET) * 0.5, size + Vector2(INSET, INSET))
	draw_rect(box, Color(Brand.BRASS_DARK, 0.45), false, 1.0)
	for corner in [box.position, box.position + Vector2(box.size.x, 0),
			box.position + Vector2(0, box.size.y), box.end]:
		draw_circle(corner, 4.5, Brand.WOOD)
		draw_circle(corner, 3.4, Brand.BRASS_DARK)
		draw_circle(corner, 2.4, Brand.BRASS)
		draw_circle(corner + Vector2(-0.8, -0.8), 0.9, Color("fff2b8"))
