extends Control
class_name CombatUI

# Interfaz de usuario para el sistema de combate por turnos
# Muestra la información del combate y permite interacción del jugador

signal combat_action_selected(action: String)
signal combat_ended_by_player

# Referencias a nodos de la UI
@onready var combat_panel: Panel = $CombatPanel
@onready var attacker_info: VBoxContainer = $CombatPanel/MainContainer/UnitsContainer/AttackerInfo
@onready var defender_info: VBoxContainer = $CombatPanel/MainContainer/UnitsContainer/DefenderInfo
@onready var combat_log: VBoxContainer = $CombatPanel/MainContainer/CombatLog/ScrollContainer/LogContainer
@onready var action_buttons: HBoxContainer = $CombatPanel/MainContainer/ActionButtons
@onready var vs_label: Label = $CombatPanel/MainContainer/UnitsContainer/VsLabel

# Botones de acción
@onready var attack_button: Button = $CombatPanel/MainContainer/ActionButtons/AttackButton
@onready var defend_button: Button = $CombatPanel/MainContainer/ActionButtons/DefendButton
@onready var retreat_button: Button = $CombatPanel/MainContainer/ActionButtons/RetreatButton
@onready var auto_button: Button = $CombatPanel/MainContainer/ActionButtons/AutoButton

# Labels de información de unidades
@onready var attacker_name: Label = $CombatPanel/MainContainer/UnitsContainer/AttackerInfo/NameLabel
@onready var attacker_icon: TextureRect = $CombatPanel/MainContainer/UnitsContainer/AttackerInfo/IconContainer/Icon
@onready var attacker_stats: VBoxContainer = $CombatPanel/MainContainer/UnitsContainer/AttackerInfo/StatsContainer

@onready var defender_name: Label = $CombatPanel/MainContainer/UnitsContainer/DefenderInfo/NameLabel
@onready var defender_icon: TextureRect = $CombatPanel/MainContainer/UnitsContainer/DefenderInfo/IconContainer/Icon
@onready var defender_stats: VBoxContainer = $CombatPanel/MainContainer/UnitsContainer/DefenderInfo/StatsContainer

# Variables de estado
var current_attacker: DivisionData
var current_defender: DivisionData
var auto_combat: bool = false
var combat_system: CombatSystem

func _ready():
	hide() # Ocultar por defecto
	setup_button_connections()
	print("✓ CombatUI inicializada")

func setup_button_connections():
	"""Conecta las señales de los botones"""
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if defend_button:
		defend_button.pressed.connect(_on_defend_pressed)
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)
	if auto_button:
		auto_button.pressed.connect(_on_auto_pressed)

# === MÉTODOS PÚBLICOS ===

func show_combat(attacker: DivisionData, defender: DivisionData, combat_sys: CombatSystem):
	"""Muestra la interfaz de combate con las unidades especificadas"""
	current_attacker = attacker
	current_defender = defender
	combat_system = combat_sys
	
	# Configurar información de las unidades
	setup_unit_display(attacker, attacker_name, attacker_icon, attacker_stats)
	setup_unit_display(defender, defender_name, defender_icon, defender_stats)
	
	# Limpiar log de combate
	clear_combat_log()
	add_combat_log("¡Combate iniciado entre %s y %s!" % [attacker.nombre, defender.nombre], "combat_start")
	
	# Configurar botones
	reset_action_buttons()
	
	# Mostrar panel
	show()
	combat_panel.visible = true
	
	print("👁 Mostrando interfaz de combate")

func hide_combat():
	"""Oculta la interfaz de combate"""
	hide()
	auto_combat = false
	print("👁 Ocultando interfaz de combate")

