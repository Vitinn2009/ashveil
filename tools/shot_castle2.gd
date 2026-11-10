extends Node

## Prints do castelo reorganizado: tools/shot_castle2.tscn -- <pasta>
func _ready() -> void:
	Session.save_enabled = false
	var out := OS.get_cmdline_user_args()[0]
	Session.set_progress("warrior", 20, 100.0, 3, 20)
	Session.inventory.gold = 3128
	for i in 12:
		Session.inventory.add_item(Item.roll(10, 20))
	var castle: Node = (load("res://scenes/Castle.tscn") as PackedScene).instantiate()
	add_child(castle)
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/c_a_default.png" % out)
	castle._inventory_window._attributes_toggle.button_pressed = true
	castle.show_menu("forge")
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/c_b_attr_forge.png" % out)
	castle._inventory_window._dropdown_button.button_pressed = true
	castle._inventory_window._bag_toggle.button_pressed = false
	castle.toggle_minimized()
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/c_c_dropdown_closed.png" % out)
	get_tree().quit()
