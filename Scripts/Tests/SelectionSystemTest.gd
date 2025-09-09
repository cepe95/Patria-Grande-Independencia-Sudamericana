extends Control

# Test script for the unit selection system
# This script can be added to a test scene to validate selection functionality

@onready var test_results_label = Label.new()
var test_count = 0
var passed_tests = 0

func _ready():
	# Setup test results display
	test_results_label.position = Vector2(400, 10)
	test_results_label.size = Vector2(300, 200)
	add_child(test_results_label)
	
	# Wait a frame for everything to initialize
	await get_tree().process_frame
	
	# Run tests
	run_selection_tests()

func run_selection_tests():
	test_results_label.text = "Running Selection System Tests...\n\n"
	
	# Test 1: SelectionManager singleton exists
	test_singleton_exists()
	
	# Test 2: Selection methods exist
	test_selection_methods()
	
	# Test 3: Visual feedback methods exist
	test_visual_feedback()
	
	# Test 4: Movement methods exist
	test_movement_methods()
	
	# Test 5: Input actions exist
	test_input_actions()
	
	# Show final results
	update_test_results("=" * 30)
	update_test_results("Tests completed: %d/%d passed" % [passed_tests, test_count])
	if passed_tests == test_count:
		update_test_results("✅ ALL TESTS PASSED!")
	else:
		update_test_results("❌ Some tests failed")

func test_singleton_exists():
	test_count += 1
	if SelectionManager:
		passed_tests += 1
		update_test_results("✅ SelectionManager singleton exists")
	else:
		update_test_results("❌ SelectionManager singleton not found")

func test_selection_methods():
	test_count += 1
	var methods = ["select_unit", "deselect_unit", "clear_selection", "get_selected_units"]
	var all_exist = true
	
	for method in methods:
		if not SelectionManager.has_method(method):
			all_exist = false
			break
	
	if all_exist:
		passed_tests += 1
		update_test_results("✅ All selection methods exist")
	else:
		update_test_results("❌ Some selection methods missing")

func test_visual_feedback():
	test_count += 1
	var methods = ["start_selection_rect", "update_selection_rect", "finish_selection_rect"]
	var all_exist = true
	
	for method in methods:
		if not SelectionManager.has_method(method):
			all_exist = false
			break
	
	if all_exist:
		passed_tests += 1
		update_test_results("✅ Visual feedback methods exist")
	else:
		update_test_results("❌ Some visual feedback methods missing")

func test_movement_methods():
	test_count += 1
	if SelectionManager.has_method("move_selected_units_to"):
		passed_tests += 1
		update_test_results("✅ Movement methods exist")
	else:
		update_test_results("❌ Movement methods missing")

func test_input_actions():
	test_count += 1
	if InputMap.has_action("ui_shift"):
		passed_tests += 1
		update_test_results("✅ Input actions configured")
	else:
		update_test_results("❌ ui_shift action not found")

func update_test_results(text: String):
	test_results_label.text += text + "\n"

# Manual test functions that can be called from debugger
func test_select_unit():
	# Test selecting a unit
	var units_container = get_tree().current_scene.get_node_or_null("UnitsContainer")
	if units_container and units_container.get_child_count() > 0:
		var first_unit = units_container.get_child(0)
		SelectionManager.select_unit(first_unit)
		print("🧪 Manual test: Selected first unit")
		return true
	else:
		print("🧪 Manual test failed: No units found")
		return false

func test_select_multiple():
	# Test selecting multiple units in a rectangle
	var units_container = get_tree().current_scene.get_node_or_null("UnitsContainer")
	if units_container:
		var rect = Rect2(Vector2(-250, -150), Vector2(100, 100))
		SelectionManager.select_units_in_rect(rect, units_container, false)
		print("🧪 Manual test: Selected units in rectangle")
		return true
	else:
		print("🧪 Manual test failed: No units container found")
		return false

func test_move_units():
	# Test moving selected units
	if SelectionManager.get_selected_units().size() > 0:
		SelectionManager.move_selected_units_to(Vector2(100, 100))
		print("🧪 Manual test: Moved selected units")
		return true
	else:
		print("🧪 Manual test failed: No units selected")
		return false

func test_clear_selection():
	# Test clearing selection
	SelectionManager.clear_selection()
	print("🧪 Manual test: Cleared selection")
	return SelectionManager.get_selected_units().size() == 0