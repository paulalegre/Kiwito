extends CanvasLayer

## Fundido a Crema, no a negro (Direccion_de_Arte.md §7): el negro pleno es
## una interrupción brusca y ansiógena para un niño pequeño.

const FADE_DURATION: float = 0.35

@export var palette: Palette

@onready var _rect: ColorRect = $ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fade_color: Color = palette.get_color(&"cream_fade") if palette != null else Color.BLACK
	fade_color.a = 0.0
	_rect.color = fade_color
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out() -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

func fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "color:a", 0.0, FADE_DURATION)
	await tween.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
