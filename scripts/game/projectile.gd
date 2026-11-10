class_name Projectile
extends Node2D

var style := "magic"
var color := Color.WHITE
var velocity := Vector2.ZERO
var damage := 10.0
var lifetime := 1.5
var radius := 6.0
var pierce := 0
var burn_ticks := 0
var burn_damage := 0.0
## Veneno (Flecha Venenosa): dano a cada segundo.
var poison_ticks := 0
var poison_damage := 0.0
## Tipo de golpe nos inimigos: "hit" (pode errar, pelo acerto do herói) ou "skill" (nunca erra, como os tiros do pet).
var hit_kind := "hit"
var _already_hit: Array = []


func _ready() -> void:
	z_index = 5
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var nodes := Enemy.snapshot(get_tree())
	var positions := Enemy.snapshot_positions()
	var radii := Enemy.snapshot_radii()
	var here := global_position
	for i in nodes.size():
		var reach := radius + radii[i]
		if here.distance_squared_to(positions[i]) > reach * reach:
			continue
		var enemy: Enemy = nodes[i]
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or _already_hit.has(enemy) or enemy.is_intangible():
			continue
		if global_position.distance_squared_to(enemy.global_position) <= reach * reach:
			enemy.take_damage(damage, hit_kind)
			if burn_ticks > 0 and not enemy.is_queued_for_deletion():
				enemy.apply_burn(burn_ticks, burn_damage)
			if poison_ticks > 0 and not enemy.is_queued_for_deletion():
				enemy.apply_poison(poison_ticks, poison_damage)
			_already_hit.append(enemy)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1


func _draw() -> void:
	match style:
		"fragment":
			# Fragmento do bacamarte: bolinha quente com um rastro curto.
			draw_line(Vector2(-radius * 2.6, 0), Vector2.ZERO, Color(color, 0.45), radius * 1.2)
			draw_circle(Vector2.ZERO, radius, Color("c9962c"))
			draw_circle(Vector2.ZERO, radius * 0.6, color)
		"axe":
			# Machado: cabo curto e lâmina larga de aço, apontando para a frente.
			draw_line(Vector2(-14, 0), Vector2(6, 0), Brand.NIGHT, 6.0)
			draw_line(Vector2(-14, 0), Vector2(6, 0), Color("a8743a"), 3.0)
			var blade := PackedVector2Array([Vector2(4, -3), Vector2(8, -13), Vector2(17, -10), Vector2(15, 0), Vector2(17, 10), Vector2(8, 13), Vector2(4, 3)])
			draw_colored_polygon(blade, Brand.NIGHT)
			draw_colored_polygon(PackedVector2Array([Vector2(5, -3), Vector2(9, -11), Vector2(15, -9), Vector2(13, 0), Vector2(15, 9), Vector2(9, 11), Vector2(5, 3)]), color)
		"fire_arrow":
			draw_circle(Vector2(-16, 0), 9.0, Color(color, 0.3))
			draw_line(Vector2(-16, 0), Vector2(6, 0), Brand.NIGHT, 5.0)
			draw_line(Vector2(-16, 0), Vector2(6, 0), Color("c9a06a"), 2.5)
			draw_colored_polygon(PackedVector2Array([Vector2(5, -5), Vector2(16, 0), Vector2(5, 5)]), color)
			draw_circle(Vector2(-18, 0), 4.5, Color("ffd36b"))
			draw_circle(Vector2(-24, 0), 3.0, Color(color, 0.6))
		"slash":
			# Meia-lua de espada: arco largo voltado para a frente.
			var center := Vector2(-radius * 0.45, 0)
			draw_arc(center, radius, -1.05, 1.05, 24, Color(color, 0.28), radius * 0.55)
			draw_arc(center, radius, -1.05, 1.05, 24, Color(color, 0.95), 5.0)
			draw_arc(center, radius * 0.82, -0.85, 0.85, 20, Color(color, 0.55), 3.0)
		"arrow":
			draw_line(Vector2(-16, 0), Vector2(6, 0), Brand.NIGHT, 5.0)
			draw_line(Vector2(-16, 0), Vector2(6, 0), Color("c9a06a"), 2.5)
			draw_colored_polygon(PackedVector2Array([Vector2(5, -5), Vector2(15, 0), Vector2(5, 5)]), color)
			draw_line(Vector2(-16, 0), Vector2(-20, -4), color, 2.0)
			draw_line(Vector2(-16, 0), Vector2(-20, 4), color, 2.0)
		"fire":
			draw_circle(Vector2.ZERO, radius * 1.9, Color(color, 0.25))
			draw_circle(Vector2.ZERO, radius * 1.2, color)
			draw_circle(Vector2.ZERO, radius * 0.6, Color("fff2a0"))
			draw_circle(Vector2(-radius * 1.4, 0), radius * 0.7, Color(color, 0.6))
		_:
			draw_circle(Vector2.ZERO, radius * 1.8, Color(color, 0.25))
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE)
