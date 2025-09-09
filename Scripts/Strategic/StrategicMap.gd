extends Node2D

const DivisionInstance = preload("res://Scenes/Strategic/DivisionInstance.tscn")

@onready var game_clock = $GameClock
@onready var units_container = $UnitsContainer
@onready var camera = $Camera2D
@onready var date_label = $UIOverlay/DateLabel

var zoom_min := 0.5
var zoom_max := 2.0
var move_speed := 300.0
var edge_margin := 20
var zoom_speed := 0.1
var division_seleccionada = null

# --- NUEVO: Lista global de subunidades libres ---
var subunidades_libres: Array[UnitData] = []

func _ready():
	# Create unit instances for testing the selection system
	_create_test_units()
	
	# Crear división patriota
	var patriota_division_1 := DivisionData.new()
	patriota_division_1.nombre = "División Leal a la Unión del Plata"
	patriota_division_1.rama_principal = "infantería"
	patriota_division_1.faccion = "Patriota"
	patriota_division_1.unidades_componentes = [
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Pelotón.tres"),
		preload("res://Data/Units/Caballería/Regimiento.tres")
	]
	patriota_division_1.cantidad_total = 650
	patriota_division_1.movilidad = 4
	patriota_division_1.moral = 85
	patriota_division_1.experiencia = 20
	patriota_division_1.icono_path = "res://Icons/Divisiones/patriota.png"

	# Crear división realista
	var realista_division_1 := DivisionData.new()
	realista_division_1.nombre = "División Realista de San Fernando"
	realista_division_1.rama_principal = "infantería"
	realista_division_1.faccion = "Realista"
	realista_division_1.unidades_componentes = [
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Pelotón.tres")
	]
	realista_division_1.cantidad_total = 410
	realista_division_1.movilidad = 3
	realista_division_1.moral = 90
	realista_division_1.experiencia = 25
	realista_division_1.icono_path = "res://Icons/Divisiones/realista.png"

	# Instanciar en el mapa
	instanciar_division(patriota_division_1, Vector2(-150, -350))
	instanciar_division(realista_division_1, Vector2(280, 350))

	# Ejemplo: agregar subunidades libres iniciales (esto es opcional)
	# subunidades_libres.append(preload("res://Data/Units/Infantería/Compañia.tres"))
	# subunidades_libres.append(preload("res://Data/Units/Caballería/Escuadrón.tres"))

	# Límites de la cámara
	camera.limit_left = -2500
	camera.limit_top = -2500
	camera.limit_right = 2500
	camera.limit_bottom = 2500

	# Conecta la señal que avisa cuando cambia la fecha (Godot 4)
	game_clock.date_changed.connect(_on_game_clock_date_changed)
	# Muestra la fecha inicial
	date_label.text = game_clock.current_date.as_string()

func _create_test_units():
	# Create some test units for the selection system
	var unit_scene = preload("res://Scenes/Strategic/UnitInstance.tscn")
	
	# Create patriot units
	var patriot_infantry = preload("res://Data/Units/Infantería/Pelotón.tres")
	var patriot_cavalry = preload("res://Data/Units/Caballería/Escuadrón.tres")
	
	# Create unit instances
	var positions = [
		Vector2(-200, -100),
		Vector2(-150, -100), 
		Vector2(-100, -100),
		Vector2(-200, -50),
		Vector2(-150, -50)
	]
	
	for i in range(positions.size()):
		var unit_instance = unit_scene.instantiate()
		var unit_data = patriot_infantry if i % 2 == 0 else patriot_cavalry
		
		# Create a copy of the unit data with faction info
		var copied_data = UnitData.new()
		copied_data.nombre = unit_data.nombre
		copied_data.rama = unit_data.rama
		copied_data.nivel = unit_data.nivel
		copied_data.tamaño = unit_data.tamaño
		copied_data.icono = unit_data.icono
		copied_data.cantidad = unit_data.cantidad
		copied_data.faccion = "Patriota"  # Make sure they're selectable
		
		unit_instance.set_data(copied_data)
		unit_instance.position = positions[i]
		units_container.add_child(unit_instance)

func _on_game_clock_date_changed(new_date):
	date_label.text = new_date.as_string()

func set_division_seleccionada(nueva):
	if division_seleccionada:
		division_seleccionada.resaltar_seleccion(false)
	division_seleccionada = nueva
	if division_seleccionada:
		division_seleccionada.resaltar_seleccion(true)
		print("✅ División seleccionada:", division_seleccionada.data.nombre)

func instanciar_division(data: DivisionData, posicion: Vector2) -> void:
	var instancia := DivisionInstance.instantiate()
	instancia.position = posicion
	units_container.add_child(instancia)
	instancia.set_button_data(data)
	# Conectar señal de selección (Godot 4)
	instancia.division_seleccionada.connect(_on_division_seleccionada)

func _on_division_seleccionada(div_instancia):
	print("📡 Señal recibida de:", div_instancia.data.nombre)
	set_division_seleccionada(div_instancia)

# ⬇️ Función para instanciar mapas
func instance_map(info: Dictionary, _position: Vector2) -> Node2D:
	var mapa_scene := load(info.path)
	if not mapa_scene:
		push_error("⚠ No se pudo cargar el mapa desde: " + info.path)
		return null
	var mapa : Node2D = mapa_scene.instantiate()
	mapa.position = _position
	mapa.set_meta("region", info.get("region", "desconocida"))
	mapa.set_meta("campaña", info.get("campaña", "sin definir"))
	return mapa

