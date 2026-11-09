extends Node

func _ready() -> void:
	Session.save_enabled = false
	var castle: Control = load("res://scenes/Castle.tscn").instantiate()
	add_child(castle)
	for i in 5:
		await get_tree().process_frame
	var panel: Control = castle._menu_panel
	print("panel min ", panel.get_combined_minimum_size(), " size ", panel.size, " pos ", panel.position)
	var column: Control = panel.get_child(0)
	for child in column.get_children():
		print("  ", child.get_class(), " ", child.name, " min ", child.get_combined_minimum_size(), " vis ", child.visible)
	for id in castle._pages:
		print("  page ", id, " min ", castle._pages[id].get_combined_minimum_size())
	for id in castle._menu_buttons:
		print("  button ", id, " min ", castle._menu_buttons[id].get_combined_minimum_size())
	get_tree().quit()
