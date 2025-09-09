extends Control

# Visual component for drawing the selection rectangle
# This overlay shows the drag selection rectangle

var selection_color := Color(0.3, 0.8, 1.0, 0.3)  # Semi-transparent blue fill
var border_color := Color(1.0, 1.0, 1.0, 0.8)     # White border
var border_width := 2.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't intercept mouse events
	set_process(true)

func _draw():
	if SelectionManager.is_drawing_rect():
		var rect = SelectionManager.get_selection_rect()
		if rect.size.length() > 5.0:  # Only draw if rectangle is meaningful size
			# Draw filled rectangle
			draw_rect(rect, selection_color)
			# Draw border
			draw_rect(rect, border_color, false, border_width)

func _process(_delta):
	# Redraw when selection rectangle changes
	if SelectionManager.is_drawing_rect():
		queue_redraw()