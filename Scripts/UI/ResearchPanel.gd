extends Panel

# ResearchPanel - Panel de investigación para el HUD estratégico
# Muestra tecnologías disponibles, en progreso y completadas

signal technology_selected(technology_id: String)
signal research_started(technology_id: String)
signal research_paused(technology_id: String)
signal research_resumed(technology_id: String)
signal research_cancelled(technology_id: String)

# Referencias a nodos UI
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var available_list: VBoxContainer = $VBoxContainer/TabContainer/Disponibles/ScrollContainer/AvailableList
@onready var in_progress_list: VBoxContainer = $VBoxContainer/TabContainer/EnProgreso/ScrollContainer/InProgressList
@onready var completed_list: VBoxContainer = $VBoxContainer/TabContainer/Completadas/ScrollContainer/CompletedList

@onready var tech_details: Panel = $VBoxContainer/TechnologyDetails
@onready var tech_name_label: Label = $VBoxContainer/TechnologyDetails/VBoxContainer/TechName
@onready var tech_description_label: Label = $VBoxContainer/TechnologyDetails/VBoxContainer/TechDescription
@onready var tech_requirements: VBoxContainer = $VBoxContainer/TechnologyDetails/VBoxContainer/Requirements
@onready var tech_benefits: VBoxContainer = $VBoxContainer/TechnologyDetails/VBoxContainer/Benefits
@onready var tech_actions: HBoxContainer = $VBoxContainer/TechnologyDetails/VBoxContainer/Actions

@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var refresh_button: Button = $VBoxContainer/HeaderContainer/RefreshButton

# Estado actual
var current_faction: String = "Patriota"
var selected_technology: TechnologyData = null

func _ready():
	setup_ui_connections()
	connect_research_manager()
	refresh_all_lists()
	tech_details.visible = false

func setup_ui_connections():
	"""Conecta las señales de los elementos de la UI"""
	close_button.pressed.connect(_on_close_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)

func connect_research_manager():
	"""Conecta las señales del ResearchManager"""
	if ResearchManager:
		ResearchManager.research_completed.connect(_on_research_completed)
		ResearchManager.research_started.connect(_on_research_started)
		ResearchManager.research_progress_updated.connect(_on_research_progress_updated)
		ResearchManager.new_technology_available.connect(_on_new_technology_available)

# === ACTUALIZACIÓN DE LISTAS ===

func refresh_all_lists():
	"""Refresca todas las listas de tecnologías"""
	refresh_available_technologies()
	refresh_in_progress_technologies()
	refresh_completed_technologies()

func refresh_available_technologies():
	"""Actualiza la lista de tecnologías disponibles"""
	clear_list(available_list)
	
	if not ResearchManager:
		return
	
	var available_techs = ResearchManager.get_available_technologies_for_faction(current_faction)
	
	for tech in available_techs:
		add_technology_entry(tech, available_list, "available")

func refresh_in_progress_technologies():
	"""Actualiza la lista de investigaciones en progreso"""
	clear_list(in_progress_list)
	
	if not ResearchManager:
		return
	
	var projects = ResearchManager.get_faction_projects(current_faction)
	
	for project in projects:
		if project.status == "active" or project.status == "paused":
			var tech = ResearchManager.get_technology_by_id(project.technology_id)
			if tech:
				add_project_entry(tech, project, in_progress_list)

func refresh_completed_technologies():
	"""Actualiza la lista de tecnologías completadas"""
	clear_list(completed_list)
	
	if not ResearchManager:
		return
	
	var completed_techs = ResearchManager.get_completed_technologies_for_faction(current_faction)
	
	for tech in completed_techs:
		add_technology_entry(tech, completed_list, "completed")

func clear_list(list: VBoxContainer):
	"""Limpia una lista de elementos"""
	for child in list.get_children():
		child.queue_free()

# === CREACIÓN DE ENTRADAS ===

