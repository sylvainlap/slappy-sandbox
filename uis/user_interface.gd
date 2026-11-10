class_name UserInterface
extends CanvasLayer

var paused: bool = false:
	set(value):
		paused = value
		pause_screen.visible = paused
		if paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false

@onready var pause_screen: Control = $PauseScreen


func _ready() -> void:
	paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		paused = true


func _on_resume_button_pressed() -> void:
	paused = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()
