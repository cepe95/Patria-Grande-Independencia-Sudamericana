extends Node
class_name CombatSystem

# Sistema de combate por turnos para Patria Grande: Independencia Sudamericana
# Maneja la lógica de combate entre unidades enemigas

signal combat_started(attacker: DivisionData, defender: DivisionData)
signal combat_ended(result: CombatResult)
signal turn_completed(turn_data: CombatTurnData)

# Estructura de datos para resultados de combate
class CombatResult:
	var winner: DivisionData
	var loser: DivisionData
	var attacker_casualties: int = 0
	var defender_casualties: int = 0
	var turns_elapsed: int = 0
	var victory_type: String = "defeat" # "defeat", "rout", "withdrawal"

# Estructura de datos para turnos de combate
class CombatTurnData:
	var turn_number: int
	var attacker: DivisionData
	var defender: DivisionData
	var attacker_action: String
	var defender_action: String
	var attacker_damage: int = 0
	var defender_damage: int = 0
	var attacker_losses: int = 0
	var defender_losses: int = 0

# Parámetros de balance del combate (modificables para modding)
var combat_balance := {
	"base_damage_infantry": 15,
	"base_damage_cavalry": 20,
	"base_damage_artillery": 25,
	"moral_damage_multiplier": 0.1,
	"experience_bonus": 0.05,
	"terrain_modifier": 1.0,
	"max_turns": 10,
	"rout_threshold": 25,
	"withdrawal_threshold": 50
}

var current_combat: Dictionary = {}
var combat_active: bool = false

func _ready():
	print("✓ CombatSystem inicializado")

# === MÉTODOS PÚBLICOS ===

func can_units_combat(unit1: DivisionData, unit2: DivisionData) -> bool:
	"""Determina si dos unidades pueden combatir entre sí"""
	if not unit1 or not unit2:
		return false
	
	# Las unidades deben ser de facciones diferentes
	if unit1.faccion == unit2.faccion:
		return false
	
	# Ambas unidades deben estar activas
	if unit1.estado != "activo" or unit2.estado != "activo":
		return false
	
	# Ambas unidades deben tener tropas
	if unit1.cantidad_total <= 0 or unit2.cantidad_total <= 0:
		return false
	
	return true

func start_combat(attacker: DivisionData, defender: DivisionData) -> bool:
	"""Inicia un combate entre dos unidades"""
	if combat_active:
		push_warning("⚠ Ya hay un combate en curso")
		return false
	
	if not can_units_combat(attacker, defender):
		push_warning("⚠ Las unidades no pueden combatir")
		return false
	
	print("⚔ Iniciando combate: %s vs %s" % [attacker.nombre, defender.nombre])
	
	# Inicializar estado del combate
	current_combat = {
		"attacker": attacker,
		"defender": defender,
		"turn": 1,
		"attacker_losses": 0,
		"defender_losses": 0,
		"active": true
	}
	
	combat_active = true
	emit_signal("combat_started", attacker, defender)
	
	return true

func execute_combat_turn() -> CombatTurnData:
	"""Ejecuta un turno de combate automático"""
	if not combat_active or current_combat.is_empty():
		push_error("⚠ No hay combate activo")
		return null
	
	var turn_data = CombatTurnData.new()
	turn_data.turn_number = current_combat.turn
	turn_data.attacker = current_combat.attacker
	turn_data.defender = current_combat.defender
	
	# Calcular acciones y daño
	_calculate_combat_actions(turn_data)
	_apply_combat_damage(turn_data)
	
	# Actualizar estado del combate
	current_combat.attacker_losses += turn_data.attacker_losses
	current_combat.defender_losses += turn_data.defender_losses
	current_combat.turn += 1
	
	emit_signal("turn_completed", turn_data)
	
	# Verificar condiciones de fin de combate
	if _should_combat_end():
		_end_combat()
	
	return turn_data

func end_combat_manually():
	"""Termina el combate manualmente (retirada)"""
	if combat_active:
		_end_combat("withdrawal")

# === MÉTODOS PRIVADOS ===

func _calculate_combat_actions(turn_data: CombatTurnData):
	"""Calcula las acciones y daño de un turno de combate"""
	var attacker = turn_data.attacker
	var defender = turn_data.defender
	
	# Determinar acciones básicas (siempre atacar por ahora)
	turn_data.attacker_action = "attack"
	turn_data.defender_action = "defend"
	
	# Calcular daño del atacante
	var attacker_damage = _calculate_unit_damage(attacker, defender)
	turn_data.attacker_damage = attacker_damage
	
	# Calcular daño del defensor (contraataque)
	var defender_damage = _calculate_unit_damage(defender, attacker) * 0.7 # Penalización por defender
	turn_data.defender_damage = int(defender_damage)

func _calculate_unit_damage(attacker: DivisionData, defender: DivisionData) -> int:
	"""Calcula el daño que una unidad puede hacer a otra"""
	var base_damage = _get_base_damage(attacker.rama_principal)
	
	# Factores de combate
	var moral_factor = 1.0 + (attacker.moral - 50) * combat_balance.moral_damage_multiplier / 50.0
	var experience_factor = 1.0 + attacker.experiencia * combat_balance.experience_bonus / 100.0
	var size_factor = min(attacker.cantidad_total / 100.0, 2.0) # Máximo 2x por tamaño
	
	var final_damage = base_damage * moral_factor * experience_factor * size_factor
	
	return max(int(final_damage), 1) # Mínimo 1 de daño

