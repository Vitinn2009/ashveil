class_name Skills
extends RefCounted

## Habilidades ativas. `cast` recebe o Game, que expõe player, weapon e world.

const DEFS := {
	"freeze": {
		"name": "Gelo",
		"desc": "Congela o chão: inimigos na área ficam 60% mais lentos por 5s.",
		"cooldown": 10.0,
		"color": Color("6ec6ff"),
		"glyph": "G",
	},
	"fire": {
		"name": "Fogo",
		"desc": "Bola de fogo que queima o inimigo 3 vezes.",
		"cooldown": 6.0,
		"color": Color("ff7a1a"),
		"glyph": "F",
	},
	"wind": {
		"name": "Vento",
		"desc": "Rajada que empurra os inimigos próximos.",
		"cooldown": 8.0,
		"color": Color("9be8c8"),
		"glyph": "V",
	},
	"double": {
		"name": "Flecha Dupla",
		"desc": "Dobra a quantidade de flechas por 6s.",
		"cooldown": 12.0,
		"color": Color("f2b705"),
		"glyph": "2x",
	},
	"haste": {
		"name": "Velocidade",
		"desc": "+50% de movimento e +40% de ataque por 6s.",
		"cooldown": 14.0,
		"color": Color("7bd389"),
		"glyph": "»",
	},
	"shield": {
		"name": "Escudo",
		"desc": "Absorve dano por 6s.",
		"cooldown": 12.0,
		"color": Color("4aa3ff"),
		"glyph": "E",
	},
}


static func def(id: String) -> Dictionary:
	return DEFS[id]


static func cast(id: String, game) -> void:
	match id:
		"freeze":
			_freeze(game)
		"fire":
			_fire(game)
		"wind":
			_wind(game)
		"double":
			game.player.double_time = 6.0
			_ring(game, 60.0, DEFS["double"]["color"], 0.4)
		"haste":
			game.player.haste_time = 6.0
			_ring(game, 70.0, DEFS["haste"]["color"], 0.4)
		"shield":
			game.player.activate_shield(6.0, 50.0 + game.player.get_defense() * 3.0)
			_ring(game, 60.0, DEFS["shield"]["color"], 0.4)


static func _ring(game, radius: float, color: Color, duration: float) -> void:
	var ring := RingEffect.new()
	ring.radius = radius
	ring.color = color
	ring.duration = duration
	game.world.add_child(ring)
	ring.global_position = game.player.global_position


static func _freeze(game) -> void:
	var zone := SkillZone.new()
	zone.radius = 170.0
	zone.duration = 5.0
	zone.slow_factor = 0.4
	game.world.add_child(zone)
	zone.global_position = game.player.global_position
	_ring(game, 170.0, DEFS["freeze"]["color"], 0.45)


static func _fire(game) -> void:
	var player: Player = game.player
	var targets: Array = game.weapon.find_targets(520.0)
	var direction: Vector2 = player.facing
	if not targets.is_empty():
		direction = (targets[0].global_position - player.global_position).normalized()
	var bolt := Projectile.new()
	bolt.style = "fire"
	bolt.color = DEFS["fire"]["color"]
	bolt.radius = 11.0
	bolt.damage = (16.0 + game.weapon.damage * 0.5) * player.get_damage_mult()
	bolt.velocity = direction * 380.0
	bolt.lifetime = 1.6
	bolt.burn_ticks = 3
	bolt.burn_damage = 8.0 * player.get_damage_mult()
	game.world.add_child(bolt)
	bolt.global_position = player.global_position


static func _wind(game) -> void:
	var player: Player = game.player
	_ring(game, 240.0, DEFS["wind"]["color"], 0.4)
	for node in game.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var offset := enemy.global_position - player.global_position
		if offset.length() <= 240.0:
			var direction := offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT
			enemy.knockback(direction * 560.0)
			enemy.take_damage(4.0 * player.get_damage_mult())
