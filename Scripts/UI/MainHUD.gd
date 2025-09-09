extends Control

# MainHUD - Interfaz principal estratégica del juego
# Maneja la comunicación entre todos los paneles de la interfaz

# === REFERENCIAS A NODOS ===
@onready var strategic_map: Node2D = $StrategicMap
@onready var resource_bar: Panel = $UI/ResourceBar
@onready var city_unit_list_panel: Panel = $UI/CityUnitListPanel
@onready var details_panel: Panel = $UI/DetailsPanel
@onready var event_panel: Panel = $UI/EventPanel
@onready var pause_menu: Control = $UI/PauseMenu

# Referencias a elementos específicos de los paneles
@onready var dinero_label: Label = $UI/ResourceBar/Content/ResourcesContainer/DineroLabel
@onready var comida_label: Label = $UI/ResourceBar/Content/ResourcesContainer/ComidaLabel
@onready var municion_label: Label = $UI/ResourceBar/Content/ResourcesContainer/MunicionLabel
@onready var date_label: Label = $UI/ResourceBar/Content/DateTurnContainer/DateLabel
@onready var turn_label: Label = $UI/ResourceBar/Content/DateTurnContainer/TurnLabel

@onready var cities_list: VBoxContainer = $UI/CityUnitListPanel/VBoxContainer/TabContainer/Ciudades/CitiesList
@onready var units_list: VBoxContainer = $UI/CityUnitListPanel/VBoxContainer/TabContainer/Unidades/UnitsList

@onready var details_title: Label = $UI/DetailsPanel/VBoxContainer/HeaderContainer/TitleLabel
@onready var details_content: VBoxContainer = $UI/DetailsPanel/VBoxContainer/ContentContainer/DetailsContent
@onready var close_details_button: Button = $UI/DetailsPanel/VBoxContainer/HeaderContainer/CloseButton

@onready var events_log: VBoxContainer = $UI/EventPanel/VBoxContainer/EventsContainer/EventsList/EventsLog
@onready var next_turn_button: Button = $UI/EventPanel/VBoxContainer/EventsContainer/QuickActionsContainer/QuickActionButtons/NextTurnButton
@onready var pause_button: Button = $UI/EventPanel/VBoxContainer/EventsContainer/QuickActionsContainer/QuickActionButtons/PauseButton

# === VARIABLES DE ESTADO ===
var selected_unit: Node = null
var selected_city: Node = null
var current_resources: Dictionary = {}
var current_turn: int = 1

# === INICIALIZACIÓN ===
func _ready():
	print("✓ MainHUD inicializado")
	setup_ui_connections()
	# Esperar un frame para que el StrategicMap esté completamente inicializado
	await get_tree().process_frame
	setup_strategic_map_connections()
	initialize_resource_display()
	populate_city_unit_lists()
	add_initial_events()

