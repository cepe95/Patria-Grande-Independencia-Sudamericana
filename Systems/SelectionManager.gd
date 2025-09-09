extends Node

# Singleton para manejar la selección de unidades
# This manager handles all unit selection logic including:
# - Individual unit selection
# - Multi-selection with rectangle
# - Visual feedback for selected units
# - Movement orders

signal selection_changed(selected_units: Array)

var selected_units: Array[Node] = []  # Array of selected unit instances
var is_drawing_selection_rect := false
var selection_start_pos: Vector2
var selection_rect: Rect2

# Visual feedback constants
const SELECTION_COLOR := Color(0.3, 0.8, 1.0, 0.7)  # Light blue
const SELECTION_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 1.0)  # White outline

func _ready():
	set_process_unhandled_input(true)

# Select a single unit, replacing current selection unless shift is held
func select_unit(unit: Node, add_to_selection: bool = false) -> void:
	if not add_to_selection:
		clear_selection()
	
	if unit and not selected_units.has(unit):
		selected_units.append(unit)
		_apply_selection_visual(unit, true)
		print("✅ Unit selected: ", unit.name if unit.has_method("get_name") else "Unknown")
	
	selection_changed.emit(selected_units.duplicate())

# Remove a unit from selection
func deselect_unit(unit: Node) -> void:
	if selected_units.has(unit):
		selected_units.erase(unit)
		_apply_selection_visual(unit, false)
		print("❌ Unit deselected: ", unit.name if unit.has_method("get_name") else "Unknown")
	
	selection_changed.emit(selected_units.duplicate())

# Select multiple units within a rectangle
func select_units_in_rect(rect: Rect2, units_container: Node, add_to_selection: bool = false, camera: Camera2D = null) -> void:
	if not add_to_selection:
		clear_selection()
	
	# Convert screen rectangle to world coordinates if camera is provided
	var world_rect = rect
	if camera:
		var top_left_world = camera.get_screen_center_position() + (rect.position - camera.get_viewport().get_visible_rect().size / 2) / camera.zoom
		var bottom_right_world = camera.get_screen_center_position() + (rect.position + rect.size - camera.get_viewport().get_visible_rect().size / 2) / camera.zoom
		world_rect = Rect2(top_left_world, bottom_right_world - top_left_world)
	
	for unit in units_container.get_children():
		if _is_unit_selectable(unit) and _is_unit_in_rect(unit, world_rect):
			if not selected_units.has(unit):
				selected_units.append(unit)
				_apply_selection_visual(unit, true)
	
	print("📦 Selected ", selected_units.size(), " units in rectangle")
	selection_changed.emit(selected_units.duplicate())

# Clear all selections
func clear_selection() -> void:
	for unit in selected_units:
		_apply_selection_visual(unit, false)
	
	var count = selected_units.size()
	selected_units.clear()
	
	if count > 0:
		print("🔄 Cleared selection of ", count, " units")
		selection_changed.emit(selected_units.duplicate())

# Get currently selected units
func get_selected_units() -> Array[Node]:
	return selected_units.duplicate()

# Check if a unit is currently selected
func is_unit_selected(unit: Node) -> bool:
	return selected_units.has(unit)

# Move all selected units to a target position with spacing
func move_selected_units_to(target_pos: Vector2, spacing: float = 50.0) -> void:
	if selected_units.is_empty():
		print("⚠️ No units selected for movement")
		return
	
	print("🚶 Moving ", selected_units.size(), " units to position: ", target_pos)
	
	# If single unit, move directly to target
	if selected_units.size() == 1:
		_move_unit_to(selected_units[0], target_pos)
		return
	
	# For multiple units, arrange them in a formation around the target
	var positions = _calculate_formation_positions(target_pos, selected_units.size(), spacing)
	
	for i in range(selected_units.size()):
		_move_unit_to(selected_units[i], positions[i])

