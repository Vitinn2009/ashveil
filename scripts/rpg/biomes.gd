class_name Biomes
extends RefCounted

## Cenários das fases. As 10 primeiras são na floresta (o cenário original); depois entram 5 cenários novos,
## um a cada 10 fases: deserto, neve, vulcão, pântano e cripta. Passada a cripta, a ordem recomeça.
## Cada cenário muda o chão, os objetos espalhados e a cor do ar.

const STAGES_PER_BIOME := 10

const LIST := [
	{
		"id": "forest", "name": "Floresta", "tint": Color(1, 1, 1),
		"blurb": "O campo verde onde tudo começa.",
	},
	{
		"id": "desert", "name": "Deserto Escaldante", "tint": Color(1.06, 0.97, 0.86),
		"blurb": "Dunas, cactos e ossos ao sol.",
		"ground": {"base": Color("d8b878"), "speck": [Color("c9a566"), Color("e6cb92"), Color("b8924f")], "pattern": "dunes", "density": 900},
		"big": [["cactus", 5], ["dune_rock", 3], ["dead_bush", 2]], "big_density": 0.16,
		"small": ["dead_bush", "dune_rock"], "small_count": 3,
		"ground_decor": ["bones", "sand_patch"], "ground_count": 5,
	},
	{
		"id": "snow", "name": "Montanhas Geladas", "tint": Color(0.92, 0.98, 1.08),
		"blurb": "Neve funda, pinheiros brancos e cristais de gelo.",
		"ground": {"base": Color("e8f1f8"), "speck": [Color("c7dcec"), Color("ffffff"), Color("b4cde0")], "pattern": "snow", "density": 1100},
		"big": [["snow_pine", 6], ["ice_crystal", 3], ["snow_rock", 3]], "big_density": 0.3,
		"small": ["snow_rock", "ice_crystal"], "small_count": 3,
		"ground_decor": ["frost_patch", "snow_tuft"], "ground_count": 8,
	},
	{
		"id": "volcano", "name": "Vulcão em Chamas", "tint": Color(1.1, 0.88, 0.8),
		"blurb": "Rocha negra, poças de lava e árvores queimadas.",
		"ground": {"base": Color("2b2422"), "speck": [Color("3a302c"), Color("1c1614"), Color("463a34")], "pattern": "lava", "density": 700},
		"big": [["charred_tree", 4], ["obsidian", 5]], "big_density": 0.2,
		"small": ["obsidian", "charred_tree"], "small_count": 3,
		"ground_decor": ["lava_pool", "ash_patch"], "ground_count": 5,
	},
	{
		"id": "swamp", "name": "Pântano Sombrio", "tint": Color(0.86, 1.0, 0.9),
		"blurb": "Lama, juncos e árvores retorcidas na névoa.",
		"ground": {"base": Color("3d4a2e"), "speck": [Color("2f3b23"), Color("4d5c3a"), Color("5a6a46")], "pattern": "mud", "density": 800},
		"big": [["dead_tree", 6], ["swamp_mushroom", 3]], "big_density": 0.3,
		"small": ["swamp_mushroom", "dead_tree"], "small_count": 3,
		"ground_decor": ["puddle", "reeds"], "ground_count": 9,
	},
	{
		"id": "crypt", "name": "Cripta Esquecida", "tint": Color(0.82, 0.82, 1.0),
		"blurb": "Lajes antigas, lápides e colunas quebradas.",
		"ground": {"base": Color("4a4a58"), "speck": [Color("3c3c48"), Color("5a5a6a"), Color("33333e")], "pattern": "tiles", "density": 600},
		"big": [["tombstone", 6], ["column", 3]], "big_density": 0.2,
		"small": ["tombstone", "candles"], "small_count": 3,
		"ground_decor": ["bones", "candles"], "ground_count": 5,
	},
]

