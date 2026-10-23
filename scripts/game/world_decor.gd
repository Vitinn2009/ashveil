class_name WorldDecor
extends Node

## Cenário infinito. O mundo é dividido em pedaços (chunks) quadrados. Em volta
## do herói, cada pedaço recebe árvores, arbustos, pedras, flores e outros
## detalhes, sorteados a partir do seed do mundo e das coordenadas do pedaço,
## então o mesmo pedaço sempre nasce igual. Pedaços longe demais são removidos.
##
## Itens "sólidos" (árvores, pedras...) ficam no mesmo nó ordenado por Y que o
## herói e os inimigos, para o herói passar na frente ou atrás deles. Itens
## "rasteiros" (flores, tufos, terra) ficam abaixo de todos.

const CHUNK_SIZE := 640.0
const LOAD_RADIUS := 2
const UNLOAD_RADIUS := 3
const SAFE_RADIUS := 150.0
const GROUND_Z := -50
const CELLS := 4

## `foot` é quantos pixels da textura ficam abaixo do ponto onde o objeto toca o chão.
const TYPES := {
	"oak": {"path": "res://assets/world/tree_oak.svg", "foot": 12.0, "ground": false, "scale": Vector2(0.62, 0.9)},
	"pine": {"path": "res://assets/world/tree_pine.svg", "foot": 12.0, "ground": false, "scale": Vector2(0.55, 0.8)},
	"bush": {"path": "res://assets/world/bush.svg", "foot": 10.0, "ground": false, "scale": Vector2(0.7, 1.1)},
	"rock_a": {"path": "res://assets/world/rock_a.svg", "foot": 10.0, "ground": false, "scale": Vector2(0.7, 1.1)},
	"rock_b": {"path": "res://assets/world/rock_b.svg", "foot": 8.0, "ground": false, "scale": Vector2(0.7, 1.1)},
	"log": {"path": "res://assets/world/log.svg", "foot": 8.0, "ground": false, "scale": Vector2(0.75, 1.0)},
	"stump": {"path": "res://assets/world/stump.svg", "foot": 8.0, "ground": false, "scale": Vector2(0.75, 1.0)},
	"mushroom": {"path": "res://assets/world/mushroom.svg", "foot": 5.0, "ground": false, "scale": Vector2(0.8, 1.2)},
	"flowers_white": {"path": "res://assets/world/flowers_white.svg", "foot": 2.0, "ground": true, "scale": Vector2(0.8, 1.2)},
	"flowers_red": {"path": "res://assets/world/flowers_red.svg", "foot": 2.0, "ground": true, "scale": Vector2(0.8, 1.2)},
	"flowers_blue": {"path": "res://assets/world/flowers_blue.svg", "foot": 2.0, "ground": true, "scale": Vector2(0.8, 1.2)},
	"tuft": {"path": "res://assets/world/tuft.svg", "foot": 3.0, "ground": true, "scale": Vector2(0.7, 1.3)},
	"dirt": {"path": "res://assets/world/patch_dirt.svg", "foot": 50.0, "ground": true, "scale": Vector2(0.9, 1.6)},
}

var follow: Node2D
var world: Node2D
var world_seed := 0
var _chunks := {}
var _center := Vector2i(1 << 20, 1 << 20)
var _textures := {}
var _noise := FastNoiseLite.new()


func _ready() -> void:
	if world_seed == 0:
		world_seed = randi()
	_noise.seed = world_seed
	_noise.frequency = 0.35
	for kind in TYPES:
		_textures[kind] = load(TYPES[kind]["path"])
	_refresh()


func _process(_delta: float) -> void:
	if follow and chunk_of(follow.global_position) != _center:
		_refresh()


static func chunk_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / CHUNK_SIZE), floori(point.y / CHUNK_SIZE))


func loaded_chunk_count() -> int:
	return _chunks.size()


func decor_count() -> int:
	var total := 0
	for sprites in _chunks.values():
		total += sprites.size()
	return total


