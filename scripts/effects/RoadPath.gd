extends Control

var path_points = []

func _ready():
	var vp = get_viewport_rect().size
	path_points = [
		Vector2(vp.x * 0.92, vp.y * 0.88),
		Vector2(vp.x * 0.08, vp.y * 0.88),
		Vector2(vp.x * 0.08, vp.y * 0.12),
		Vector2(vp.x * 0.92, vp.y * 0.12)
	]
	queue_redraw()

func _draw():
	print("Drawing road, size: ", size)
	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i+1], Color(0.4, 0.35, 0.5, 0.25), 20.0)
