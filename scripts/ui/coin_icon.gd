class_name CoinIcon
extends Control

## Moeda de ouro ao lado do saldo, no inventário e no castelo.


func _init() -> void:
	custom_minimum_size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	Icons.draw(self, "coin", Rect2(Vector2.ZERO, size), Brand.BRASS)
