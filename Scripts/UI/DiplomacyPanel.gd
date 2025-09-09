extends Panel

# DiplomacyPanel - Panel de interfaz para gestionar relaciones diplomáticas
# Permite seleccionar facciones y realizar acciones diplomáticas

# Referencias a nodos de la UI
@onready var faction_list: VBoxContainer = $VBoxContainer/Content/FactionSelection/FactionListScroll/FactionList
@onready var faction_info: VBoxContainer = $VBoxContainer/Content/DiplomacyActions/FactionInfoScroll/FactionInfo
@onready var action_buttons: VBoxContainer = $VBoxContainer/Content/DiplomacyActions/ActionButtonsScroll/ActionButtons
@onready var proposals_list: VBoxContainer = $VBoxContainer/ProposalsSection/ProposalsScroll/ProposalsList
@onready var close_button: Button = $VBoxContainer/Header/CloseButton
@onready var title_label: Label = $VBoxContainer/Header/TitleLabel

# Estado actual
var selected_faction: String = ""
var player_faction: String = "Patriota"  # La facción del jugador

signal panel_closed
signal diplomatic_action_performed(action: String, target_faction: String)

func _ready():
	setup_ui()
	connect_signals()
	refresh_faction_list()
	refresh_proposals()

func setup_ui():
	"""Configura la interfaz inicial"""
	title_label.text = "Panel de Diplomacia"
	visible = false

func connect_signals():
	"""Conecta las señales necesarias"""
	close_button.pressed.connect(_on_close_pressed)
	DiplomacyManager.diplomatic_status_changed.connect(_on_diplomatic_status_changed)
	DiplomacyManager.proposal_received.connect(_on_proposal_received)

func show_panel():
	"""Muestra el panel de diplomacia"""
	visible = true
	refresh_faction_list()
	refresh_proposals()

func hide_panel():
	"""Oculta el panel de diplomacia"""
	visible = false
	selected_faction = ""
	clear_faction_info()

func refresh_faction_list():
	"""Actualiza la lista de facciones disponibles"""
	# Limpiar lista actual
	for child in faction_list.get_children():
		child.queue_free()
	
	# Agregar facciones (excluyendo la del jugador)
	for faction_name in FactionManager.facciones.keys():
		if faction_name != player_faction:
			create_faction_entry(faction_name)

func create_faction_entry(faction_name: String):
	"""Crea una entrada para una facción en la lista"""
	var entry = HBoxContainer.new()
	
	# Icono de facción (usando color como indicador)
	var color_rect = ColorRect.new()
	var faction_data = FactionManager.obtener_faccion(faction_name)
	if faction_data:
		color_rect.color = faction_data.color
	else:
		color_rect.color = Color.WHITE
	color_rect.custom_min_size = Vector2(20, 20)
	
	# Nombre de la facción
	var name_label = Label.new()
	name_label.text = faction_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Estado diplomático actual
	var status = DiplomacyManager.get_diplomatic_status(player_faction, faction_name)
	var status_label = Label.new()
	status_label.text = DiplomacyManager.get_status_name(status)
	status_label.add_theme_color_override("font_color", get_status_color(status))
	
	# Botón de selección
	var select_button = Button.new()
	select_button.text = "Seleccionar"
	select_button.custom_min_size = Vector2(80, 30)
	select_button.pressed.connect(_on_faction_selected.bind(faction_name))
	
	entry.add_child(color_rect)
	entry.add_child(name_label)
	entry.add_child(status_label)
	entry.add_child(select_button)
	
	faction_list.add_child(entry)

func get_status_color(status: DiplomacyManager.DiplomaticStatus) -> Color:
	"""Devuelve el color asociado a un estado diplomático"""
	match status:
		DiplomacyManager.DiplomaticStatus.NEUTRAL:
			return Color.WHITE
		DiplomacyManager.DiplomaticStatus.PEACE:
			return Color.CYAN
		DiplomacyManager.DiplomaticStatus.ALLIANCE:
			return Color.GREEN
		DiplomacyManager.DiplomaticStatus.TRADE:
			return Color.YELLOW
		DiplomacyManager.DiplomaticStatus.WAR:
			return Color.RED
		DiplomacyManager.DiplomaticStatus.HOSTILE:
			return Color.ORANGE
		_:
			return Color.WHITE

