extends Node

## Eventos globais que desacoplam combate, drops e interface.

## `loot` é false para inimigos que não soltam nada (gosmas pequenas).
signal enemy_killed(at_position: Vector2, xp_value: int, loot: bool)
## kind: "xp", "gold", "potion" ou "item". payload: quantidade ou Item.
signal pickup_collected(kind: String, payload: Variant)
