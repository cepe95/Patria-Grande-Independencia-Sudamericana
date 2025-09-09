extends Panel
class_name DiplomacyPanel

# Referencias a nodos UI
@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var factions_list: VBoxContainer = $VBoxContainer/ContentContainer/FactionsScrollContainer/FactionsList
@onready var details_panel: Panel = $VBoxContainer/ContentContainer/DetailsPanel
@onready var faction_name_label: Label = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/FactionInfo/FactionNameLabel
@onready var relation_status_label: Label = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/FactionInfo/RelationStatusLabel
@onready var opinion_label: Label = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/FactionInfo/OpinionLabel
@onready var treaties_list: VBoxContainer = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/TreatiesContainer/TreatiesList
@onready var proposals_list: VBoxContainer = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/ProposalsContainer/ProposalsList
@onready var actions_container: HBoxContainer = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/ActionsContainer
@onready var events_list: VBoxContainer = $VBoxContainer/ContentContainer/DetailsPanel/VBoxContainer/EventsContainer/EventsList

# Variables
var diplomacy_manager: DiplomacyManager
var selected_faction: String = ""
var player_faction: String = "Patriota"

# Señales
signal proposal_sent(from_faction: String, to_faction: String, proposal_type: String)

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hide()
	
	# Buscar DiplomacyManager
	diplomacy_manager = get_node("/root/DiplomacyManager") if get_node_or_null("/root/DiplomacyManager") else null
	if not diplomacy_manager:
		push_error("DiplomacyPanel: No se encontró DiplomacyManager")

func show_diplomacy():
	"""Muestra el panel de diplomacia"""
	if not diplomacy_manager:
		push_error("DiplomacyPanel: DiplomacyManager no disponible")
		return
	
	populate_factions_list()
	show()

func populate_factions_list():
	"""Puebla la lista de facciones conocidas"""
	# Limpiar lista
	for child in factions_list.get_children():
		child.queue_free()
	
	# Obtener todas las facciones excepto la del jugador
	var all_factions = FactionManager.facciones.keys()
	var other_factions = all_factions.filter(func(f): return f != player_faction)
	
	for faction_name in other_factions:
		create_faction_entry(faction_name)

func create_faction_entry(faction_name: String):
	"""Crea una entrada en la lista de facciones"""
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 10)
	
	# Obtener datos de la facción
	var faction_data = FactionManager.obtener_faccion(faction_name)
	var relation = diplomacy_manager.get_diplomatic_relation(player_faction, faction_name) if diplomacy_manager else null
	
	# Icono de bandera
	var flag_icon = TextureRect.new()
	flag_icon.custom_min_size = Vector2(32, 24)
	flag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if faction_data and faction_data.bandera_path:
		var texture = load(faction_data.bandera_path) as Texture2D
		if texture:
			flag_icon.texture = texture
	
	# Información de la facción
	var info_container = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = faction_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", faction_data.color if faction_data else Color.WHITE)
	
	var status_label = Label.new()
	if relation:
		status_label.text = relation.get_relation_name()
		status_label.add_theme_color_override("font_color", relation.get_relation_color())
	else:
		status_label.text = "Sin Contacto"
		status_label.add_theme_color_override("font_color", Color.GRAY)
	
	status_label.add_theme_font_size_override("font_size", 11)
	
	info_container.add_child(name_label)
	info_container.add_child(status_label)
	
	# Indicadores visuales adicionales
	var indicators_container = VBoxContainer.new()
	
	if relation:
		# Indicador de opinion
		var opinion = relation.get_opinion_towards(faction_name)
		var opinion_indicator = Label.new()
		opinion_indicator.text = "Opinion: %+d" % opinion
		opinion_indicator.add_theme_font_size_override("font_size", 10)
		if opinion > 20:
			opinion_indicator.add_theme_color_override("font_color", Color.GREEN)
		elif opinion < -20:
			opinion_indicator.add_theme_color_override("font_color", Color.RED)
		else:
			opinion_indicator.add_theme_color_override("font_color", Color.WHITE)
		
		indicators_container.add_child(opinion_indicator)
		
		# Indicadores de tratados
		if relation.trade_agreement:
			var trade_indicator = Label.new()
			trade_indicator.text = "💰 Comercio"
			trade_indicator.add_theme_font_size_override("font_size", 9)
			trade_indicator.add_theme_color_override("font_color", Color.YELLOW)
			indicators_container.add_child(trade_indicator)
		
		if relation.military_access:
			var access_indicator = Label.new()
			access_indicator.text = "⚔️ Acceso Militar"
			access_indicator.add_theme_font_size_override("font_size", 9)
			access_indicator.add_theme_color_override("font_color", Color.CYAN)
			indicators_container.add_child(access_indicator)
	
	# Botón de interacción
	var interact_button = Button.new()
	interact_button.text = "Interactuar"
	interact_button.custom_min_size = Vector2(100, 30)
	interact_button.pressed.connect(_on_faction_selected.bind(faction_name))
	
	entry.add_child(flag_icon)
	entry.add_child(info_container)
	entry.add_child(indicators_container)
	entry.add_child(interact_button)
	
	factions_list.add_child(entry)

