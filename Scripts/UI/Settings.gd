extends Control

# Settings - Menú de configuración completo y moderno
# Permite ajustar audio, video, idioma, accesibilidad y controles

# === REFERENCIAS A NODOS ===
@onready var tab_container: TabContainer = $Background/MarginContainer/VBoxContainer/TabContainer
@onready var close_button: Button = $Background/MarginContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var reset_button: Button = $Background/MarginContainer/VBoxContainer/FooterContainer/ResetButton
@onready var apply_button: Button = $Background/MarginContainer/VBoxContainer/FooterContainer/ApplyButton

# Audio Tab
@onready var music_volume_slider: HSlider = $Background/MarginContainer/VBoxContainer/TabContainer/Audio/AudioContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_label: Label = $Background/MarginContainer/VBoxContainer/TabContainer/Audio/AudioContainer/MusicVolumeContainer/MusicVolumeLabel
@onready var sfx_volume_slider: HSlider = $Background/MarginContainer/VBoxContainer/TabContainer/Audio/AudioContainer/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_label: Label = $Background/MarginContainer/VBoxContainer/TabContainer/Audio/AudioContainer/SFXVolumeContainer/SFXVolumeLabel

# Video Tab
@onready var resolution_option: OptionButton = $Background/MarginContainer/VBoxContainer/TabContainer/Video/VideoContainer/ResolutionContainer/ResolutionOption
@onready var fullscreen_check: CheckBox = $Background/MarginContainer/VBoxContainer/TabContainer/Video/VideoContainer/FullscreenContainer/FullscreenCheck
@onready var graphics_option: OptionButton = $Background/MarginContainer/VBoxContainer/TabContainer/Video/VideoContainer/GraphicsContainer/GraphicsOption
@onready var vsync_check: CheckBox = $Background/MarginContainer/VBoxContainer/TabContainer/Video/VideoContainer/VSyncContainer/VSyncCheck

# Language Tab
@onready var language_option: OptionButton = $Background/MarginContainer/VBoxContainer/TabContainer/Idioma/LanguageContainer/LanguageOption

# Accessibility Tab
@onready var font_size_option: OptionButton = $Background/MarginContainer/VBoxContainer/TabContainer/Accesibilidad/AccessibilityContainer/FontSizeContainer/FontSizeOption
@onready var high_contrast_check: CheckBox = $Background/MarginContainer/VBoxContainer/TabContainer/Accesibilidad/AccessibilityContainer/HighContrastContainer/HighContrastCheck

# Controls Tab
@onready var controls_list: VBoxContainer = $Background/MarginContainer/VBoxContainer/TabContainer/Controles/ControlsContainer/ControlsList
@onready var reset_controls_button: Button = $Background/MarginContainer/VBoxContainer/TabContainer/Controles/ControlsContainer/ResetControlsButton

# === VARIABLES ===
var pending_changes := {}
var original_settings := {}

func _ready():
	print("✓ Settings UI inicializada")
	setup_ui_connections()
	setup_controls_tab()
	
	# Esperar a que SettingsManager esté listo
	if SettingsManager.current_settings.is_empty():
		await SettingsManager.settings_loaded
	
	load_current_settings()

