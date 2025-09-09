extends Control

# Test script for the settings system
# This script validates the SettingsManager and Settings UI functionality

@onready var test_results_label = Label.new()
var test_count = 0
var passed_tests = 0

func _ready():
	# Setup test results display
	test_results_label.position = Vector2(50, 50)
	test_results_label.size = Vector2(400, 500)
	test_results_label.add_theme_font_size_override("font_size", 14)
	add_child(test_results_label)
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Run tests
	run_settings_tests()

func run_settings_tests():
	test_results_label.text = "Running Settings System Tests...\n\n"
	
	# Test 1: SettingsManager singleton exists
	test_settings_manager_exists()
	
	# Test 2: Default settings structure
	test_default_settings()
	
	# Test 3: Settings persistence methods
	test_persistence_methods()
	
	# Test 4: Settings application methods
	test_application_methods()
	
	# Test 5: Audio bus configuration
	test_audio_buses()
	
	# Test 6: Settings UI can be instantiated
	test_settings_ui()
	
	# Show final results
	update_test_results("=" * 40)
	update_test_results("Tests completed: %d/%d passed" % [passed_tests, test_count])
	if passed_tests == test_count:
		update_test_results("✅ ALL TESTS PASSED!")
		update_test_results("Settings system is ready to use!")
	else:
		update_test_results("❌ Some tests failed")

func test_settings_manager_exists():
	test_count += 1
	if SettingsManager:
		passed_tests += 1
		update_test_results("✅ SettingsManager singleton exists")
	else:
		update_test_results("❌ SettingsManager singleton not found")

func test_default_settings():
	test_count += 1
	if SettingsManager.default_settings.has("audio") and \
	   SettingsManager.default_settings.has("video") and \
	   SettingsManager.default_settings.has("language") and \
	   SettingsManager.default_settings.has("accessibility") and \
	   SettingsManager.default_settings.has("controls"):
		passed_tests += 1
		update_test_results("✅ All required setting categories exist")
	else:
		update_test_results("❌ Missing required setting categories")

func test_persistence_methods():
	test_count += 1
	if SettingsManager.has_method("load_settings") and \
	   SettingsManager.has_method("save_settings") and \
	   SettingsManager.has_method("get_setting") and \
	   SettingsManager.has_method("set_setting"):
		passed_tests += 1
		update_test_results("✅ Settings persistence methods exist")
	else:
		update_test_results("❌ Missing settings persistence methods")

func test_application_methods():
	test_count += 1
	if SettingsManager.has_method("apply_all_settings") and \
	   SettingsManager.has_method("apply_audio_settings") and \
	   SettingsManager.has_method("apply_video_settings") and \
	   SettingsManager.has_method("reset_to_defaults"):
		passed_tests += 1
		update_test_results("✅ Settings application methods exist")
	else:
		update_test_results("❌ Missing settings application methods")

func test_audio_buses():
	test_count += 1
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if music_bus >= 0 and sfx_bus >= 0:
		passed_tests += 1
		update_test_results("✅ Audio buses configured (Music: %d, SFX: %d)" % [music_bus, sfx_bus])
	else:
		update_test_results("❌ Audio buses not found (Music: %d, SFX: %d)" % [music_bus, sfx_bus])

func test_settings_ui():
	test_count += 1
	var settings_scene = load("res://Scenes/UI/Settings.tscn")
	if settings_scene:
		var settings_instance = settings_scene.instantiate()
		if settings_instance and settings_instance.has_method("show_settings"):
			passed_tests += 1
			update_test_results("✅ Settings UI scene loads successfully")
			settings_instance.queue_free()
		else:
			update_test_results("❌ Settings UI missing required methods")
	else:
		update_test_results("❌ Settings UI scene failed to load")

func update_test_results(message: String):
	test_results_label.text += message + "\n"

# Manual test functions for interactive validation
func test_audio_volume():
	"""Test audio volume changes manually"""
	print("Testing audio volume changes...")
	SettingsManager.set_setting("audio", "music_volume", 0.5)
	SettingsManager.set_setting("audio", "sfx_volume", 0.3)
	update_test_results("Manual test: Audio volumes set to 50% and 30%")

func test_video_settings():
	"""Test video settings changes manually"""
	print("Testing video settings changes...")
	SettingsManager.set_setting("video", "fullscreen", false)
	SettingsManager.set_setting("video", "vsync", true)
	update_test_results("Manual test: Video settings changed")

func test_save_load():
	"""Test save and load functionality"""
	print("Testing save/load functionality...")
	var original_music = SettingsManager.get_setting("audio", "music_volume")
	SettingsManager.set_setting("audio", "music_volume", 0.7)
	SettingsManager.save_settings()
	SettingsManager.load_settings()
	var loaded_music = SettingsManager.get_setting("audio", "music_volume")
	
	if loaded_music == 0.7:
		update_test_results("Manual test: Save/Load working correctly")
	else:
		update_test_results("Manual test: Save/Load FAILED")

func _input(event):
	"""Handle test keyboard shortcuts"""
	if event.is_action_pressed("ui_accept"):
		test_audio_volume()
	elif event.is_action_pressed("ui_up"):
		test_video_settings()
	elif event.is_action_pressed("ui_down"):
		test_save_load()