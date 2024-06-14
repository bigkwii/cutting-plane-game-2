extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# draw a square
func _draw():
	var points = PackedVector2Array([
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(200, 200),
		Vector2(100, 200)
	])

	var colors = PackedColorArray([
		Color(1, 0, 0, 0.2),
		Color(1, 0, 0, 0.2),
		Color(1, 0, 0, 0.2),
		Color(1, 0, 0, 0.2),
	])

	draw_polygon(points, colors)

	# make a solid outline around the square
	points.append(points[0])
	draw_polyline(points, Color(1, 0, 0, 1), 2)
