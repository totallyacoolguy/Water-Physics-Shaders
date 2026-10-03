@tool
class_name SmoothPath
extends Path2D

@export var spline_length: float = 100  ## lower = rigid and breaks less/higher = smooth and breaks more
@export var width: float = 4.0
@export var color: Color = Color.WHITE

func straighten(value) -> void:
	if (not value): return
	for i in curve.get_point_count():
		curve.set_point_in(i, Vector2())
		curve.set_point_out(i, Vector2())

func smooth(value) -> void:
	if (not value): return
	var point_count: int = curve.get_point_count()
	for i in point_count:
		var spline = get_spline(i)
		curve.set_point_in(i, -spline)
		curve.set_point_out(i, spline)

func get_spline(i):
	var last_point = get_point(i - 1)
	var next_point = get_point(i + 1)
	var spline = last_point.direction_to(next_point) * spline_length
	return spline

func get_point(i) -> Vector2:
	var point_count = curve.get_point_count()
	var wrapped_index = wrapi(i, 0, point_count)
	return curve.get_point_position(wrapped_index)

func _draw() -> void:
	var points = curve.get_baked_points()
	if points:
		draw_polyline(points, color, width, true)
