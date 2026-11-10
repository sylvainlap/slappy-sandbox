class_name Player
extends CharacterBody3D

enum View {
	FIRST_PERSON,
	THIRD_PERSON
}

## How fast the player moves on the ground.
@export var base_speed: float = 6.0
## How high the player can jump in meters.
@export var jump_height: float = 1.2
## How fast the player falls after reaching max jump height.
@export var fall_multiplier: float = 2.5

@export_category("Camera")
## How much moving the mouse moves the camera. Overwritten in settings.
@export var mouse_sensitivity: float = 0.00075
## Limits how low the player can look down.
@export var bottom_clamp: float = -90.0
## Limits how high the player can look up.
@export var top_clamp: float = 90.0

@export_category("Third Person")
## Limits how far the player can zoom in.
@export var min_zoom: float = 1.5
## Limits how far the player can zoom out.
@export var max_zoom: float = 6.0
## How quickly to zoom the camera.
@export var zoom_sensitivity: float = 0.4

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
# Stores the direction the player is trying to look this frame.
var _look := Vector2.ZERO

# Updates the cameras to swap between first and third person.
var view: View = View.FIRST_PERSON:
	set(value):
		view = value
		match view:
			View.FIRST_PERSON:
				# Get the fov of the current camera and apply it to the target.
				camera.fov = get_viewport().get_camera_3d().fov
				camera.current = true
			View.THIRD_PERSON:
				# Get the fov of the current camera and apply it to the target.
				third_person_camera.fov = get_viewport().get_camera_3d().fov
				third_person_camera.current = true

# Control the target length of the third person camera arm.
var zoom: float = min_zoom:
	set(value):
		zoom = clamp(value, min_zoom, max_zoom)
		if value < min_zoom:
			# When the player zooms all the way in swap to first person.
			view = View.FIRST_PERSON
		elif value > min_zoom:
			# When the player zooms out swap to third person.
			view = View.THIRD_PERSON

@onready var camera_target: Node3D = $CameraTarget
@onready var camera: SmoothCamera = $SmoothCamera
@onready var spring_arm_3d: SpringArm3D = %SpringArm3D
@onready var third_person_camera: Camera3D = %ThirdPersonCamera



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	frame_camera_rotation()
	camera_zoom(delta)

	# Handle gravity.
	if not is_on_floor():
		if velocity.y >= 0 and Input.is_action_pressed("jump"):
			velocity.y -= gravity * delta
		else:
			velocity.y -= gravity * delta * fall_multiplier

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Projectile motion to turn jump height into a velocity.
		velocity.y = sqrt(jump_height * 2.0 * gravity)

	# Handle movement.
	var direction: Vector3 = get_movement_direction()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * base_speed, base_speed * delta)
		velocity.z =  lerp(velocity.z, direction.z * base_speed, base_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, base_speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, base_speed * delta * 5.0)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# Capture the mouse if it is uncaptured.
	if event.is_action_pressed("click"):
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Update the _look variable to the latest mouse offset.
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_look = -event.relative * mouse_sensitivity

	# Camera controls.
	if event.is_action_pressed("toggle_view"):
		cycle_view()
	if event.is_action_pressed("zoom_in"):
		zoom -= zoom_sensitivity
	elif event.is_action_pressed("zoom_out"):
		zoom += zoom_sensitivity


# Apply the _look variables rotation to the camera.
func frame_camera_rotation() -> void:
	rotate_y(_look.x)
	# The smooth camera orients the camera to align with the target smoothly.
	camera_target.rotate_x(_look.y)
	camera_target.rotation.x = clamp(camera_target.rotation.x, deg_to_rad(bottom_clamp), deg_to_rad(top_clamp))
	# Reset the _look variable so the same offset can't be reapplied.
	_look = Vector2.ZERO


# Turn movent inputs into a locally oriented vector.
func get_movement_direction() -> Vector3:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


# Interpolate the third person distance to the target length.
func camera_zoom(delta: float) -> void:
	spring_arm_3d.spring_length = lerp(spring_arm_3d.spring_length, zoom, delta * 10.0)


func cycle_view() -> void:
	# Swap from third to first person and vice versa.
	match view:
		View.FIRST_PERSON:
			view = View.THIRD_PERSON
			# Set the default third person zoom to halfway between min and max.
			zoom = lerp(min_zoom, max_zoom, 0.5)
		View.THIRD_PERSON:
			view = View.FIRST_PERSON
		_:
			view = View.FIRST_PERSON