func _on_faction_selected(faction_name: String):
	"""Callback cuando se selecciona una facción"""
	selected_faction = faction_name
	show_faction_info(faction_name)

func show_faction_info(faction_name: String):
	"""Muestra información detallada de la facción seleccionada"""
	clear_faction_info()
	
	var faction_data = FactionManager.obtener_faccion(faction_name)
	if not faction_data:
		return
	
	# Título
	var title = Label.new()
	title.text = "Relaciones con " + faction_name
	title.add_theme_font_size_override("font_size", 16)
	faction_info.add_child(title)
	
	# Estado actual
	var status = DiplomacyManager.get_diplomatic_status(player_faction, faction_name)
	var status_label = Label.new()
	status_label.text = "Estado: " + DiplomacyManager.get_status_name(status)
	status_label.add_theme_color_override("font_color", get_status_color(status))
	faction_info.add_child(status_label)
	
	# Información adicional
	var ideology_label = Label.new()
	ideology_label.text = "Ideología: " + faction_data.ideologia
	faction_info.add_child(ideology_label)
	
	# Crear botones de acción
	create_action_buttons(faction_name)

func create_action_buttons(faction_name: String):
	"""Crea los botones de acciones diplomáticas disponibles"""
	clear_action_buttons()
	
	var current_status = DiplomacyManager.get_diplomatic_status(player_faction, faction_name)
	
	# Declarar guerra (si no están en guerra)
	if DiplomacyManager._can_send_proposal(player_faction, faction_name, DiplomacyManager.ProposalType.DECLARE_WAR):
		create_action_button("Declarar Guerra", DiplomacyManager.ProposalType.DECLARE_WAR, faction_name, Color.RED)
	
	# Proponer paz (si están en guerra o hostiles)
	if DiplomacyManager._can_send_proposal(player_faction, faction_name, DiplomacyManager.ProposalType.PROPOSE_PEACE):
		create_action_button("Proponer Paz", DiplomacyManager.ProposalType.PROPOSE_PEACE, faction_name, Color.CYAN)
	
	# Proponer alianza (si no están en guerra)
	if DiplomacyManager._can_send_proposal(player_faction, faction_name, DiplomacyManager.ProposalType.PROPOSE_ALLIANCE):
		create_action_button("Proponer Alianza", DiplomacyManager.ProposalType.PROPOSE_ALLIANCE, faction_name, Color.GREEN)
	
	# Proponer tratado comercial (si no están en guerra)
	if DiplomacyManager._can_send_proposal(player_faction, faction_name, DiplomacyManager.ProposalType.PROPOSE_TRADE):
		create_action_button("Proponer Comercio", DiplomacyManager.ProposalType.PROPOSE_TRADE, faction_name, Color.YELLOW)

func create_action_button(text: String, proposal_type: DiplomacyManager.ProposalType, target_faction: String, color: Color):
	"""Crea un botón de acción diplomática"""
	var button = Button.new()
	button.text = text
	button.custom_min_size = Vector2(200, 40)
	button.add_theme_color_override("font_color", color)
	button.pressed.connect(_on_action_button_pressed.bind(proposal_type, target_faction))
	action_buttons.add_child(button)

func refresh_proposals():
	"""Actualiza la lista de propuestas pendientes"""
	clear_proposals()
	
	# Filtrar propuestas dirigidas al jugador
	var player_proposals = DiplomacyManager.pending_proposals.filter(
		func(proposal): return proposal.receiver == player_faction
	)
	
	if player_proposals.is_empty():
		var no_proposals_label = Label.new()
		no_proposals_label.text = "No hay propuestas pendientes"
		no_proposals_label.add_theme_color_override("font_color", Color.GRAY)
		proposals_list.add_child(no_proposals_label)
		return
	
	for proposal in player_proposals:
		create_proposal_entry(proposal)

