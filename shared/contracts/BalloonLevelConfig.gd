class_name BalloonLevelConfig
extends LevelConfig

## Tunables del cartucho Explotaglobos (GDD_MVP.md §5). Sin valores hardcodeados
## en mg_balloons.gd: todo lo que varía por nivel vive aquí.

@export var target_color_id: StringName = &""
@export var win_count: int = 5
@export var spawn_interval_sec: float = 1.5
@export var ascent_speed: float = 80.0