## Lista [{kind, position, ground}] de um pedaço, sem criar nenhum nó. É o que
## torna o cenário determinístico e testável.
func plan_chunk(chunk: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(chunk.x, chunk.y, world_seed))
	var origin := Vector2(chunk) * CHUNK_SIZE
	var center := origin + Vector2.ONE * CHUNK_SIZE * 0.5
	# Ruído suave define florestas densas e clareiras.
	var forest := remap(_noise.get_noise_2d(center.x / CHUNK_SIZE, center.y / CHUNK_SIZE), -1.0, 1.0, 0.08, 0.6)
	var plan: Array = []

	var cell_size := CHUNK_SIZE / CELLS
	for cy in CELLS:
		for cx in CELLS:
			if rng.randf() < forest * 0.5:
				var kind := "oak" if rng.randf() < 0.55 else "pine"
				plan.append(_entry(kind, origin + Vector2(cx + rng.randf(), cy + rng.randf()) * cell_size))
	_scatter(plan, rng, origin, ["bush"], roundi(2.0 + forest * 5.0))
	_scatter(plan, rng, origin, ["rock_a", "rock_b"], rng.randi_range(1, 3))
	_scatter(plan, rng, origin, ["log", "stump"], 1 if rng.randf() < 0.5 else 0)
	_scatter(plan, rng, origin, ["mushroom"], rng.randi_range(0, 3))
	_scatter(plan, rng, origin, ["flowers_white", "flowers_red", "flowers_blue"], roundi(3.0 + (0.6 - forest) * 8.0))
	_scatter(plan, rng, origin, ["tuft"], 18)
	_scatter(plan, rng, origin, ["dirt"], rng.randi_range(1, 3))
	return plan


func _scatter(plan: Array, rng: RandomNumberGenerator, origin: Vector2, kinds: Array, count: int) -> void:
	for i in count:
		var kind: String = kinds[rng.randi() % kinds.size()]
		plan.append(_entry(kind, origin + Vector2(rng.randf(), rng.randf()) * CHUNK_SIZE))


func _entry(kind: String, point: Vector2) -> Dictionary:
	return {"kind": kind, "position": point, "ground": TYPES[kind]["ground"]}


func _refresh() -> void:
	_center = chunk_of(follow.global_position) if follow else Vector2i.ZERO
	for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk := _center + Vector2i(dx, dy)
			if not _chunks.has(chunk):
				_load_chunk(chunk)
	for chunk in _chunks.keys():
		if absi(chunk.x - _center.x) > UNLOAD_RADIUS or absi(chunk.y - _center.y) > UNLOAD_RADIUS:
			_unload_chunk(chunk)


func _load_chunk(chunk: Vector2i) -> void:
	var sprites: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(chunk.x, chunk.y, world_seed + 1))
	for entry in plan_chunk(chunk):
		if entry["position"].length() < SAFE_RADIUS:
			continue
		sprites.append(_make_sprite(entry, rng))
	_chunks[chunk] = sprites


func _unload_chunk(chunk: Vector2i) -> void:
	for sprite in _chunks[chunk]:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_chunks.erase(chunk)


func _make_sprite(entry: Dictionary, rng: RandomNumberGenerator) -> Sprite2D:
	var kind: String = entry["kind"]
	var data: Dictionary = TYPES[kind]
	var sprite := Sprite2D.new()
	var texture: Texture2D = _textures[kind]
	sprite.texture = texture
	var range_scale: Vector2 = data["scale"]
	sprite.scale = Vector2.ONE * rng.randf_range(range_scale.x, range_scale.y)
	sprite.flip_h = rng.randf() < 0.5
	# O ponto de referência fica no chão, para a ordenação por Y funcionar.
	sprite.offset = Vector2(0, -texture.get_height() * 0.5 + data["foot"])
	sprite.position = entry["position"]
	if data["ground"]:
		sprite.z_index = GROUND_Z
		if kind == "tuft" or kind.begins_with("flowers"):
			sprite.modulate = Color.WHITE.lerp(Color(0.8, 0.9, 0.75), rng.randf() * 0.5)
	world.add_child(sprite)
	return sprite