func _process(delta: float) -> void:
	var move := Vector2.ZERO
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport().get_visible_rect().size

	# --- Movimiento con teclas ---
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1

	# --- Movimiento con bordes de pantalla ---
	if mouse_pos.x <= edge_margin:
		move.x -= 1
	elif mouse_pos.x >= screen_size.x - edge_margin:
		move.x += 1

	if mouse_pos.y <= edge_margin:
		move.y -= 1
	elif mouse_pos.y >= screen_size.y - edge_margin:
		move.y += 1

	# Normalizar movimiento
	if move != Vector2.ZERO:
		move = move.normalized()

	camera.position += move * move_speed * delta

func _unhandled_input(event):
	# Handle selection and movement input
	_handle_selection_input(event)
	
	# Original division selection logic (keep for compatibility)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Si clickeamos en "nada", deseleccionamos
		if not get_viewport().gui_get_focus_owner():
			if division_seleccionada:
				print("❌ Deseleccionando división:", division_seleccionada.data.nombre)
			set_division_seleccionada(null)

	# Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(zoom_speed)  # acercar
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(-zoom_speed)  # alejar

func _handle_selection_input(event):
	var shift_pressed = Input.is_action_pressed("ui_shift") if Input.has_action("ui_shift") else false
	
	if event is InputEventMouseButton:
		var screen_mouse_pos = get_viewport().get_mouse_position()
		var global_mouse_pos = get_global_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start potential drag selection (use screen coordinates for UI)
				SelectionManager.start_selection_rect(screen_mouse_pos)
			else:
				# Finish drag selection or handle click selection
				if SelectionManager.is_drawing_rect():
					SelectionManager.finish_selection_rect(units_container, shift_pressed, camera)
				else:
					# Click selection - check if we clicked on a unit (use world coordinates)
					var clicked_unit = _get_unit_at_position(global_mouse_pos)
					if clicked_unit:
						if shift_pressed and SelectionManager.is_unit_selected(clicked_unit):
							SelectionManager.deselect_unit(clicked_unit)
						else:
							SelectionManager.select_unit(clicked_unit, shift_pressed)
					else:
						# Clicked empty space - clear selection
						if not shift_pressed:
							SelectionManager.clear_selection()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click - movement order (use world coordinates)
			var selected_units = SelectionManager.get_selected_units()
			if not selected_units.is_empty():
				SelectionManager.move_selected_units_to(global_mouse_pos)
	
	elif event is InputEventMouseMotion:
		# Update selection rectangle while dragging (use screen coordinates)
		if SelectionManager.is_drawing_rect():
			SelectionManager.update_selection_rect(get_viewport().get_mouse_position())

func _get_unit_at_position(pos: Vector2) -> Node:
	# Check all units in the units container to see if any contain the position
	for unit in units_container.get_children():
		if _is_position_over_unit(pos, unit):
			return unit
	return null

func _is_position_over_unit(pos: Vector2, unit: Node) -> bool:
	# Check if position is over the unit's visual area
	var unit_rect: Rect2
	
	# Try to get the unit's visual bounds
	if unit.has_method("obtener_area_visual"):
		unit_rect = unit.obtener_area_visual()
	elif unit.has_node("Sprite2D"):
		var sprite = unit.get_node("Sprite2D")
		if sprite.texture:
			var size = sprite.texture.get_size() * sprite.scale
			unit_rect = Rect2(unit.global_position - size / 2, size)
		else:
			unit_rect = Rect2(unit.global_position - Vector2(25, 25), Vector2(50, 50))
	elif unit.has_node("Icon"):
		var icon = unit.get_node("Icon")
		var size = Vector2(50, 50)  # Default size
		if icon.texture:
			size = icon.texture.get_size() * icon.scale
		unit_rect = Rect2(unit.global_position - size / 2, size)
	else:
		# Default fallback area
		unit_rect = Rect2(unit.global_position - Vector2(25, 25), Vector2(50, 50))
	
	return unit_rect.has_point(pos)

func _zoom_at_mouse(amount: float) -> void:
	var old_zoom: Vector2 = camera.zoom
	var new_zoom: Vector2 = clamp(
		old_zoom + Vector2(amount, amount),
		Vector2(zoom_min, zoom_min),
		Vector2(zoom_max, zoom_max)
	)
	var mouse_pos := get_global_mouse_position()
	# Ajustar posición para que el zoom sea hacia el mouse
	var offset: Vector2 = (mouse_pos - camera.position) * (1.0 - new_zoom.x / old_zoom.x)
	camera.position += offset
	camera.zoom = new_zoom

# -------------------------------
# GESTIÓN DE SUBUNIDADES LIBRES
# -------------------------------

func agregar_subunidad_libre(unit_data: UnitData) -> void:
	if not subunidades_libres.has(unit_data):
		subunidades_libres.append(unit_data)
		# Aquí puedes actualizar el panel de subunidades libres si está presente
		actualizar_panel_subunidades_libres()

func quitar_subunidad_libre(unit_data: UnitData) -> void:
	if subunidades_libres.has(unit_data):
		subunidades_libres.erase(unit_data)
		actualizar_panel_subunidades_libres()

func actualizar_panel_subunidades_libres():
	# Si tienes un panel tipo UnassignedUnitsPanel, llama a su función de refresco aquí.
	# Ejemplo:
	# $UIOverlay/UnassignedUnitsPanel.mostrar_subunidades_libres()
	pass

func get_subunidades_libres() -> Array[UnitData]:
	return subunidades_libres.duplicate()
