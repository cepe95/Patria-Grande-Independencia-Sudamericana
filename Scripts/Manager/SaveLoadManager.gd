extends Node
class_name SaveLoadManager

# SaveLoadManager - Gestor centralizado del sistema de guardado y carga
# Implementa las mejores prácticas de Godot para persistencia de datos
# Diseñado para ser extensible por modders

# === CONFIGURACIÓN ===
const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".save"
const MAX_SAVE_FILES = 50 # Límite de archivos para evitar sobrecarga

# === SEÑALES ===
signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)
signal save_list_updated(save_files: Array)

# === VARIABLES INTERNAS ===
var _last_error: String = ""

func _ready():
	"""Inicializa el manager y crea el directorio de guardado"""
	create_save_directory()

func create_save_directory():
	"""Crea el directorio de guardado si no existe"""
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			var error = dir.make_dir("saves")
			if error != OK:
				push_error("SaveLoadManager: No se pudo crear el directorio de guardado: " + str(error))
			else:
				print("✓ SaveLoadManager: Directorio de guardado creado")
	else:
		push_error("SaveLoadManager: No se pudo acceder al directorio user://")

func save_game(game_state: GameState, filename: String = "") -> bool:
	"""Guarda el estado del juego usando ResourceSaver
	
	Args:
		game_state: El estado del juego a guardar
		filename: Nombre del archivo (opcional, se genera automáticamente si no se proporciona)
	
	Returns:
		bool: true si el guardado fue exitoso, false en caso contrario
	"""
	if not game_state:
		_emit_save_error("Estado de juego inválido")
		return false
	
	# Generar nombre de archivo si no se proporciona
	if filename.is_empty():
		filename = generate_save_filename()
	
	# Asegurar que tenga la extensión correcta
	if not filename.ends_with(SAVE_EXTENSION):
		filename += SAVE_EXTENSION
	
	var full_path = SAVE_DIR + filename
	
	# Configurar metadatos del guardado
	game_state.save_date = Time.get_datetime_string_from_system()
	if game_state.save_name.is_empty():
		game_state.save_name = filename.get_basename()
	
	# Intentar guardar usando ResourceSaver
	var error = ResourceSaver.save(game_state, full_path)
	
	if error == OK:
		print("✓ SaveLoadManager: Partida guardada exitosamente en: ", full_path)
		save_completed.emit(true, "Partida guardada correctamente")
		save_list_updated.emit(get_save_files())
		return true
	else:
		var error_msg = "Error al guardar la partida: " + str(error)
		_emit_save_error(error_msg)
		return false

func load_game(filename: String) -> GameState:
	"""Carga un estado de juego usando ResourceLoader
	
	Args:
		filename: Nombre del archivo a cargar (con o sin extensión)
	
	Returns:
		GameState: El estado cargado, o null si hubo error
	"""
	if filename.is_empty():
		_emit_load_error("Nombre de archivo vacío")
		return null
	
	# Asegurar que tenga la extensión correcta
	if not filename.ends_with(SAVE_EXTENSION):
		filename += SAVE_EXTENSION
	
	var full_path = SAVE_DIR + filename
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists(full_path):
		_emit_load_error("El archivo de guardado no existe: " + filename)
		return null
	
	# Intentar cargar usando ResourceLoader
	var loaded_resource = ResourceLoader.load(full_path)
	
	if loaded_resource is GameState:
		print("✓ SaveLoadManager: Partida cargada exitosamente desde: ", full_path)
		load_completed.emit(true, "Partida cargada correctamente")
		return loaded_resource as GameState
	else:
		_emit_load_error("El archivo no contiene un estado de juego válido: " + filename)
		return null

func get_save_files() -> Array[Dictionary]:
	"""Obtiene la lista de archivos de guardado con metadatos
	
	Returns:
		Array[Dictionary]: Lista de archivos con información para mostrar en la UI
	"""
	var save_files: Array[Dictionary] = []
	var dir = DirAccess.open(SAVE_DIR)
	
	if not dir:
		push_warning("SaveLoadManager: No se pudo acceder al directorio de guardado")
		return save_files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(SAVE_EXTENSION):
			var file_info = get_save_file_info(file_name)
			if file_info:
				save_files.append(file_info)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Ordenar por fecha de modificación (más reciente primero)
	save_files.sort_custom(func(a, b): return a.modified_time > b.modified_time)
	
	return save_files

