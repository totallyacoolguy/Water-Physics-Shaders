class_name Log
extends RigidBody2D

@export var density: float = 2.0
@export var volume: float = 2.0
@export var balance_dampening: float = 0.5 # Helps stop the log from wobbling forever

@onready var player: Player = get_tree().get_first_node_in_group("Player")

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

@onready var liquid_detection: Area2D = $Detection/LiquidDetection
@onready var liquid_detectionHB: CollisionShape2D = $Detection/LiquidDetection/LiquidDetectionHB
@onready var air_detection: Area2D = $Detection/AirDetection
@onready var air_detection_hb: CollisionShape2D = $Detection/AirDetection/AirDetectionHB
@onready var player_detection: Area2D = $Detection/PlayerDetection
@onready var player_detectionHB: CollisionShape2D = $Detection/PlayerDetection/PlayerDetectionHB

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var buoyant_force: float = 1300
var water_linear_damp: float = 10
var air_linear_damp: float = 5
var balance_force: float = buoyant_force - gravity
var player_force: float = balance_force
var underwater_player_force: float = balance_force - 200 # If player contact: lower subtracting value = faster rise|higher subtracting value = slower rise 
var torque_strength: float = -balance_force
var air_force: Vector2 = Vector2(0, balance_force)
var water_probe_offsets: Array = [Vector2(-40, 5), Vector2(40, 5)] # Adjust based on log width
var air_probe_offsets: Array = [Vector2(-40, -5), Vector2(40, -5)] # Adjust based on log width

func _ready() -> void:
	angular_damp = 18.0
	contact_monitor = true
	max_contacts_reported = 5

func _physics_process(_delta: float) -> void:
	var player_relative_position: Vector2 = player.global_position - global_position
	update_player_force_state()
	handle_air_and_player_forces(player_relative_position)
	handle_liquid_forces()

func apply_buoyant_force(buoyant: float) -> void:
	if (liquid_detection.get_overlapping_areas().is_empty()): push_error("No liquid overlapping")
	
	var depths: Array = []
	var total_depth: float = 0.0
	var area: Area2D = liquid_detection.get_overlapping_areas()[0]
	var water_surface_y: float = area.global_position.y + area.get_node("WaterBodyCollision").shape.get_rect().position.y
	for offset in water_probe_offsets:
		var world_offset: Vector2 = offset.rotated(rotation)
		var probe_world_pos: Vector2 = global_position + world_offset
		var depth: float = max(0, probe_world_pos.y - water_surface_y) 
		depths.append(depth)
		total_depth += depth
	
	for i in range(water_probe_offsets.size()):
		if (total_depth > 0):
			var depth_percentage: float = depths[i] / total_depth
			var dynamic_force: float = buoyant * depth_percentage
			var world_offset: Vector2 = water_probe_offsets[i].rotated(rotation)
			apply_force(Vector2(0, -dynamic_force), world_offset)

func handle_liquid_forces() -> void:
	if liquid_detection.has_overlapping_areas():
		linear_damp = water_linear_damp
		apply_buoyant_force(buoyant_force)
	else:
		linear_damp = air_linear_damp

func handle_air_and_player_forces(player_relative_position: Vector2) -> void:
	if (not air_detection.has_overlapping_areas() and not player_detection.has_overlapping_bodies()):
		apply_central_force(air_force)
		return
	
	if (player_detection.has_overlapping_bodies()):
		if (player_relative_position.y < 0): 
			apply_force(Vector2(0, player_force), player_relative_position)
		else: 
			apply_central_force(air_force)
			var calculated_torque: float = player_relative_position.x * torque_strength
			apply_torque(calculated_torque)

func update_player_force_state() -> void:
	if (not air_detection.has_overlapping_areas()):
		player_force = balance_force
	else:
		player_force = underwater_player_force
