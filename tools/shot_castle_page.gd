extends Node

## Abre o castelo numa página do menu e salva uma captura. Uso:
##   godot --path . --resolution 1280x720 res://tools/shot_castle_page.tscn -- <página> <arquivo.png> [rolar]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Session.save_enabled = false
	Session.monster_kills = {"slime": 12, "bat": 60}
	Session.grant_pet("slime_king")
	Session.grant_pet("m_bat")
	Session.grant_pet("m_wolf")
	Session.pet_levels = {"m_wolf": 14}
	Session.monster_kills = {"bat": 1000, "wolf": 1200, "ghost": 640, "brute": 130}
	Session.inventory.gold = 500
	Session.inventory.stone = 30
	Session.inventory.moonstone = 4
	Session.inventory.scrolls = 2
	Session.inventory.fragments = [12, 30, 8, 2, 1]
	Session.inventory.runes = {"critdmg_A": 3, "attack_C": 5, "hp_B": 4, "attack_S": 1}

	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for slot_name in Item.SLOTS:
		Session.inventory.equipped[slot_name] = Item.create(rng, slot_name, 0, 20, 3, 2)
	Session.inventory.equipped["weapon"].forge = 6
	Session.inventory.equipped["weapon"].insert_rune("attack_C")
	Session.hero_progress = {"warrior": {"level": 30, "xp": 10.0, "points": 30, "earned": 30}}
	Session.skill_tree = {"warrior": {"root": 3, "b0_1": 5, "b0_2": 2, "b1_1": 1}}
	var castle: Node = (load("res://scenes/Castle.tscn") as PackedScene).instantiate()
	add_child(castle)
	for i in 5:
		await get_tree().process_frame
	castle.show_menu(args[0])
	for i in 10:
		await get_tree().process_frame
	if args.size() > 2 and args[2] == "popup":
		castle.open_mission_popup()
		for i in 5:
			await get_tree().process_frame
	elif args.size() > 2:
		for n in int(args[2]):
			var wheel := InputEventMouseButton.new()
			wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
			wheel.pressed = true
			wheel.position = Vector2(1000, 400)
			wheel.global_position = wheel.position
			get_viewport().push_input(wheel)
			await get_tree().process_frame
		for i in 5:
			await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args[1])
	print("SHOT ", args[1])
	get_tree().quit()