## Objetos novos: `foot`, `ground` (rasteiro) e `scale` (mínimo e máximo), como em WorldDecor.TYPES.
## `path` reaproveita uma arte existente (com `tint`); sem `path`, o desenho vem de SVG_DECOR.
const DECOR_TYPES := {
	"cactus": {"foot": 6.0, "ground": false, "scale": Vector2(0.8, 1.2)},
	"dune_rock": {"path": "res://assets/world/rock_a.svg", "tint": Color(1.15, 0.95, 0.7), "foot": 10.0, "ground": false, "scale": Vector2(0.7, 1.2)},
	"dead_bush": {"foot": 4.0, "ground": false, "scale": Vector2(0.8, 1.2)},
	"bones": {"foot": 3.0, "ground": true, "scale": Vector2(0.8, 1.2)},
	"sand_patch": {"foot": 30.0, "ground": true, "scale": Vector2(0.9, 1.6)},
	"snow_pine": {"path": "res://assets/world/tree_pine.svg", "tint": Color(0.82, 0.95, 1.25), "foot": 12.0, "ground": false, "scale": Vector2(0.55, 0.8)},
	"ice_crystal": {"foot": 6.0, "ground": false, "scale": Vector2(0.8, 1.3)},
	"snow_rock": {"path": "res://assets/world/rock_b.svg", "tint": Color(0.9, 1.05, 1.25), "foot": 8.0, "ground": false, "scale": Vector2(0.7, 1.2)},
	"frost_patch": {"foot": 30.0, "ground": true, "scale": Vector2(0.9, 1.6)},
	"snow_tuft": {"path": "res://assets/world/tuft.svg", "tint": Color(1.1, 1.2, 1.3), "foot": 3.0, "ground": true, "scale": Vector2(0.7, 1.3)},
	"charred_tree": {"path": "res://assets/world/tree_oak.svg", "tint": Color(0.3, 0.24, 0.22), "foot": 12.0, "ground": false, "scale": Vector2(0.6, 0.85)},
	"obsidian": {"path": "res://assets/world/rock_a.svg", "tint": Color(0.35, 0.3, 0.4), "foot": 10.0, "ground": false, "scale": Vector2(0.8, 1.3)},
	"lava_pool": {"foot": 40.0, "ground": true, "scale": Vector2(0.9, 1.5)},
	"ash_patch": {"foot": 30.0, "ground": true, "scale": Vector2(0.9, 1.6)},
	"dead_tree": {"foot": 8.0, "ground": false, "scale": Vector2(0.8, 1.2)},
	"swamp_mushroom": {"path": "res://assets/world/mushroom.svg", "tint": Color(0.7, 1.1, 0.8), "foot": 5.0, "ground": false, "scale": Vector2(1.2, 1.9)},
	"puddle": {"foot": 30.0, "ground": true, "scale": Vector2(0.9, 1.6)},
	"reeds": {"foot": 3.0, "ground": true, "scale": Vector2(0.8, 1.2)},
	"tombstone": {"foot": 4.0, "ground": false, "scale": Vector2(0.8, 1.2)},
	"column": {"foot": 6.0, "ground": false, "scale": Vector2(0.8, 1.1)},
	"candles": {"foot": 3.0, "ground": true, "scale": Vector2(0.8, 1.2)},
}