func setup_ui_connections():
	"""Conecta todas las señales de la UI"""
	# Botones principales
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	# Audio
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Video
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	graphics_option.item_selected.connect(_on_graphics_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	# Language
	language_option.item_selected.connect(_on_language_selected)
	
	# Accessibility
	font_size_option.item_selected.connect(_on_font_size_selected)
	high_contrast_check.toggled.connect(_on_high_contrast_toggled)
	
	# Controls
	reset_controls_button.pressed.connect(_on_reset_controls_pressed)

func setup_controls_tab():
	"""Configura la pestaña de controles con las teclas actuales"""
	var controls_info = [
		["Mover unidad", "Click derecho"],
		["Seleccionar unidad", "Click izquierdo"],
		["Selección múltiple", "Arrastrar"],
		["Selección aditiva", "Shift + Click"],
		["Limpiar selección", "Click en vacío"],
		["Pausa", "Espacio"],
		["Menú principal", "Escape"]
	]
	
	for control_info in controls_info:
		var container = HBoxContainer.new()
		
		var action_label = Label.new()
		action_label.text = control_info[0]
		action_label.custom_min_size.x = 200
		
		var key_label = Label.new()
		key_label.text = control_info[1]
		key_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		
		container.add_child(action_label)
		container.add_child(key_label)
		controls_list.add_child(container)

func load_current_settings():
	"""Carga la configuración actual en la UI"""
	original_settings = SettingsManager.current_settings.duplicate(true)
	
	# Audio
	var music_vol = SettingsManager.get_setting("audio", "music_volume")
	var sfx_vol = SettingsManager.get_setting("audio", "sfx_volume")
	
	music_volume_slider.value = music_vol
	sfx_volume_slider.value = sfx_vol
	_update_volume_label(music_volume_label, music_vol)
	_update_volume_label(sfx_volume_label, sfx_vol)
	
	# Video
	_setup_resolution_options()
	_setup_graphics_options()
	
	var current_res = SettingsManager.get_setting("video", "resolution")
	var fullscreen = SettingsManager.get_setting("video", "fullscreen")
	var graphics = SettingsManager.get_setting("video", "graphics_quality")
	var vsync = SettingsManager.get_setting("video", "vsync")
	
	_select_resolution_option(current_res)
	fullscreen_check.button_pressed = fullscreen
	_select_graphics_option(graphics)
	vsync_check.button_pressed = vsync
	
	# Language
	_setup_language_options()
	var current_lang = SettingsManager.get_setting("language", "current")
	_select_language_option(current_lang)
	
	# Accessibility
	_setup_accessibility_options()
	var font_size = SettingsManager.get_setting("accessibility", "font_size")
	var high_contrast = SettingsManager.get_setting("accessibility", "high_contrast")
	
	_select_font_size_option(font_size)
	high_contrast_check.button_pressed = high_contrast

func _setup_resolution_options():
	"""Configura las opciones de resolución"""
	resolution_option.clear()
	for res in SettingsManager.get_resolution_list():
		resolution_option.add_item(res)

func _setup_graphics_options():
	"""Configura las opciones de calidad gráfica"""
	graphics_option.clear()
	graphics_option.add_item("Baja")
	graphics_option.add_item("Media")
	graphics_option.add_item("Alta")

func _setup_language_options():
	"""Configura las opciones de idioma"""
	language_option.clear()
	for lang_code in SettingsManager.get_language_list():
		var lang_name = SettingsManager.get_language_list()[lang_code]
		language_option.add_item(lang_name)
		language_option.set_item_metadata(language_option.get_item_count() - 1, lang_code)

func _setup_accessibility_options():
	"""Configura las opciones de accesibilidad"""
	font_size_option.clear()
	font_size_option.add_item("Normal")
	font_size_option.add_item("Grande")

func _select_resolution_option(resolution: String):
	"""Selecciona la opción de resolución correspondiente"""
	for i in range(resolution_option.get_item_count()):
		if resolution_option.get_item_text(i) == resolution:
			resolution_option.selected = i
			return

func _select_graphics_option(quality: String):
	"""Selecciona la opción de calidad gráfica correspondiente"""
	var index = 1  # Default to "Media"
	match quality:
		"baja": index = 0
		"media": index = 1
		"alta": index = 2
	graphics_option.selected = index

func _select_language_option(lang_code: String):
	"""Selecciona la opción de idioma correspondiente"""
	for i in range(language_option.get_item_count()):
		if language_option.get_item_metadata(i) == lang_code:
			language_option.selected = i
			return

func _select_font_size_option(size: String):
	"""Selecciona la opción de tamaño de fuente correspondiente"""
	var index = 0  # Default to "Normal"
	if size == "grande":
		index = 1
	font_size_option.selected = index

func _update_volume_label(label: Label, value: float):
	"""Actualiza la etiqueta de volumen"""
	label.text = "%d%%" % (value * 100)

# === CALLBACKS DE UI ===
func _on_close_pressed():
	"""Cierra el menú sin guardar cambios pendientes"""
	hide()

func _on_reset_pressed():
	"""Resetea toda la configuración a valores por defecto"""
	SettingsManager.reset_to_defaults()
	load_current_settings()
	pending_changes.clear()

func _on_apply_pressed():
	"""Aplica todos los cambios pendientes"""
	for section in pending_changes:
		for key in pending_changes[section]:
			var value = pending_changes[section][key]
			SettingsManager.set_setting(section, key, value)
	
	pending_changes.clear()
	original_settings = SettingsManager.current_settings.duplicate(true)
	print("✓ Configuración aplicada")

# Audio callbacks
func _on_music_volume_changed(value: float):
	"""Callback del slider de volumen de música"""
	_update_volume_label(music_volume_label, value)
	_queue_setting_change("audio", "music_volume", value)

func _on_sfx_volume_changed(value: float):
	"""Callback del slider de volumen de efectos"""
	_update_volume_label(sfx_volume_label, value)
	_queue_setting_change("audio", "sfx_volume", value)

# Video callbacks
func _on_resolution_selected(index: int):
	"""Callback de selección de resolución"""
	var resolution = resolution_option.get_item_text(index)
	_queue_setting_change("video", "resolution", resolution)

func _on_fullscreen_toggled(pressed: bool):
	"""Callback de pantalla completa"""
	_queue_setting_change("video", "fullscreen", pressed)

func _on_graphics_selected(index: int):
	"""Callback de selección de calidad gráfica"""
	var quality_map = ["baja", "media", "alta"]
	var quality = quality_map[index]
	_queue_setting_change("video", "graphics_quality", quality)

func _on_vsync_toggled(pressed: bool):
	"""Callback de VSync"""
	_queue_setting_change("video", "vsync", pressed)

# Language callbacks
func _on_language_selected(index: int):
	"""Callback de selección de idioma"""
	var lang_code = language_option.get_item_metadata(index)
	_queue_setting_change("language", "current", lang_code)

# Accessibility callbacks
func _on_font_size_selected(index: int):
	"""Callback de selección de tamaño de fuente"""
	var size_map = ["normal", "grande"]
	var size = size_map[index]
	_queue_setting_change("accessibility", "font_size", size)

func _on_high_contrast_toggled(pressed: bool):
	"""Callback de alto contraste"""
	_queue_setting_change("accessibility", "high_contrast", pressed)

# Controls callbacks
func _on_reset_controls_pressed():
	"""Resetea los controles a valores por defecto"""
	print("✓ Controles reseteados a valores por defecto")
	# Por implementar cuando se añada el rebinding

# === UTILIDADES ===
func _queue_setting_change(section: String, key: String, value):
	"""Añade un cambio a la cola de cambios pendientes"""
	if not pending_changes.has(section):
		pending_changes[section] = {}
	
	pending_changes[section][key] = value

func show_settings():
	"""Muestra el menú de configuración"""
	load_current_settings()
	show()

func _input(event):
	"""Maneja inputs del teclado"""
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()