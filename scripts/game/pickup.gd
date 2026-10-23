class_name Pickup
extends Node2D

## Item no chão: XP, ouro, poção ou equipamento. É atraído pelo herói quando
## ele chega perto e avisa o EventBus ao ser coletado.

const MAGNET_SPEED := 460.0
const COLLECT_DISTANCE := 18.0

var kind := "xp"
var payload: Variant = 1
var target: Player
var _collected := false


func _ready() -> void:
	# Os drops ficam sempre visíveis, mesmo atrás de uma árvore.
	z_index = 1


func _physics_process(delta: float) -> void:
	if _collected or target == null:
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance <= target.pickup_radius:
		global_position += offset / max(distance, 0.001) * MAGNET_SPEED * delta
	if distance <= COLLECT_DISTANCE:
		_collected = true
		EventBus.pickup_collected.emit(kind, payload)
		queue_free()


func _draw() -> void:
	match kind:
		"gold":
			draw_circle(Vector2.ZERO, 7.0, Brand.NIGHT)
			draw_circle(Vector2.ZERO, 5.5, Brand.GOLD)
			draw_arc(Vector2.ZERO, 3.0, 0.4, 2.6, 8, Color("fff2a0"), 1.5)
		"potion":
			draw_circle(Vector2(0, 3), 8.5, Brand.NIGHT)
			draw_circle(Vector2(0, 3), 7.0, Color("e0452d"))
			draw_rect(Rect2(-4, -10, 8, 8), Brand.NIGHT)
			draw_rect(Rect2(-2.5, -8.5, 5, 6), Brand.PARCHMENT)
		"item":
			var item_color: Color = payload.color()
			var gem := PackedVector2Array([Vector2(0, -11), Vector2(10, 0), Vector2(0, 11), Vector2(-10, 0)])
			draw_colored_polygon(gem, Brand.NIGHT)
			var inner := PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)])
			draw_colored_polygon(inner, item_color)
		_:
			var diamond := PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
			draw_colored_polygon(diamond, Color("7bd389"))
