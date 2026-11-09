class_name Progression
extends RefCounted

## Nível do herói: acumulativo, sem nível máximo. O XP que falta para o próximo nível cresce de forma
## quadrática, então cada nível custa mais que o anterior. Cada nível dá pontos de habilidade para a
## futura árvore de habilidades.

const SKILL_POINTS_PER_LEVEL := 1
## Reduz o XP pedido por nível (os níveis sobem mais rápido).
const XP_SCALE := 0.6


## XP necessário para sair do nível `level` e ir para o seguinte.
static func xp_needed(level: int) -> float:
	var l := float(maxi(level, 1))
	return (5.0 + 0.8 * l * l + 1.5 * l) * XP_SCALE


## XP total gasto para chegar ao nível `level` (partindo do nível 1).
static func total_xp_to_reach(level: int) -> float:
	var total := 0.0
	for l in range(1, level):
		total += xp_needed(l)
	return total