# Start drawing selection rectangle
func start_selection_rect(start_pos: Vector2) -> void:
	is_drawing_selection_rect = true
	selection_start_pos = start_pos
	selection_rect = Rect2(start_pos, Vector2.ZERO)

# Update selection rectangle while dragging
func update_selection_rect(current_pos: Vector2) -> void:
	if not is_drawing_selection_rect:
		return
	
	var top_left = Vector2(
		min(selection_start_pos.x, current_pos.x),
		min(selection_start_pos.y, current_pos.y)
	)
	var size = Vector2(
		abs(current_pos.x - selection_start_pos.x),
		abs(current_pos.y - selection_start_pos.y)
	)
	selection_rect = Rect2(top_left, size)

# Finish drawing selection rectangle
func finish_selection_rect(units_container: Node, add_to_selection: bool = false, camera: Camera2D = null) -> void:
	if not is_drawing_selection_rect:
		return
	
	is_drawing_selection_rect = false
	
	# Only select if the rectangle has meaningful size
	if selection_rect.size.length() > 10.0:
		select_units_in_rect(selection_rect, units_container, add_to_selection, camera)

# Get current selection rectangle for drawing
func get_selection_rect() -> Rect2:
	return selection_rect if is_drawing_selection_rect else Rect2()

# Check if currently drawing selection rectangle
func is_drawing_rect() -> bool:
	return is_drawing_selection_rect

# Private helper methods

func _apply_selection_visual(unit: Node, selected: bool) -> void:
	if not unit:
		return
	
	# Apply visual feedback based on unit type
	if unit.has_method("set_selected"):
		unit.set_selected(selected)
	elif unit.has_node("Sprite2D"):
		var sprite = unit.get_node("Sprite2D")
		if selected:
			sprite.modulate = SELECTION_COLOR
		else:
			sprite.modulate = Color.WHITE
	elif unit.has_node("Icon"):
		var icon = unit.get_node("Icon")
		if selected:
			icon.modulate = SELECTION_COLOR
		else:
			icon.modulate = Color.WHITE
	else:
		# Fallback: modulate the entire unit
		if selected:
			unit.modulate = SELECTION_COLOR
		else:
			unit.modulate = Color.WHITE

func _is_unit_selectable(unit: Node) -> bool:
	# Check if the unit belongs to the player's faction
	if unit.has_method("is_player_unit"):
		return unit.is_player_unit()
	elif unit.has("data") and unit.data:
		var unit_data = unit.data
		if unit_data.has("faccion"):
			return unit_data.faccion == "Patriota"
		elif unit_data.has_method("get") and unit_data.has_method("has"):
			if unit_data.has("faccion"):
				return unit_data.get("faccion") == "Patriota"
	
	# For now, assume all units in the units container are selectable
	# This can be refined later based on faction logic
	return true

func _is_unit_in_rect(unit: Node, rect: Rect2) -> bool:
	var unit_pos = unit.global_position if unit.has_method("get_global_position") else unit.position
	return rect.has_point(unit_pos)

func _move_unit_to(unit: Node, target_pos: Vector2) -> void:
	if unit.has_method("mover_a"):
		unit.mover_a(target_pos)
	elif unit.has_method("move_to"):
		unit.move_to(target_pos)
	else:
		# Direct position assignment as fallback
		var tween = unit.create_tween() if unit.has_method("create_tween") else null
		if tween:
			tween.tween_property(unit, "position", target_pos, 1.0)
		else:
			unit.position = target_pos

func _calculate_formation_positions(center: Vector2, unit_count: int, spacing: float) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	if unit_count <= 1:
		positions.append(center)
		return positions
	
	# Arrange units in a roughly circular formation
	var radius = spacing * unit_count / (2.0 * PI)
	radius = max(radius, spacing)  # Minimum radius
	
	for i in range(unit_count):
		var angle = (2.0 * PI * i) / unit_count
		var offset = Vector2(cos(angle), sin(angle)) * radius
		positions.append(center + offset)
	
	return positions