func _get_base_damage(unit_type: String) -> int:
	"""Obtiene el daño base según el tipo de unidad"""
	match unit_type.to_lower():
		"infantería", "infanteria":
			return combat_balance.base_damage_infantry
		"caballería", "caballeria":
			return combat_balance.base_damage_cavalry
		"artillería", "artilleria":
			return combat_balance.base_damage_artillery
		_:
			return combat_balance.base_damage_infantry

func _apply_combat_damage(turn_data: CombatTurnData):
	"""Aplica el daño calculado a las unidades"""
	var attacker = turn_data.attacker
	var defender = turn_data.defender
	
	# Aplicar daño al defensor
	var defender_casualties = min(turn_data.attacker_damage, defender.cantidad_total)
	defender.cantidad_total -= defender_casualties
	defender.moral = max(defender.moral - 2, 0) # Pérdida de moral por combate
	turn_data.defender_losses = defender_casualties
	
	# Aplicar daño al atacante (contraataque)
	var attacker_casualties = min(turn_data.defender_damage, attacker.cantidad_total)
	attacker.cantidad_total -= attacker_casualties
	attacker.moral = max(attacker.moral - 1, 0) # Menor pérdida de moral para atacante
	turn_data.attacker_losses = attacker_casualties
	
	print("💥 Turno %d: %s pierde %d, %s pierde %d" % [
		turn_data.turn_number,
		defender.nombre, defender_casualties,
		attacker.nombre, attacker_casualties
	])

func _should_combat_end() -> bool:
	"""Determina si el combate debe terminar"""
	var attacker = current_combat.attacker
	var defender = current_combat.defender
	
	# Una unidad fue eliminada
	if attacker.cantidad_total <= 0 or defender.cantidad_total <= 0:
		return true
	
	# Moral demasiado baja (ruta)
	if attacker.moral <= combat_balance.rout_threshold or defender.moral <= combat_balance.rout_threshold:
		return true
	
	# Muchas pérdidas (retirada)
	var attacker_loss_percent = current_combat.attacker_losses * 100 / (attacker.cantidad_total + current_combat.attacker_losses)
	var defender_loss_percent = current_combat.defender_losses * 100 / (defender.cantidad_total + current_combat.defender_losses)
	
	if attacker_loss_percent >= combat_balance.withdrawal_threshold or defender_loss_percent >= combat_balance.withdrawal_threshold:
		return true
	
	# Máximo de turnos alcanzado
	if current_combat.turn > combat_balance.max_turns:
		return true
	
	return false

func _end_combat(victory_type: String = ""):
	"""Finaliza el combate y determina el resultado"""
	if not combat_active:
		return
	
	var result = CombatResult.new()
	var attacker = current_combat.attacker
	var defender = current_combat.defender
	
	result.attacker_casualties = current_combat.attacker_losses
	result.defender_casualties = current_combat.defender_losses
	result.turns_elapsed = current_combat.turn - 1
	
	# Determinar ganador y tipo de victoria
	if victory_type == "withdrawal":
		result.victory_type = "withdrawal"
		result.winner = defender # El defensor "gana" por retirada del atacante
		result.loser = attacker
	elif attacker.cantidad_total <= 0:
		result.winner = defender
		result.loser = attacker
		result.victory_type = "defeat"
	elif defender.cantidad_total <= 0:
		result.winner = attacker
		result.loser = defender
		result.victory_type = "defeat"
	elif attacker.moral <= combat_balance.rout_threshold:
		result.winner = defender
		result.loser = attacker
		result.victory_type = "rout"
	elif defender.moral <= combat_balance.rout_threshold:
		result.winner = attacker
		result.loser = defender
		result.victory_type = "rout"
	else:
		# Empate o retirada mutua
		result.victory_type = "withdrawal"
		if current_combat.attacker_losses < current_combat.defender_losses:
			result.winner = attacker
			result.loser = defender
		else:
			result.winner = defender
			result.loser = attacker
	
	print("🏁 Combate terminado: %s (%s)" % [result.winner.nombre, result.victory_type])
	
	# Limpiar estado
	current_combat.clear()
	combat_active = false
	
	emit_signal("combat_ended", result)

# === MÉTODOS PARA MODDING ===

func set_balance_parameter(parameter: String, value):
	"""Modifica parámetros de balance para modding"""
	if combat_balance.has(parameter):
		combat_balance[parameter] = value
		print("⚙ Parámetro de combate actualizado: %s = %s" % [parameter, str(value)])
	else:
		push_warning("⚠ Parámetro de combate desconocido: " + parameter)

func get_balance_parameter(parameter: String):
	"""Obtiene un parámetro de balance"""
	return combat_balance.get(parameter, null)

func get_all_balance_parameters() -> Dictionary:
	"""Obtiene todos los parámetros de balance"""
	return combat_balance.duplicate()

# === MÉTODOS DE UTILIDAD ===

func is_combat_active() -> bool:
	"""Verifica si hay un combate activo"""
	return combat_active

func get_current_combat_info() -> Dictionary:
	"""Obtiene información del combate actual"""
	if combat_active:
		return current_combat.duplicate()
	return {}