func _on_faction_selected(faction_name: String):
	"""Maneja la selección de una facción"""
	selected_faction = faction_name
	show_faction_details(faction_name)

func show_faction_details(faction_name: String):
	"""Muestra los detalles de la facción seleccionada"""
	if not diplomacy_manager:
		return
	
	faction_name_label.text = faction_name
	
	var faction_data = FactionManager.obtener_faccion(faction_name)
	var relation = diplomacy_manager.get_diplomatic_relation(player_faction, faction_name)
	
	if relation:
		relation_status_label.text = "Estado: " + relation.get_relation_name()
		relation_status_label.add_theme_color_override("font_color", relation.get_relation_color())
		
		var opinion = relation.get_opinion_towards(faction_name)
		opinion_label.text = "Opinión: %+d" % opinion
		if opinion > 20:
			opinion_label.add_theme_color_override("font_color", Color.GREEN)
		elif opinion < -20:
			opinion_label.add_theme_color_override("font_color", Color.RED)
		else:
			opinion_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		relation_status_label.text = "Estado: Sin Contacto"
		relation_status_label.add_theme_color_override("font_color", Color.GRAY)
		opinion_label.text = "Opinión: Desconocida"
		opinion_label.add_theme_color_override("font_color", Color.GRAY)
	
	populate_treaties_list(relation)
	populate_proposals_list(faction_name)
	populate_diplomatic_actions(relation)
	populate_recent_events(relation)
	
	details_panel.visible = true

func populate_treaties_list(relation: DiplomaticRelation):
	"""Puebla la lista de tratados activos"""
	# Limpiar lista
	for child in treaties_list.get_children():
		child.queue_free()
	
	if not relation or relation.active_treaties.is_empty():
		var no_treaties_label = Label.new()
		no_treaties_label.text = "Sin tratados activos"
		no_treaties_label.add_theme_color_override("font_color", Color.GRAY)
		treaties_list.add_child(no_treaties_label)
		return
	
	for treaty in relation.active_treaties:
		var treaty_label = Label.new()
		treaty_label.text = "• " + treaty.capitalize()
		treaty_label.add_theme_color_override("font_color", Color.GREEN)
		treaties_list.add_child(treaty_label)

func populate_proposals_list(faction_name: String):
	"""Puebla la lista de propuestas pendientes"""
	# Limpiar lista
	for child in proposals_list.get_children():
		child.queue_free()
	
	if not diplomacy_manager:
		return
	
	var pending_proposals = diplomacy_manager.get_pending_proposals_for_faction(player_faction)
	var faction_proposals = pending_proposals.filter(func(p): return p.get("from", "") == faction_name)
	
	if faction_proposals.is_empty():
		var no_proposals_label = Label.new()
		no_proposals_label.text = "Sin propuestas pendientes"
		no_proposals_label.add_theme_color_override("font_color", Color.GRAY)
		proposals_list.add_child(no_proposals_label)
		return
	
	for proposal in faction_proposals:
		create_proposal_entry(proposal)

func create_proposal_entry(proposal: Dictionary):
	"""Crea una entrada de propuesta"""
	var container = VBoxContainer.new()
	
	var header = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = proposal.get("type", "").capitalize()
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(title_label)
	
	var actions = HBoxContainer.new()
	var accept_button = Button.new()
	accept_button.text = "Aceptar"
	accept_button.custom_min_size = Vector2(70, 25)
	accept_button.pressed.connect(_on_proposal_response.bind(proposal.get("id", ""), true))
	
	var reject_button = Button.new()
	reject_button.text = "Rechazar"
	reject_button.custom_min_size = Vector2(70, 25)
	reject_button.pressed.connect(_on_proposal_response.bind(proposal.get("id", ""), false))
	
	actions.add_child(accept_button)
	actions.add_child(reject_button)
	
	container.add_child(header)
	container.add_child(actions)
	
	proposals_list.add_child(container)

