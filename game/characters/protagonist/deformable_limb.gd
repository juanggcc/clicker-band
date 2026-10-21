@tool
extends Polygon2D
## Picking-arm mesh with a fixed sleeve attachment.

var rest_points: PackedVector2Array


func configure(image: Texture2D, area: Rect2, spacing: float = 9.0) -> void:
	rest_points.clear()
	texture = image
	var columns: int = ceili(area.size.x / spacing)
	var rows: int = ceili(area.size.y / spacing)
	var triangles: Array[PackedInt32Array] = []
	for y: int in range(rows + 1):
		for x: int in range(columns + 1):
			rest_points.append(area.position + area.size * Vector2(float(x) / columns, float(y) / rows))
	for y: int in range(rows):
		for x: int in range(columns):
			var a: int = y * (columns + 1) + x
			var b: int = a + 1
			var c: int = a + columns + 1
			triangles.append(PackedInt32Array([a, b, c]))
			triangles.append(PackedInt32Array([b, c + 1, c]))
	uv = rest_points
	polygon = rest_points
	polygons = triangles


func strum(angle: float) -> void:
	var points: PackedVector2Array = rest_points.duplicate()
	var elbow: Vector2 = Vector2(240, 410)
	for i: int in points.size():
		var p: Vector2 = rest_points[i]
		var weight: float = smoothstep(389.0, 431.0, p.y)
		points[i] = p.lerp(elbow + (p - elbow).rotated(angle), weight)
	polygon = points

