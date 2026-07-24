extends GutTest

## Pruebas del helper puro de solape de spawn (sin nodos ni escena).
## Ver openspec/changes/mg-balloons-spawn-collision/.


func test_candidate_intersecting_active_footprint_is_not_clear() -> void:
	var candidate: Rect2 = Rect2(Vector2(-10, -10), Vector2(20, 20))
	var active_footprints: Array[Rect2] = [Rect2(Vector2(-5, -5), Vector2(20, 20))]

	assert_false(SpawnPlacement.is_position_clear(candidate, active_footprints))


func test_candidate_not_intersecting_any_footprint_is_clear() -> void:
	var candidate: Rect2 = Rect2(Vector2(0, 0), Vector2(20, 20))
	var active_footprints: Array[Rect2] = [Rect2(Vector2(100, 100), Vector2(20, 20))]

	assert_true(SpawnPlacement.is_position_clear(candidate, active_footprints))


func test_candidate_is_clear_when_no_active_footprints() -> void:
	var candidate: Rect2 = Rect2(Vector2(0, 0), Vector2(20, 20))
	var active_footprints: Array[Rect2] = []

	assert_true(SpawnPlacement.is_position_clear(candidate, active_footprints))


func test_every_candidate_in_a_saturated_range_is_rejected() -> void:
	# Simula el rango X válido completamente cubierto por globos activos
	# contiguos, como en el fallback de "skip" ejercitado en la tarea 3.
	var footprint_width: float = 220.0
	var active_footprints: Array[Rect2] = []
	for i: int in range(6):
		active_footprints.append(Rect2(Vector2(i * footprint_width, 0), Vector2(footprint_width, 280.0)))

	for attempt: int in range(8):
		var candidate_x: float = attempt * (footprint_width / 8.0)
		var candidate: Rect2 = Rect2(Vector2(candidate_x, 0), Vector2(footprint_width, 280.0))
		assert_false(
			SpawnPlacement.is_position_clear(candidate, active_footprints),
			"candidate at x=%s should be rejected in a saturated range" % candidate_x
		)