func populate_diplomatic_actions(relation: DiplomaticRelation):
	"""Puebla las acciones diplomáticas disponibles"""
	# Limpiar acciones
	for child in actions_container.get_children():
		child.queue_free()
	
	if not relation:
		return
	
	# Botón de alianza
	if relation.can_propose_alliance():
		var alliance_button = Button.new()
		alliance_button.text = "Proponer Alianza"
		alliance_button.custom_min_size = Vector2(120, 30)
		alliance_button.pressed.connect(_on_action_pressed.bind("alliance"))
		actions_container.add_child(alliance_button)
	
	# Botón de acuerdo comercial
	if relation.can_propose_trade():
		var trade_button = Button.new()
		trade_button.text = "Acuerdo Comercial"
		trade_button.custom_min_size = Vector2(120, 30)
		trade_button.pressed.connect(_on_action_pressed.bind("trade_agreement"))
		actions_container.add_child(trade_button)
	
	# Botón de declaración de guerra
	if relation.can_declare_war():
		var war_button = Button.new()
		war_button.text = "Declarar Guerra"
		war_button.custom_min_size = Vector2(120, 30)
		war_button.add_theme_color_override("font_color", Color.RED)
		war_button.pressed.connect(_on_action_pressed.bind("war_declaration"))
		actions_container.add_child(war_button)
	
	# Botón de paz (si están en guerra)
	if relation.status == DiplomaticRelation.RelationStatus.WAR:
		var peace_button = Button.new()
		peace_button.text = "Proponer Paz"
		peace_button.custom_min_size = Vector2(120, 30)
		peace_button.add_theme_color_override("font_color", Color.GREEN)
		peace_button.pressed.connect(_on_action_pressed.bind("peace_treaty"))
		actions_container.add_child(peace_button)

func populate_recent_events(relation: DiplomaticRelation):
	"""Puebla la lista de eventos recientes"""
	# Limpiar eventos
	for child in events_list.get_children():
		child.queue_free()
	
	if not relation or relation.recent_events.is_empty():
		var no_events_label = Label.new()
		no_events_label.text = "Sin eventos recientes"
		no_events_label.add_theme_color_override("font_color", Color.GRAY)
		events_list.add_child(no_events_label)
		return
	
	# Mostrar los últimos 5 eventos
	var recent_events = relation.recent_events.slice(-5)
	for event in recent_events:
		var event_label = Label.new()
		event_label.text = "[Turno %d] %s" % [event.get("turn", 0), event.get("description", "")]
		event_label.add_theme_font_size_override("font_size", 10)
		event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var impact = event.get("impact", 0)
		if impact > 0:
			event_label.add_theme_color_override("font_color", Color.GREEN)
		elif impact < 0:
			event_label.add_theme_color_override("font_color", Color.RED)
		else:
			event_label.add_theme_color_override("font_color", Color.WHITE)
		
		events_list.add_child(event_label)

func _on_action_pressed(action_type: String):
	"""Maneja las acciones diplomáticas"""
	if not diplomacy_manager or selected_faction.is_empty():
		return
	
	diplomacy_manager.send_diplomatic_proposal(player_faction, selected_faction, action_type)
	proposal_sent.emit(player_faction, selected_faction, action_type)
	
	# Actualizar la vista
	show_faction_details(selected_faction)

func _on_proposal_response(proposal_id: String, accept: bool):
	"""Maneja la respuesta a una propuesta"""
	if not diplomacy_manager:
		return
	
	diplomacy_manager.respond_to_proposal(proposal_id, accept)
	
	# Actualizar la vista
	if not selected_faction.is_empty():
		show_faction_details(selected_faction)

func _on_close_pressed():
	"""Cierra el panel de diplomacia"""
	hide()
	details_panel.visible = false
	selected_faction = ""

func update_display():
	"""Actualiza la visualización del panel"""
	if visible:
		populate_factions_list()
		if not selected_faction.is_empty():
			show_faction_details(selected_faction)