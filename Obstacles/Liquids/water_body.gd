@tool
class_name WaterBody
extends Node2D

@export var spring_constant: float = 0.015
@export var dampen: float = 0.03
@export var spread: float = 0.002 ## how much velocity transfered over to other node
@export var water_thickness: float = 1.1:
	set(value):
		water_thickness = value
		if Engine.is_editor_hint() and is_inside_tree() and water_border:
			water_border.width = water_thickness
@export var distance_between_springs: float = 27.5:
	set(value):
		distance_between_springs = value
		if (Engine.is_editor_hint()):
			setup_water_body()
@export var spring_number: int = 7:
	set(value):
		spring_number = value
		if (Engine.is_editor_hint()):
			setup_water_body()
@export var depth: float = 1000:
	set(value):
		depth = value
		if (Engine.is_editor_hint()):
			setup_water_body()
@export var water_spring: PackedScene
@export var death_particles: PackedScene

@onready var water_border: SmoothPath = $WaterBorder
@onready var water_polygon: Polygon2D = $WaterPolygon

@onready var water_body_area: Area2D = $WaterBodyArea
@onready var water_body_collision: CollisionShape2D = $WaterBodyArea/WaterBodyCollision

var passes: int = 1
var water_length: float = distance_between_springs * spring_number
var target_height: float = global_position.y
var bottom: float = target_height + depth
var springs: Array[WaterSpring] = []

var player: Player = null 
var is_player_inside: bool = false
@export var lag_speed: float = 2.0 # Lower = longer, more dramatic trail lag
var lagged_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		setup_water_body()
	else:
		player = get_tree().get_first_node_in_group("Player") as Player
		water_body_area.body_entered.connect(touched_water_body)
		water_body_area.body_exited.connect(touched_water_body)
		setup_water_body()

func _physics_process(_delta: float) -> void:
	if (Engine.is_editor_hint()): pass
	for i in springs:
		if (i and i.has_method("water_movement")):
			i.water_movement(spring_constant, dampen)
	
	var left_deltas: Array[float] = []
	var right_deltas: Array[float] = []
	left_deltas.resize(springs.size())
	right_deltas.resize(springs.size())
	left_deltas.fill(0.0)
	right_deltas.fill(0.0)
	apply_spread(left_deltas, right_deltas)
	new_border()
	draw_water_body()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): pass
	if (is_player_inside and is_instance_valid(player) and water_polygon.material):
		lagged_velocity = lagged_velocity.lerp(player.velocity, lag_speed * delta)
		water_polygon.material.set_shader_parameter("lagged_velocity", lagged_velocity)
		var player_global_canvas_pos = player.get_global_transform_with_canvas().origin
		var screen_size = get_viewport_rect().size
		var player_screen_uv = player_global_canvas_pos / screen_size
		water_polygon.material.set_shader_parameter("player_screen_pos", player_screen_uv)

func apply_spread(left_deltas: Array, right_deltas: Array) -> void:
	for j in range(passes):
		for i in range(springs.size()):
			if (i > 0):
				left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
				springs[i-1].velocity += left_deltas[i]
			if (i < springs.size()-1):
				right_deltas[i] = spread * (springs[i].height - springs[i+1].height)
				springs[i+1].velocity += right_deltas[i] 

func draw_water_body() -> void:
	var curve = water_border.curve
	var points = Array(curve.get_baked_points())
	var water_polygon_points: Array = points
	var first_index: int = 0
	var last_index: int = water_polygon_points.size() - 1
	water_polygon_points.append(Vector2(water_polygon_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(water_polygon_points[first_index].x, bottom))
	water_polygon_points = PackedVector2Array(water_polygon_points)
	water_polygon.set_polygon(water_polygon_points)

func new_border():
	var curve = Curve2D.new().duplicate()
	var surface_points: Array[Vector2] = []
	for i in range(springs.size()):
		surface_points.append(springs[i].position)
	
	for i in range(surface_points.size()):
		curve.add_point(surface_points[i])
	
	water_border.curve = curve
	water_border.smooth(true)
	water_border.queue_redraw()

func setup_water_body() -> void:
	if (water_border == null): water_border = get_node_or_null("WaterBorder") 
	if (water_body_area == null): water_body_area = get_node_or_null("WaterBodyArea")
	if (water_body_collision == null): water_body_collision = get_node_or_null("WaterBodyArea/WaterBodyCollision")
	if (not water_border or not water_body_area or not water_body_collision): return
	
	bottom = depth
	for s in springs:
		if (is_instance_valid(s)):
			s.queue_free()
	
	springs.clear()
	var total_length: float = distance_between_springs * (spring_number - 1)
	water_border.width = water_thickness
	setup_water_springs()
	setup_water_body_rect(total_length)

func setup_water_body_rect(total_length: float) -> void:
	var rectangle: RectangleShape2D = RectangleShape2D.new().duplicate()
	var rect_position: Vector2 = Vector2(total_length/2, depth/2)
	var rect_size: Vector2 = Vector2(total_length, depth)
	water_body_area.position = rect_position
	rectangle.size = rect_size
	water_body_collision.shape = rectangle

func setup_water_springs() -> void:
	for i in range(spring_number):
		var x_position: float = distance_between_springs * i
		var water_node: WaterSpring = water_spring.instantiate()
		add_child(water_node)
		springs.append(water_node)
		water_node.initialize(x_position, i)
		water_node.set_collision_width(distance_between_springs)
		water_node.connect("splash", splash)

func splash(index: int, speed: float) -> void:
	if (index >=0 and index < springs.size()):
		springs[index].velocity += speed

func touched_water_body(body: Node2D) -> void:
	if (body.is_in_group("Player")):
		is_player_inside = not is_player_inside  
	var clone := death_particles.instantiate()
	get_tree().current_scene.add_child.call_deferred(clone)
	clone.global_position = body.global_position
	clone.emitting = true
	await clone.finished
	clone.queue_free()