func update_combat_turn(turn_data: CombatSystem.CombatTurnData):
	"""Actualiza la interfaz con los resultados de un turno"""
	if not turn_data:
		return
	
	# Actualizar estadísticas de las unidades
	update_unit_stats(current_attacker, attacker_stats)
	update_unit_stats(current_defender, defender_stats)
	
	# Agregar información del turno al log
	var turn_text = "Turno %d: " % turn_data.turn_number
	
	if turn_data.attacker_damage > 0:
		turn_text += "%s ataca a %s por %d de daño. " % [
			current_attacker.nombre,
			current_defender.nombre,
			turn_data.attacker_damage
		]
	
	if turn_data.defender_damage > 0:
		turn_text += "%s contraataca por %d de daño. " % [
			current_defender.nombre,
			turn_data.defender_damage
		]
	
	if turn_data.defender_losses > 0:
		turn_text += "%s pierde %d tropas. " % [current_defender.nombre, turn_data.defender_losses]
	
	if turn_data.attacker_losses > 0:
		turn_text += "%s pierde %d tropas. " % [current_attacker.nombre, turn_data.attacker_losses]
	
	add_combat_log(turn_text, "combat_turn")
	
	# Si está en modo automático, continuar combate después de un delay
	if auto_combat and combat_system and combat_system.is_combat_active():
		await get_tree().create_timer(1.5).timeout
		if combat_system.is_combat_active(): # Verificar de nuevo por si acaso
			var next_turn = combat_system.execute_combat_turn()
			if next_turn:
				update_combat_turn(next_turn)

func show_combat_result(result: CombatSystem.CombatResult):
	"""Muestra el resultado final del combate"""
	auto_combat = false
	
	var result_text = ""
	match result.victory_type:
		"defeat":
			result_text = "¡%s ha derrotado completamente a %s!" % [result.winner.nombre, result.loser.nombre]
		"rout":
			result_text = "¡%s ha puesto en fuga a %s!" % [result.winner.nombre, result.loser.nombre]
		"withdrawal":
			result_text = "%s se retira del combate. %s mantiene el campo." % [result.loser.nombre, result.winner.nombre]
		_:
			result_text = "El combate ha terminado de manera indecisa."
	
	add_combat_log(result_text, "combat_end")
	add_combat_log("Bajas del atacante: %d" % result.attacker_casualties, "casualties")
	add_combat_log("Bajas del defensor: %d" % result.defender_casualties, "casualties")
	add_combat_log("Duración: %d turnos" % result.turns_elapsed, "info")
	
	# Deshabilitar botones de acción
	disable_action_buttons()
	
	# Auto-cerrar después de unos segundos
	await get_tree().create_timer(5.0).timeout
	hide_combat()

# === MÉTODOS PRIVADOS ===

func setup_unit_display(unit: DivisionData, name_label: Label, icon_rect: TextureRect, stats_container: VBoxContainer):
	"""Configura la visualización de una unidad"""
	if name_label:
		name_label.text = unit.nombre
		name_label.add_theme_color_override("font_color", _get_faction_color(unit.faccion))
	
	if icon_rect:
		var icon_path = ""
		match unit.faccion:
			"Patriota":
				icon_path = "res://Assets/Icons/Division Patriota.png"
			"Realista":
				icon_path = "res://Assets/Icons/Division Realista.png"
			_:
				icon_path = "res://Assets/Icons/Division Patriota.png"
		
		var texture = load(icon_path) as Texture2D
		if texture:
			icon_rect.texture = texture
	
	if stats_container:
		update_unit_stats(unit, stats_container)

func update_unit_stats(unit: DivisionData, stats_container: VBoxContainer):
	"""Actualiza las estadísticas mostradas de una unidad"""
	if not stats_container:
		return
	
	# Limpiar estadísticas anteriores
	for child in stats_container.get_children():
		child.queue_free()
	
	# Crear nuevas estadísticas
	add_stat_label(stats_container, "Tropas", str(unit.cantidad_total))
	add_stat_label(stats_container, "Moral", str(unit.moral))
	add_stat_label(stats_container, "Experiencia", str(unit.experiencia))
	add_stat_label(stats_container, "Rama", unit.rama_principal.capitalize())
	add_stat_label(stats_container, "Movilidad", str(unit.movilidad))