func create_proposal_entry(proposal: DiplomacyManager.DiplomaticProposal):
	"""Crea una entrada para una propuesta pendiente"""
	var entry = VBoxContainer.new()
	
	# Información de la propuesta
	var info_label = Label.new()
	info_label.text = "%s de %s: %s" % [
		DiplomacyManager.get_proposal_type_name(proposal.type),
		proposal.sender,
		DiplomacyManager.get_proposal_type_name(proposal.type)
	]
	entry.add_child(info_label)
	
	# Botones de acción
	var buttons_container = HBoxContainer.new()
	
	var accept_button = Button.new()
	accept_button.text = "Aceptar"
	accept_button.custom_min_size = Vector2(80, 30)
	accept_button.add_theme_color_override("font_color", Color.GREEN)
	accept_button.pressed.connect(_on_proposal_accepted.bind(proposal))
	
	var reject_button = Button.new()
	reject_button.text = "Rechazar"
	reject_button.custom_min_size = Vector2(80, 30)
	reject_button.add_theme_color_override("font_color", Color.RED)
	reject_button.pressed.connect(_on_proposal_rejected.bind(proposal))
	
	buttons_container.add_child(accept_button)
	buttons_container.add_child(reject_button)
	entry.add_child(buttons_container)
	
	# Separador
	var separator = HSeparator.new()
	entry.add_child(separator)
	
	proposals_list.add_child(entry)

func clear_faction_info():
	"""Limpia la información de facción"""
	for child in faction_info.get_children():
		child.queue_free()

func clear_action_buttons():
	"""Limpia los botones de acción"""
	for child in action_buttons.get_children():
		child.queue_free()

func clear_proposals():
	"""Limpia la lista de propuestas"""
	for child in proposals_list.get_children():
		child.queue_free()

# === CALLBACKS ===

func _on_close_pressed():
	"""Callback cuando se presiona el botón cerrar"""
	hide_panel()
	panel_closed.emit()

func _on_action_button_pressed(proposal_type: DiplomacyManager.ProposalType, target_faction: String):
	"""Callback cuando se presiona un botón de acción diplomática"""
	var success = DiplomacyManager.send_proposal(player_faction, target_faction, proposal_type)
	
	if success:
		var action_name = DiplomacyManager.get_proposal_type_name(proposal_type)
		diplomatic_action_performed.emit(action_name, target_faction)
		
		# Refrescar la interfaz
		if selected_faction == target_faction:
			show_faction_info(target_faction)
	else:
		# Mostrar error (esto se podría mejorar con un sistema de notificaciones)
		print("No se pudo enviar la propuesta diplomática")

func _on_proposal_accepted(proposal: DiplomacyManager.DiplomaticProposal):
	"""Callback cuando se acepta una propuesta"""
	var success = DiplomacyManager.accept_proposal(proposal)
	
	if success:
		diplomatic_action_performed.emit("Propuesta Aceptada", proposal.sender)
		refresh_proposals()
		refresh_faction_list()
		
		if selected_faction == proposal.sender:
			show_faction_info(selected_faction)

func _on_proposal_rejected(proposal: DiplomacyManager.DiplomaticProposal):
	"""Callback cuando se rechaza una propuesta"""
	DiplomacyManager.reject_proposal(proposal)
	diplomatic_action_performed.emit("Propuesta Rechazada", proposal.sender)
	refresh_proposals()

func _on_diplomatic_status_changed(faction1: String, faction2: String, old_status: DiplomacyManager.DiplomaticStatus, new_status: DiplomacyManager.DiplomaticStatus):
	"""Callback cuando cambia el estado diplomático"""
	# Refrescar la interfaz si está afectada
	if faction1 == player_faction or faction2 == player_faction:
		refresh_faction_list()
		
		# Si la facción seleccionada está involucrada, actualizar info
		if selected_faction == faction1 or selected_faction == faction2:
			var target = faction1 if faction1 != player_faction else faction2
			show_faction_info(target)

func _on_proposal_received(proposal: DiplomacyManager.DiplomaticProposal):
	"""Callback cuando se recibe una nueva propuesta"""
	if proposal.receiver == player_faction:
		refresh_proposals()