func add_technology_entry(tech: TechnologyData, target_list: VBoxContainer, entry_type: String):
	"""Añade una entrada de tecnología a una lista"""
	var entry = create_base_tech_entry(tech)
	
	# Añadir información específica según el tipo
	match entry_type:
		"available":
			add_available_tech_info(entry, tech)
		"completed":
			add_completed_tech_info(entry, tech)
	
	target_list.add_child(entry)

func add_project_entry(tech: TechnologyData, project: ResearchProject, target_list: VBoxContainer):
	"""Añade una entrada de proyecto en progreso"""
	var entry = create_base_tech_entry(tech)
	add_progress_tech_info(entry, tech, project)
	target_list.add_child(entry)

func create_base_tech_entry(tech: TechnologyData) -> Control:
	"""Crea la estructura base de una entrada de tecnología"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)
	
	# Icono de la tecnología
	var icon = TextureRect.new()
	icon.custom_min_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Cargar icono (por ahora usar icono por defecto)
	var texture = load("res://icon.svg") as Texture2D
	if texture:
		icon.texture = texture
	
	# Información principal
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = tech.name
	name_label.add_theme_font_size_override("font_size", 14)
	
	var category_label = Label.new()
	category_label.text = "Categoría: %s | Era: %s" % [tech.category.capitalize(), tech.era.capitalize()]
	category_label.add_theme_font_size_override("font_size", 10)
	category_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	info_container.add_child(name_label)
	info_container.add_child(category_label)
	
	entry.add_child(icon)
	entry.add_child(info_container)
	
	return entry

func add_available_tech_info(entry: HBoxContainer, tech: TechnologyData):
	"""Añade información específica para tecnologías disponibles"""
	var actions_container = VBoxContainer.new()
	
	# Costo de investigación
	var cost_label = Label.new()
	cost_label.text = "Costo: %d pts" % tech.research_cost
	cost_label.add_theme_font_size_override("font_size", 10)
	
	# Tiempo estimado
	var time_label = Label.new()
	time_label.text = "Tiempo: %d turnos" % tech.research_time
	time_label.add_theme_font_size_override("font_size", 10)
	
	# Botones de acción
	var buttons_container = HBoxContainer.new()
	
	var details_button = Button.new()
	details_button.text = "Detalles"
	details_button.custom_min_size = Vector2(70, 30)
	details_button.pressed.connect(_on_tech_details_pressed.bind(tech))
	
	var research_button = Button.new()
	research_button.text = "Investigar"
	research_button.custom_min_size = Vector2(80, 30)
	research_button.pressed.connect(_on_start_research_pressed.bind(tech.id))
	
	# Verificar si se puede investigar
	if not ResearchManager or not ResearchManager.can_research_technology(tech.id, current_faction):
		research_button.disabled = true
		research_button.text = "No disponible"
	
	buttons_container.add_child(details_button)
	buttons_container.add_child(research_button)
	
	actions_container.add_child(cost_label)
	actions_container.add_child(time_label)
	actions_container.add_child(buttons_container)
	
	entry.add_child(actions_container)

func add_progress_tech_info(entry: HBoxContainer, tech: TechnologyData, project: ResearchProject):
	"""Añade información específica para tecnologías en progreso"""
	var progress_container = VBoxContainer.new()
	
	# Barra de progreso
	var progress_bar = ProgressBar.new()
	progress_bar.custom_min_size = Vector2(150, 20)
	progress_bar.value = project.get_progress_percentage() * 100
	progress_bar.show_percentage = true
	
	# Estado del proyecto
	var status_label = Label.new()
	status_label.text = project.get_status_display()
	status_label.add_theme_font_size_override("font_size", 10)
	
	# Información adicional
	var info_label = Label.new()
	info_label.text = "Investigadores: %d | Est. %d turnos" % [project.assigned_researchers, project.estimated_turns_remaining]
	info_label.add_theme_font_size_override("font_size", 9)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Botones de control
	var buttons_container = HBoxContainer.new()
	
	var details_button = Button.new()
	details_button.text = "Detalles"
	details_button.custom_min_size = Vector2(60, 25)
	details_button.pressed.connect(_on_tech_details_pressed.bind(tech))
	
	var pause_button = Button.new()
	if project.status == "active":
		pause_button.text = "Pausar"
		pause_button.pressed.connect(_on_pause_research_pressed.bind(tech.id))
	else:
		pause_button.text = "Reanudar"
		pause_button.pressed.connect(_on_resume_research_pressed.bind(tech.id))
	pause_button.custom_min_size = Vector2(70, 25)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancelar"
	cancel_button.custom_min_size = Vector2(70, 25)
	cancel_button.pressed.connect(_on_cancel_research_pressed.bind(tech.id))
	cancel_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	
	buttons_container.add_child(details_button)
	buttons_container.add_child(pause_button)
	buttons_container.add_child(cancel_button)
	
	progress_container.add_child(progress_bar)
	progress_container.add_child(status_label)
	progress_container.add_child(info_label)
	progress_container.add_child(buttons_container)
	
	entry.add_child(progress_container)

func add_completed_tech_info(entry: HBoxContainer, tech: TechnologyData):
	"""Añade información específica para tecnologías completadas"""
	var completed_container = VBoxContainer.new()
	
	var completed_label = Label.new()
	completed_label.text = "✓ COMPLETADA"
	completed_label.add_theme_font_size_override("font_size", 12)
	completed_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	
	var details_button = Button.new()
	details_button.text = "Ver Detalles"
	details_button.custom_min_size = Vector2(100, 30)
	details_button.pressed.connect(_on_tech_details_pressed.bind(tech))
	
	completed_container.add_child(completed_label)
	completed_container.add_child(details_button)
	
	entry.add_child(completed_container)

# === PANEL DE DETALLES ===

func show_technology_details(tech: TechnologyData):
	"""Muestra los detalles de una tecnología"""
	selected_technology = tech
	
	tech_name_label.text = tech.name
	tech_description_label.text = tech.description
	
	# Limpiar contenido anterior
	clear_details_container(tech_requirements)
	clear_details_container(tech_benefits)
	clear_details_container(tech_actions)
	
	# Mostrar requisitos
	add_requirements_info(tech)
	
	# Mostrar beneficios
	add_benefits_info(tech)
	
	# Mostrar acciones disponibles
	add_actions_info(tech)
	
	tech_details.visible = true

func clear_details_container(container: Container):
	"""Limpia un contenedor de detalles"""
	for child in container.get_children():
		child.queue_free()

func add_requirements_info(tech: TechnologyData):
	"""Añade información de requisitos al panel de detalles"""
	var req_title = Label.new()
	req_title.text = "Requisitos:"
	req_title.add_theme_font_size_override("font_size", 12)
	tech_requirements.add_child(req_title)
	
	# Tecnologías requeridas
	if tech.required_technologies.size() > 0:
		for req_tech_id in tech.required_technologies:
			var req_tech = ResearchManager.get_technology_by_id(req_tech_id)
			var req_label = Label.new()
			if req_tech:
				req_label.text = "• " + req_tech.name
			else:
				req_label.text = "• " + req_tech_id
			req_label.add_theme_font_size_override("font_size", 10)
			tech_requirements.add_child(req_label)
	
	# Recursos requeridos
	if tech.required_resources.size() > 0:
		for resource in tech.required_resources:
			var amount = tech.required_resources[resource]
			var resource_label = Label.new()
			resource_label.text = "• %s: %d" % [resource.capitalize(), amount]
			resource_label.add_theme_font_size_override("font_size", 10)
			tech_requirements.add_child(resource_label)
	
	if tech.required_technologies.size() == 0 and tech.required_resources.size() == 0:
		var no_req_label = Label.new()
		no_req_label.text = "Sin requisitos especiales"
		no_req_label.add_theme_font_size_override("font_size", 10)
		no_req_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		tech_requirements.add_child(no_req_label)

func add_benefits_info(tech: TechnologyData):
	"""Añade información de beneficios al panel de detalles"""
	var benefits_title = Label.new()
	benefits_title.text = "Beneficios:"
	benefits_title.add_theme_font_size_override("font_size", 12)
	tech_benefits.add_child(benefits_title)
	
	var benefits_text = tech.get_benefits_summary()
	if benefits_text != "":
		var benefits_lines = benefits_text.split("\n")
		for line in benefits_lines:
			var benefit_label = Label.new()
			benefit_label.text = "• " + line
			benefit_label.add_theme_font_size_override("font_size", 10)
			tech_benefits.add_child(benefit_label)
	else:
		var no_benefits_label = Label.new()
		no_benefits_label.text = "Sin beneficios específicos definidos"
		no_benefits_label.add_theme_font_size_override("font_size", 10)
		no_benefits_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		tech_benefits.add_child(no_benefits_label)

func add_actions_info(tech: TechnologyData):
	"""Añade botones de acción al panel de detalles"""
	var close_details_button = Button.new()
	close_details_button.text = "Cerrar"
	close_details_button.pressed.connect(_on_close_details_pressed)
	tech_actions.add_child(close_details_button)
	
	# Verificar si se puede investigar
	if ResearchManager and ResearchManager.can_research_technology(tech.id, current_faction):
		var start_research_button = Button.new()
		start_research_button.text = "Iniciar Investigación"
		start_research_button.pressed.connect(_on_start_research_pressed.bind(tech.id))
		tech_actions.add_child(start_research_button)

# === CALLBACKS DE UI ===

func _on_close_pressed():
	"""Callback para cerrar el panel de investigación"""
	visible = false

func _on_refresh_pressed():
	"""Callback para refrescar las listas"""
	refresh_all_lists()

func _on_tech_details_pressed(tech: TechnologyData):
	"""Callback para mostrar detalles de una tecnología"""
	show_technology_details(tech)

func _on_start_research_pressed(technology_id: String):
	"""Callback para iniciar investigación"""
	if ResearchManager:
		if ResearchManager.start_research(technology_id, current_faction):
			research_started.emit(technology_id)
			refresh_all_lists()

func _on_pause_research_pressed(technology_id: String):
	"""Callback para pausar investigación"""
	if ResearchManager:
		if ResearchManager.pause_research_project(technology_id, current_faction):
			research_paused.emit(technology_id)
			refresh_all_lists()

func _on_resume_research_pressed(technology_id: String):
	"""Callback para reanudar investigación"""
	if ResearchManager:
		if ResearchManager.resume_research_project(technology_id, current_faction):
			research_resumed.emit(technology_id)
			refresh_all_lists()

func _on_cancel_research_pressed(technology_id: String):
	"""Callback para cancelar investigación"""
	if ResearchManager:
		if ResearchManager.cancel_research_project(technology_id, current_faction):
			research_cancelled.emit(technology_id)
			refresh_all_lists()

func _on_close_details_pressed():
	"""Callback para cerrar panel de detalles"""
	tech_details.visible = false
	selected_technology = null

# === CALLBACKS DEL RESEARCH MANAGER ===

func _on_research_completed(technology_id: String, faction_name: String):
	"""Callback cuando se completa una investigación"""
	if faction_name == current_faction:
		refresh_all_lists()
		# TODO: Mostrar notificación de investigación completada

func _on_research_started(technology_id: String, faction_name: String):
	"""Callback cuando se inicia una investigación"""
	if faction_name == current_faction:
		refresh_all_lists()

func _on_research_progress_updated(technology_id: String, faction_name: String, progress: float):
	"""Callback cuando se actualiza el progreso de investigación"""
	if faction_name == current_faction:
		# Actualizar solo la entrada específica en lugar de toda la lista
		refresh_in_progress_technologies()

func _on_new_technology_available(technology_id: String, faction_name: String):
	"""Callback cuando se desbloquea una nueva tecnología"""
	if faction_name == current_faction:
		refresh_available_technologies()
		# TODO: Mostrar notificación de nueva tecnología disponible

# === MÉTODOS PÚBLICOS ===

func set_faction(faction_name: String):
	"""Cambia la facción mostrada en el panel"""
	current_faction = faction_name
	refresh_all_lists()

func get_current_faction() -> String:
	"""Retorna la facción actualmente mostrada"""
	return current_faction