func get_save_file_info(filename: String) -> Dictionary:
	"""Obtiene información detallada de un archivo de guardado
	
	Args:
		filename: Nombre del archivo
	
	Returns:
		Dictionary: Información del archivo para mostrar en la UI
	"""
	var full_path = SAVE_DIR + filename
	var file_access = FileAccess.open(full_path, FileAccess.READ)
	
	if not file_access:
		return {}
	
	var file_info = {
		"filename": filename,
		"display_name": filename.get_basename(),
		"full_path": full_path,
		"size": file_access.get_length(),
		"modified_time": FileAccess.get_modified_time(full_path)
	}
	
	file_access.close()
	
	# Intentar cargar metadatos básicos sin cargar todo el estado
	var loaded_resource = ResourceLoader.load(full_path)
	if loaded_resource is GameState:
		var game_state = loaded_resource as GameState
		file_info["display_name"] = game_state.get_display_name()
		file_info["turn"] = game_state.current_turn
		file_info["save_date"] = game_state.save_date
		file_info["version"] = game_state.version
	
	return file_info

func delete_save_file(filename: String) -> bool:
	"""Elimina un archivo de guardado
	
	Args:
		filename: Nombre del archivo a eliminar
	
	Returns:
		bool: true si se eliminó correctamente
	"""
	if not filename.ends_with(SAVE_EXTENSION):
		filename += SAVE_EXTENSION
	
	var full_path = SAVE_DIR + filename
	
	if not FileAccess.file_exists(full_path):
		_last_error = "El archivo no existe: " + filename
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		var error = dir.remove(filename)
		if error == OK:
			print("✓ SaveLoadManager: Archivo eliminado: ", filename)
			save_list_updated.emit(get_save_files())
			return true
		else:
			_last_error = "Error al eliminar archivo: " + str(error)
			return false
	else:
		_last_error = "No se pudo acceder al directorio de guardado"
		return false

func cleanup_old_saves():
	"""Limpia archivos de guardado antiguos si exceden el límite"""
	var save_files = get_save_files()
	
	if save_files.size() <= MAX_SAVE_FILES:
		return
	
	print("SaveLoadManager: Limpiando archivos antiguos (%d > %d)" % [save_files.size(), MAX_SAVE_FILES])
	
	# Eliminar los archivos más antiguos
	for i in range(MAX_SAVE_FILES, save_files.size()):
		delete_save_file(save_files[i]["filename"])

func generate_save_filename() -> String:
	"""Genera un nombre único para archivo de guardado
	
	Returns:
		String: Nombre de archivo único
	"""
	var datetime = Time.get_datetime_dict_from_system()
	return "save_%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

func get_last_error() -> String:
	"""Retorna el último error ocurrido"""
	return _last_error

func has_save_files() -> bool:
	"""Verifica si existen archivos de guardado"""
	return get_save_files().size() > 0

# === MÉTODOS PRIVADOS ===

func _emit_save_error(message: String):
	"""Emite señal de error de guardado"""
	_last_error = message
	push_error("SaveLoadManager: " + message)
	save_completed.emit(false, message)

func _emit_load_error(message: String):
	"""Emite señal de error de carga"""
	_last_error = message
	push_error("SaveLoadManager: " + message)
	load_completed.emit(false, message)

# === MÉTODOS ESTÁTICOS DE UTILIDAD ===

static func format_file_size(bytes: int) -> String:
	"""Formatea el tamaño de archivo para mostrar en la UI"""
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (bytes / 1024.0)
	else:
		return "%.1f MB" % (bytes / (1024.0 * 1024.0))

static func format_date(unix_timestamp: int) -> String:
	"""Formatea una fecha Unix para mostrar en la UI"""
	var datetime = Time.get_datetime_dict_from_unix_time(unix_timestamp)
	return "%02d/%02d/%04d %02d:%02d" % [
		datetime.day, datetime.month, datetime.year,
		datetime.hour, datetime.minute
	]