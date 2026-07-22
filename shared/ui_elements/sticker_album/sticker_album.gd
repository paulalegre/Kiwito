extends CanvasLayer

## Modal del Álbum de Stickers (GDD_MVP.md §6): un slot por hito, silueta
## negra si está bloqueado, coloreado desde `Palette` si está desbloqueado.
## Cierre por toque en cualquier parte del fondo (cero texto, cero bloqueo
## para el niño).

signal closed

const SLOT_MIN_SIZE: Vector2 = Vector2(140.0, 140.0)
const UNLOCKED_COLOR_ID: StringName = &"red_coral"

@export var palette: Palette

@onready var _background: ColorRect = $Background
@onready var _grid: GridContainer = $Background/CenterContainer/GridContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_background.gui_input.connect(_on_background_gui_input)
	_populate_slots()

func _populate_slots() -> void:
	for milestone: Dictionary in ProgressionManager.MILESTONES:
		var sticker_id: StringName = milestone["sticker_id"]
		var slot: ColorRect = ColorRect.new()
		slot.custom_minimum_size = SLOT_MIN_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ProgressionManager.unlocked_stickers.has(sticker_id):
			slot.color = palette.get_color(UNLOCKED_COLOR_ID)
		else:
			slot.color = Color.BLACK
		_grid.add_child(slot)

func _on_background_gui_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return

	var touch: InputEventScreenTouch = event
	if touch.index != 0 or not touch.pressed:
		return

	closed.emit()
	get_viewport().set_input_as_handled()