func setup_ui_connections():
	"""Conecta las señales de los elementos de la UI"""
	# Botón de cerrar panel de detalles
	close_details_button.pressed.connect(_on_close_details_pressed)
	
	# Botones de acciones rápidas
	next_turn_button.pressed.connect(_on_next_turn_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	
	# Input de teclado para pausar (ESC)
	set_process_unhandled_input(true)

func setup_strategic_map_connections():
	"""Conecta las señales del mapa estratégico"""
	if strategic_map:
		# Conectar señal de cambio de fecha del GameClock
		var game_clock = strategic_map.get_node_or_null("GameClock")
		if game_clock and game_clock.has_signal("date_changed"):
			game_clock.date_changed.connect(_on_date_changed)
		
		# Conectar a las divisiones existentes y futuras
		connect_to_existing_divisions()
		
		# Conectar a nuevas divisiones que se agreguen
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			units_container.child_entered_tree.connect(_on_new_division_added)

func connect_to_existing_divisions():
	"""Conecta las señales de las divisiones existentes"""
	if not strategic_map:
		return
		
	var units_container = strategic_map.get_node_or_null("UnitsContainer")
	if units_container:
		for child in units_container.get_children():
			if child.has_signal("division_seleccionada"):
				if not child.division_seleccionada.is_connected(_on_unit_selected):
					child.division_seleccionada.connect(_on_unit_selected)
					print("✓ Conectado a división: ", child.get("data").get("nombre", "Desconocida") if child.get("data") else "Sin datos")

func _on_new_division_added(node: Node):
	"""Callback cuando se agrega una nueva división al mapa"""
	if node.has_signal("division_seleccionada"):
		node.division_seleccionada.connect(_on_unit_selected)
		print("✓ Nueva división conectada: ", node.get("data").get("nombre", "Desconocida") if node.get("data") else "Sin datos")
		# Actualizar la lista de unidades
		call_deferred("populate_units_list")

# === MANEJO DE RECURSOS ===
func initialize_resource_display():
	"""Inicializa la visualización de recursos"""
	current_resources = {
		"dinero": 1000,
		"comida": 500,
		"municion": 200
	}
	update_resource_display()

func update_resource_display():
	"""Actualiza la visualización de recursos en la barra superior"""
	dinero_label.text = "Dinero: %d" % current_resources.get("dinero", 0)
	comida_label.text = "Comida: %d" % current_resources.get("comida", 0)
	municion_label.text = "Munición: %d" % current_resources.get("municion", 0)

func update_date_turn_display(date_text: String = "", turn: int = -1):
	"""Actualiza la visualización de fecha y turno"""
	if date_text != "":
		date_label.text = "Fecha: %s" % date_text
	if turn > 0:
		current_turn = turn
		turn_label.text = "Turno: %d" % current_turn

# === LISTAS DE CIUDADES Y UNIDADES ===
func populate_city_unit_lists():
	"""Puebla las listas de ciudades y unidades con datos del mapa"""
	populate_cities_list()
	populate_units_list()

func populate_cities_list():
	"""Puebla la lista de ciudades"""
	# Limpiar lista existente
	for child in cities_list.get_children():
		child.queue_free()
	
	# TODO: Obtener ciudades reales del mapa estratégico
	# Por ahora, agregar ciudades de ejemplo
	var example_cities = [
		{"nombre": "Buenos Aires", "tipo": "Capital", "faccion": "Patriota"},
		{"nombre": "Córdoba", "tipo": "Ciudad", "faccion": "Realista"},
		{"nombre": "Montevideo", "tipo": "Puerto", "faccion": "Patriota"}
	]
	
	for city_data in example_cities:
		add_city_to_list(city_data)

func populate_units_list():
	"""Puebla la lista de unidades"""
	# Limpiar lista existente
	for child in units_list.get_children():
		child.queue_free()
	
	# Obtener unidades del mapa estratégico
	if strategic_map:
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			for unit in units_container.get_children():
				if unit.has_method("get_button_data") or unit.get("data"):
					add_unit_to_list(unit)
			print("✓ Lista de unidades poblada con %d unidades" % units_container.get_child_count())
		else:
			print("⚠ No se encontró UnitsContainer en StrategicMap")
			# Agregar unidades de ejemplo si no hay mapa
			add_example_units()
	else:
		print("⚠ StrategicMap no disponible, agregando unidades de ejemplo")
		add_example_units()

func add_example_units():
	"""Agrega unidades de ejemplo cuando el mapa estratégico no está disponible"""
	var example_units = [
		{"nombre": "División Patriota Ejemplo", "faccion": "Patriota", "tipo": "División"},
		{"nombre": "División Realista Ejemplo", "faccion": "Realista", "tipo": "División"}
	]
	
	for unit_data in example_units:
		var unit_entry = create_list_entry(
			unit_data.get("nombre", "Unidad Desconocida"),
			unit_data.get("tipo", "División"),
			unit_data.get("faccion", "Neutral"),
			"unit",
			null  # Sin nodo de referencia para ejemplos
		)
		units_list.add_child(unit_entry)

func add_city_to_list(city_data: Dictionary):
	"""Agrega una ciudad a la lista"""
	var city_entry = create_list_entry(
		city_data.get("nombre", "Ciudad Desconocida"),
		city_data.get("tipo", "Desconocido"),
		city_data.get("faccion", "Neutral"),
		"city"
	)
	cities_list.add_child(city_entry)

func add_unit_to_list(unit_node: Node):
	"""Agrega una unidad a la lista"""
	var unit_data = unit_node.get("data")
	if not unit_data:
		return
	
	var unit_entry = create_list_entry(
		unit_data.get("nombre", "Unidad Desconocida"),
		"División", # Tipo por defecto
		unit_data.get("faccion", "Neutral"),
		"unit",
		unit_node
	)
	units_list.add_child(unit_entry)

func create_list_entry(name: String, type: String, faction: String, entry_type: String, reference_node: Node = null) -> Control:
	"""Crea una entrada para las listas de ciudades/unidades"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)
	
	# Icono de facción/bandera
	var icon = TextureRect.new()
	icon.custom_min_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Cargar icono según facción
	var icon_path = ""
	match faction:
		"Patriota":
			icon_path = "res://Assets/Icons/Division Patriota.png"
		"Realista":
			icon_path = "res://Assets/Icons/Division Realista.png"
		_:
			icon_path = "res://Assets/Icons/Division Patriota.png"  # Por defecto
	
	var texture = load(icon_path) as Texture2D
	if texture:
		icon.texture = texture
	
	# Información de texto
	var info_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 12)
	
	var type_label = Label.new()
	type_label.text = "%s (%s)" % [type, faction]
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	info_container.add_child(name_label)
	info_container.add_child(type_label)
	
	# Botón de selección
	var select_button = Button.new()
	select_button.text = "Ver"
	select_button.custom_min_size = Vector2(50, 30)
	
	# Conectar señal del botón
	select_button.pressed.connect(_on_list_entry_selected.bind(entry_type, name, reference_node))
	
	entry.add_child(icon)
	entry.add_child(info_container)
	entry.add_child(select_button)
	
	return entry

# === PANEL DE DETALLES ===
func show_details(title: String, content_data: Dictionary):
	"""Muestra el panel de detalles con la información proporcionada"""
	details_title.text = title
	
	# Limpiar contenido anterior
	for child in details_content.get_children():
		child.queue_free()
	
	# Agregar nuevo contenido
	for key in content_data:
		var info_line = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = str(key) + ":"
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_font_size_override("font_size", 12)
		
		var value_label = Label.new()
		value_label.text = str(content_data[key])
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 12)
		
		info_line.add_child(key_label)
		info_line.add_child(value_label)
		details_content.add_child(info_line)
	
	details_panel.visible = true

func hide_details():
	"""Oculta el panel de detalles"""
	details_panel.visible = false
	selected_unit = null
	selected_city = null

# === MANEJO DE EVENTOS ===
func add_event(message: String, event_type: String = "info"):
	"""Agrega un evento al log de eventos"""
	var event_entry = HBoxContainer.new()
	
	var time_label = Label.new()
	time_label.text = "[Turno %d]" % current_turn
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	time_label.custom_min_size = Vector2(80, 0)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 11)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Color según tipo de evento
	match event_type:
		"warning":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		"error":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"success":
			message_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		_:  # info
			message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	event_entry.add_child(time_label)
	event_entry.add_child(message_label)
	events_log.add_child(event_entry)
	
	# Scroll automático al final
	await get_tree().process_frame
	var scroll_container = events_log.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func add_initial_events():
	"""Agrega eventos iniciales de ejemplo"""
	add_event("¡Bienvenido a Patria Grande: Independencia Sudamericana!", "success")
	add_event("El movimiento independentista se extiende por Sudamérica", "info")
	add_event("Consulta el panel de ciudades y unidades para comenzar", "info")
	add_event("Usa ESPACIO para avanzar turno, ESC para pausar", "info")

# === SEÑALES Y CALLBACKS ===
func _on_unit_selected(unit_node: Node):
	"""Callback cuando se selecciona una unidad en el mapa"""
	selected_unit = unit_node
	selected_city = null
	
	var unit_data = unit_node.get("data")
	if unit_data:
		var details = {
			"Nombre": unit_data.get("nombre", "Desconocido"),
			"Facción": unit_data.get("faccion", "Neutral"),
			"Rama Principal": unit_data.get("rama_principal", "Desconocida"),
			"Cantidad Total": unit_data.get("cantidad_total", 0),
			"Movilidad": unit_data.get("movilidad", 0),
			"Moral": unit_data.get("moral", 0),
			"Experiencia": unit_data.get("experiencia", 0)
		}
		show_details("División: " + unit_data.get("nombre", "Desconocida"), details)
		add_event("División seleccionada: " + unit_data.get("nombre", "Desconocida"), "info")

func _on_list_entry_selected(entry_type: String, name: String, reference_node: Node):
	"""Callback cuando se selecciona una entrada de las listas"""
	match entry_type:
		"unit":
			if reference_node:
				_on_unit_selected(reference_node)
			else:
				# Manejo para unidades de ejemplo sin nodo de referencia
				var example_details = {
					"Nombre": name,
					"Tipo": "División (Ejemplo)",
					"Estado": "Disponible",
					"Composición": "Unidades variadas",
					"Nota": "Esta es una unidad de ejemplo"
				}
				show_details("División: " + name, example_details)
				add_event("División de ejemplo seleccionada: " + name, "info")
		"city":
			selected_city = name  # Guardar referencia de ciudad seleccionada
			selected_unit = null
			var city_details = {
				"Nombre": name,
				"Tipo": "Ciudad",
				"Estado": "Controlada",
				"Población": "15,000",
				"Recursos": "Comida, Dinero",
				"Guarnición": "1 Compañía"
			}
			show_details("Ciudad: " + name, city_details)
			add_event("Ciudad seleccionada: " + name, "info")
			
			# Agregar botón de reclutamiento
			add_recruitment_button(name)

func _on_close_details_pressed():
	"""Callback para cerrar el panel de detalles"""
	hide_details()

func _on_next_turn_pressed():
	"""Callback para avanzar al siguiente turno"""
	current_turn += 1
	update_date_turn_display("", current_turn)
	add_event("Nuevo turno iniciado", "success")
	
	# Procesar mantenimiento de unidades
	process_unit_maintenance()
	
	# TODO: Aquí se procesarían otros eventos del turno
	print("✓ Avanzando al turno: ", current_turn)

func process_unit_maintenance():
	"""Procesa el mantenimiento de todas las unidades al inicio del turno"""
	var recruitment_manager = get_recruitment_manager()
	if not recruitment_manager:
		add_event("⚠ Sistema de mantenimiento no disponible", "warning")
		return
	
	# Obtener todas las unidades del mapa
	var all_units = get_all_units()
	var all_towns = get_all_towns()
	
	if all_units.is_empty():
		add_event("No hay unidades que requieran mantenimiento", "info")
		return
	
	# Aplicar costos de mantenimiento
	var maintenance_result = recruitment_manager.apply_maintenance_costs(all_units, all_towns)
	
	# Informar resultados
	if maintenance_result["units_processed"] > 0:
		add_event("✓ Mantenimiento aplicado a %d unidades" % maintenance_result["units_processed"], "success")
		
		# Mostrar resumen de recursos consumidos
		var total_cost = maintenance_result["total_cost"]
		if not total_cost.is_empty():
			var cost_summary = "Recursos consumidos: "
			var cost_items = []
			for resource in total_cost:
				if total_cost[resource] > 0:
					cost_items.append("%s: %s" % [resource, total_cost[resource]])
			if not cost_items.is_empty():
				cost_summary += cost_items.join(", ")
				add_event(cost_summary, "info")
	
	if maintenance_result["units_without_maintenance"] > 0:
		add_event("⚠ %d unidades sin mantenimiento adecuado" % maintenance_result["units_without_maintenance"], "warning")

func get_all_units() -> Array:
	"""Obtiene todas las unidades del mapa estratégico"""
	var units = []
	
	if strategic_map:
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			units = units_container.get_children()
	
	return units

func get_all_towns() -> Array:
	"""Obtiene todas las ciudades del mapa estratégico"""
	var towns = []
	
	if strategic_map:
		var towns_container = strategic_map.get_node_or_null("TownsContainer")
		if towns_container:
			towns = towns_container.get_children()
	
	return towns

func _on_pause_pressed():
	"""Callback para pausar el juego"""
	pause_menu.visible = true
	add_event("Juego pausado", "info")

func _on_date_changed(new_date):
	"""Callback cuando cambia la fecha en el GameClock"""
	if new_date and new_date.has_method("as_string"):
		update_date_turn_display(new_date.as_string())

func _unhandled_input(event):
	"""Manejo de input no procesado (teclas de acceso rápido)"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if details_panel.visible:
					hide_details()
				else:
					_on_pause_pressed()
			KEY_SPACE:
				_on_next_turn_pressed()

# === MÉTODOS PÚBLICOS PARA INTEGRACIÓN ===

func add_recruitment_button(city_name: String):
	"""Agrega un botón de reclutamiento al panel de detalles de ciudad"""
	var recruitment_button = Button.new()
	recruitment_button.text = "Reclutar Unidades"
	recruitment_button.custom_min_size = Vector2(150, 30)
	recruitment_button.pressed.connect(_on_recruitment_button_pressed.bind(city_name))
	
	details_content.add_child(recruitment_button)

func _on_recruitment_button_pressed(city_name: String):
	"""Callback cuando se presiona el botón de reclutamiento"""
	show_recruitment_panel(city_name)

func show_recruitment_panel(city_name: String):
	"""Muestra el panel de reclutamiento para una ciudad"""
	var town_instance = find_town_by_name(city_name)
	if not town_instance:
		add_event("No se encontró la ciudad: " + city_name, "error")
		return
	
	var recruitment_manager = get_recruitment_manager()
	if not recruitment_manager:
		add_event("Sistema de reclutamiento no disponible", "error")
		return
	
	# Obtener unidades disponibles para reclutamiento
	var available_units = recruitment_manager.get_available_units_for_recruitment(town_instance)
	
	if available_units.is_empty():
		add_event("No hay unidades disponibles para reclutar en " + city_name, "warning")
		return
	
	# Limpiar el panel de detalles y mostrar opciones de reclutamiento
	for child in details_content.get_children():
		child.queue_free()
	
	details_title.text = "Reclutamiento en " + city_name
	
	# Agregar información de la ciudad
	var city_info = Label.new()
	city_info.text = "Selecciona una unidad para reclutar:"
	city_info.add_theme_font_size_override("font_size", 12)
	details_content.add_child(city_info)
	
	# Agregar botones para cada unidad disponible
	for unit_data in available_units:
		if unit_data:
			add_recruitment_option(unit_data, town_instance)
	
	# Botón para volver
	var back_button = Button.new()
	back_button.text = "Volver"
	back_button.custom_min_size = Vector2(100, 30)
	back_button.pressed.connect(_on_list_entry_selected.bind("city", city_name, null))
	details_content.add_child(back_button)

func add_recruitment_option(unit_data: UnitData, town_instance: Node):
	"""Agrega una opción de reclutamiento al panel"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	
	# Información de la unidad
	var unit_label = Label.new()
	unit_label.text = "%s (%d hombres)" % [unit_data.nombre, unit_data.tamaño]
	unit_label.add_theme_font_size_override("font_size", 12)
	container.add_child(unit_label)
	
	# Mostrar costos de reclutamiento
	var costs_label = Label.new()
	var cost_text = "Costos: "
	var cost_items = []
	for resource in unit_data.costos_reclutamiento:
		if unit_data.costos_reclutamiento[resource] > 0:
			cost_items.append("%s: %s" % [resource, unit_data.costos_reclutamiento[resource]])
	cost_text += cost_items.join(", ")
	costs_label.text = cost_text
	costs_label.add_theme_font_size_override("font_size", 10)
	costs_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(costs_label)
	
	# Mostrar costos de mantenimiento
	var maintenance_label = Label.new()
	var maintenance_text = "Mantenimiento: "
	var maintenance_items = []
	for resource in unit_data.costos_mantenimiento:
		if unit_data.costos_mantenimiento[resource] > 0:
			maintenance_items.append("%s: %s" % [resource, unit_data.costos_mantenimiento[resource]])
	maintenance_text += maintenance_items.join(", ")
	maintenance_label.text = maintenance_text
	maintenance_label.add_theme_font_size_override("font_size", 10)
	maintenance_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	container.add_child(maintenance_label)
	
	# Verificar si se puede reclutar
	var recruitment_manager = get_recruitment_manager()
	var can_recruit_result = recruitment_manager.can_recruit_unit(unit_data, town_instance)
	
	var recruit_button = Button.new()
	recruit_button.text = "Reclutar"
	recruit_button.custom_min_size = Vector2(100, 25)
	
	if can_recruit_result["success"]:
		recruit_button.pressed.connect(_on_unit_recruitment_confirmed.bind(unit_data, town_instance))
	else:
		recruit_button.disabled = true
		recruit_button.text = "Recursos insuficientes"
		
		# Mostrar recursos faltantes
		var missing_resources = can_recruit_result.get("missing_resources", {})
		if not missing_resources.is_empty():
			var missing_label = Label.new()
			var missing_text = "Faltan: "
			var missing_items = []
			for resource in missing_resources:
				missing_items.append("%s: %s" % [resource, missing_resources[resource]])
			missing_text += missing_items.join(", ")
			missing_label.text = missing_text
			missing_label.add_theme_font_size_override("font_size", 9)
			missing_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			container.add_child(missing_label)
	
	container.add_child(recruit_button)
	
	# Separador
	var separator = HSeparator.new()
	container.add_child(separator)
	
	details_content.add_child(container)

func _on_unit_recruitment_confirmed(unit_data: UnitData, town_instance: Node):
	"""Callback cuando se confirma el reclutamiento de una unidad"""
	var recruitment_manager = get_recruitment_manager()
	
	if recruitment_manager.recruit_unit(unit_data, town_instance):
		add_event("✓ %s reclutado en %s" % [unit_data.nombre, town_instance.town_data.nombre], "success")
		
		# Crear la instancia de la unidad en el mapa
		create_unit_instance(unit_data, town_instance.position)
		
		# Refrescar el panel de reclutamiento para mostrar recursos actualizados
		show_recruitment_panel(town_instance.town_data.nombre)
	else:
		add_event("✗ Falló el reclutamiento de %s" % unit_data.nombre, "error")

func refresh_interface():
	"""Refresca toda la interfaz - útil para llamar desde scripts externos"""
	populate_city_unit_lists()
	connect_to_existing_divisions()
	add_event("Interfaz actualizada", "info")

func get_selected_unit() -> Node:
	"""Retorna la unidad actualmente seleccionada"""
	return selected_unit

func get_selected_city() -> String:
	"""Retorna el nombre de la ciudad actualmente seleccionada"""
	return selected_city if selected_city else ""

func update_resources(new_resources: Dictionary):
	"""Actualiza los recursos desde scripts externos"""
	for resource in new_resources:
		if current_resources.has(resource):
			current_resources[resource] = new_resources[resource]
	update_resource_display()
	add_event("Recursos actualizados", "info")

# === MÉTODOS PLACEHOLDER PARA INTEGRACIÓN FUTURA ===

func move_unit_to_position(unit: Node, target_position: Vector2):
	"""PLACEHOLDER: Mover unidad a posición específica"""
	print("TODO: Implementar movimiento de unidad a posición: ", target_position)
	add_event("Movimiento de unidad ordenado", "info")

func start_battle(attacking_unit: Node, defending_unit: Node):
	"""PLACEHOLDER: Iniciar batalla entre unidades"""
	print("TODO: Implementar sistema de batalla")
	add_event("¡Batalla iniciada!", "warning")

func recruit_unit_in_city(city_name: String, unit_type: String):
	"""Implementa el reclutamiento de unidades en ciudades"""
	# Buscar la ciudad en el mapa estratégico
	var town_instance = find_town_by_name(city_name)
	if not town_instance:
		add_event("No se encontró la ciudad: " + city_name, "error")
		return
	
	# Buscar el tipo de unidad solicitado
	var unit_data = find_unit_data_by_type(unit_type)
	if not unit_data:
		add_event("Tipo de unidad no encontrado: " + unit_type, "error")
		return
	
	# Obtener el manager de reclutamiento
	var recruitment_manager = get_recruitment_manager()
	if not recruitment_manager:
		add_event("Sistema de reclutamiento no disponible", "error")
		return
	
	# Intentar reclutar la unidad
	if recruitment_manager.recruit_unit(unit_data, town_instance):
		add_event("✓ %s reclutado en %s" % [unit_data.nombre, city_name], "success")
		# Crear la instancia de la unidad en el mapa
		create_unit_instance(unit_data, town_instance.position)
	else:
		add_event("✗ Falló el reclutamiento de %s en %s" % [unit_type, city_name], "error")

func find_town_by_name(town_name: String) -> Node:
	"""Busca una ciudad por nombre en el mapa estratégico"""
	if not strategic_map:
		return null
	
	var towns_container = strategic_map.get_node_or_null("TownsContainer")
	if not towns_container:
		return null
	
	for town in towns_container.get_children():
		if town.get("town_data") and town.town_data.get("nombre") == town_name:
			return town
	
	return null

func find_unit_data_by_type(unit_type: String) -> UnitData:
	"""Busca datos de unidad por tipo"""
	var unit_paths = {
		"Pelotón de Infantería": "res://Data/Units/Infantería/Pelotón.tres",
		"Compañía de Infantería": "res://Data/Units/Infantería/Compañia.tres",
		"Batallón de Infantería": "res://Data/Units/Infantería/Batallón.tres",
		"Regimiento de Infantería": "res://Data/Units/Infantería/Regimiento.tres",
		"Escuadrón de Caballería": "res://Data/Units/Caballería/Escuadrón.tres",
		"Compañía de Caballería": "res://Data/Units/Caballería/Compañia.tres",
		"Regimiento de Caballería": "res://Data/Units/Caballería/Regimiento.tres",
		"Batería Pequeña": "res://Data/Units/Artillería/Batería_Pequeña.tres",
		"Batería Mediana": "res://Data/Units/Artillería/Batería_Mediana.tres",
		"Batería Grande": "res://Data/Units/Artillería/Batería_Grande.tres"
	}
	
	var path = unit_paths.get(unit_type)
	if path:
		return load(path)
	return null

func get_recruitment_manager() -> Node:
	"""Obtiene el manager de reclutamiento"""
	var recruitment_manager = get_node_or_null("/root/RecruitmentManager")
	if not recruitment_manager:
		# Crear el manager si no existe
		var manager_script = load("res://Scripts/Manager/RecruitmentManager.gd")
		recruitment_manager = manager_script.new()
		recruitment_manager.name = "RecruitmentManager"
		get_tree().root.add_child(recruitment_manager)
	return recruitment_manager

func create_unit_instance(unit_data: UnitData, position: Vector2):
	"""Crea una instancia de unidad en el mapa"""
	var unit_scene = load("res://Scenes/Strategic/UnitInstance.tscn")
	if unit_scene:
		var unit_instance = unit_scene.instantiate()
		unit_instance.set_data(unit_data)
		unit_instance.position = position
		
		# Agregar al contenedor de unidades
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			units_container.add_child(unit_instance)
		else:
			strategic_map.add_child(unit_instance)
		
		# Refrescar la lista de unidades
		call_deferred("populate_units_list")

func manage_city_production(city_name: String, resource_type: String):
	"""PLACEHOLDER: Gestionar producción de ciudad"""
	print("TODO: Implementar gestión de producción urbana")
	add_event("Producción ajustada en " + city_name, "info")

func show_diplomacy_panel():
	"""PLACEHOLDER: Mostrar panel de diplomacia"""
	print("TODO: Implementar panel de diplomacia")
	add_event("Panel de diplomacia solicitado", "info")

func show_technology_tree():
	"""PLACEHOLDER: Mostrar árbol de tecnologías"""
	print("TODO: Implementar árbol de tecnologías")
	add_event("Investigación tecnológica solicitada", "info")

func save_game():
	"""PLACEHOLDER: Guardar partida"""
	print("TODO: Implementar sistema de guardado")
	add_event("Partida guardada", "success")

func load_game():
	"""PLACEHOLDER: Cargar partida"""
	print("TODO: Implementar sistema de carga")
	add_event("Partida cargada", "success")