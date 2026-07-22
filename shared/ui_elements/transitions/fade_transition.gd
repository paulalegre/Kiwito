extends CanvasLayer

const FADE_DURATION: float = 0.35

@onready var _rect: ColorRect = $ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.color = Color(0.0, 0.0, 0.0, 0.0)
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
