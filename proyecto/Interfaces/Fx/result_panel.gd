extends Node2D

@onready var label: Label = $ColorRect/Label

func set_number(value: int) -> void:
	label.text = str(value)
