extends Node2D
## The Convex Integer Hull of a polygon.[br][br]
## Used simply to draw the hull and manage it's visibility. The vertices themselves get calculated in the parent polygon.

# -- vars --
## The vertices of the convex integer hull, in lattice coords.
@export var convex_integer_hull: PackedVector2Array = []

## The scaling factor for the hull.
var SCALING: int = DEFAULTS.SCALING
## The offset for the hull.
var OFFSET: Vector2 = DEFAULTS.OFFSET

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _draw():
	if convex_integer_hull.size() > 2:
		var points = []
		for vert in convex_integer_hull:
			points.append( vert * SCALING + OFFSET ) # this is why we need to go from packed -> array -> packed
		draw_polyline(points, Color(0, 0, 1), 2) # solid border
