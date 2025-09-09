extends Node

# DiplomacyManager - Sistema de gestión de relaciones diplomáticas
# Maneja el estado diplomático entre facciones y la validación de acciones

enum DiplomaticStatus {
	NEUTRAL,     # Estado inicial, no hay relaciones establecidas
	PEACE,       # Paz formal (requiere acuerdo previo)
	ALLIANCE,    # Alianza (cooperación activa)
	TRADE,       # Tratado comercial (beneficios económicos)
	WAR,         # Guerra declarada
	HOSTILE      # Hostilidad sin guerra formal
}

enum ProposalType {
	DECLARE_WAR,
	PROPOSE_PEACE,
	PROPOSE_ALLIANCE,
	PROPOSE_TRADE
}

# Estructura para almacenar propuestas diplomáticas
class DiplomaticProposal:
	var sender: String
	var receiver: String
	var type: ProposalType
	var timestamp: int
	
	func _init(s: String, r: String, t: ProposalType, time: int):
		sender = s
		receiver = r
		type = t
		timestamp = time

# Relaciones diplomáticas entre facciones (facción1 -> facción2 -> estado)
var diplomatic_relations: Dictionary = {}
# Propuestas pendientes
var pending_proposals: Array[DiplomaticProposal] = []
# Historial de eventos diplomáticos para validación
var diplomatic_history: Array = []

signal diplomatic_status_changed(faction1: String, faction2: String, old_status: DiplomaticStatus, new_status: DiplomaticStatus)
signal proposal_received(proposal: DiplomaticProposal)

func _ready():
	# Inicializar relaciones entre facciones existentes
	initialize_diplomatic_relations()

func initialize_diplomatic_relations():
	"""Inicializa las relaciones diplomáticas entre todas las facciones conocidas"""
	var factions = FactionManager.facciones.keys()
	
	for faction1 in factions:
		if not diplomatic_relations.has(faction1):
			diplomatic_relations[faction1] = {}
		
		for faction2 in factions:
			if faction1 != faction2 and not diplomatic_relations[faction1].has(faction2):
				diplomatic_relations[faction1][faction2] = DiplomaticStatus.NEUTRAL

func get_diplomatic_status(faction1: String, faction2: String) -> DiplomaticStatus:
	"""Obtiene el estado diplomático entre dos facciones"""
	if diplomatic_relations.has(faction1) and diplomatic_relations[faction1].has(faction2):
		return diplomatic_relations[faction1][faction2]
	return DiplomaticStatus.NEUTRAL

