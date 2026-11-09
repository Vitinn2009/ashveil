extends Node

## Print do duelo da arena PvP: tools/shot_pvp.tscn -- <arquivo.png> [herói rival]
func _ready() -> void:
	Session.save_enabled = false
	var args := OS.get_cmdline_user_args()
	Session.hero_id = "warrior"
	Session.pvp = true
	Session.pvp_rival = args[1] if args.size() > 1 else "mage"
	var game: Node = (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().create_timer(6.0).timeout
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()
