class_name Weapon
extends Node

## Arma automática: dispara projéteis contra os inimigos mais próximos.

var damage := 12.0
var fire_interval := 0.6
var attack_range := 280.0
var projectile_speed := 480.0
var projectile_count := 1
var _owner_node: Node2D
var _world: Node2D
var _cooldown := 0.0


func setup(owner_node: Node2D, world: Node2D) -> void:
	_owner_node = owner_node
	_world = world


func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var targets := _find_targets()
	if targets.is_empty():
		return
	_cooldown = fire_interval
	for i in range(min(projectile_count, targets.size())):
		_fire_at(targets[i])


func _find_targets() -> Array:
	var origin := _owner_node.global_position
	var max_distance_squared := attack_range * attack_range
	var in_range: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			if origin.distance_squared_to(enemy.global_position) <= max_distance_squared:
				in_range.append(enemy)
	in_range.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	return in_range


func _fire_at(target: Node2D) -> void:
	var projectile := Projectile.new()
	projectile.damage = damage
	projectile.velocity = (target.global_position - _owner_node.global_position).normalized() * projectile_speed
	projectile.lifetime = attack_range * 1.5 / projectile_speed
	_world.add_child(projectile)
	projectile.global_position = _owner_node.global_position
