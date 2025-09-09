extends Panel

# MilitaryPanel - Panel de gestión militar en el HUD
# Permite ver unidades, reclutar, desplegar y gestionar operaciones militares

signal unit_movement_requested(unit: DivisionData, destination: String)
signal recruitment_requested(unit_type: String, city: String)

@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var units_tab: Control = $VBoxContainer/TabContainer/Unidades
@onready var recruitment_tab: Control = $VBoxContainer/TabContainer/Reclutamiento
@onready var battles_tab: Control = $VBoxContainer/TabContainer/Batallas

# Unidades Tab
@onready var units_list: VBoxContainer = $VBoxContainer/TabContainer/Unidades/ScrollContainer/UnitsList
@onready var unit_filter: OptionButton = $VBoxContainer/TabContainer/Unidades/FilterContainer/UnitFilter
@onready var unit_details: RichTextLabel = $VBoxContainer/TabContainer/Unidades/HSplitContainer/UnitDetailsContainer/UnitDetails

# Reclutamiento Tab
@onready var city_selector: OptionButton = $VBoxContainer/TabContainer/Reclutamiento/RecruitmentContainer/CitySelector
@onready var unit_type_selector: OptionButton = $VBoxContainer/TabContainer/Reclutamiento/RecruitmentContainer/UnitTypeSelector
@onready var recruit_button: Button = $VBoxContainer/TabContainer/Reclutamiento/RecruitmentContainer/RecruitButton
@onready var recruitment_cost_label: RichTextLabel = $VBoxContainer/TabContainer/Reclutamiento/RecruitmentContainer/CostLabel
@onready var recruitment_queue_list: VBoxContainer = $VBoxContainer/TabContainer/Reclutamiento/QueueContainer/QueueList

# Batallas Tab
@onready var active_battles_list: VBoxContainer = $VBoxContainer/TabContainer/Batallas/BattlesContainer/ActiveBattlesList
@onready var battle_history_list: VBoxContainer = $VBoxContainer/TabContainer/Batallas/HistoryContainer/BattleHistoryList

var selected_unit: DivisionData = null
var available_cities: Array[String] = []
var faction_name: String = "Patriota"  # Por defecto, se puede cambiar

func _ready():
	setup_ui()
	connect_signals()
	populate_initial_data()

func setup_ui():
	"""Configura la interfaz inicial"""
	# Configurar filtros de unidad
	unit_filter.add_item("Todas las unidades")
	unit_filter.add_item("Infantería")
	unit_filter.add_item("Caballería") 
	unit_filter.add_item("Artillería")
	unit_filter.add_item("En combate")
	unit_filter.add_item("En reserva")
	
	# Inicializar paneles
	update_unit_details(null)
	update_recruitment_costs()

func connect_signals():
	"""Conecta las señales de la interfaz"""
	unit_filter.item_selected.connect(_on_unit_filter_changed)
	city_selector.item_selected.connect(_on_city_selected)
	unit_type_selector.item_selected.connect(_on_unit_type_selected)
	recruit_button.pressed.connect(_on_recruit_button_pressed)
	
	# Conectar señales del MilitaryManager
	if MilitaryManager:
		MilitaryManager.unit_recruited.connect(_on_unit_recruited)
		MilitaryManager.battle_started.connect(_on_battle_started)
		MilitaryManager.battle_finished.connect(_on_battle_finished)

func populate_initial_data():
	"""Carga datos iniciales"""
	refresh_units_list()
	refresh_cities_list()
	refresh_unit_types()
	refresh_recruitment_queue()
	refresh_battles()

func refresh_units_list():
	"""Actualiza la lista de unidades"""
	clear_container(units_list)
	
	# Obtener unidades del mapa estratégico
	var strategic_map = get_node_or_null("/root/Main/StrategicMap")
	if not strategic_map:
		strategic_map = get_node_or_null("../../../StrategicMap")
	
	if strategic_map:
		var units_container = strategic_map.get_node_or_null("UnitsContainer")
		if units_container:
			for unit_node in units_container.get_children():
				var unit_data = unit_node.get("data")
				if unit_data and should_show_unit(unit_data):
					add_unit_to_list(unit_data)

func should_show_unit(unit_data: DivisionData) -> bool:
	"""Determina si una unidad debe mostrarse según los filtros"""
	var filter_index = unit_filter.selected
	
	match filter_index:
		0: return true  # Todas las unidades
		1: return unit_data.rama_principal == "infanteria"
		2: return unit_data.rama_principal == "caballeria"
		3: return unit_data.rama_principal == "artilleria"
		4: return unit_data.estado_actual == "En combate"
		5: return unit_data.estado_actual == "En reserva"
	
	return true

func add_unit_to_list(unit_data: DivisionData):
	"""Agrega una unidad a la lista"""
	var unit_entry = create_unit_entry(unit_data)
	units_list.add_child(unit_entry)