const SVG_HEAD := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 80' width='64' height='80'><g stroke='#120a05' stroke-width='2.5' stroke-linejoin='round' stroke-linecap='round'>"
const SVG_TAIL := "</g></svg>"
const SVG_DECOR := {
	"cactus": "<rect x='25' y='20' width='14' height='52' rx='7' fill='#4f9a4a'/><path d='M25 44h-8a5 5 0 0 1-5-5V30a4 4 0 0 1 8 0v5h5z' fill='#4f9a4a'/><path d='M39 36h8a5 5 0 0 0 5-5V24a4 4 0 0 0-8 0v4h-5z' fill='#4f9a4a'/><path d='M32 24v40M20 36v4M44 28v4' stroke='#2f6a2c' stroke-width='1.5' fill='none'/>",
	"dead_bush": "<path d='M32 72V46M32 56L18 40M32 52L46 34M32 46L26 26M32 60L50 50' stroke='#7a5a34' stroke-width='4' fill='none'/>",
	"bones": "<g transform='translate(0 10)'><path d='M12 56L50 40' stroke='#e8e0cc' stroke-width='6' fill='none'/><circle cx='11' cy='57' r='5' fill='#e8e0cc'/><circle cx='51' cy='39' r='5' fill='#e8e0cc'/><circle cx='34' cy='28' r='10' fill='#efe8d8'/><circle cx='30' cy='27' r='2.500' fill='#2a1f12'/><circle cx='38' cy='27' r='2.500' fill='#2a1f12'/></g>",
	"sand_patch": "<ellipse cx='32' cy='62' rx='26' ry='9' fill='#c9a566' stroke='none' opacity='0.6'/>",
	"ice_crystal": "<polygon points='32,6 42,34 36,72 28,72 22,34' fill='#9fdcff'/><polygon points='14,38 20,26 24,40 22,72 12,72' fill='#7ac4ee'/><polygon points='50,42 44,30 40,44 42,72 52,72' fill='#bfe9ff'/><path d='M32 10v30' stroke='#e8f8ff' stroke-width='2' fill='none'/>",
	"frost_patch": "<ellipse cx='32' cy='62' rx='24' ry='8' fill='#c7dcec' stroke='none' opacity='0.7'/>",
	"lava_pool": "<ellipse cx='32' cy='60' rx='27' ry='12' fill='#ff6a1a' stroke='#3a1a0c'/><ellipse cx='32' cy='60' rx='18' ry='7' fill='#ffb02e' stroke='none'/><ellipse cx='28' cy='58' rx='8' ry='3' fill='#fff0a0' stroke='none'/>",
	"ash_patch": "<ellipse cx='32' cy='62' rx='24' ry='8' fill='#14100f' stroke='none' opacity='0.5'/>",
	"dead_tree": "<path d='M28 74V40L18 26M30 52L44 36M29 40L34 20M44 36l8-8M18 26l-8-2' stroke='#4a3a2a' stroke-width='6' fill='none'/><path d='M28 74V40' stroke='#6a5238' stroke-width='3' fill='none'/>",
	"puddle": "<ellipse cx='32' cy='62' rx='26' ry='10' fill='#2f5a52' stroke='#1a2e2a'/><ellipse cx='26' cy='60' rx='10' ry='3.500' fill='#5a8f84' stroke='none' opacity='0.7'/>",
	"reeds": "<path d='M22 74V30M30 74V20M38 74V28M46 74V38' stroke='#6a8a3a' stroke-width='4' fill='none'/><ellipse cx='30' cy='20' rx='3' ry='7' fill='#7a5a34'/><ellipse cx='38' cy='28' rx='3' ry='6' fill='#7a5a34'/>",
	"tombstone": "<path d='M14 74V32a18 18 0 0 1 36 0v42z' fill='#8d909c'/><path d='M32 28v22M24 36h16' stroke='#4a4d58' stroke-width='3' fill='none'/><path d='M14 74h36' stroke='#4a4d58' stroke-width='3' fill='none'/>",
	"column": "<rect x='20' y='10' width='24' height='62' rx='2' fill='#a0a3ae'/><rect x='16' y='6' width='32' height='8' rx='2' fill='#b8bbc6'/><rect x='16' y='68' width='32' height='8' rx='2' fill='#b8bbc6'/><path d='M28 14v54M36 14v54' stroke='#6a6d78' stroke-width='1.500' fill='none'/><path d='M20 28l24 6' stroke='#4a4d58' stroke-width='2' fill='none'/>",
	"candles": "<rect x='16' y='50' width='8' height='22' fill='#efe8d8'/><rect x='30' y='44' width='9' height='28' fill='#efe8d8'/><rect x='45' y='52' width='8' height='20' fill='#efe8d8'/><path d='M20 48c-3-5 0-8 0-10 3 2 4 6 0 10zM34 42c-3-5 0-8 0-10 4 2 5 6 0 10zM49 50c-3-5 0-8 0-10 3 2 4 6 0 10z' fill='#ffb02e' stroke='none'/>",
}

static var _ground_cache := {}
static var _decor_cache := {}


static func count() -> int:
	return LIST.size()


## O cenário da fase de índice `index` (0 = fase 1): floresta nas 10 primeiras, depois os 5 novos em ordem.
static func index_for_stage(index: int) -> int:
	return (maxi(index, 0) / STAGES_PER_BIOME) % LIST.size()


