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
	
	# Crear pueblos de prueba para el sistema de reclutamiento
	crear_pueblos_prueba()
	
	# Conectar señales de pueblos
	call_deferred("conectar_señales_pueblos")

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
	# Agregar al grupo "unidades" para detección por pueblos
	instancia.add_to_group("unidades")
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

# -------------------------------
# GESTIÓN DE RECLUTAMIENTO
# -------------------------------

# -------------------------------
# GESTIÓN DE RECLUTAMIENTO
# -------------------------------

func crear_pueblos_prueba():
	"""Crea algunos pueblos de prueba para el sistema de reclutamiento"""
	const TownInstance = preload("res://Scenes/Strategic/TownInstance.tscn")
	
	# Pueblo cerca de la división patriota
	var pueblo1_data = TownData.new()
	pueblo1_data.nombre = "Villa Independencia"
	pueblo1_data.tipo = "villa"
	pueblo1_data.importancia = 2
	pueblo1_data.estado = "neutral"
	
	var pueblo1 = TownInstance.instantiate()
	pueblo1.position = Vector2(-100, -300)  # Cerca de la división patriota
	pueblo1.set_data(pueblo1_data)
	pueblo1.configurar_por_tipo()
	add_child(pueblo1)
	
	# Ciudad mediana cerca de la división realista
	var pueblo2_data = TownData.new()
	pueblo2_data.nombre = "Ciudad Real"
	pueblo2_data.tipo = "ciudad_mediana"
	pueblo2_data.importancia = 3
	pueblo2_data.estado = "neutral"
	
	var pueblo2 = TownInstance.instantiate()
	pueblo2.position = Vector2(250, 300)  # Cerca de la división realista
	pueblo2.set_data(pueblo2_data)
	pueblo2.configurar_por_tipo()
	add_child(pueblo2)
	
	# Capital en el centro del mapa
	var capital_data = TownData.new()
	capital_data.nombre = "Capital del Virreinato"
	capital_data.tipo = "capital"
	capital_data.importancia = 5
	capital_data.estado = "neutral"
	
	var capital = TownInstance.instantiate()
	capital.position = Vector2(0, 0)  # Centro del mapa
	capital.set_data(capital_data)
	capital.configurar_por_tipo()
	add_child(capital)

func conectar_señales_pueblos():
	"""Conecta las señales de todos los pueblos en el mapa para reclutamiento"""
	var towns = get_tree().get_nodes_in_group("towns")
	for town in towns:
		if town.has_signal("division_en_pueblo"):
			if not town.division_en_pueblo.is_connected(_on_division_en_pueblo):
				town.division_en_pueblo.connect(_on_division_en_pueblo)
		if town.has_signal("division_sale_pueblo"):
			if not town.division_sale_pueblo.is_connected(_on_division_sale_pueblo):
				town.division_sale_pueblo.connect(_on_division_sale_pueblo)

func _on_division_en_pueblo(division, town):
	"""Callback cuando una división llega a un pueblo"""
	print("🏘️ División", division.data.nombre, "puede reclutar en", town.town_data.nombre)
	# Notificar al MainHUD para mostrar opciones de reclutamiento
	var main_hud = get_node("../")  # MainHUD es el padre de StrategicMap
	if main_hud and main_hud.has_method("habilitar_reclutamiento"):
		main_hud.habilitar_reclutamiento(division, town)

func _on_division_sale_pueblo(division, town):
	"""Callback cuando una división sale de un pueblo"""
	print("🚶 División", division.data.nombre, "ya no puede reclutar en", town.town_data.nombre)
	# Notificar al MainHUD para ocultar opciones de reclutamiento
	var main_hud = get_node("../")  # MainHUD es el padre de StrategicMap
	if main_hud and main_hud.has_method("deshabilitar_reclutamiento"):
		main_hud.deshabilitar_reclutamiento(division, town)