func create_unit_entry(unit_data: DivisionData) -> Control:
	"""Crea una entrada de unidad para la lista"""
	var entry = HBoxContainer.new()
	entry.custom_minimum_size.y = 60
	
	# Icono de la unidad
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	if unit_data.icono:
		icon.texture = unit_data.icono
	
	# Información principal
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = unit_data.nombre
	name_label.add_theme_font_size_override("font_size", 14)
	
	var stats_label = Label.new()
	stats_label.text = "%d efectivos | Moral: %d | Ubicación: %s" % [
		unit_data.cantidad_total,
		unit_data.moral,
		unit_data.ubicacion if unit_data.ubicacion else "Sin asignar"
	]
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.modulate = Color(0.8, 0.8, 0.8)
	
	info_container.add_child(name_label)
	info_container.add_child(stats_label)
	
	# Botón de selección
	var select_button = Button.new()
	select_button.text = "Seleccionar"
	select_button.pressed.connect(_on_unit_selected.bind(unit_data))
	
	entry.add_child(icon)
	entry.add_child(info_container)
	entry.add_child(select_button)
	
	return entry

func refresh_cities_list():
	"""Actualiza la lista de ciudades disponibles para reclutamiento"""
	city_selector.clear()
	available_cities.clear()
	
	# Obtener ciudades del mapa estratégico
	var strategic_map = get_node_or_null("/root/Main/StrategicMap")
	if not strategic_map:
		strategic_map = get_node_or_null("../../../StrategicMap")
	
	if strategic_map:
		var cities_container = strategic_map.get_node_or_null("CitiesContainer")
		if cities_container:
			for city_node in cities_container.get_children():
				var city_data = city_node.get("data")
				if city_data and city_data.get("faccion") == faction_name:
					available_cities.append(city_data.get("nombre", "Ciudad Desconocida"))
					city_selector.add_item(city_data.get("nombre", "Ciudad Desconocida"))
	
	# Agregar ciudades de ejemplo si no hay ninguna
	if available_cities.is_empty():
		available_cities = ["Buenos Aires", "Caracas", "Bogotá"]
		for city in available_cities:
			city_selector.add_item(city)

func refresh_unit_types():
	"""Actualiza la lista de tipos de unidad disponibles"""
	unit_type_selector.clear()
	
	if MilitaryManager:
		var unit_types = MilitaryManager.get_available_unit_types()
		for unit_type in unit_types:
			unit_type_selector.add_item(unit_type)

func refresh_recruitment_queue():
	"""Actualiza la cola de reclutamiento"""
	clear_container(recruitment_queue_list)
	
	if MilitaryManager:
		for order in MilitaryManager.recruitment_queue:
			var entry = create_recruitment_entry(order)
			recruitment_queue_list.add_child(entry)

func create_recruitment_entry(order: Dictionary) -> Control:
	"""Crea una entrada para la cola de reclutamiento"""
	var entry = HBoxContainer.new()
	
	var info_label = Label.new()
	info_label.text = "%s en %s - %d turnos restantes" % [
		order.get("unit_type", "Desconocido"),
		order.get("city", "Desconocida"),
		order.get("turns_remaining", 0)
	]
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	entry.add_child(info_label)
	return entry

func refresh_battles():
	"""Actualiza la información de batallas"""
	clear_container(active_battles_list)
	clear_container(battle_history_list)
	
	if MilitaryManager:
		# Batallas activas
		for battle in MilitaryManager.active_battles:
			var entry = create_battle_entry(battle, true)
			active_battles_list.add_child(entry)

func create_battle_entry(battle_data: Dictionary, is_active: bool = true) -> Control:
	"""Crea una entrada de batalla"""
	var entry = VBoxContainer.new()
	
	var title_label = Label.new()
	title_label.text = "Batalla en %s" % battle_data.get("location", "Ubicación desconocida")
	title_label.add_theme_font_size_override("font_size", 12)
	
	var participants_label = Label.new()
	participants_label.text = "%s vs %s" % [
		battle_data.get("attacker", {}).get("nombre", "Atacante desconocido"),
		battle_data.get("defender", {}).get("nombre", "Defensor desconocido")
	]
	participants_label.add_theme_font_size_override("font_size", 10)
	participants_label.modulate = Color(0.8, 0.8, 0.8)
	
	entry.add_child(title_label)
	entry.add_child(participants_label)
	
	return entry

func update_unit_details(unit_data: DivisionData):
	"""Actualiza los detalles de la unidad seleccionada"""
	if not unit_data:
		unit_details.text = "[center]Selecciona una unidad para ver sus detalles[/center]"
		return
	
	var details_text = "[b]%s[/b]\n\n" % unit_data.nombre
	details_text += "[color=yellow]Información General:[/color]\n"
	details_text += "• Facción: %s\n" % unit_data.faccion
	details_text += "• Rama: %s\n" % unit_data.rama_principal
	details_text += "• Efectivos: %d\n" % unit_data.cantidad_total
	details_text += "• Estado: %s\n" % unit_data.estado_actual
	details_text += "• Ubicación: %s\n\n" % (unit_data.ubicacion if unit_data.ubicacion else "Sin asignar")
	
	details_text += "[color=green]Estadísticas de Combate:[/color]\n"
	details_text += "• Moral: %d/100\n" % unit_data.moral
	details_text += "• Experiencia: %d/100\n" % unit_data.experiencia
	details_text += "• Movilidad: %d\n" % unit_data.movilidad
	details_text += "• Suministros: %d/100\n\n" % unit_data.suministro
	
	details_text += "[color=cyan]Misión Actual:[/color]\n"
	details_text += "• %s\n\n" % unit_data.mision
	
	if unit_data.historial_batallas.size() > 0:
		details_text += "[color=red]Historial de Batallas:[/color]\n"
		for batalla in unit_data.historial_batallas:
			details_text += "• %s\n" % batalla
	
	unit_details.text = details_text

