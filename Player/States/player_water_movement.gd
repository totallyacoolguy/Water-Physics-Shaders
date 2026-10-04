class_name PlayerWaterMovement
extends State

signal dashed
signal default
signal jump
signal slide

@export var actor: Player
@export var animator: AnimatedSprite2D
@export var animation: AnimationPlayer
@export var coyote_timer: Timer
@export var dash_timer: Timer
@export var water_jump_timer: Timer
@export var liquid_detection: Area2D

func _ready() -> void:
	set_physics_process(false)
	set_process(false)

func _enter_state() -> void:
	GravityManager.water_gravity(actor)
	actor.able_double_jump = true
	set_physics_process(true)
	set_process(true)

func _exit_state() -> void:
	GravityManager.full_gravity(actor)
	actor.could_quick_fall = false
	set_process(false)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var input_axis_x: float = Input.get_axis("move_left", "move_right")
	var input_axis_y: float = Input.get_axis("move_up", "move_down")
	handle_acceleration_x(input_axis_x,delta) 
	handle_acceleration_y(input_axis_y,delta)
	handle_friction_x(input_axis_x,delta)
	handle_water_timer()
	
	if (Input.is_action_just_pressed("dash") and Input.is_action_pressed("move_down") and dash_timer.time_left == 0): 
		slide.emit()
	elif (Input.is_action_just_pressed("dash") and dash_timer.time_left == 0): 
		dashed.emit()
	elif ((Input.is_action_pressed("move_up") or water_jump_timer.time_left > 0) and not liquid_detection.has_overlapping_areas()):
		jump.emit()
	elif (not liquid_detection.has_overlapping_areas()):
		default.emit()

func _process(_delta: float) -> void:
	animator.play("walk")

func handle_acceleration_x(input_axis: float, delta: float) -> void:
	if (input_axis != 0):
		actor.velocity.x = move_toward(actor.velocity.x, input_axis * actor.character_data.speed, actor.character_data.acceleration * delta)

func handle_acceleration_y(input_axis: float, delta: float) -> void:
	if (input_axis != 0):
		actor.velocity.y = move_toward(actor.velocity.y, input_axis * actor.character_data.speed, actor.character_data.acceleration * delta)

func handle_friction_x(input_axis: float, delta: float) -> void:
	if (input_axis == 0):
		actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)

func handle_water_timer() -> void:
	if (Input.is_action_just_released("move_up")):
		water_jump_timer.start()
