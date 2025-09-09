extends Control

# EventModal - Modal para mostrar eventos con opciones de decisión

signal event_choice_made(event_data: EventData, choice: Dictionary)
signal event_dismissed(event_data: EventData)

# === REFERENCIAS A NODOS ===
@onready var background: ColorRect = $Background
@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $ModalPanel/VBoxContainer/HeaderContainer/CloseButton
@onready var event_image: TextureRect = $ModalPanel/VBoxContainer/ContentContainer/EventImage
@onready var description_label: RichTextLabel = $ModalPanel/VBoxContainer/ContentContainer/DescriptionLabel
@onready var choices_container: VBoxContainer = $ModalPanel/VBoxContainer/ContentContainer/ChoicesContainer
@onready var continue_button: Button = $ModalPanel/VBoxContainer/FooterContainer/ContinueButton

# === VARIABLES ===
var current_event: EventData
var is_showing: bool = false

func _ready():
	# Inicialmente oculto
	visible = false
	
	# Esperar un frame para que los nodos estén listos
	await get_tree().process_frame
	
	# Conectar señales
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Configurar fondo semi-transparente
	if background:
		background.color = Color(0, 0, 0, 0.7)
		background.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear input detrás del modal
	
	print("✓ EventModal inicializado")

func show_event(event: EventData):
	"""Muestra un evento en el modal"""
	if is_showing:
		print("⚠ Modal ya está mostrando un evento")
		return
	
	current_event = event
	is_showing = true
	
	# Configurar contenido
	setup_event_content()
	
	# Mostrar modal con animación
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# Centrar el modal
	center_modal()
	
	print("✓ Mostrando evento: %s" % event.title)

func setup_event_content():
	"""Configura el contenido del modal según el evento"""
	if not current_event:
		return
	
	# Título
	title_label.text = current_event.title
	
	# Imagen del evento
	setup_event_image()
	
	# Descripción
	description_label.text = current_event.description
	
	# Configurar opciones
	setup_choices()

func setup_event_image():
	"""Configura la imagen del evento"""
	if current_event.image_path.is_empty():
		event_image.visible = false
		return
	
	var texture = load(current_event.image_path) as Texture2D
	if texture:
		event_image.texture = texture
		event_image.visible = true
		# Ajustar tamaño manteniendo proporción
		event_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		event_image.custom_min_size = Vector2(300, 200)
	else:
		event_image.visible = false
		print("⚠ No se pudo cargar imagen: %s" % current_event.image_path)

func setup_choices():
	"""Configura las opciones de decisión"""
	# Limpiar opciones anteriores
	for child in choices_container.get_children():
		child.queue_free()
	
	if not current_event.has_choices or current_event.choices.is_empty():
		# No hay opciones, mostrar solo botón continuar
		choices_container.visible = false
		continue_button.visible = true
		continue_button.text = "Continuar"
		return
	
	# Hay opciones, configurarlas
	choices_container.visible = true
	continue_button.visible = false
	
	for i in range(current_event.choices.size()):
		var choice = current_event.choices[i]
		var choice_button = create_choice_button(choice, i)
		choices_container.add_child(choice_button)

func create_choice_button(choice: Dictionary, index: int) -> Button:
	"""Crea un botón para una opción de decisión"""
	var button = Button.new()
	button.text = choice.get("text", "Opción %d" % (index + 1))
	button.add_theme_font_size_override("font_size", 14)
	button.custom_min_size = Vector2(0, 40)
	
	# Mostrar efectos de la opción si los hay
	var effects = choice.get("effects", [])
	if not effects.is_empty():
		button.tooltip_text = get_effects_tooltip(effects)
	
	# Conectar señal
	button.pressed.connect(_on_choice_selected.bind(choice, index))
	
	return button

func get_effects_tooltip(effects: Array) -> String:
	"""Genera texto de tooltip para mostrar los efectos de una opción"""
	var tooltip_lines = ["Efectos:"]
	
	for effect in effects:
		match effect.get("type", EventData.EffectType.CUSTOM):
			EventData.EffectType.RESOURCE_CHANGE:
				var resource = effect.get("resource", "")
				var amount = effect.get("amount", 0)
				var sign = "+" if amount >= 0 else ""
				tooltip_lines.append("• %s: %s%d" % [resource.capitalize(), sign, amount])
			
			EventData.EffectType.DIPLOMATIC_CHANGE:
				var faction = effect.get("faction", "")
				var change = effect.get("relation_change", 0)
				var sign = "+" if change >= 0 else ""
				tooltip_lines.append("• Relación con %s: %s%d" % [faction, sign, change])
			
			_:
				tooltip_lines.append("• Efecto especial")
	
	return "\n".join(tooltip_lines)

func center_modal():
	"""Centra el modal en la pantalla"""
	var screen_size = get_viewport().get_visible_rect().size
	var modal_size = modal_panel.size
	
	modal_panel.position = (screen_size - modal_size) / 2

func hide_modal():
	"""Oculta el modal con animación"""
	if not is_showing:
		return
	
	is_showing = false
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	visible = false
	current_event = null
	
	print("✓ Modal de evento ocultado")

func _on_choice_selected(choice: Dictionary, index: int):
	"""Callback cuando se selecciona una opción"""
	print("✓ Opción seleccionada: %s" % choice.get("text", ""))
	
	# Emitir señal de elección hecha
	event_choice_made.emit(current_event, choice)
	
	# Ocultar modal
	hide_modal()

func _on_continue_pressed():
	"""Callback del botón continuar"""
	# Emitir señal de evento completado sin elección específica
	event_dismissed.emit(current_event)
	
	# Ocultar modal
	hide_modal()

func _on_close_pressed():
	"""Callback del botón cerrar"""
	# Tratar como si se hubiera presionado continuar
	_on_continue_pressed()

func _input(event):
	"""Manejo de input para cerrar con ESC"""
	if not is_showing:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()

# === MÉTODOS PÚBLICOS PARA PERSONALIZACIÓN ===

func set_modal_theme(panel_style: StyleBox = null, title_style: LabelSettings = null):
	"""Personaliza el estilo visual del modal"""
	if panel_style:
		modal_panel.add_theme_stylebox_override("panel", panel_style)
	
	if title_style:
		title_label.label_settings = title_style

func set_modal_size(new_size: Vector2):
	"""Establece el tamaño del modal"""
	modal_panel.custom_min_size = new_size
	center_modal()

func get_current_event() -> EventData:
	"""Retorna el evento actual siendo mostrado"""
	return current_event

func is_modal_showing() -> bool:
	"""Retorna si el modal está siendo mostrado"""
	return is_showing