func add_stat_label(container: VBoxContainer, stat_name: String, stat_value: String):
	"""Agrega una etiqueta de estadística al contenedor"""
	var stat_line = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var value_label = Label.new()
	value_label.text = stat_value
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	stat_line.add_child(name_label)
	stat_line.add_child(value_label)
	container.add_child(stat_line)

func clear_combat_log():
	"""Limpia el log de combate"""
	if combat_log:
		for child in combat_log.get_children():
			child.queue_free()

func add_combat_log(message: String, log_type: String = "info"):
	"""Agrega un mensaje al log de combate"""
	if not combat_log:
		return
	
	var log_entry = HBoxContainer.new()
	
	var message_label = Label.new()
	message_label.text = message
	message_label.add_theme_font_size_override("font_size", 11)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Color según tipo de log
	match log_type:
		"combat_start":
			message_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"combat_end":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		"combat_turn":
			message_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		"casualties":
			message_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		_:
			message_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	log_entry.add_child(message_label)
	combat_log.add_child(log_entry)
	
	# Scroll automático al final
	await get_tree().process_frame
	var scroll_container = combat_log.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func reset_action_buttons():
	"""Resetea los botones de acción al estado inicial"""
	if attack_button:
		attack_button.disabled = false
	if defend_button:
		defend_button.disabled = false
	if retreat_button:
		retreat_button.disabled = false
	if auto_button:
		auto_button.disabled = false
		auto_button.text = "Auto"

func disable_action_buttons():
	"""Deshabilita todos los botones de acción"""
	if attack_button:
		attack_button.disabled = true
	if defend_button:
		defend_button.disabled = true
	if retreat_button:
		retreat_button.disabled = true
	if auto_button:
		auto_button.disabled = true

func _get_faction_color(faction: String) -> Color:
	"""Obtiene el color de una facción"""
	match faction:
		"Patriota":
			return Color(0.2, 0.8, 0.2)
		"Realista":
			return Color(0.8, 0.2, 0.2)
		_:
			return Color(1.0, 1.0, 1.0)

# === SEÑALES DE BOTONES ===

func _on_attack_pressed():
	"""Callback para el botón de ataque"""
	if combat_system and combat_system.is_combat_active():
		var turn_data = combat_system.execute_combat_turn()
		if turn_data:
			update_combat_turn(turn_data)
	
	emit_signal("combat_action_selected", "attack")

func _on_defend_pressed():
	"""Callback para el botón de defensa"""
	# Por ahora, defensa es igual que ataque pero podría tener bonificaciones
	if combat_system and combat_system.is_combat_active():
		var turn_data = combat_system.execute_combat_turn()
		if turn_data:
			update_combat_turn(turn_data)
	
	emit_signal("combat_action_selected", "defend")

func _on_retreat_pressed():
	"""Callback para el botón de retirada"""
	add_combat_log("¡Ordenando retirada!", "combat_end")
	
	if combat_system:
		combat_system.end_combat_manually()
	
	emit_signal("combat_ended_by_player")

func _on_auto_pressed():
	"""Callback para el botón de combate automático"""
	auto_combat = !auto_combat
	
	if auto_combat:
		auto_button.text = "Parar"
		add_combat_log("Combate automático activado", "info")
		
		# Iniciar combate automático
		if combat_system and combat_system.is_combat_active():
			var turn_data = combat_system.execute_combat_turn()
			if turn_data:
				update_combat_turn(turn_data)
	else:
		auto_button.text = "Auto"
		add_combat_log("Combate automático desactivado", "info")

# === MÉTODOS PÚBLICOS ADICIONALES ===

func set_auto_combat(enabled: bool):
	"""Configura el combate automático desde el exterior"""
	auto_combat = enabled
	if auto_button:
		auto_button.text = "Parar" if enabled else "Auto"

func is_auto_combat_enabled() -> bool:
	"""Verifica si el combate automático está habilitado"""
	return auto_combat