func update_recruitment_costs():
	"""Actualiza la información de costos de reclutamiento"""
	if unit_type_selector.selected < 0 or not MilitaryManager:
		recruitment_cost_label.text = "Selecciona un tipo de unidad"
		return
	
	var unit_type = unit_type_selector.get_item_text(unit_type_selector.selected)
	var config = MilitaryManager.get_unit_config(unit_type)
	
	if config.is_empty():
		recruitment_cost_label.text = "Configuración no encontrada"
		return
	
	var cost_text = "[b]Costo de Reclutamiento:[/b]\n"
	var recruitment_cost = config.get("recruitment_cost", {})
	for resource in recruitment_cost:
		cost_text += "• %s: %d\n" % [resource.capitalize(), recruitment_cost[resource]]
	
	cost_text += "\n[b]Tiempo:[/b] %d turnos\n" % config.get("recruitment_time", 1)
	cost_text += "[b]Efectivos:[/b] %d\n" % config.get("size", 0)
	cost_text += "[b]Efectividad:[/b] %d\n" % config.get("effectiveness", 0)
	
	recruitment_cost_label.text = cost_text

func clear_container(container: Container):
	"""Limpia todos los hijos de un contenedor"""
	for child in container.get_children():
		child.queue_free()

# === CALLBACKS DE SEÑALES ===

func _on_unit_filter_changed(index: int):
	"""Callback cuando cambia el filtro de unidades"""
	refresh_units_list()

func _on_city_selected(index: int):
	"""Callback cuando se selecciona una ciudad"""
	update_recruitment_costs()

func _on_unit_type_selected(index: int):
	"""Callback cuando se selecciona un tipo de unidad"""
	update_recruitment_costs()

func _on_recruit_button_pressed():
	"""Callback cuando se presiona el botón de reclutar"""
	if city_selector.selected < 0 or unit_type_selector.selected < 0:
		return
	
	var city = city_selector.get_item_text(city_selector.selected)
	var unit_type = unit_type_selector.get_item_text(unit_type_selector.selected)
	
	if MilitaryManager and MilitaryManager.recruit_unit(unit_type, city, faction_name):
		refresh_recruitment_queue()
		recruitment_requested.emit(unit_type, city)
		
		# Enviar evento al HUD principal
		var main_hud = get_node_or_null("../../..")
		if main_hud and main_hud.has_method("add_event"):
			main_hud.add_event("Reclutamiento iniciado: %s en %s" % [unit_type, city], "success")
	else:
		# Mostrar error
		var main_hud = get_node_or_null("../../..")
		if main_hud and main_hud.has_method("add_event"):
			main_hud.add_event("No se puede reclutar: recursos insuficientes", "error")

func _on_unit_selected(unit_data: DivisionData):
	"""Callback cuando se selecciona una unidad"""
	selected_unit = unit_data
	update_unit_details(unit_data)

func _on_unit_recruited(unit_data: UnitData, city: String):
	"""Callback cuando se completa un reclutamiento"""
	refresh_recruitment_queue()
	refresh_units_list()
	
	var main_hud = get_node_or_null("../../..")
	if main_hud and main_hud.has_method("add_event"):
		main_hud.add_event("¡Reclutamiento completado! %s en %s" % [unit_data.nombre, city], "success")

func _on_battle_started(attacker: DivisionData, defender: DivisionData, location: String):
	"""Callback cuando inicia una batalla"""
	refresh_battles()
	
	var main_hud = get_node_or_null("../../..")
	if main_hud and main_hud.has_method("add_event"):
		main_hud.add_event("¡Batalla iniciada en %s!" % location, "warning")

func _on_battle_finished(result: Dictionary):
	"""Callback cuando termina una batalla"""
	refresh_battles()
	refresh_units_list()
	
	var main_hud = get_node_or_null("../../..")
	if main_hud and main_hud.has_method("add_event"):
		var message = "Batalla en %s: %s vs %s" % [
			result.get("location", "ubicación desconocida"),
			result.get("attacker_name", "atacante"),
			result.get("defender_name", "defensor")
		]
		main_hud.add_event(message, "info")

# === MÉTODOS PÚBLICOS ===

func set_faction(new_faction: String):
	"""Establece la facción del jugador"""
	faction_name = new_faction
	refresh_cities_list()
	refresh_units_list()

func process_turn():
	"""Procesa un turno para el sistema militar"""
	if MilitaryManager:
		MilitaryManager.process_recruitment()
		refresh_recruitment_queue()
		refresh_units_list()