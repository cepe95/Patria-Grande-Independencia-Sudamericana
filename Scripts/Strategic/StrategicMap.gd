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

# Límites del mapa para validación de movimiento
var map_bounds := Rect2(-2500, -2500, 5000, 5000)

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
	instancia.global_position = posicion
	units_container.add_child(instancia)
	instancia.set_button_data(data)
	
	# Conectar señales de selección y movimiento (Godot 4)
	instancia.division_seleccionada.connect(_on_division_seleccionada)
	instancia.division_movida.connect(_on_division_movida)
	instancia.solicitar_accion.connect(_on_solicitar_accion)
	
	print("✅ División instanciada:", data.nombre, "en posición:", posicion)

func _on_division_seleccionada(div_instancia):
	print("📡 Señal recibida de:", div_instancia.data.nombre)
	set_division_seleccionada(div_instancia)
	
	# Notificar al MainHUD si existe
	var main_hud = get_tree().current_scene.get_node_or_null("MainHUD")
	if not main_hud:
		main_hud = get_parent()
	if main_hud and main_hud.has_method("_on_unit_selected"):
		main_hud._on_unit_selected(div_instancia)

func _on_division_movida(div_instancia, nueva_posicion: Vector2):
	"""Callback cuando una división ha sido movida"""
	print("🚀 División movida:", div_instancia.data.nombre, "a:", nueva_posicion)
	
	# Actualizar datos de posición si la división los tiene
	if div_instancia.data.has("posicion_inicial"):
		div_instancia.data.posicion_inicial = nueva_posicion
	
	# Notificar al MainHUD sobre el movimiento
	var main_hud = get_tree().current_scene.get_node_or_null("MainHUD")
	if not main_hud:
		main_hud = get_parent()
	if main_hud and main_hud.has_method("add_event"):
		main_hud.add_event("División %s movida a nueva posición" % div_instancia.data.nombre, "info")

func _on_solicitar_accion(div_instancia, tipo_accion: String):
	"""Callback para manejar solicitudes de acciones futuras (atacar, fortificar, etc.)"""
	print("⚡ Acción solicitada:", tipo_accion, "para división:", div_instancia.data.nombre)
	
	match tipo_accion:
		"menu_contextual":
			# TODO: Mostrar menú contextual
			print("📋 Menú contextual para:", div_instancia.data.nombre)
		"atacar":
			# TODO: Iniciar ataque
			print("⚔️ Preparando ataque con:", div_instancia.data.nombre)
		"fortificar":
			# TODO: Fortificar posición
			print("🏰 Fortificando posición de:", div_instancia.data.nombre)
		"mover":
			# TODO: Modo de movimiento especial
			print("🎯 Modo de movimiento para:", div_instancia.data.nombre)

func validar_posicion_unidad(posicion: Vector2, unidad_movida: Node = null) -> bool:
	"""Valida si una posición es válida para colocar una unidad"""
	# Verificar límites del mapa
	if not map_bounds.has_point(posicion):
		return false
	
	# Verificar colisiones con otras unidades
	if verificar_colision_unidades(posicion, unidad_movida):
		return false
	
	# TODO: Verificar terreno válido
	# TODO: Verificar zonas restringidas
	
	return true

func verificar_colision_unidades(posicion: Vector2, unidad_ignorar: Node = null) -> bool:
	"""Verifica si hay colisión con otras unidades en la posición dada"""
	var distancia_minima = 80.0  # Distancia mínima entre unidades
	
	for child in units_container.get_children():
		if child == unidad_ignorar:
			continue
		
		var distancia = posicion.distance_to(child.global_position)
		if distancia < distancia_minima:
			return true
	
	return false

func obtener_unidades_en_area(centro: Vector2, radio: float) -> Array:
	"""Obtiene todas las unidades en un área circular"""
	var unidades_en_area = []
	
	for child in units_container.get_children():
		var distancia = centro.distance_to(child.global_position)
		if distancia <= radio:
			unidades_en_area.append(child)
	
	return unidades_en_area

func obtener_unidad_mas_cercana(posicion: Vector2, max_distancia: float = 200.0) -> Node:
	"""Obtiene la unidad más cercana a una posición"""
	var unidad_cercana = null
	var distancia_minima = max_distancia
	
	for child in units_container.get_children():
		var distancia = posicion.distance_to(child.global_position)
		if distancia < distancia_minima:
			distancia_minima = distancia
			unidad_cercana = child
	
	return unidad_cercana

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
