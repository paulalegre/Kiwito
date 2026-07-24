class_name SpawnPlacement
extends RefCounted

## Chequeo de solape puro para posicionamiento de spawn de globos (sin
## dependencia de nodos, escena ni Shape2D concreto). Ver
## openspec/changes/mg-balloons-spawn-collision/design.md.

static func is_position_clear(candidate: Rect2, active_footprints: Array[Rect2]) -> bool:
	for footprint: Rect2 in active_footprints:
		if candidate.intersects(footprint):
			return false
	return true
