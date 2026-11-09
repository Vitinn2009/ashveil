class_name QuickBar
extends VBoxContainer

## Slots de poção e comidas numa coluna na lateral direita da tela (toque para usar).

signal consumable_requested(id: String)

const SLOT := 56.0

var _inventory: Inventory
var _slots := {}


func bind(inventory: Inventory) -> void:
	_inventory = inventory
	add_theme_constant_override("separation", 6)
	for id in InventoryWindow.CONSUMABLES:
		var slot := ItemSlot.new(SLOT)
		slot.pressed.connect(func() -> void: consumable_requested.emit(id))
		_slots[id] = slot
		add_child(slot)
	inventory.changed.connect(refresh)
	refresh()


func refresh() -> void:
	for id in _slots:
		_slots[id].show_consumable(id, _inventory.count(id))
