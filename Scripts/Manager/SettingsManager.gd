extends Node

# SettingsManager - Singleton para manejar la configuración del juego
# Guarda y carga configuraciones desde user://settings.cfg

# === CONFIGURACIÓN POR DEFECTO ===
var default_settings := {
	"audio": {
		"music_volume": 0.8,
		"sfx_volume": 0.8
	},
	"video": {
		"resolution": "1920x1080",
		"fullscreen": false,
		"graphics_quality": "media",
		"vsync": true
	},
	"language": {
		"current": "es"
	},
	"accessibility": {
		"font_size": "normal",
		"high_contrast": false
	},
	"controls": {
		"version": 1  # Para futuras expansiones de controles
	}
}

# === CONFIGURACIÓN ACTUAL ===
var current_settings := {}

# === RESOLUCIONES DISPONIBLES ===
var available_resolutions := [
	"1920x1080",
	"1680x1050", 
	"1600x900",
	"1366x768",
	"1280x720",
	"1024x768"
]

# === IDIOMAS DISPONIBLES ===
var available_languages := {
	"es": "Español",
	"en": "English"
}

# === ARCHIVO DE CONFIGURACIÓN ===
const SETTINGS_FILE = "user://settings.cfg"

# === SEÑALES ===
signal settings_changed(section: String, key: String, value)
signal settings_loaded()

func _ready():
	print("✓ SettingsManager inicializado")
	load_settings()
	apply_all_settings()

# === CARGA Y GUARDADO ===
func load_settings():
	"""Carga la configuración desde el archivo o usa valores por defecto"""
	current_settings = default_settings.duplicate(true)
	
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	if err == OK:
		print("✓ Configuración cargada desde: ", SETTINGS_FILE)
		# Cargar cada sección
		for section in default_settings.keys():
			if config.has_section(section):
				for key in default_settings[section].keys():
					if config.has_section_key(section, key):
						current_settings[section][key] = config.get_value(section, key)
	else:
		print("⚠️ No se encontró archivo de configuración, usando valores por defecto")
		save_settings()  # Crear archivo con valores por defecto
	
	settings_loaded.emit()

func save_settings():
	"""Guarda la configuración actual al archivo"""
	var config = ConfigFile.new()
	
	# Guardar cada sección
	for section in current_settings.keys():
		for key in current_settings[section].keys():
			config.set_value(section, key, current_settings[section][key])
	
	var err = config.save(SETTINGS_FILE)
	if err == OK:
		print("✓ Configuración guardada en: ", SETTINGS_FILE)
	else:
		print("❌ Error al guardar configuración: ", err)

# === GETTERS Y SETTERS ===
func get_setting(section: String, key: String):
	"""Obtiene un valor de configuración"""
	if current_settings.has(section) and current_settings[section].has(key):
		return current_settings[section][key]
	else:
		print("⚠️ Configuración no encontrada: ", section, ".", key)
		return null

func set_setting(section: String, key: String, value):
	"""Establece un valor de configuración"""
	if not current_settings.has(section):
		current_settings[section] = {}
	
	current_settings[section][key] = value
	settings_changed.emit(section, key, value)
	
	# Aplicar cambio inmediatamente si es necesario
	apply_setting(section, key, value)
	
	# Guardar automáticamente
	save_settings()

# === APLICACIÓN DE CONFIGURACIONES ===
func apply_all_settings():
	"""Aplica todas las configuraciones actuales al juego"""
	# Audio
	apply_audio_settings()
	# Video
	apply_video_settings()
	# Accesibilidad
	apply_accessibility_settings()

func apply_setting(section: String, key: String, value):
	"""Aplica una configuración específica inmediatamente"""
	match section:
		"audio":
			apply_audio_setting(key, value)
		"video":
			apply_video_setting(key, value)
		"accessibility":
			apply_accessibility_setting(key, value)

func apply_audio_settings():
	"""Aplica configuraciones de audio"""
	var music_vol = get_setting("audio", "music_volume")
	var sfx_vol = get_setting("audio", "sfx_volume")
	
	if music_vol != null:
		apply_audio_setting("music_volume", music_vol)
	if sfx_vol != null:
		apply_audio_setting("sfx_volume", sfx_vol)

func apply_audio_setting(key: String, value):
	"""Aplica una configuración de audio específica"""
	match key:
		"music_volume":
			# Convertir a decibeles y aplicar al bus de música
			var db = linear_to_db(value)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
		"sfx_volume":
			# Convertir a decibeles y aplicar al bus de efectos
			var db = linear_to_db(value)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

func apply_video_settings():
	"""Aplica configuraciones de video"""
	var resolution = get_setting("video", "resolution")
	var fullscreen = get_setting("video", "fullscreen")
	var vsync = get_setting("video", "vsync")
	
	if resolution != null:
		apply_video_setting("resolution", resolution)
	if fullscreen != null:
		apply_video_setting("fullscreen", fullscreen)
	if vsync != null:
		apply_video_setting("vsync", vsync)

func apply_video_setting(key: String, value):
	"""Aplica una configuración de video específica"""
	match key:
		"resolution":
			var parts = value.split("x")
			if parts.size() == 2:
				var width = int(parts[0])
				var height = int(parts[1])
				get_window().size = Vector2i(width, height)
		"fullscreen":
			if value:
				get_window().mode = Window.MODE_FULLSCREEN
			else:
				get_window().mode = Window.MODE_WINDOWED
		"vsync":
			if value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_accessibility_settings():
	"""Aplica configuraciones de accesibilidad"""
	# Por ahora solo almacenamos estos valores
	# La aplicación real dependerá de cómo se implementen en la UI
	pass

func apply_accessibility_setting(key: String, value):
	"""Aplica una configuración de accesibilidad específica"""
	# Por implementar según necesidades específicas de UI
	pass

# === UTILIDADES ===
func reset_to_defaults():
	"""Resetea toda la configuración a valores por defecto"""
	current_settings = default_settings.duplicate(true)
	apply_all_settings()
	save_settings()
	print("✓ Configuración reseteada a valores por defecto")

func get_resolution_list() -> Array:
	"""Devuelve la lista de resoluciones disponibles"""
	return available_resolutions

func get_language_list() -> Dictionary:
	"""Devuelve el diccionario de idiomas disponibles"""
	return available_languages

func get_current_resolution() -> String:
	"""Obtiene la resolución actual de la ventana"""
	var size = get_window().size
	return "%dx%d" % [size.x, size.y]