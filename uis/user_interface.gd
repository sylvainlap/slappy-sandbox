class_name UserInterface
extends CanvasLayer

@export_category("FOV")
@export var min_fov: float = 60
@export var max_fov: float = 100
@export var default_fov: float = 75

var _paused: bool = false:
	set(value):
		_paused = value
		pause_screen.visible = _paused
		if _paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false

@onready var pause_screen: Control = $PauseScreen
@onready var pause_container: CenterContainer = $PauseScreen/PauseContainer
@onready var settings_container: MarginContainer = $PauseScreen/SettingsContainer
@onready var fov_slider: HSlider = %FOVSlider
@onready var fov_value_label: Label = %FOVValueLabel


func _ready() -> void:
	_paused = false
	fov_slider.min_value = min_fov
	fov_slider.max_value = max_fov
	fov_slider.value = default_fov


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_paused = true


func _on_resume_button_pressed() -> void:
	_paused = false


func _on_settings_button_pressed() -> void:
	pause_container.visible = false
	settings_container.visible = true


func _on_settings_back_button_pressed() -> void:
	pause_container.visible = true
	settings_container.visible = false


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_fov_slider_value_changed(value: float) -> void:
	fov_value_label.text = str(value)
	# The player is then responsible for updating the second camera to the same.
	var camera = get_viewport().get_camera_3d()
	if is_instance_valid(camera):
		camera.fov = value


func _on_fullscreen_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
