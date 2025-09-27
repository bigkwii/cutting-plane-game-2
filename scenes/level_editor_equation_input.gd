extends HBoxContainer

@export var A: float = 0.0
@export var B: float = 0.0
@export var C: float = 0.0

@onready var A_LINE_EDIT = $A
@onready var B_LINE_EDIT = $B
@onready var C_LINE_EDIT = $C
@onready var DELETE_BTN = $delete_btn

signal changed_input
signal eq_deleted

func _ready():
	changed_input.emit()

func disable_delete_btn():
	DELETE_BTN.disabled = true

func enable_delete_btn():
	DELETE_BTN.disabled = false

func _parse_float_input(new_text: String, max_digits_after_decimal_point: int = 5) -> Array:
	var result: String = ""
	var caret_step: int = 0
	var dot_seen: bool = false
	if new_text == "-":
		return ["-", false]
	for i in range(new_text.length()):
		var c = new_text[i]
		if c in "0123456789":
			result += c
		elif (c == "." or c == ",") and not dot_seen:
			result += "."
			dot_seen = true
		if c == "-" and i == 0:
			result += "-"
	if dot_seen:
		var parts = result.split(".")
		if parts.size() == 2:
			var decimals = parts[1]
			if decimals.length() > max_digits_after_decimal_point:
				decimals = decimals.substr(0, max_digits_after_decimal_point)
			result = parts[0] + "." + decimals
	return [result, caret_step]

func _on_A_text_changed(new_text: String):
	var old_caret_pos: int = A_LINE_EDIT.caret_column
	var parsed_text = _parse_float_input(new_text)
	A_LINE_EDIT.text = parsed_text[0]
	A = parsed_text[0].to_float()
	A_LINE_EDIT.caret_column = old_caret_pos + int(parsed_text[1]) # WHY is this variable, WHICH IS CLEARLY AND INTEGER, being interpreted as a bool???
	changed_input.emit()

func _on_B_text_changed(new_text: String):
	var old_caret_pos: int = B_LINE_EDIT.caret_column
	var parsed_text = _parse_float_input(new_text)
	B_LINE_EDIT.text = parsed_text[0]
	B = parsed_text[0].to_float()
	B_LINE_EDIT.caret_column = old_caret_pos + int(parsed_text[1]) # ditto
	changed_input.emit()

func _on_C_text_changed(new_text: String):
	var old_caret_pos: int = C_LINE_EDIT.caret_column
	var parsed_text = _parse_float_input(new_text)
	C_LINE_EDIT.text = parsed_text[0]
	C = parsed_text[0].to_float()
	C_LINE_EDIT.caret_column = old_caret_pos + int(parsed_text[1]) # ditto
	changed_input.emit()

func _on_delete_btn_pressed():
	eq_deleted.emit()
	queue_free()
