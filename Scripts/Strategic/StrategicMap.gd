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

# === DETECCIÓN Y MANEJO DE COMBATE ===

func check_for_combat_on_movement(moving_unit: Node):
	"""Verifica si una unidad que se mueve entra en combate"""
	if not moving_unit or not moving_unit.has_method("get"):
		return
	
	var moving_data = moving_unit.get("data")
	if not moving_data:
		return
	
	# Buscar otras unidades en la misma posición
	for child in units_container.get_children():
		if child == moving_unit:
			continue
		
		var other_data = child.get("data")
		if not other_data:
			continue
		
		# Verificar distancia
		if moving_unit.global_position.distance_to(child.global_position) < 50:
			# Verificar si son de facciones diferentes
			if moving_data.faccion != other_data.faccion:
				print("⚔ Conflicto detectado entre %s y %s" % [moving_data.nombre, other_data.nombre])
				
				# Solicitar combate al HUD principal
				var main_hud = get_tree().current_scene.get_node_or_null("MainHUD")
				if main_hud and main_hud.has_method("initiate_combat_between_units"):
					main_hud.initiate_combat_between_units(moving_unit, child)
				break

func get_units_at_position(position: Vector2, tolerance: float = 50.0) -> Array:
	"""Obtiene todas las unidades en una posición específica"""
	var units_at_pos = []
	
	for child in units_container.get_children():
		if child.global_position.distance_to(position) <= tolerance:
			units_at_pos.append(child)
	
	return units_at_pos

func get_hostile_units_in_range(unit: Node, range_pixels: float = 50.0) -> Array:
	"""Obtiene unidades hostiles dentro del rango especificado"""
	var hostile_units = []
	
	if not unit or not unit.has_method("get"):
		return hostile_units
	
	var unit_data = unit.get("data")
	if not unit_data:
		return hostile_units
	
	for child in units_container.get_children():
		if child == unit:
			continue
		
		var other_data = child.get("data")
		if not other_data:
			continue
		
		# Verificar si es hostil y está en rango
		if unit_data.faccion != other_data.faccion:
			if unit.global_position.distance_to(child.global_position) <= range_pixels:
				hostile_units.append(child)
	
	return hostile_units
