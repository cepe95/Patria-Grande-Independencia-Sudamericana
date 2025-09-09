extends Control

# ResearchNotification - Panel de notificaciones para alertas de investigación
# Muestra alertas sobre descubrimientos, bloqueos y progreso de investigación

signal notification_closed(notification_id: String)

@onready var notification_container: VBoxContainer = $VBoxContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var close_button: Button = $VBoxContainer/CloseButton

var notification_id: String = ""
var auto_close_timer: Timer

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	setup_auto_close_timer()

func setup_auto_close_timer():
	"""Configura el timer para auto-cerrar notificaciones"""
	auto_close_timer = Timer.new()
	auto_close_timer.wait_time = 5.0  # 5 segundos
	auto_close_timer.one_shot = true
	auto_close_timer.timeout.connect(_on_auto_close_timeout)
	add_child(auto_close_timer)

func show_notification(id: String, title: String, message: String, notification_type: String = "info", auto_close: bool = true):
	"""Muestra una notificación de investigación"""
	notification_id = id
	title_label.text = title
	message_label.text = message
	
	# Aplicar colores según el tipo
	match notification_type:
		"success":
			modulate = Color(0.8, 1.0, 0.8)  # Verde claro
		"warning":
			modulate = Color(1.0, 1.0, 0.8)  # Amarillo claro
		"error":
			modulate = Color(1.0, 0.8, 0.8)  # Rojo claro
		"discovery":
			modulate = Color(0.8, 0.8, 1.0)  # Azul claro
		_:  # info
			modulate = Color(1.0, 1.0, 1.0)  # Blanco
	
	visible = true
	
	if auto_close:
		auto_close_timer.start()

func _on_close_pressed():
	"""Callback para cerrar la notificación manualmente"""
	close_notification()

func _on_auto_close_timeout():
	"""Callback para auto-cerrar la notificación"""
	close_notification()

func close_notification():
	"""Cierra la notificación y emite señal"""
	visible = false
	notification_closed.emit(notification_id)
	queue_free()

# Métodos estáticos para crear notificaciones específicas
static func create_research_completed_notification(tech_name: String) -> ResearchNotification:
	"""Crea una notificación de investigación completada"""
	var notification = preload("res://Scenes/UI/ResearchNotification.tscn").instantiate()
	notification.show_notification(
		"research_completed_" + tech_name,
		"¡Investigación Completada!",
		"La tecnología '%s' ha sido desarrollada exitosamente." % tech_name,
		"success"
	)
	return notification

static func create_research_blocked_notification(tech_name: String, reason: String) -> ResearchNotification:
	"""Crea una notificación de investigación bloqueada"""
	var notification = preload("res://Scenes/UI/ResearchNotification.tscn").instantiate()
	notification.show_notification(
		"research_blocked_" + tech_name,
		"Investigación Bloqueada",
		"La investigación de '%s' ha sido pausada: %s" % [tech_name, reason],
		"warning"
	)
	return notification

static func create_new_technology_notification(tech_name: String) -> ResearchNotification:
	"""Crea una notificación de nueva tecnología disponible"""
	var notification = preload("res://Scenes/UI/ResearchNotification.tscn").instantiate()
	notification.show_notification(
		"new_tech_" + tech_name,
		"Nueva Tecnología Disponible",
		"La tecnología '%s' está ahora disponible para investigar." % tech_name,
		"discovery"
	)
	return notification

static func create_research_milestone_notification(tech_name: String, progress: int) -> ResearchNotification:
	"""Crea una notificación de hito de investigación"""
	var notification = preload("res://Scenes/UI/ResearchNotification.tscn").instantiate()
	notification.show_notification(
		"research_milestone_" + tech_name,
		"Progreso de Investigación",
		"La investigación de '%s' ha alcanzado el %d%% de progreso." % [tech_name, progress],
		"info",
		false  # No auto-cerrar para hitos importantes
	)
	return notification