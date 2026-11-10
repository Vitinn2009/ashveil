extends Node

## Prints da loja premium e do Viking: tools/shot_shop.tscn -- <pasta>
func _ready() -> void:
	Session.save_enabled = false
	Tuning.save_enabled = false
	var out := OS.get_cmdline_user_args()[0]
	Session.add_diamonds(350)
	var select: Node = (load("res://scenes/CharacterSelect.tscn") as PackedScene).instantiate()
	add_child(select)
	for i in 5:
		await get_tree().process_frame
	select.select_hero("viking")
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/s_viking.png" % out)
	select.queue_free()
	var castle: Node = (load("res://scenes/Castle.tscn") as PackedScene).instantiate()
	add_child(castle)
	for i in 6:
		await get_tree().process_frame
	castle.show_menu("diamonds")
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/s_packs.png" % out)
	castle._diamond_panel.show_tab("hero")
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/s_hero.png" % out)
	castle._diamond_panel.show_tab("gear")
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/s_gear.png" % out)
	get_tree().quit()
