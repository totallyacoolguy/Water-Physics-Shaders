@tool
class_name WaterSpring
extends Node2D

signal splash(index, speed)

@onready var collision: CollisionShape2D = $Area2D/CollisionShape
@onready var area: Area2D = $Area2D

var velocity: float = 0
var force: float = 0
var height: float = position.y
var target_height: float = height + 120
var motion_factor: float = 0.008
var index: int = 0

func _ready() -> void:
	area.body_entered.connect(touched_water_spring)

func water_movement(spring_constant: float, dampen: float) -> void:
	height = position.y
	var delta_x: float = height - target_height
	force = (-spring_constant * delta_x) - (velocity * dampen)
	velocity += force
	position.y += velocity

func initialize(x_position: float, id: int) -> void:
	height = 0
	target_height = 0
	velocity = 0
	position.x = x_position
	index = id

func set_collision_width(x_size: float) -> void:
	if (collision == null): collision = get_node_or_null("CollisionShape2D")
	if (collision == null or collision.shape == null): return
	var size: Vector2 = collision.shape.size
	var new_size: Vector2 = Vector2(x_size, size.y)
	collision.shape.size = new_size

func touched_water_spring(body: Node2D) -> void:
	var speed: float = 0.0
	if (body is RigidBody2D):
		speed = body.linear_velocity.y * motion_factor
	else:
		speed = body.velocity.y * motion_factor
	splash.emit(index, speed)
