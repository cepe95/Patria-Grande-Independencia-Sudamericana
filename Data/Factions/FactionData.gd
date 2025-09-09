extends Resource
class_name FactionData

@export var nombre: String
@export var color: Color
@export var bandera_path: String
@export var ideologia: String
@export var recursos := {
	# Alimentación
	"pan": 0,
	"carne": 0,
	"fruta": 0,
	"verdura": 0,
	"vino": 0,
	"aguardiente": 0,
	"tabaco": 0,

	# Economía
	"dinero": 0,
	"oro": 0,
	"plata": 0,

	# Militar
	"municion": 0,
	"polvora": 0,
	"mosquetes": 0,
	"sables": 0,
	"lanzas": 0,
	"cañones": 0,
	"caballos": 0,

	# Cultural
	"biblias": 0,

	# Estado estratégico
	"moral": 100,
	"prestigio": 0
}

# === MÉTODOS DE CONVENIENCIA PARA DIPLOMACIA ===
# Estos métodos facilitan el acceso al sistema de diplomacia desde las facciones

func get_diplomatic_status_with(other_faction: String):
	"""Obtiene el estado diplomático con otra facción"""
	if DiplomacyManager:
		return DiplomacyManager.get_diplomatic_status(nombre, other_faction)
	return DiplomacyManager.DiplomaticStatus.NEUTRAL

func is_at_war_with(other_faction: String) -> bool:
	"""Verifica si está en guerra con otra facción"""
	return get_diplomatic_status_with(other_faction) == DiplomacyManager.DiplomaticStatus.WAR

func is_allied_with(other_faction: String) -> bool:
	"""Verifica si es aliado de otra facción"""
	return get_diplomatic_status_with(other_faction) == DiplomacyManager.DiplomaticStatus.ALLIANCE

func has_trade_agreement_with(other_faction: String) -> bool:
	"""Verifica si tiene tratado comercial con otra facción"""
	return get_diplomatic_status_with(other_faction) == DiplomacyManager.DiplomaticStatus.TRADE

func is_hostile_to(other_faction: String) -> bool:
	"""Verifica si es hostil hacia otra facción"""
	var status = get_diplomatic_status_with(other_faction)
	return status in [DiplomacyManager.DiplomaticStatus.WAR, DiplomacyManager.DiplomaticStatus.HOSTILE]

func can_trade_with(other_faction: String) -> bool:
	"""Verifica si puede comerciar con otra facción (no están en guerra)"""
	var status = get_diplomatic_status_with(other_faction)
	return status != DiplomacyManager.DiplomaticStatus.WAR

func get_all_allies() -> Array[String]:
	"""Obtiene todas las facciones aliadas"""
	if DiplomacyManager:
		return DiplomacyManager.get_factions_with_status(nombre, DiplomacyManager.DiplomaticStatus.ALLIANCE)
	return []

func get_all_enemies() -> Array[String]:
	"""Obtiene todas las facciones enemigas"""
	if DiplomacyManager:
		return DiplomacyManager.get_factions_with_status(nombre, DiplomacyManager.DiplomaticStatus.WAR)
	return []

func get_trade_partners() -> Array[String]:
	"""Obtiene todas las facciones con tratados comerciales"""
	if DiplomacyManager:
		return DiplomacyManager.get_factions_with_status(nombre, DiplomacyManager.DiplomaticStatus.TRADE)
	return []

# === EFECTOS DIPLOMÁTICOS EN RECURSOS ===
# Estos métodos muestran cómo la diplomacia puede afectar a la economía

func apply_trade_bonus():
	"""Aplica bonificaciones por tratados comerciales activos
	
	MODDER NOTE: Este método puede ser extendido para aplicar diferentes
	bonificaciones según el tipo de tratado o facción aliada.
	"""
	var trade_partners = get_trade_partners()
	var trade_bonus = trade_partners.size() * 10  # 10 dinero por socio comercial
	
	if trade_bonus > 0:
		recursos["dinero"] += trade_bonus
		print("Bonificación comercial aplicada: +%d dinero" % trade_bonus)

func apply_war_penalties():
	"""Aplica penalizaciones por estar en guerra
	
	MODDER NOTE: Los modders pueden personalizar estas penalizaciones
	o agregar nuevos efectos basados en el estado diplomático.
	"""
	var enemies = get_all_enemies()
	var war_penalty = enemies.size() * 5  # 5 de moral perdida por enemigo
	
	if war_penalty > 0:
		recursos["moral"] = max(0, recursos["moral"] - war_penalty)
		print("Penalización por guerra aplicada: -%d moral" % war_penalty)

func apply_alliance_benefits():
	"""Aplica beneficios por alianzas activas"""
	var allies = get_all_allies()
	var alliance_bonus = allies.size() * 2  # 2 prestigio por aliado
	
	if alliance_bonus > 0:
		recursos["prestigio"] += alliance_bonus
		print("Bonificación por alianzas aplicada: +%d prestigio" % alliance_bonus)
