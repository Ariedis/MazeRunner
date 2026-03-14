class_name TestBase
extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _results: Array[String] = []
var _test_name: String = "Unnamed Test"


func run_tests() -> void:
	pass  # Override in subclass


func assert_equal(actual, expected, label: String = "") -> void:
	if actual == expected:
		_pass(label if label else "assert_equal")
	else:
		_fail(label if label else "assert_equal", "expected %s == %s" % [str(expected), str(actual)])


func assert_not_equal(actual, not_expected, label: String = "") -> void:
	if actual != not_expected:
		_pass(label if label else "assert_not_equal")
	else:
		_fail(label if label else "assert_not_equal", "expected %s != %s" % [str(not_expected), str(actual)])


func assert_true(condition: bool, label: String = "") -> void:
	if condition:
		_pass(label if label else "assert_true")
	else:
		_fail(label if label else "assert_true", "expected true, got false")


func assert_false(condition: bool, label: String = "") -> void:
	if not condition:
		_pass(label if label else "assert_false")
	else:
		_fail(label if label else "assert_false", "expected false, got true")


func assert_gt(actual, expected, label: String = "") -> void:
	if actual > expected:
		_pass(label if label else "assert_gt")
	else:
		_fail(label if label else "assert_gt", "expected %s > %s" % [str(actual), str(expected)])


func get_pass_count() -> int:
	return _pass_count


func get_fail_count() -> int:
	return _fail_count


func get_results() -> Array[String]:
	return _results


func get_summary() -> String:
	return "[%s] PASS: %d  FAIL: %d" % [_test_name, _pass_count, _fail_count]


func _pass(label: String) -> void:
	_pass_count += 1
	_results.append("  PASS: %s" % label)


func _fail(label: String, detail: String) -> void:
	_fail_count += 1
	var msg := "  FAIL: %s — %s" % [label, detail]
	_results.append(msg)
	push_warning("[%s] %s" % [_test_name, msg])
