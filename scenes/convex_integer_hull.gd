extends Node2D
## The Convex Integer Hull of a polygon.[br][br]
## Used simply to draw the hull and manage it's visibility. The vertices themselves get calculated in the parent polygon.

# -- vars --
## The vertices of the convex integer hull, in lattice coords.
@export var convex_integer_hull: PackedVector2Array = []
## The alpha value of the hull.
@export var alpha: = 0.0

## The scaling factor for the hull.
var SCALING: int = GLOBALS.DEFAULT_SCALING
## The offset for the hull.
var OFFSET: Vector2 = GLOBALS.DEFAULT_OFFSET

# - child nodes -
@onready var ANIM_PLAYER = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	play_idle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	queue_redraw()

func _draw():
	if convex_integer_hull.size() > 2:
		var points = []
		for vert in convex_integer_hull:
			points.append( vert * SCALING + OFFSET ) # this is why we need to go from packed -> array -> packed
		draw_polyline(points, Color(0, 0, 1, alpha), 2) # solid border

func play_show_hull():
	ANIM_PLAYER.play("show_hull")

func play_idle():
	ANIM_PLAYER.play("idle")

func play_hidden():
	ANIM_PLAYER.play("hidden")

