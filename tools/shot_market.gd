extends Node

func _ready() -> void:
	Session.save_enabled = false
	Session.inventory.gold = 2500
	var castle: Node = (load("res://scenes/Castle.tscn") as PackedScene).instantiate()
	add_child(castle)
	for i in 5:
		await get_tree().process_frame
	castle.select_category(OS.get_cmdline_user_args()[0])
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[1])
	get_tree().quit()