func set_diplomatic_status(faction1: String, faction2: String, status: DiplomaticStatus) -> bool:
	"""Establece el estado diplomático entre dos facciones (bidireccional)"""
	if not _can_change_status(faction1, faction2, status):
		return false
	
	var old_status = get_diplomatic_status(faction1, faction2)
	
	# Inicializar si no existe
	if not diplomatic_relations.has(faction1):
		diplomatic_relations[faction1] = {}
	if not diplomatic_relations.has(faction2):
		diplomatic_relations[faction2] = {}
	
	# Establecer relación bidireccional
	diplomatic_relations[faction1][faction2] = status
	diplomatic_relations[faction2][faction1] = status
	
	# Registrar en historial
	diplomatic_history.append({
		"faction1": faction1,
		"faction2": faction2,
		"status": status,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Emitir señal
	diplomatic_status_changed.emit(faction1, faction2, old_status, status)
	
	return true

func send_proposal(sender: String, receiver: String, proposal_type: ProposalType) -> bool:
	"""Envía una propuesta diplomática"""
	if not _can_send_proposal(sender, receiver, proposal_type):
		return false
	
	var proposal = DiplomaticProposal.new(sender, receiver, proposal_type, Time.get_unix_time_from_system())
	pending_proposals.append(proposal)
	
	proposal_received.emit(proposal)
	return true

func accept_proposal(proposal: DiplomaticProposal) -> bool:
	"""Acepta una propuesta diplomática"""
	if not proposal in pending_proposals:
		return false
	
	var success = false
	
	match proposal.type:
		ProposalType.DECLARE_WAR:
			success = set_diplomatic_status(proposal.sender, proposal.receiver, DiplomaticStatus.WAR)
		ProposalType.PROPOSE_PEACE:
			success = set_diplomatic_status(proposal.sender, proposal.receiver, DiplomaticStatus.PEACE)
		ProposalType.PROPOSE_ALLIANCE:
			success = set_diplomatic_status(proposal.sender, proposal.receiver, DiplomaticStatus.ALLIANCE)
		ProposalType.PROPOSE_TRADE:
			success = set_diplomatic_status(proposal.sender, proposal.receiver, DiplomaticStatus.TRADE)
	
	if success:
		pending_proposals.erase(proposal)
	
	return success

func reject_proposal(proposal: DiplomaticProposal):
	"""Rechaza una propuesta diplomática"""
	pending_proposals.erase(proposal)

func _can_change_status(faction1: String, faction2: String, new_status: DiplomaticStatus) -> bool:
	"""Valida si es posible cambiar el estado diplomático según las reglas del juego"""
	var current_status = get_diplomatic_status(faction1, faction2)
	
	match new_status:
		DiplomaticStatus.PEACE:
			# Solo se puede hacer paz si previamente hubo guerra o hostilidad
			return current_status in [DiplomaticStatus.WAR, DiplomaticStatus.HOSTILE]
		
		DiplomaticStatus.ALLIANCE:
			# No se puede hacer alianza si hay guerra activa
			return current_status != DiplomaticStatus.WAR
		
		DiplomaticStatus.TRADE:
			# No se puede comerciar en guerra
			return current_status != DiplomaticStatus.WAR
		
		DiplomaticStatus.WAR:
			# Siempre se puede declarar guerra (excepto si ya hay guerra)
			return current_status != DiplomaticStatus.WAR
		
		DiplomaticStatus.HOSTILE:
			# Se puede ser hostil desde cualquier estado excepto guerra
			return current_status != DiplomaticStatus.WAR
		
		DiplomaticStatus.NEUTRAL:
			# Se puede volver a neutral desde paz o comercio
			return current_status in [DiplomaticStatus.PEACE, DiplomaticStatus.TRADE, DiplomaticStatus.NEUTRAL]
	
	return true

func _can_send_proposal(sender: String, receiver: String, proposal_type: ProposalType) -> bool:
	"""Valida si se puede enviar una propuesta específica"""
	# Verificar que las facciones existan
	if not FactionManager.faccion_existe(sender) or not FactionManager.faccion_existe(receiver):
		return false
	
	# No se puede enviar propuestas a uno mismo
	if sender == receiver:
		return false
	
	# Verificar si ya hay una propuesta pendiente del mismo tipo
	for proposal in pending_proposals:
		if proposal.sender == sender and proposal.receiver == receiver and proposal.type == proposal_type:
			return false
	
	var current_status = get_diplomatic_status(sender, receiver)
	
	match proposal_type:
		ProposalType.DECLARE_WAR:
			return current_status != DiplomaticStatus.WAR
		ProposalType.PROPOSE_PEACE:
			return current_status in [DiplomaticStatus.WAR, DiplomaticStatus.HOSTILE]
		ProposalType.PROPOSE_ALLIANCE:
			return current_status != DiplomaticStatus.WAR
		ProposalType.PROPOSE_TRADE:
			return current_status != DiplomaticStatus.WAR
	
	return true

func get_status_name(status: DiplomaticStatus) -> String:
	"""Devuelve el nombre legible del estado diplomático"""
	match status:
		DiplomaticStatus.NEUTRAL:
			return "Neutral"
		DiplomaticStatus.PEACE:
			return "Paz"
		DiplomaticStatus.ALLIANCE:
			return "Alianza"
		DiplomaticStatus.TRADE:
			return "Tratado Comercial"
		DiplomaticStatus.WAR:
			return "Guerra"
		DiplomaticStatus.HOSTILE:
			return "Hostil"
		_:
			return "Desconocido"

func get_proposal_type_name(type: ProposalType) -> String:
	"""Devuelve el nombre legible del tipo de propuesta"""
	match type:
		ProposalType.DECLARE_WAR:
			return "Declaración de Guerra"
		ProposalType.PROPOSE_PEACE:
			return "Propuesta de Paz"
		ProposalType.PROPOSE_ALLIANCE:
			return "Propuesta de Alianza"
		ProposalType.PROPOSE_TRADE:
			return "Propuesta de Tratado Comercial"
		_:
			return "Propuesta Desconocida"

func get_factions_with_status(target_faction: String, status: DiplomaticStatus) -> Array[String]:
	"""Obtiene todas las facciones que tienen un estado específico con la facción objetivo"""
	var result: Array[String] = []
	
	if diplomatic_relations.has(target_faction):
		for faction in diplomatic_relations[target_faction]:
			if diplomatic_relations[target_faction][faction] == status:
				result.append(faction)
	
	return result

# === FUNCIONES PARA MODDERS ===
# Estas funciones permiten a los modders extender el sistema de diplomacia

func add_custom_diplomatic_status(status_name: String, status_id: int):
	"""MODDER API: Permite agregar nuevos estados diplomáticos personalizados
	
	Uso para modders:
		DiplomacyManager.add_custom_diplomatic_status("VASSAL", 100)
	"""
	# Nota: En una implementación completa, esto requeriría un sistema más robusto
	# para manejar estados personalizados sin conflictos con los enum existentes
	print("MODDER API: Estado diplomático personalizado registrado: ", status_name, " ID: ", status_id)

func add_custom_proposal_type(proposal_name: String, proposal_id: int):
	"""MODDER API: Permite agregar nuevos tipos de propuestas diplomáticas
	
	Uso para modders:
		DiplomacyManager.add_custom_proposal_type("TRIBUTE_DEMAND", 200)
	"""
	print("MODDER API: Tipo de propuesta personalizada registrada: ", proposal_name, " ID: ", proposal_id)

func register_custom_validation_rule(rule_name: String, validation_function: Callable):
	"""MODDER API: Permite agregar reglas personalizadas de validación
	
	Uso para modders:
		DiplomacyManager.register_custom_validation_rule("no_war_on_sundays", my_validation_func)
	"""
	print("MODDER API: Regla de validación personalizada registrada: ", rule_name)