static func for_stage(index: int) -> Dictionary:
	return LIST[index_for_stage(index)]


## Os objetos de um cenário novo (vazio na floresta, que usa o cenário original).
static func decor_textures_needed(biome: Dictionary) -> Array:
	var kinds: Array = []
	for entry in biome.get("big", []):
		kinds.append(entry[0])
	kinds.append_array(biome.get("small", []))
	kinds.append_array(biome.get("ground_decor", []))
	return kinds


## Textura de um objeto novo: a arte reaproveitada ou o SVG desenhado aqui.
static func decor_texture(kind: String) -> Texture2D:
	if _decor_cache.has(kind):
		return _decor_cache[kind]
	var data: Dictionary = DECOR_TYPES[kind]
	var texture: Texture2D
	if data.has("path"):
		texture = load(String(data["path"]))
	else:
		var image := Image.new()
		image.load_svg_from_string(SVG_HEAD + String(SVG_DECOR[kind]) + SVG_TAIL, 1.0)
		texture = ImageTexture.create_from_image(image)
	_decor_cache[kind] = texture
	return texture


## O chão do cenário: um ladrilho de 256 px que se repete sem emenda (tudo é desenhado com volta nas bordas).
static func ground_texture(biome: Dictionary) -> Texture2D:
	var id: String = biome["id"]
	if not biome.has("ground"):
		return load("res://assets/world/grass.png")
	if _ground_cache.has(id):
		return _ground_cache[id]
	var spec: Dictionary = biome["ground"]
	var size := 256
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(spec["base"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var specks: Array = spec["speck"]
	# Manchas grandes e suaves, para o chão não ficar chapado.
	for i in 26:
		_blob(image, rng.randi_range(0, size - 1), rng.randi_range(0, size - 1), rng.randi_range(10, 26), Color(specks[rng.randi() % specks.size()], 0.35))
	for i in int(spec["density"]):
		var color: Color = specks[rng.randi() % specks.size()]
		_put(image, rng.randi_range(0, size - 1), rng.randi_range(0, size - 1), color)
	match String(spec["pattern"]):
		"dunes":
			for row in range(0, size, 32):
				for x in size:
					_put(image, x, row + int(sin(float(x) / size * TAU * 2.0) * 7.0), Color(specks[2], 0.55))
		"snow":
			for i in 40:
				_blob(image, rng.randi_range(0, size - 1), rng.randi_range(0, size - 1), rng.randi_range(3, 7), Color("ffffff", 0.7))
		"lava":
			for i in 7:
				var x := rng.randi_range(0, size - 1)
				var y := rng.randi_range(0, size - 1)
				for step in 40:
					x += rng.randi_range(-2, 3)
					y += rng.randi_range(-1, 3)
					_put(image, x, y, Color("ff6a1a"))
					_put(image, x + 1, y, Color("ffb02e", 0.8))
		"mud":
			for i in 22:
				_blob(image, rng.randi_range(0, size - 1), rng.randi_range(0, size - 1), rng.randi_range(2, 5), Color("6f8a5a", 0.8))
			for i in 8:
				_blob(image, rng.randi_range(0, size - 1), rng.randi_range(0, size - 1), rng.randi_range(8, 14), Color("2a3a30", 0.5))
		"tiles":
			for line in range(0, size, 64):
				for k in size:
					_put(image, line, k, Color("2a2a34"))
					_put(image, k, line, Color("2a2a34"))
					_put(image, line + 1, k, Color("62627a", 0.6))
					_put(image, k, line + 1, Color("62627a", 0.6))
	var texture := ImageTexture.create_from_image(image)
	_ground_cache[id] = texture
	return texture


static func _put(image: Image, x: int, y: int, color: Color) -> void:
	var size := image.get_width()
	var px := posmod(x, size)
	var py := posmod(y, size)
	if color.a >= 0.99:
		image.set_pixel(px, py, color)
	else:
		image.set_pixel(px, py, image.get_pixel(px, py).lerp(Color(color, 1.0), color.a))


static func _blob(image: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var distance := sqrt(float(dx * dx + dy * dy))
			if distance <= radius:
				_put(image, cx + dx, cy + dy, Color(color, color.a * (1.0 - distance / (radius + 1.0))))
